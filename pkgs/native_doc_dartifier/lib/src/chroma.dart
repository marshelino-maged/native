import 'dart:io';

import 'package:chromadb/chromadb.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'code_processor.dart';
import 'prompts.dart';
import 'public_abstractor.dart';

// Test Large Context with RAG
// First you need to get the docker image: docker pull chromadb/chroma:0.6.3
// Then run it: docker run -p 8000:8000 chromadb/chroma:0.6.3

Future<String> dartifyNativeCodeWithRAG(
  String sourceCode,
  String bindingsPath, {
  bool useRAG = false,
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

  if (useRAG) {
    final embededContent = await model.batchEmbedContents(
      List.generate(
        bindingsSummary.length,
        (index) => EmbedContentRequest(Content.text(bindingsSummary[index])),
      ),
    );

    final embeddings =
        embededContent.embeddings.map((embedding) => embedding.values).toList();

    final client = ChromaClient();
    final collection = await client.createCollection(name: 'test');
    await collection.add(
      ids: List.generate(
        bindingsSummary.length,
        (index) => (index + 1).toString(),
      ),
      embeddings: embeddings,
      documents: bindingsSummary,
    );

    print('Added ${bindingsSummary.length} documents to the collection.');

    print('Querying the collection...');
    final queryEmbeddings = await model
        .embedContent(Content.text(sourceCode))
        .then((embedContent) => embedContent.embedding.values);
    final query = await collection.query(
      queryEmbeddings: [queryEmbeddings],
      nResults: 10,
    );

    final ragSummary = query.documents?.join('\n') ?? '';
    print('RAG Summary: $ragSummary');

    await client.deleteCollection(name: 'test');
    return ragSummary;
  }

  final translatePrompt = TranslatePrompt(
    sourceCode,
    bindingsSummary.join('\n'),
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
