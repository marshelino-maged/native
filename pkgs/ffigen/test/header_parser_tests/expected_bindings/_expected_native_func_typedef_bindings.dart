// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
import 'dart:ffi' as ffi;

/// Unnamed Enums Test
class NativeLibrary {
  /// Holds the Dynamic library.
  final ffi.DynamicLibrary _dylib;

  /// The symbols are looked up in [dynamicLibrary].
  NativeLibrary(ffi.DynamicLibrary dynamicLibrary) : _dylib = dynamicLibrary;

  void func(
    ffi.Pointer<ffi.NativeFunction<_typedefC_4>> unnamed1,
  ) {
    return (_func ??= _dylib.lookupFunction<_c_func, _dart_func>('func'))(
      unnamed1,
    );
  }

  _dart_func? _func;

  void funcWithNativeFunc(
    ffi.Pointer<ffi.NativeFunction<withTypedefReturnType>> named,
  ) {
    return (_funcWithNativeFunc ??=
        _dylib.lookupFunction<_c_funcWithNativeFunc, _dart_funcWithNativeFunc>(
            'funcWithNativeFunc'))(
      named,
    );
  }

  _dart_funcWithNativeFunc? _funcWithNativeFunc;
}

class struc extends ffi.Struct {
  external ffi.Pointer<ffi.NativeFunction<_typedefC_2>> unnamed1;
}

class Struc2 extends ffi.Struct {
  external ffi.Pointer<ffi.NativeFunction<VoidFuncPointer>> constFuncPointer;
}

typedef _typedefC_3 = ffi.Void Function();

typedef _typedefC_4 = ffi.Void Function(
  ffi.Pointer<ffi.NativeFunction<_typedefC_3>>,
);

typedef _c_func = ffi.Void Function(
  ffi.Pointer<ffi.NativeFunction<_typedefC_4>> unnamed1,
);

typedef _dart_func = void Function(
  ffi.Pointer<ffi.NativeFunction<_typedefC_4>> unnamed1,
);

typedef insideReturnType = ffi.Void Function();

typedef withTypedefReturnType
    = ffi.Pointer<ffi.NativeFunction<insideReturnType>> Function();

typedef _c_funcWithNativeFunc = ffi.Void Function(
  ffi.Pointer<ffi.NativeFunction<withTypedefReturnType>> named,
);

typedef _dart_funcWithNativeFunc = void Function(
  ffi.Pointer<ffi.NativeFunction<withTypedefReturnType>> named,
);

typedef _typedefC_1 = ffi.Void Function();

typedef _typedefC_2 = ffi.Void Function(
  ffi.Pointer<ffi.NativeFunction<_typedefC_1>>,
);

typedef VoidFuncPointer = ffi.Void Function();
