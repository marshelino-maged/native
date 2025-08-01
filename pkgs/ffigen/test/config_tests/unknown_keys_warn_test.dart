// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:ffigen/src/strings.dart' as strings;
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  var logString = '';
  group('unknown_keys_warn_test', () {
    setUpAll(() {
      final logArr = <String>[];
      final logger = logToArray(logArr, Level.WARNING);
      testConfig('''
${strings.name}: 'NativeLibrary'
${strings.description}: 'Warn for unknown keys.'
${strings.output}: 'unused'
${strings.headers}:
  ${strings.entryPoints}:
    - '${absPath('test/header_parser_tests/packed_structs.h')}'
'warn-1': 'warn'
${strings.typeMap}:
  'warn-2': 'warn'
  'warn-3': 'warn'
        ''', logger: logger);
      logString = logArr.join('\n');
    });
    test('Warn for unknown keys.', () {
      expect(logString.contains('warn-1'), true);
      expect(logString.contains('warn-2'), true);
      expect(logString.contains('warn-3'), true);
    });
  });
}
