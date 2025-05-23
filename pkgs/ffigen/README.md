[![Build Status](https://github.com/dart-lang/native/actions/workflows/ffigen.yml/badge.svg)](https://github.com/dart-lang/native/actions/workflows/ffigen.yml)
[![Coverage Status](https://coveralls.io/repos/github/dart-lang/native/badge.svg?branch=main)](https://coveralls.io/github/dart-lang/native?branch=main)
[![pub package](https://img.shields.io/pub/v/ffigen.svg)](https://pub.dev/packages/ffigen)
[![package publisher](https://img.shields.io/pub/publisher/ffigen.svg)](https://pub.dev/packages/ffigen/publisher)

Binding generator for [FFI](https://dart.dev/guides/libraries/c-interop) bindings.

> Note: ffigen only supports parsing `C` headers, not `C++` headers.

This bindings generator can be used to call C code -- or code in another
language that compiles to C modules that follow the C calling convention --
such as Go or Rust. For more details, see:
https://dart.dev/guides/libraries/c-interop

ffigen also has experimental support for calling ObjC and Swift code;
for details see:
https://dart.dev/guides/libraries/objective-c-interop

## Example

For some header file _example.h_:
```C
int sum(int a, int b);
```
Add configurations to Pubspec File:
```yaml
ffigen:
  output: 'generated_bindings.dart'
  headers:
    entry-points:
      - 'example.h'
```
Output (_generated_bindings.dart_).
```dart
import 'dart:ffi' as ffi;
class NativeLibrary {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;
  NativeLibrary(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;
  NativeLibrary.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  int sum(int a, int b) {
    return _sum(a, b);
  }

  late final _sumPtr = _lookup<ffi.NativeFunction<ffi.Int Function(ffi.Int, ffi.Int)>>('sum');
  late final _sum = _sumPtr.asFunction<int Function(int, int)>();
}
}
```
## Using this package
- Add `ffigen` under `dev_dependencies` in your `pubspec.yaml` (run `dart pub add -d ffigen`).
- Add `package:ffi` under `dependencies` in your `pubspec.yaml` (run `dart pub add ffi`).
- Install LLVM (see [Installing LLVM](#installing-llvm)).
- Configurations must be provided in `pubspec.yaml` or in a custom YAML file (see [configurations](#configurations)).
- Run the tool- `dart run ffigen`.

Jump to [FAQ](#faq).

## Installing LLVM
`package:ffigen` uses LLVM. Install LLVM (9+) in the following way.

#### Linux
1. Install libclangdev.

   With apt-get: `sudo apt-get install libclang-dev`.

   With dnf: `sudo dnf install clang-devel`.

#### Windows
1. Install Visual Studio with C++ development support.
2. Install [LLVM](https://releases.llvm.org/download.html) or `winget install -e --id LLVM.LLVM`.

#### MacOS
1. Install Xcode.
2. Install Xcode command line tools - `xcode-select --install`.

## Configurations
Configurations can be provided in 2 ways-
1. In the project's `pubspec.yaml` file under the key `ffigen`.
2. Via a custom YAML file, then specify this file while running -
`dart run ffigen --config config.yaml`

The following configuration options are available-
<table>
<thead>
  <tr>
    <th>Key</th>
    <th>Explaination</th>
    <th>Example</th>
  </tr>
  <colgroup>
      <col>
      <col style="width: 100px;">
  </colgroup>
</thead>
<tbody>
  <tr>
    <td>output<br><i><b>(Required)</b></i></td>
    <td>Output path of the generated bindings.</td>
    <td>

```yaml
output: 'generated_bindings.dart'
```
or
```yaml
output:
  bindings: 'generated_bindings.dart'
  ...
```
  </td>
  </tr>
  <tr>
    <td>llvm-path</td>
    <td>Path to <i>llvm</i> folder.<br> ffigen will sequentially search
    for `lib/libclang.so` on linux, `lib/libclang.dylib` on macOs and
    `bin\libclang.dll` on windows, in the specified paths.<br><br>
    Complete path to the dynamic library can also be supplied.<br>
    <i>Required</i> if ffigen is unable to find this at default locations.</td>
    <td>

```yaml
llvm-path:
  - '/usr/local/opt/llvm'
  - 'C:\Program Files\llvm`
  - '/usr/lib/llvm-11'
  # Specify exact path to dylib
  - '/usr/lib64/libclang.so'
```
  </td>
  </tr>
  <tr>
    <td>headers<br><i><b>(Required)</b></i></td>
    <td>The header entry-points and include-directives. Glob syntax is allowed.<br>
    If include-directives are not specified ffigen will generate everything directly/transitively under the entry-points.</td>
    <td>

```yaml
headers:
  entry-points:
    - 'folder/**.h'
    - 'folder/specific_header.h'
  include-directives:
    - '**index.h'
    - '**/clang-c/**'
    - '/full/path/to/a/header.h'
```
  </td>
  </tr>
  <tr>
    <td>name<br><i>(Prefer)</i></td>
    <td>Name of generated class.</td>
    <td>

```yaml
name: 'SQLite'
```
  </td>
  </tr>
  <tr>
    <td>description<br><i>(Prefer)</i></td>
    <td>Dart Doc for generated class.</td>
    <td>

```yaml
description: 'Bindings to SQLite'
```
  </td>
  </tr>
  <tr>
    <td>compiler-opts</td>
    <td>Pass compiler options to clang. You can also pass
    these via the command line tool.</td>
    <td>

```yaml
compiler-opts:
  - '-I/usr/lib/llvm-9/include/'
```
and/or via the command line -
```bash
dart run ffigen --compiler-opts "-I/headers
-L 'path/to/folder name/file'"
```
  </td>
  </tr>
    <tr>
    <td>compiler-opts-automatic.macos.include-c-standard-library</td>
    <td>Tries to automatically find and add C standard library path to
    compiler-opts on macos.<br>
    <b>Default: true</b>
    </td>
    <td>

```yaml
compiler-opts-automatic:
  macos:
    include-c-standard-library: false
```
  </td>
  </tr>
  <tr>
    <td>
      functions<br><br>structs<br><br>unions<br><br>enums<br><br>
      unnamed-enums<br><br>macros<br><br>globals
    </td>
    <td>Filters for declarations.<br><b>Default: all are included.</b><br><br>
    Options -<br>
    - Include/Exclude declarations.<br>
    - Rename declarations.<br>
    - Rename enum, struct, and union members, function parameters, and ObjC
      interface and protocol methods and properties.<br>
    - Expose symbol-address for functions and globals.<br>
    </td>
    <td>

```yaml
functions:
  include: # 'exclude' is also available.
    # Matches using regexp.
    - [a-z][a-zA-Z0-9]*
    # '.' matches any character.
    - prefix.*
    # Matches with exact name
    - someFuncName
    # Full names have higher priority.
    - anotherName
  rename:
    # Regexp groups based replacement.
    'clang_(.*)': '$1'
    'clang_dispose': 'dispose'
    # Removes '_' from beginning.
    '_(.*)': '$1'
  symbol-address:
    # Used to expose symbol address.
    include:
      - myFunc
structs:
  rename:
    # Removes prefix underscores
    # from all structures.
    '_(.*)': '$1'
  member-rename:
    '.*': # Matches any struct.
      # Removes prefix underscores
      # from members.
      '_(.*)': '$1'
enums:
  rename:
    # Regexp groups based replacement.
    'CXType_(.*)': '$1'
  member-rename:
    '(.*)': # Matches any enum.
      # Removes '_' from beginning
      # enum member name.
      '_(.*)': '$1'
    # Full names have higher priority.
    'CXTypeKind':
      # $1 keeps only the 1st
      # group i.e only '(.*)'.
      'CXType(.*)': '$1'
  as-int:
    # These enums will be generated as Dart integers instead of Dart enums
    include:
      - MyIntegerEnum
globals:
  exclude:
    - aGlobal
  rename:
    # Removes '_' from
    # beginning of a name.
    '_(.*)': '$1'
```
  </td>
  </tr>
  <tr>
    <td>typedefs</td>
    <td>Filters for referred typedefs.<br><br>
    Options -<br>
    - Include/Exclude (referred typedefs only).<br>
    - Rename typedefs.<br><br>
    Note: By default, typedefs that are not referred to anywhere will not be generated.
    </td>
    <td>

```yaml
typedefs:
  exclude:
    # Typedefs starting with `p` are not generated.
    - 'p.*'
  rename:
    # Removes '_' from beginning of a typedef.
    '_(.*)': '$1'
```
  </td>
  </tr>
  <tr>
    <td>include-unused-typedefs</td>
    <td>
      Also generate typedefs that are not referred to anywhere.
      <br>
      <b>Default: false</b>
    </td>
    <td>

```yaml
include-unused-typedefs: true
```
  </td>
  </tr>
  <tr>
    <td>functions.expose-typedefs</td>
    <td>Generate the typedefs to Native and Dart type of a function<br>
    <b>Default: Inline types are used and no typedefs to Native/Dart
    type are generated.</b>
    </td>
    <td>

```yaml
functions:
  expose-typedefs:
    include:
      # Match function name.
      - 'myFunc'
       # Do this to expose types for all function.
      - '.*'
    exclude:
      # If you only use exclude, then everything
      # not excluded is generated.
      - 'dispose'
```
  </td>
  </tr>
  <tr>
    <td>functions.leaf</td>
    <td>Set isLeaf:true for functions.<br>
    <b>Default: all functions are excluded.</b>
    </td>
    <td>

```yaml
functions:
  leaf:
    include:
      # Match function name.
      - 'myFunc'
       # Do this to set isLeaf:true for all functions.
      - '.*'
    exclude:
      # If you only use exclude, then everything
      # not excluded is generated.
      - 'dispose'
```
  </td>
  </tr>
  <tr>
    <td>functions.variadic-arguments</td>
    <td>Generate multiple functions with different variadic arguments.<br>
    <b>Default: var args for any function are ignored.</b>
    </td>
    <td>

```yaml
functions:
  variadic-arguments:
    myfunc:
      // Native C types are supported
      - [int, unsigned char, long*, float**]
      // Common C typedefs (stddef.h) are supported too
      - [uint8_t, intptr_t, size_t, wchar_t*]
      // Structs/Unions/Typedefs from generated code or a library import can be referred too.
      - [MyStruct*, my_custom_lib.CustomUnion]
```
  </td>
  </tr>
  <tr>
    <td>structs.pack</td>
    <td>Override the @Packed(X) annotation for generated structs.<br><br>
    <i>Options - none, 1, 2, 4, 8, 16</i><br>
    You can use RegExp to match with the <b>generated</b> names.<br><br>
    Note: Ffigen can only reliably identify packing specified using
    __attribute__((__packed__)). However, structs packed using
    `#pragma pack(...)` or any other way could <i>potentially</i> be incorrect
    in which case you can override the generated annotations.
    </td>
    <td>

```yaml
structs:
  pack:
    # Matches with the generated name.
    'NoPackStruct': none # No packing
    '.*': 1 # Pack all structs with value 1
```
  </td>
  </tr>
  <tr>
    <td>comments</td>
    <td>Extract documentation comments for declarations.<br>
    The style and length of the comments recognized can be specified with the following options- <br>
    <i>style: doxygen(default) | any </i><br>
    <i>length: brief | full(default) </i><br>
    If you want to disable all comments you can also pass<br>
    comments: false.
    </td>
    <td>

```yaml
comments:
  style: any
  length: full
```
  </td>
  </tr>
  <tr>
    <td>structs.dependency-only<br><br>
        unions.dependency-only
    </td>
    <td>If `opaque`, generates empty `Opaque` structs/unions if they
were not included in config (but were added since they are a dependency) and
only passed by reference(pointer).<br>
    <i>Options - full(default) | opaque</i><br>
    </td>
    <td>

```yaml
structs:
  dependency-only: opaque
unions:
  dependency-only: opaque
```
  </td>
  </tr>
  <tr>
    <td>sort</td>
    <td>Sort the bindings according to name.<br>
      <b>Default: false</b>, i.e keep the order as in the source files.
    </td>
    <td>

```yaml
sort: true
```
  </td>
  </tr>
  <tr>
    <td>use-supported-typedefs</td>
    <td>Should automatically map typedefs, E.g uint8_t => Uint8, int16_t => Int16, size_t => Size etc.<br>
    <b>Default: true</b>
    </td>
    <td>

```yaml
use-supported-typedefs: true
```
  </td>
  </tr>
  <tr>
    <td>use-dart-handle</td>
    <td>Should map `Dart_Handle` to `Handle`.<br>
    <b>Default: true</b>
    </td>
    <td>

```yaml
use-dart-handle: true
```

  </td>
  </tr>
  <tr>
    <td>ignore-source-errors</td>
    <td>Where to ignore compiler warnings/errors in source header files.<br>
    <b>Default: false</b>
    </td>
    <td>

```yaml
ignore-source-errors: true
```
and/or via the command line -
```bash
dart run ffigen --ignore-source-errors
```
  </td>
  </tr>
  <tr>
    <td>silence-enum-warning</td>
    <td>Where to silence warning for enum integer type mimicking.<br>
    The integer type used for enums is implementation-defined, and not part of
    the ABI. FFIgen tries to mimic the integer sizes chosen by the most common
    compilers for the various OS and architecture combinations.<br>
    <b>Default: false</b>
    </td>
    <td>

```yaml
silence-enum-warning: true
```
  </td>
  </tr>
  <tr>
    <td>exclude-all-by-default</td>
    <td>
      When a declaration filter (eg `functions:` or `structs:`) is empty or
      unset, it defaults to including everything. If this flag is enabled, the
      default behavior is to exclude everything instead.<br>
      <b>Default: false</b>
    </td>
    <td>

```yaml
exclude-all-by-default: true
```
  </td>
  </tr>
  <tr>
    <td>preamble</td>
    <td>Raw header of the file, pasted as-it-is.</td>
    <td>

```yaml
preamble: |
  // ignore_for_file: camel_case_types, non_constant_identifier_names
```
</td>
  </tr>
  <tr>
    <td>library-imports</td>
    <td>Specify library imports for use in type-map.<br><br>
    Note: ffi (dart:ffi) is already available as a predefined import.
    </td>
    <td>

```yaml
library-imports:
  custom_lib: 'package:some_pkg/some_file.dart'
```
  </td>
  </tr>
  <tr>
    <td>type-map</td>
    <td>Map types like integers, typedefs, structs,  unions to any other type.<br><br>
    <b>Sub-fields</b> - <i>typedefs</i>, <i>structs</i>, <i>unions</i>, <i>ints</i><br><br>
    <b><i>lib</i></b> must be specified in <i>library-imports</i> or be one of a predefined import.
    </td>
    <td>

```yaml
type-map:
  'native-types': # Targets native types.
    'char':
      'lib': 'pkg_ffi' # predefined import.
      'c-type': 'Char'
      # For native-types dart-type can be be int, double or float
      # but same otherwise.
      'dart-type': 'int'
    'int':
      'lib': 'custom_lib'
      'c-type': 'CustomType4'
      'dart-type': 'int'
  'typedefs': # Targets typedefs.
    'my_type1':
      'lib': 'custom_lib'
      'c-type': 'CustomType'
      'dart-type': 'CustomType'
  'structs': # Targets structs.
    'my_type2':
      'lib': 'custom_lib'
      'c-type': 'CustomType2'
      'dart-type': 'CustomType2'
  'unions': # Targets unions.
    'my_type3':
      'lib': 'custom_lib'
      'c-type': 'CustomType3'
      'dart-type': 'CustomType3'
```
  </td>
  </tr>
  <tr>
    <td>ffi-native</td>
    <td>
      <b>WARNING:</b> Native support is EXPERIMENTAL. The API may change
      in a breaking way without notice.
      <br><br>
      Generate `@Native` bindings instead of bindings using `DynamicLibrary` or `lookup`.
    </td>
    <td>

```yaml
ffi-native:
  asset-id: 'package:some_pkg/asset' # Optional, was assetId in previous versions
```
  </td>
  </tr>
  <tr>
    <td>language</td>
    <td>
      <b>WARNING:</b> Other language support is EXPERIMENTAL. The API may change
      in a breaking way without notice.
      <br><br>
      Choose the input langauge. Must be one of 'c', or 'objc'. Defaults to 'c'.
    </td>
    <td>

```yaml
language: 'objc'
```
  </td>
  </tr>
  <tr>
    <td>output.objc-bindings</td>
    <td>
      Choose where the generated ObjC code (if any) is placed. The default path
      is `'${output.bindings}.m'`, so if your Dart bindings are in
      `generated_bindings.dart`, your ObjC code will be in
      `generated_bindings.dart.m`.
      <br><br>
      This ObjC file will only be generated if it's needed. If it is generated,
      it must be compiled into your package, as part of a flutter plugin or
      build.dart script. If your package already has some sort of native build,
      you can simply add this generated ObjC file to that build.
    </td>
    <td>

```yaml
output:
  ...
  objc-bindings: 'generated_bindings.m'
```
</td>
  </tr>
  <tr>
    <td>output.symbol-file</td>
    <td>Generates a symbol file yaml containing all types defined in the generated output.</td>
    <td>

```yaml
output:
  ...
  symbol-file:
    # Although file paths are supported here, prefer Package Uri's here
    # so that other pacakges can use them.
    output: 'package:some_pkg/symbols.yaml'
    import-path: 'package:some_pkg/base.dart'
```
</td>
  </tr>
  <tr>
    <td>import.symbol-files</td>
    <td>Import symbols from a symbol file. Used for sharing type definitions from other pacakges.</td>
    <td>

```yaml
import:
  symbol-files:
    # Both package Uri and file paths are supported here.
    - 'package:some_pkg/symbols.yaml'
    - 'path/to/some/symbol_file.yaml'
```
  </td>
  </tr>

  <tr>
    <td>
      external-versions
    </td>
    <td>
      Interfaces, methods, and other API elements may be marked with
      deprecation annotations that indicate which platform version they were
      deprecated in. If external-versions is set, APIs that were
      deprecated as of the minimum version will be omitted from the
      generated bindings.
      <br><br>
      The minimum version is specified per platform, and an API will be
      generated if it is available on *any* of the targeted platform versions.
      If a version is not specified for a particular platform, the API's
      inclusion will be based purely on the platforms that have a specified
      minimum version.
      <br><br>
      Current support OS keys are ios and macos. If you have a use case for
      version checking on other OSs, please file an issue.
    </td>
    <td>

```yaml
external-versions:
  # See https://docs.flutter.dev/reference/supported-platforms.
  ios:
    min: 12.0.0
  macos:
    min: 10.14.0
```

  </td>
  </tr>
</tbody>
</table>

### Objective-C config options

<table>
<thead>
  <tr>
    <th>Key</th>
    <th>Explaination</th>
    <th>Example</th>
  </tr>
  <colgroup>
    <col>
    <col style="width: 100px;">
  </colgroup>
</thead>
<tbody>
  <tr>
    <td>
      objc-interfaces<br><br>
      objc-protocols<br><br>
      objc-categories
    </td>
    <td>
      Filters for Objective C interface, protocol, and category declarations.
      This option works the same as other declaration filters like `functions`
      and `structs`.
    </td>
    <td>

```yaml
objc-interfaces:
  include:
    # Includes a specific interface.
    - 'MyInterface'
    # Includes all interfaces starting with "NS".
    - 'NS.*'
  exclude:
    # Override the above NS.* inclusion, to exclude NSURL.
    - 'NSURL'
  rename:
    # Removes '_' prefix from interface names.
    '_(.*)': '$1'
objc-protocols:
  include:
    # Generates bindings for a specific protocol.
    - MyProtocol
objc-categories:
  include:
    # Generates bindings for a specific category.
    - MyCategory
```

  </td>
  </tr>

  <tr>
    <td>
      objc-interfaces.module<br><br>
      objc-protocols.module
    </td>
    <td>
      Adds a module prefix to the interface/protocol name when loading it
      from the dylib. This is only relevent for ObjC headers that are generated
      wrappers for a Swift library. See example/swift for more information.
      <br><br>
      This is not necessary for objc-categories.
    </td>
    <td>

```yaml
headers:
  entry-points:
    # Generated by swiftc to wrap foo_lib.swift.
    - 'foo_lib-Swift.h'
objc-interfaces:
  include:
    # Eg, foo_lib contains a set of classes prefixed with FL.
    - 'FL.*'
  module:
    # Use 'foo_lib' as the module name for all the FL.* classes.
    # We don't match .* here because other classes like NSString
    # shouldn't be given a module prefix.
    'FL.*': 'foo_lib'
```

  </td>
  </tr>

  <tr>
    <td>
      objc-interfaces.member-filter<br><br>
      objc-protocols.member-filter<br><br>
      objc-categories.member-filter
    </td>
    <td>
      Filters interface and protocol methods and properties. This is a map from
      interface name to a list of method include and exclude rules. The
      interface name can be a regexp. The include and exclude rules work exactly
      like any other declaration. See
      <a href="#how-does-objc-method-filtering-work">below</a> for more details.
    </td>
    <td>

```yaml
objc-interfaces:
  member-filter:
    MyInterface:
      include:
        - "someMethod:withArg:"
      # Since MyInterface has an include rule, all other methods
      # are excluded by default.
objc-protocols:
  member-filter:
    NS.*:  # Matches all protocols starting with NS.
      exclude:
        - copy.*  # Remove all copy methods from these protocols.
objc-categories:
  member-filter:
    MyCategory:
      include:
        - init.*  # Include all init methods.
```

  </td>
  </tr>

  <tr>
    <td>
      include-transitive-objc-interfaces<br><br>
      include-transitive-objc-protocols
    </td>
    <td>
      By default, Objective-C interfaces and protocols that are not directly
      included by the inclusion rules, but are transitively depended on by
      the inclusions, are not fully code genned. Transitively included
      interfaces are generated as stubs, and transitive protocols are omitted.
      <br><br>
      If these flags are enabled, transitively included interfaces and protocols
      are fully code genned.
      <br><br>
      <b>Default: false</b>
    </td>
    <td>

```yaml
include-transitive-objc-interfaces: true
include-transitive-objc-protocols: true
```
  </td>
  </tr>

  <tr>
    <td>
      include-transitive-objc-categories
    </td>
    <td>
      By default, if an Objective-C interface is included in the bindings, all
      the categories that extend it are also included. To filter them, set this
      flag to false, then use objc-categories to include/exclude particular
      categories.
      <br><br>
      Transitive categories are generated by default because it's not always
      obvious from the Apple documentation which interface methods are declared
      directly in the interface, and which are declared in categories. So it may
      appear that the interface is missing methods, when in fact those methods
      are part of a category. This would be a difficult problem to diagnose if
      transitive categories were not generated by default.
      <br><br>
      <b>Default: true</b>
    </td>
    <td>

```yaml
include-transitive-objc-categories: false
```
  </td>
  </tr>
</tbody>
</table>

## Trying out examples
1. `cd examples/<example_u_want_to_run>`, Run `dart pub get`.
2. Run `dart run ffigen`.

## Running Tests

See [test/README.md](test/README.md)

## FAQ
### Can ffigen be used for removing underscores or renaming declarations?
Ffigen supports **regexp based renaming**, the regexp must be a
full match, for renaming you can use regexp groups (`$1` means group 1).

E.g - For renaming `clang_dispose_string` to `string_dispose`.
We can can match it using `clang_(.*)_(.*)` and rename with `$2_$1`.

Here's an example of how to remove prefix underscores from any struct and its members.
```yaml
structs:
  ...
  rename:
    '_(.*)': '$1' # Removes prefix underscores from all structures.
  member-rename:
    '.*': # Matches any struct.
      '_(.*)': '$1' # Removes prefix underscores from members.
```
### How to generate declarations only from particular headers?
The default behaviour is to include everything directly/transitively under
each of the `entry-points` specified.

If you only want to have declarations directly particular header you can do so
using `include-directives`. You can use **glob matching** to match header paths.
```yaml
headers:
  entry-points:
    - 'path/to/my_header.h'
  include-directives:
    - '**my_header.h' # This glob pattern matches the header path.
```
### Can ffigen filter declarations by name?
Ffigen supports including/excluding declarations using full regexp matching.

Here's an example to filter functions using names
```yaml
functions:
  include:
    - 'clang.*' # Include all functions starting with clang.
  exclude:
    - '.*dispose': # Exclude all functions ending with dispose.
```
This will include `clang_help`. But will exclude `clang_dispose`.

Note: exclude overrides include.
### How does ffigen handle C Strings?

Ffigen treats `char*` just as any other pointer,(`Pointer<Int8>`).
To convert these to/from `String`, you can use [package:ffi](https://pub.dev/packages/ffi). Use `ptr.cast<Utf8>().toDartString()` to convert `char*` to dart `string` and `"str".toNativeUtf8()` to convert `string` to `char*`.

### How are unnamed enums handled?

Unnamed enums are handled separately, under the key `unnamed-enums`, and are generated as top level constants.

Here's an example that shows how to include/exclude/rename unnamed enums
```yaml
unnamed-enums:
  include:
    - 'CX_.*'
  exclude:
    - '.*Flag'
  rename:
    'CXType_(.*)': '$1'
```

### How can I handle unexpected enum values?

Native enums are, by default, generated into Dart enums with `int get value` and `fromValue(int)`.
This works well in the case that your enums values are known in advance and not going to change,
and in return, you get the full benefits of Dart enums like exhaustiveness checking.

However, if a native library adds another possible enum value after you generate your bindings,
and this new value is passed to your Dart code, this will result in an `ArgumentError` at runtime.
To fix this, you can regenerate the bindings on the new header file, but if you wish to avoid this
issue entirely, you can tell ffigen to generate plain Dart integers for your enum instead. To do
this, simply list your enum's name in the `as-int` section of your ffigen config:
```yaml
enums:
  as-int:
    include:
      - MyIntegerEnum
      - '*IntegerEnum'
    exclude:
      - FakeIntegerEnum
```

Functions that accept or return these enums will now accept or return integers instead, and it will
be up to your code to map integer values to behavior and handle invalid values. But your code will
be future-proof against new additions to the enums.

### Why are some struct/union declarations generated even after excluded them in config?

This happens when an excluded struct/union is a dependency to some included declaration.
(A dependency means a struct is being passed/returned by a function or is member of another struct in some way)

Note: If you supply `structs.dependency-only` as `opaque` ffigen will generate
these struct dependencies as `Opaque` if they were only passed by reference(pointer).
```yaml
structs:
  dependency-only: opaque
unions:
  dependency-only: opaque
```

### How to expose the native pointers?

By default the native pointers are private, but you can use the
`symbol-address` subkey for functions/globals and make them public by matching with its name. The pointers are then accesible via `nativeLibrary.addresses`.

Example -
```yaml
functions:
  symbol-address:
    include:
      - 'myFunc' # Match function name.
      - '.*' # Do this to expose all function pointers.
    exclude: # If you only use exclude, then everything not excluded is generated.
      - 'dispose'
```

### How to get typedefs to Native and Dart type of a function?

By default these types are inline. But you can use the `expose-typedef` subkey
for functions to generate them. This will expose the Native and Dart type.
E.g - for a function named `hello`, the generated typedefs are named
as `NativeHello` and `DartHello`.

Example -
```yaml
functions:
  expose-typedefs:
    include:
      - 'myFunc' # Match function name.
      - '.*' # Do this to expose types for all function.
    exclude: # If you only use exclude, then everything not excluded is generated.
      - 'dispose'
```

### How are Structs/Unions/Enums that are reffered to via typedefs handled?

Named declarations use their own names even when inside another typedef.
However, unnamed declarations inside typedefs take the name of the _first_ typedef
that refers to them.

### Why are some typedefs not generated?

The following typedefs are not generated -
  - They are not referred to anywhere in the included declarations.
  - They refer to a struct/union having the same name as itself.
  - They refer to a boolean, enum, inline array, Handle or any unsupported type.

### How are macros handled?

`ffigen` uses `clang`'s own compiler frontend to parse and traverse the `C` header files. `ffigen` expands the macros using `clang`'s macro expansion and then traverses the expanded code. To do this, `ffigen` generates temporary files in a system tmp directory.

A custom temporary directory can be specified by setting the `TEST_TMPDIR` environment variable.

### What are these logs generated by ffigen and how to fix them?

Ffigen can sometimes generate a lot of logs, especially when it's parsing a lot of code.
  - `SEVERE` logs are something you *definitely need to address*. They can be
    caused due to syntax errors, or more generally missing header files
    (which need to be specified using `compiler-opts` in config)
  - `WARNING` logs are something *you can ignore*, but should probably look into.
    These are mostly indications of declarations ffigen couldn't generate due
    to limitations of dart:ffi, private declarations (which can be resolved
    by renaming them via ffigen config) or other minor issues in the config
    file itself.
  - Everything else can be safely ignored. It's purpose is to simply
    let you know what ffigen is doing.
  - The verbosity of the logs can be changed by adding a flag with
    the log level. E.g - `dart run ffigen --verbose <level>`.
    Level options are - `[all, fine, info (default), warning, severe]`.
    The `all` and `fine` will print a ton of logs are meant for debugging
    purposes only.

### How can type definitions be shared?

Ffigen can share type definitions using symbol files.
- A package can generate a symbol file using the `output.symbol-file` config.
- And another package can then import this, using `import.symbol-files` config.
- Doing so will reuse all the types such as Struct/Unions, and will automatically
 exclude generating other types (E.g functions, enums, macros).

Checkout `examples/shared_bindings` for details.

For manually reusing definitions from another package, the `library-imports`
and `type-map` config can be used.

### How does ObjC method filtering work?

Methods and properties on ObjC interfaces and protocols can be filtered using
the `member-filter` option under `objc-interfaces` and `objc-protocols`. For
simplicity we'll focus on interface methods, but the same rules apply to
properties and protocols. There are two parts to the filtering process: matching
the interface, and then filtering the method.

The syntax of `member-filter` is a YAML map from a pattern to some
`include`/`exclude` rules, and `include` and `exclude` are each a list of
patterns.

```yaml
objc-interfaces:
  member-filter:
    MyInterface:  # Matches an interface.
      include:
        - "someMethod:withArg:"  # Matches a method.
      exclude:
        - someOtherMethod  # Matches a method.
```

The interface matching logic is the same as the matching logic for the
`member-rename` option:

- The pattern is compared against the original name of the interface (before any
  renaming is applied).
- The pattern may be a string or a regexp, but in either case they must match
  the entire interface name.
- If the pattern contains only alphanumeric characters, or `_`, it is treated as
  a string rather than a regex.
- String patterns take precedence over regexps. That is, if an interface matches
  both a regexp pattern, and a string pattern, it uses the string pattern's
  `include`/`exclude` rules.

The method filtering logic uses the same `include`/`exclude` rules as the rest
of the config:

- `include` and `exclude` are a list of patterns.
- The patterns are compared against the original name of the method, before
  renaming.
- The patterns can be strings or regexps, but must match the entire method name.
- The method name is in ObjC selector syntax, which means that the method name
  and all the external parameter names are concatenated together with `:`
  characters. This is the same name you'll see in ObjC's API documentation.
- **NOTE:** Since the pattern must match the entire method name, and most ObjC
  method names end with a `:`, it's a good idea to surround the pattern with
  quotes, `"`. Otherwise YAML will think you're defining a map key.
- If no  `include` or `exclude` rules are defined, all methods are included,
  regardless of the top level `exclude-all-by-default` rule.
- If only `include` rules are `defined`, all non-matching methods are excluded.
- If only `exclude` rules are `defined`, all non-matching methods are included.
- If both `include` and `exclude` rules are defined, the `exclude` rules take
  precedence. That is, if a method name matches both an `include` rule and an
  `exclude` rule, the method is excluded. All non-matching methods are also
  excluded.

The property filtering rules live in the same `objc-interfaces.member-filter`
option as the methods. There is no distinction between methods and properties in
the filters. The protocol filtering rules live in
`objc-protocols.member-filter`.

### How do I generate bindings for Apple APIs?

It can be tricky to locate header files containing Apple's ObjC frameworks, and
the paths can vary between computers depending on which version of Xcode you are
using and where it is installed. So ffigen provides the following variable
substitutions that can be used in the `headers.entry-points` list:

- `$XCODE`: Replaced with the result of `xcode-select -p`, which is the
  directory where Xcode's APIs are installed.
- `$IOS_SDK`: Replaced with `xcrun --show-sdk-path --sdk iphoneos`, which is the
  directory within `$XCODE` where the iOS SDK is installed.
- `$MACOS_SDK`: Replaced with `xcrun --show-sdk-path --sdk macosx`, which is the
  directory within `$XCODE` where the macOS SDK is installed.

For example:

```Yaml
headers:
  entry-points:
    - '$MACOS_SDK/System/Library/Frameworks/Foundation.framework/Headers/NSDate.h'
```
