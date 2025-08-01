// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:ffigen/src/config_provider.dart';
import 'package:ffigen/src/header_parser.dart' as parser;
import 'package:ffigen/src/strings.dart' as strings;
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('separate_definition', () {
    setUpAll(() {
      logWarnings(Level.SEVERE);
    });
    test('different header order', () {
      final entryPoints = [
        'test/header_parser_tests/separate_definition_base.h',
        'test/header_parser_tests/separate_definition.h',
      ];
      final library1String = parser
          .parse(testContext(_makeConfig(entryPoints)))
          .generate();
      final library2String = parser
          .parse(testContext(_makeConfig(entryPoints.reversed.toList())))
          .generate();

      expect(library1String, library2String);
    });
  });
}

FfiGen _makeConfig(List<String> entryPoints) {
  final entryPointBuilder = StringBuffer();
  for (final ep in entryPoints) {
    entryPointBuilder.writeln('    - $ep');
  }
  final config = testConfig('''
${strings.name}: 'Bindings'
${strings.output}: 'unused'

${strings.headers}:
  ${strings.entryPoints}:
${entryPointBuilder.toString()}
''');
  return config;
}
