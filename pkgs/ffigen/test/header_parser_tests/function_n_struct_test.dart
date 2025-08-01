// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:ffigen/src/code_generator.dart';
import 'package:ffigen/src/header_parser.dart' as parser;
import 'package:ffigen/src/strings.dart' as strings;
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

late Library actual, expected;

void main() {
  group('function_n_struct_test', () {
    setUpAll(() {
      logWarnings(Level.SEVERE);
      expected = expectedLibrary();
      actual = parser.parse(
        testContext(
          testConfig('''
${strings.name}: 'NativeLibrary'
${strings.description}: 'Function And Struct Test'
${strings.output}: 'unused'

${strings.headers}:
  ${strings.entryPoints}:
    - '${absPath('test/header_parser_tests/function_n_struct.h')}'
        '''),
        ),
      );
    });

    test('Total bindings count', () {
      expect(actual.bindings.length, expected.bindings.length);
    });
    test('func1 struct pointer parameter', () {
      expect(
        actual.getBindingAsString('func1'),
        expected.getBindingAsString('func1'),
      );
    });
    test('func2 incomplete array parameter', () {
      expect(
        actual.getBindingAsString('func2'),
        expected.getBindingAsString('func2'),
      );
    });
    test('Struct2 nested struct member', () {
      expect(
        actual.getBindingAsString('Struct2'),
        expected.getBindingAsString('Struct2'),
      );
    });
    test('Struct3 flexible array member', () {
      expect((actual.getBinding('Struct3') as Struct).members.isEmpty, true);
    });
    test('Struct4 bit field member', () {
      expect((actual.getBinding('Struct4') as Struct).members.isEmpty, true);
    });
    test('Struct5 incompleted struct member', () {
      expect((actual.getBinding('Struct5') as Struct).members.isEmpty, true);
    });
    test('Struct6 typedef constant array', () {
      expect(
        actual.getBindingAsString('Struct6'),
        expected.getBindingAsString('Struct6'),
      );
    });
    test('Struct7 zero length array (extension on flexible array member)', () {
      expect((actual.getBinding('Struct7') as Struct).members.isEmpty, true);
    });
    test('func3 constant typedef array parameter', () {
      expect(
        actual.getBindingAsString('func3'),
        expected.getBindingAsString('func3'),
      );
    });
  });
}

Library expectedLibrary() {
  final struct1 = Struct(
    name: 'Struct1',
    members: [CompoundMember(name: 'a', type: intType)],
  );
  final struct2 = Struct(
    name: 'Struct2',
    members: [CompoundMember(name: 'a', type: struct1)],
  );
  final struct3 = Struct(name: 'Struct3');
  return Library(
    context: testContext(),
    name: 'Bindings',
    bindings: [
      struct1,
      struct2,
      struct3,
      Func(
        name: 'func1',
        parameters: [
          Parameter(name: 's', type: PointerType(struct2), objCConsumed: false),
        ],
        returnType: NativeType(SupportedNativeType.voidType),
      ),
      Func(
        name: 'func2',
        parameters: [
          Parameter(name: 's', type: PointerType(struct3), objCConsumed: false),
        ],
        returnType: NativeType(SupportedNativeType.voidType),
      ),
      Func(
        name: 'func3',
        parameters: [
          Parameter(name: 'a', type: PointerType(intType), objCConsumed: false),
        ],
        returnType: NativeType(SupportedNativeType.voidType),
      ),
      Struct(name: 'Struct4'),
      Struct(name: 'Struct5'),
      Struct(
        name: 'Struct6',
        members: [
          CompoundMember(
            name: 'a',
            type: ConstantArray(
              2,
              ConstantArray(10, intType, useArrayType: false),
              useArrayType: false,
            ),
          ),
        ],
      ),
      Struct(name: 'Struct7'),
    ],
  );
}
