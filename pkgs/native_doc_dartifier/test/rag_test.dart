import 'dart:core';
import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:native_doc_dartifier/src/public_abstractor.dart';
import 'package:test/test.dart';

import 'models.dart';
import 'objectbox.g.dart';

Future<List<String>> queryDB(
  String javaSnippet,
  GenerativeModel embeddingModel,
) async {
  final store = openStore();
  final classSummaryBox = store.box<ClassSummaryModel>();
  final queryEmbeddings = await embeddingModel
      .embedContent(Content.text(javaSnippet))
      .then((embedContent) => embedContent.embedding.values);

  // The Database makes use of HNSW algorithm for vector search which
  // is O(log n) in search time complexity not O(n).
  // but the tradeoff that it gets the approximate nearest neighbor
  // instead of the exact one
  // so make it to return approx 100 nearest neighbors and then get the top 10.
  final query =
      classSummaryBox
          .query(
            ClassSummaryModel_.embeddings.nearestNeighborsF32(
              queryEmbeddings,
              100,
            ),
          )
          .build();
  query.limit = 10;
  final resultWithScore = query.findWithScores();
  final result = resultWithScore.map((e) => e.object.summary).toList();

  query.close();
  store.close();
  return result;
}

Future<void> main() async {
  // open the bindings file and get the summary (AST) of each class
  final bindingsFile = File('test/bindings.dart');
  if (!await bindingsFile.exists()) {
    stderr.writeln('File not found: ');
    exit(1);
  }

  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null) {
    stderr.writeln(r'No $GEMINI_API_KEY environment variable');
    exit(1);
  }

  final bindings = await bindingsFile.readAsString();

  final abstractor = PublicAbstractor();
  parseString(content: bindings).unit.visitChildren(abstractor);
  final classesSummary = abstractor.getClassesSummary();

  print('Total Number of Classes: ${classesSummary.length}');

  final geminiModel = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: apiKey,
  );

  final tokenCount = await geminiModel.countTokens([
    Content.text(classesSummary.join('\n')),
  ]);
  print('Total Bindings Tokens: ${tokenCount.totalTokens}');

  // get embeddings of each class summary
  final store = openStore();
  final classSummaryBox = store.box<ClassSummaryModel>();

  final embeddingModel = GenerativeModel(
    apiKey: apiKey,
    model: 'gemini-embedding-001',
  );

  const batchSize = 100;
  final batchEmbededContent = <BatchEmbedContentsResponse>[];

  for (var i = 0; i < classesSummary.length; i += batchSize) {
    print('Processing batch from $i to ${i + batchSize}');
    final batch = classesSummary.sublist(
      i,
      i + batchSize > classesSummary.length
          ? classesSummary.length
          : i + batchSize,
    );

    final batchResponse = await embeddingModel.batchEmbedContents(
      List.generate(
        batch.length,
        (index) => EmbedContentRequest(Content.text(batch[index])),
      ),
    );

    batchEmbededContent.add(batchResponse);
    await Future<void>.delayed(const Duration(minutes: 1));
  }

  final embeddings = <List<double>>[];
  for (final response in batchEmbededContent) {
    for (final embedContent in response.embeddings) {
      embeddings.add(embedContent.values);
    }
  }

  final classSummaries = <ClassSummaryModel>[];
  for (var i = 0; i < classesSummary.length; i++) {
    classSummaries.add(ClassSummaryModel(classesSummary[i], embeddings[i]));
  }
  classSummaryBox.putMany(classSummaries);

  print('Added ${classesSummary.length} documents to the ObjectBox DB.');

  test('Snippet that uses Accumulator only', () async {
    const javaSnippet = '''
Boolean overloadedMethods() {
    Accumulator acc1 = new Accumulator();
    acc1.add(10);
    acc1.add(10, 10);
    acc1.add(10, 10, 10);

    Accumulator acc2 = new Accumulator(20);
    acc2.add(acc1);

    Accumulator acc3 = new Accumulator(acc2);
    return acc3.accumulator == 80;
}
''';
    final documents = await queryDB(javaSnippet, embeddingModel);
    final ragSummary = documents.join('\n');

    print('Query Results:');
    for (var i = 0; i < documents.length; i++) {
      print(documents[i].split('\n')[0]);
    }

    expect(ragSummary.contains('class Accumulator'), isTrue);

    final tokens = await geminiModel.countTokens([Content.text(ragSummary)]);
    print('Number of Tokens in the RAG Summary: ${tokens.totalTokens}');
  });

  test('Snippet that uses Example only', () async {
    const javaSnippet = '''
Boolean useEnums() {
    Example example = new Example();
    Boolean isTrueUsage = example.enumValueToString(Operation.ADD) == "Addition";
    return isTrueUsage;
}''';
    final documents = await queryDB(javaSnippet, embeddingModel);
    final ragSummary = documents.join('\n');

    print('Query Results:');
    for (var i = 0; i < documents.length; i++) {
      print(documents[i].split('\n')[0]);
    }

    expect(ragSummary.contains('class Example'), isTrue);

    final tokens = await geminiModel.countTokens([Content.text(ragSummary)]);
    print('Number of Tokens in the RAG Summary: ${tokens.totalTokens}');
  });

  test('Snippet that uses both FileReader and BufferReader', () async {
    const javaSnippet = '''
public class ReadFile {
    public static void main(String[] args) {
        String filePath = "my-file.txt";
        try (
            FileReader fileReader = new FileReader(filePath);
            BufferedReader bufferedReader = new BufferedReader(fileReader)
        ) {
            String line = bufferedReader.readLine();
            System.out.println("The first line of the file is: " + line);
        } catch (IOException e) {
            System.err.println("An error occurred while reading the file: " + e.getMessage());
        }
    }
}''';
    final documents = await queryDB(javaSnippet, embeddingModel);
    final ragSummary = documents.join('\n');

    print('Query Results:');
    for (var i = 0; i < documents.length; i++) {
      print(documents[i].split('\n')[0]);
    }

    expect(ragSummary.contains('class FileReader'), isTrue);
    expect(ragSummary.contains('class BufferedReader'), isTrue);

    final tokens = await geminiModel.countTokens([Content.text(ragSummary)]);
    print('Number of Tokens in the RAG Summary: ${tokens.totalTokens}');
  });

  store.close();
}
