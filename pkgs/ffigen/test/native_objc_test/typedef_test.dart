// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Objective C support is only available on mac.
@TestOn('mac-os')
import 'dart:ffi';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import '../test_utils.dart';
import 'typedef_bindings.dart';
import 'util.dart';

void main() {
  group('typedef', () {
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
      generateBindingsForCoverage('typedef');
    });

    test('Regression test for #386', () {
      // https://github.com/dart-lang/ffigen/issues/386
      // Make sure that the typedef DartSomeClassPtr is for SomeClass.
      final DartSomeClassPtr instance = SomeClass();
      expect(instance.ref.pointer, isNot(nullptr));
    });
  });
}
