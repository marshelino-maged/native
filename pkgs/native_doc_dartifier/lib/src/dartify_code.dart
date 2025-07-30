// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:chromadb/chromadb.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'code_processor.dart';
import 'prompts.dart';
import 'public_abstractor.dart';

bool firstTime = true;

Future<String> dartifyNativeCode(
  String sourceCode,
  String bindingsPath, {
  bool useRAG = false,
  bool firstTime = true,
}) async {
  final bindingsFile = File(bindingsPath);

  if (!await bindingsFile.exists()) {
    stderr.writeln('File not found: $bindingsPath');
    exit(1);
  }

  final apiKey = Platform.environment['GEMINI_API_KEY'];

  if (apiKey == null) {
    stderr.writeln(r'No $GEMINI_API_KEY environment variable');
    exit(1);
  }

  final bindings = await bindingsFile.readAsString();

  final model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: apiKey,
    generationConfig: GenerationConfig(
      temperature: 0,
      topK: 64,
      topP: 0.95,
      maxOutputTokens: 8192,
      responseMimeType: 'application/json',
    ),
  );

  final bindingsSummary = generateBindingsSummary(bindings);
  print('Total Number of Classes: ${bindingsSummary.length}');
  final tokenCount = await model.countTokens([
    Content.text(bindingsSummary.join('\n')),
  ]);
  print('Total Bindings Tokens: ${tokenCount.totalTokens}');

  String? ragSummary;
  if (useRAG) {
    final client = ChromaClient();
    final collection = await client.getCollection(name: 'bindings');
    final embeddingModel = GenerativeModel(
      apiKey: apiKey,
      model: 'gemini-embedding-001',
    );

    if (firstTime) {
      const batchSize = 90;
      final batchEmbededContent = <BatchEmbedContentsResponse>[];

      for (var i = 0; i < bindingsSummary.length; i += batchSize) {
        print('Processing batch from $i to ${i + batchSize}');
        final batch = bindingsSummary.sublist(
          i,
          i + batchSize > bindingsSummary.length
              ? bindingsSummary.length
              : i + batchSize,
        );

        final batchResponse = await embeddingModel.batchEmbedContents(
          List.generate(
            batch.length,
            (index) => EmbedContentRequest(Content.text(batch[index])),
          ),
        );

        batchEmbededContent.add(batchResponse);
      }

      final embeddings = <List<double>>[];
      for (final response in batchEmbededContent) {
        for (final embedContent in response.embeddings) {
          embeddings.add(embedContent.values);
        }
      }

      await collection.add(
        ids: List.generate(
          bindingsSummary.length,
          (index) => (index + 1).toString(),
        ),
        embeddings: embeddings,
        documents: bindingsSummary,
      );

      print('Added ${bindingsSummary.length} documents to the collection.');
    }

    print('Querying the collection...');
    final queryEmbeddings = await embeddingModel
        .embedContent(Content.text(sourceCode))
        .then((embedContent) => embedContent.embedding.values);
    final query = await collection.query(
      queryEmbeddings: [queryEmbeddings],
      nResults: 10,
    );

    print('RAG Number of Classes: ${query.documents?.length}');
    final tokenCount = await model.countTokens([
      Content.text(query.documents!.join('\n')),
    ]);

    print('RAG Bindings Tokens: ${tokenCount.totalTokens}');

    ragSummary = query.documents!.join('\n');
    print('Java Snippet: $sourceCode');
    print('RAG Summary: $ragSummary');
  }

  final translatePrompt = TranslatePrompt(
    sourceCode,
    ragSummary ?? bindingsSummary.join('\n'),
  );

  final chatSession = model.startChat();

  final response = await chatSession.sendMessage(
    Content.text(translatePrompt.prompt),
  );
  var mainCode = translatePrompt.getParsedResponse(response.text ?? '');
  var helperCode = '';

  final codeProcessor = CodeProcessor();
  mainCode = codeProcessor.addImports(mainCode, [
    'package:jni/jni.dart',
    bindingsFile.path,
  ]);

  for (var i = 0; i < 3; i++) {
    final errorMessage = await codeProcessor.analyzeCode(mainCode, helperCode);
    if (errorMessage.isEmpty) {
      break;
    }
    stderr.writeln('Dart analysis found issues: $errorMessage');
    final fixPrompt = FixPrompt(mainCode, helperCode, errorMessage);
    final fixResponse = await chatSession.sendMessage(
      Content.text(fixPrompt.prompt),
    );
    final fixedCode = fixPrompt.getParsedResponse(fixResponse.text ?? '');

    mainCode = fixedCode.mainCode;
    helperCode = fixedCode.helperCode;
  }
  mainCode = codeProcessor.removeImports(mainCode);
  return mainCode;
}

// void main() async {
//   final client = ChromaClient();
//   await client.createCollection(name: 'bindings');
//   print('Finished');
// }
