// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Objective C support is only available on mac.
@TestOn('mac-os')
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:objective_c/objective_c.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import '../test_utils.dart';
import 'property_bindings.dart';
import 'util.dart';

void main() {
  late PropertyInterface testInstance;

  group('properties', () {
    setUpAll(() {
      // TODO(https://github.com/dart-lang/native/issues/1068): Remove this.
      DynamicLibrary.open(
        path.join(
          packagePathForTests,
          '..',
          'objective_c',
          'test',
          'objective_c.dylib',
        ),
      );
      final dylib = File(
        path.join(
          packagePathForTests,
          'test',
          'native_objc_test',
          'objc_test.dylib',
        ),
      );
      verifySetupFile(dylib);
      DynamicLibrary.open(dylib.absolute.path);
      testInstance = PropertyInterface();
      generateBindingsForCoverage('property');
    });

    group('instance properties', () {
      test('read-only property', () {
        expect(testInstance.readOnlyProperty, 7);
      });

      test('read-write property', () {
        testInstance.readWriteProperty = 23;
        expect(testInstance.readWriteProperty, 23);
      });
    });

    group('class properties', () {
      test('read-only property', () {
        expect(PropertyInterface.getClassReadOnlyProperty(), 42);
      });

      test('read-write property', () {
        PropertyInterface.setClassReadWriteProperty(101);
        expect(PropertyInterface.getClassReadWriteProperty(), 101);
      });
    });

    group('Regress #209', () {
      // Test for https://github.com/dart-lang/native/issues/209
      test('Structs', () {
        final inputPtr = calloc<Vec4>();
        final input = inputPtr.ref;
        input.x = 1.2;
        input.y = 3.4;
        input.z = 5.6;
        input.w = 7.8;

        testInstance.structProperty = input;
        final result = testInstance.structProperty;
        expect(result.x, 1.2);
        expect(result.y, 3.4);
        expect(result.z, 5.6);
        expect(result.w, 7.8);

        calloc.free(inputPtr);
      });

      test('Floats', () {
        testInstance.floatProperty = 1.23;
        expect(testInstance.floatProperty, closeTo(1.23, 1e-6));
      });

      test('Doubles', () {
        testInstance.doubleProperty = 1.23;
        expect(testInstance.doubleProperty, 1.23);
      });
    });

    test('Instance and static properties with same name', () {
      // Test for https://github.com/dart-lang/native/issues/1136
      expect(testInstance.instStaticSameName, 123);
      expect(PropertyInterface.getInstStaticSameName(), 456);
    });

    test('Regress #1268', () {
      // Test for https://github.com/dart-lang/native/issues/1268
      NSArray array = PropertyInterface.getRegressGH1268();
      expect(array.length, 1);
      expect(NSString.castFrom(array[0]).toDartString(), "hello");
    });
  });
}
