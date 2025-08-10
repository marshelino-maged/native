// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

// getData Tool Setup
String getData() => '5,5,5,6,6';

final getDataTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'getData',
      'get the data numbers as a string seperated with comma.',
      null,
    ),
  ],
);

// calculateData Tool Setup
int calculateData(List<int> data) => data.reduce((a, b) => a + b);

final calculateDataTool = Tool(
  functionDeclarations: [
    FunctionDeclaration(
      'calculateData',
      'Calculates the data and returns the result.',
      Schema.object(
        properties: {'numbers': Schema.array(items: Schema.integer())},
      ),
    ),
  ],
);

void main() async {
  final apiKey = Platform.environment['GEMINI_API_KEY'];

  if (apiKey == null) {
    stderr.writeln(r'No $GEMINI_API_KEY environment variable');
    exit(1);
  }

  final model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: apiKey,
    generationConfig: GenerationConfig(
      temperature: 0.5,
      topK: 64,
      topP: 0.95,
      maxOutputTokens: 8192,
    ),

    tools: [getDataTool, calculateDataTool],
  );

  const prompt = '''
you are an assistant that can query the database to get the data, then you can use some tool to calculate the result of those data.
you can use provided tools.
use one tool at a time, and if you need to use the tool again, you can do that.
at the end output the result in a json format like this:
{
  "result": <result>,
}
  ''';

  final chat = model.startChat();

  var response = await chat.sendMessage(Content.text(prompt));
  while (true) {
    print('Response\'s function calls:');
    print(response.functionCalls.toString());
    if (response.functionCalls.isNotEmpty) {
      final functionCall = response.functionCalls.first;

      if (functionCall.name == 'getData') {
        final data = getData();
        print('Tool getting data: $data');

        // Send the tool's result back to the model for a final response.
        final secondResponse = await chat.sendMessage(
          Content.functionResponse('getData', {'data': data}),
        );
        response = secondResponse;
      } else if (functionCall.name == 'calculateData') {
        print('Tool calculating data: ${functionCall.args}');
        final dynamicNumbers = functionCall.args['numbers'] as List<dynamic>;
        final intNumbers = dynamicNumbers.cast<int>();

        final result = calculateData(intNumbers);
        print('Tool getting result: $result');

        // Send the tool's result back to the model for a final response.
        final secondResponse = await chat.sendMessage(
          Content.functionResponse('calculateData', {'result': result}),
        );

        response = secondResponse;
      }
    } else {
      print(response.text);
      break;
    }
  }
}
