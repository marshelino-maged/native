// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:hooks/hooks.dart';
import 'package:hooks/src/args_parser.dart';

void main(List<String> args) async {
  final inputPath = getInputArgument(args);
  final buildInput = BuildInput(
    json.decode(File(inputPath).readAsStringSync()) as Map<String, Object?>,
  );
  await File.fromUri(buildInput.outputFile).writeAsString(_wrongContents);
}

const _wrongContents = '''
timestamp: 2023-07-28 14:22:45.000
assets:
  foo: 123
dependencies: []
metadata: {}
version: 1.0.0
''';
