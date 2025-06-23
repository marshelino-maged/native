// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Prompts {
  // TODO: Add few-shot examples for better translation quality.
  // Use examples from https://github.com/dart-lang/native/issues/2343
  static String _fewShotExamples() => '';

  static String translatePrompt(String sourceCode, String bindingsSummary) =>
      '''
Only output the required snippet of code without additional comments or explanations. 

You are a code translator expert that converts Java/Kotlin code to Dart code.
You will be given a Java/Kotlin code snippet and a summary of the classes, methods, and fields available in the JNI bindings.
Your task is to accurately translate the provided code into equivalent Dart code, ensuring that the Dart code uses the accurate class names, method names, and field names as specified in the bindings summary.

Notes:
- when there is a string passed to a parameter it should be converted using ".toJString()" ... while when returned it should be converted using ".toDartString()"
- the nested classes should be resolved by concatenating them using the "_" sign.
- when translate anonymous class implementation to dart it should be converted to be
  "ClassName.implement(\$ClassName(method1: (param1) {// implementation}))"

Here is the generated bindings classes, fields and methods:
```$bindingsSummary```

Here is the Java/Kotlin code that should be converted:
```$sourceCode```

${_fewShotExamples()}
''';
}
