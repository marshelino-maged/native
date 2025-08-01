// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:ffigen/src/code_generator.dart';
import 'package:ffigen/src/header_parser.dart' show parse;
import 'package:ffigen/src/strings.dart' as strings;
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('exclude_all_by_default', () {
    test('exclude_all_by_default test flag false', () {
      final config = testConfig('''
${strings.name}: 'NativeLibrary'
${strings.description}: 'exclude_all_by_default test'
${strings.output}: 'unused'
${strings.excludeAllByDefault}: false
${strings.headers}:
  ${strings.entryPoints}:
    - '${absPath('test/config_tests/exclude_all_by_default.h')}'
''');

      final library = parse(testContext(config));
      expect(library.getBinding('func'), isA<Func>());
      expect(library.getBinding('Struct'), isA<Struct>());
      expect(library.getBinding('Union'), isA<Union>());
      expect(library.getBinding('global'), isA<Global>());
      expect(library.getBinding('MACRO'), isA<Constant>());
      expect(library.getBinding('Enum'), isA<EnumClass>());
      expect(library.getBinding('unnamedEnum'), isA<Constant>());
    });

    test('exclude_all_by_default test flag true', () {
      final config = testConfig('''
${strings.name}: 'NativeLibrary'
${strings.description}: 'exclude_all_by_default test'
${strings.output}: 'unused'
${strings.excludeAllByDefault}: true
${strings.headers}:
  ${strings.entryPoints}:
    - '${absPath('test/config_tests/exclude_all_by_default.h')}'
''');

      final library = parse(testContext(config));
      expect(() => library.getBinding('func'), throwsException);
      expect(() => library.getBinding('Struct'), throwsException);
      expect(() => library.getBinding('Union'), throwsException);
      expect(() => library.getBinding('global'), throwsException);
      expect(() => library.getBinding('MACRO'), throwsException);
      expect(() => library.getBinding('Enum'), throwsException);
      expect(() => library.getBinding('unnamedEnum'), throwsException);
    });
  });
}
