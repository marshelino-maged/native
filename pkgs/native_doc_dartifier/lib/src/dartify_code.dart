// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'prompts.dart';
import 'public_abstractor.dart';

Future<String> dartifyNativeCode(String sourceCode, String bindingsPath) async {
  final file = File(bindingsPath);

  if (!await file.exists()) {
    stderr.writeln('File not found: $bindingsPath');
    exit(1);
  }

  final apiKey = Platform.environment['GEMINI_API_KEY'];

  if (apiKey == null) {
    stderr.writeln(r'No $GEMINI_API_KEY environment variable');
    exit(1);
  }

  final bindings = await file.readAsString();

  final model = GenerativeModel(
    model: 'gemini-1.5-flash-latest',
    apiKey: apiKey,
    generationConfig: GenerationConfig(
      temperature: 0.1,
      topK: 64,
      topP: 0.95,
      maxOutputTokens: 8192,
      responseMimeType: 'text/plain',
    ),
  );

  final prompt = Prompts.translatePrompt(
    sourceCode,
    generateBindingsSummary(bindings),
  );
  final content = [Content.text(prompt)];
  print(prompt);
  final response = await model.generateContent(content);

  return response.text?.trim() ?? '';
}

void main() async {
  const code = '''public void onClick() {
    ImageCapture.OutputFileOptions outputFileOptions =
            new ImageCapture.OutputFileOptions.Builder(new File(...)).build();
    imageCapture.takePicture(outputFileOptions, cameraExecutor,
        new ImageCapture.OnImageSavedCallback() {
            @Override
            public void onImageSaved(ImageCapture.OutputFileResults outputFileResults) {
                // insert your code here.
            }
            @Override
            public void onError(ImageCaptureException error) {
                // insert your code here.
            }
       }
    );
}
''';
  const bindingsPath =
      '/home/marshelino/Native/pkgs/native_doc_dartifier/lib/src/camerax.dart';

  try {
    final dartCode = await dartifyNativeCode(code, bindingsPath);
    print(dartCode);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
