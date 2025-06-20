// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: unused_element, camel_case_types, non_constant_identifier_names

// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint
import 'dart:ffi' as ffi;

class init_dylib$1 {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
  _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  init_dylib$1(ffi.DynamicLibrary dynamicLibrary)
    : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  init_dylib$1.fromLookup(
    ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup,
  ) : _lookup = lookup;

  void test() {
    return _test$1();
  }

  late final _testPtr = _lookup<ffi.NativeFunction<ffi.Void Function()>>(
    'test',
  );
  late final _test$1 = _testPtr.asFunction<void Function()>();

  void _test() {
    return __test();
  }

  late final __testPtr = _lookup<ffi.NativeFunction<ffi.Void Function()>>(
    '_test',
  );
  late final __test = __testPtr.asFunction<void Function()>();

  void _c_test() {
    return __c_test();
  }

  late final __c_testPtr = _lookup<ffi.NativeFunction<ffi.Void Function()>>(
    '_c_test',
  );
  late final __c_test = __c_testPtr.asFunction<void Function()>();

  void _dart_test() {
    return __dart_test();
  }

  late final __dart_testPtr = _lookup<ffi.NativeFunction<ffi.Void Function()>>(
    '_dart_test',
  );
  late final __dart_test = __dart_testPtr.asFunction<void Function()>();

  void Test() {
    return _Test();
  }

  late final _TestPtr = _lookup<ffi.NativeFunction<ffi.Void Function()>>(
    'Test',
  );
  late final _Test = _TestPtr.asFunction<void Function()>();
}

final class _Test extends ffi.Struct {
  @ffi.Array.multi([2])
  external ffi.Array<ffi.Int8> array;
}

final class ArrayHelperPrefixCollisionTest extends ffi.Opaque {}

sealed class _c_Test {}

sealed class init_dylib {}
