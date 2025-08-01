// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:ffigen/ffigen.dart';
import 'package:ffigen/src/header_parser.dart' show parse;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import '../test_utils.dart';
import '_expected_native_test_bindings.dart';

void main() {
  late NativeLibrary bindings;
  group('native_test', () {
    setUpAll(() {
      logWarnings();
      var dylibName = 'test/native_test/native_test.so';
      if (Platform.isMacOS) {
        dylibName = 'test/native_test/native_test.dylib';
      } else if (Platform.isWindows) {
        dylibName = r'test\native_test\native_test.dll';
      }
      final dylib = File(path.join(packagePathForTests, dylibName));
      verifySetupFile(dylib);
      bindings = NativeLibrary(DynamicLibrary.open(dylib.absolute.path));
    });

    test('generate_bindings', () {
      final configFile = File(
        path.join(packagePathForTests, 'test', 'native_test', 'config.yaml'),
      ).absolute;
      final outFile = File(
        path.join(
          packagePathForTests,
          'test',
          'debug_generated',
          '_expected_native_test_bindings.dart',
        ),
      ).absolute;

      late FfiGen config;
      withChDir(configFile.path, () {
        config = testConfigFromPath(configFile.path);
      });
      final library = parse(testContext(config));

      library.generateFile(outFile);

      try {
        final actual = outFile.readAsStringSync().replaceAll('\r', '');
        final expected = File(
          path.join(config.output.toFilePath()),
        ).readAsStringSync().replaceAll('\r', '');
        expect(actual, expected);
        if (outFile.existsSync()) {
          outFile.delete();
        }
      } catch (e) {
        print('Failed test: Debug generated file: ${outFile.absolute.path}');
        rethrow;
      }
    });

    test('bool', () {
      expect(bindings.Function1Bool(true), false);
      expect(bindings.Function1Bool(false), true);
    });
    test('uint8_t', () {
      expect(bindings.Function1Uint8(pow(2, 8).toInt()), 42);
    });
    test('uint16_t', () {
      expect(bindings.Function1Uint16(pow(2, 16).toInt()), 42);
    });
    test('uint32_t', () {
      expect(bindings.Function1Uint32(pow(2, 32).toInt()), 42);
    });
    test('uint64_t', () {
      expect(bindings.Function1Uint64(pow(2, 64).toInt()), 42);
    });
    test('int8_t', () {
      expect(
        bindings.Function1Int8(pow(2, 7).toInt()),
        -pow(2, 7).toInt() + 42,
      );
    });
    test('int16_t', () {
      expect(
        bindings.Function1Int16(pow(2, 15).toInt()),
        -pow(2, 15).toInt() + 42,
      );
    });
    test('int32_t', () {
      expect(
        bindings.Function1Int32(pow(2, 31).toInt()),
        -pow(2, 31).toInt() + 42,
      );
    });
    test('int64_t', () {
      expect(
        bindings.Function1Int64(pow(2, 63).toInt()),
        -pow(2, 63).toInt() + 42,
      );
    });
    test('intptr_t', () {
      expect(bindings.Function1IntPtr(0), 42);
    });
    test('float', () {
      expect(bindings.Function1Float(0), 42.0);
    });
    test('double', () {
      expect(bindings.Function1Double(0), 42.0);
    });
    test('array global', () {
      bindings.globalArray[0] = 1;
      bindings.globalArray[1] = 2;
      expect(bindings.globalArray[0], 1);
      expect(bindings.globalArray[1], 2);
      bindings.globalArray[1] = 3;
      expect(bindings.globalArray[1], 3);
    });
    test('Array Test: Order of access', () {
      final struct1 = bindings.getStruct1();
      var expectedValue = 1;
      final dimensions = [3, 1, 2];
      for (var i = 0; i < dimensions[0]; i++) {
        for (var j = 0; j < dimensions[1]; j++) {
          for (var k = 0; k < dimensions[2]; k++) {
            expect(struct1.ref.data[i][j][k], expectedValue);
            expectedValue++;
          }
        }
      }
    });

    test('Array Workaround: Range Errors', () {
      final struct1 = bindings.getStruct1();
      // Index (get) above range.
      expect(
        () => struct1.ref.data[4][0][0],
        throwsA(const TypeMatcher<RangeError>()),
      );
      expect(
        () => struct1.ref.data[0][2][0],
        throwsA(const TypeMatcher<RangeError>()),
      );
      expect(
        () => struct1.ref.data[0][0][3],
        throwsA(const TypeMatcher<RangeError>()),
      );
      // Index (get) below range.
      expect(
        () => struct1.ref.data[-1][0][0],
        throwsA(const TypeMatcher<RangeError>()),
      );
      expect(
        () => struct1.ref.data[-1][0][0],
        throwsA(const TypeMatcher<RangeError>()),
      );
      expect(
        () => struct1.ref.data[0][0][-1],
        throwsA(const TypeMatcher<RangeError>()),
      );

      // Index (set) above range.
      expect(
        () => struct1.ref.data[4][0][0] = 0,
        throwsA(const TypeMatcher<RangeError>()),
      );
      expect(
        () => struct1.ref.data[0][2][0] = 0,
        throwsA(const TypeMatcher<RangeError>()),
      );
      expect(
        () => struct1.ref.data[0][0][3] = 0,
        throwsA(const TypeMatcher<RangeError>()),
      );
      // Index (get) below range.
      expect(
        () => struct1.ref.data[-1][0][0] = 0,
        throwsA(const TypeMatcher<RangeError>()),
      );
      expect(
        () => struct1.ref.data[-1][0][0] = 0,
        throwsA(const TypeMatcher<RangeError>()),
      );
      expect(
        () => struct1.ref.data[0][0][-1] = 0,
        throwsA(const TypeMatcher<RangeError>()),
      );
    });
    test('Struct By Value', () {
      final r = Random();
      final a = r.nextInt(100), b = r.nextInt(100), c = r.nextInt(100);
      final s = bindings.Function1StructReturnByValue(a, b, c);
      expect(bindings.Function1StructPassByValue(s), a + b + c);
    });

    test('Enum1 is a Dart enum', () {
      final enum1 = Enum1.enum1Value1;
      final result = bindings.funcWithEnum1(enum1);
      expect(enum1, isA<Enum1>());
      expect(enum1.value, isA<int>());
      expect(result, enum1);
    });

    test('Enum2 is a Dart integer', () {
      final enum2 = Enum2.enum2Value1;
      final result = bindings.funcWithEnum2(enum2);
      expect(enum2, isA<int>());
      expect(result, enum2);
    });

    test('Enum in a struct', () {
      final struct1 = bindings.getStructWithEnums();
      Enum1 enum1;
      enum1 = struct1.enum1;
      expect(enum1, Enum1.enum1Value1);
      expect(enum1, isA<Enum1>());
      expect(enum1.value, isA<int>());

      enum1 = Enum1.fromValue(struct1.enum1Pointer.value);
      expect(struct1.enum1Pointer, isA<Pointer<UnsignedInt>>());
      expect(enum1, Enum1.enum1Value2);

      for (var i = 0; i < 5; i++) {
        enum1 = Enum1.fromValue(struct1.enum1Array[i]);
        expect(enum1, Enum1.enum1Value3);
      }

      int enum2;
      enum2 = struct1.enum2;
      expect(enum2, Enum2.enum2Value1);
      expect(enum2, isA<int>());

      enum2 = struct1.enum2Pointer.value;
      expect(struct1.enum2Pointer, isA<Pointer<UnsignedInt>>());
      expect(enum2, Enum2.enum2Value2);

      for (var i = 0; i < 5; i++) {
        enum2 = struct1.enum2Array[i];
        expect(enum2, Enum2.enum2Value3);
      }
    });
  });
}
