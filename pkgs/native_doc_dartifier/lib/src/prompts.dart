// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

abstract class Prompts {
  // TODO: Add few-shot examples for better translation quality.
  // Use examples from https://github.com/dart-lang/native/issues/2343
  static String _fewShotExamples() => '';

  static const String _schema = '''
{
  "dartCode": "Dart code here"
}
''';

  static String translatePrompt(String sourceCode, String bindingsSummary) =>
      '''
Only output the required snippet of code without additional comments or explanations. 

You are translator expert that converts Java/Kotlin code to equivilant Dart code using the help of JNI bindings.
You will be given JNI bindings use it to correctly write Dart snippet code.
Your task is to accurately translate the provided Java/Kotlin code into equivalent Dart code.

Notes:
- when having Dart string use `'DartValue'.toJString()` method to convert it to JString.
- when having JString use `'JStringValue'.toDartString()` method to convert it to Dart string.
- when translate anonymous class implementation to dart it should be converted to be
  "ClassName.implement(\n \$ClassName(\n  method1: (param1) {\n // implementation \n}))"
- when translating method calls, ensure to use the correct method name that has the same parameters as the given Java/Kotlin method.

- use variables name similar to the original Java/Kotlin code.
- ensure that the Dart code is idiomatic and follows Dart conventions.
- use single quote for strings.
- use `final` for variables that are not reassigned.

Here is the generated Dart bindings Summary classes, fields and methods:
```dart
$bindingsSummary
```

Here is the Java/Kotlin code that should be converted:
```java
$sourceCode
```

${_fewShotExamples()}

output the response in JSON format:
$_schema
''';

  static String parseTranslateResponse(String response) {
    print('Response: $response');
    final json = jsonDecode(response) as Map<String, dynamic>;
    final dartCode = json['dartCode'].toString();
    print('Dart Code: $dartCode');
    return dartCode;
  }
}
