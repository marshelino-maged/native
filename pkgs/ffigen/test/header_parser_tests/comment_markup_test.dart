// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:ffigen/src/code_generator.dart';
import 'package:ffigen/src/header_parser.dart' as parser;
import 'package:ffigen/src/strings.dart' as strings;
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

late Library actual;
void main() {
  group('comment_markup_test', () {
    setUpAll(() {
      logWarnings(Level.SEVERE);
      actual = parser.parse(
        testContext(
          testConfig('''
${strings.name}: 'NativeLibrary'
${strings.description}: 'Comment Markup Test'
${strings.output}: 'unused'
${strings.headers}:
  ${strings.entryPoints}:
    - '${absPath('test/header_parser_tests/comment_markup.h')}'
${strings.comments}:
  ${strings.style}: ${strings.any}
  ${strings.length}: ${strings.full}
        '''),
        ),
      );
    });

    test('Expected bindings', () {
      matchLibraryWithExpected(
        actual,
        'header_parser_comment_markup_test_output.dart',
        [
          'test',
          'header_parser_tests',
          'expected_bindings',
          '_expected_comment_markup_bindings.dart',
        ],
      );
    });
  });
}
