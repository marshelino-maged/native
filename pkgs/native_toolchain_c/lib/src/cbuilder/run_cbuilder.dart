// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';

import '../native_toolchain/msvc.dart';
import '../native_toolchain/tool_likeness.dart';
import '../native_toolchain/xcode.dart';
import '../tool/tool_instance.dart';
import '../utils/run_process.dart';
import 'compiler_resolver.dart';
import 'language.dart';
import 'linker_options.dart';
import 'optimization_level.dart';

class RunCBuilder {
  /// The options are for linking only, so this will be non-null iff a linker
  /// should be run.
  final LinkerOptions? linkerOptions;
  final HookInput input;
  final CodeConfig codeConfig;
  final Logger? logger;
  final List<Uri> sources;
  final List<Uri> includes;
  final List<Uri> forcedIncludes;
  final List<String> frameworks;
  final List<String> libraries;
  final List<Uri> libraryDirectories;
  final Uri? executable;
  final Uri? dynamicLibrary;
  final Uri? staticLibrary;
  final Uri outDir;

  /// The install name of the [dynamicLibrary].
  ///
  /// Can be inspected with `otool -D <path-to-dylib>`.
  ///
  /// Can be modified with `install_name_tool`.
  final Uri? installName;

  final List<String> flags;
  final Map<String, String?> defines;
  final bool? pic;
  final String? std;
  final Language language;
  final String? cppLinkStdLib;
  final OptimizationLevel optimizationLevel;
  final List<Map<String, dynamic>> compilationCommands;

  RunCBuilder({
    required this.input,
    required this.codeConfig,
    this.linkerOptions,
    this.logger,
    this.sources = const [],
    this.includes = const [],
    this.forcedIncludes = const [],
    required this.frameworks,
    this.libraries = const [],
    this.libraryDirectories = const [],
    this.executable,
    this.dynamicLibrary,
    this.staticLibrary,
    this.installName,
    this.flags = const [],
    this.defines = const {},
    this.pic,
    this.std,
    this.language = Language.c,
    this.cppLinkStdLib,
    required this.optimizationLevel,
  })  : outDir = input.outputDirectory,
        compilationCommands = [],
        assert(
         [executable, dynamicLibrary, staticLibrary].whereType<Uri>().length ==
             1,
       ) {
    if (codeConfig.targetOS == OS.windows && cppLinkStdLib != null) {
      throw ArgumentError.value(
        cppLinkStdLib,
        'cppLinkStdLib',
        'is not supported when targeting Windows',
      );
    }
  }

  late final _resolver = CompilerResolver(
    codeConfig: codeConfig,
    logger: logger,
  );

  Future<ToolInstance> compiler() async => await _resolver.resolveCompiler();

  Future<Uri> archiver() async => (await _resolver.resolveArchiver()).uri;

  Future<ToolInstance> linker() async => await _resolver.resolveLinker();

  Future<Uri> iosSdk(IOSSdk iosSdk, {required Logger? logger}) async {
    if (iosSdk == IOSSdk.iPhoneOS) {
      return (await iPhoneOSSdk.defaultResolver!.resolve(
        logger: logger,
      )).where((i) => i.tool == iPhoneOSSdk).first.uri;
    }
    assert(iosSdk == IOSSdk.iPhoneSimulator);
    return (await iPhoneSimulatorSdk.defaultResolver!.resolve(
      logger: logger,
    )).where((i) => i.tool == iPhoneSimulatorSdk).first.uri;
  }

  Future<Uri> macosSdk({required Logger? logger}) async =>
      (await macosxSdk.defaultResolver!.resolve(
        logger: logger,
      )).where((i) => i.tool == macosxSdk).first.uri;

  Uri androidSysroot(ToolInstance compiler) =>
      compiler.uri.resolve('../sysroot/');

  Future<void> run() async {
    final toolInstance_ =
        linkerOptions != null ? await linker() : await compiler();
    final tool = toolInstance_.tool;
    if (tool.isClangLike || tool.isLdLike) {
      await runClangLike(tool: toolInstance_);
      return;
    } else if (tool == cl) {
      await runCl(tool: toolInstance_);
    } else {
      throw UnimplementedError('This package does not know how to run $tool.');
    }
  }

  Future<void> runClangLike({required ToolInstance tool}) async {
    // Clang for Windows requires the MSVC Developer Environment.
    final environment = await _resolver.resolveEnvironment(tool);

    final isStaticLib = staticLibrary != null;
    Uri? archiver_;
    if (isStaticLib) {
      archiver_ = await archiver();
    }

    final IOSSdk? targetIosSdk;
    if (codeConfig.targetOS == OS.iOS) {
      targetIosSdk = codeConfig.iOS.targetSdk;
    } else {
      targetIosSdk = null;
    }

    // The Android Gradle plugin does not honor API level 19 and 20 when
    // invoking clang. Mimic that behavior here.
    // See https://github.com/dart-lang/native/issues/171.
    final int? targetAndroidNdkApi;
    if (codeConfig.targetOS == OS.android) {
      final minimumApi =
          codeConfig.targetArchitecture == Architecture.riscv64 ? 35 : 21;
      targetAndroidNdkApi = max(codeConfig.android.targetNdkApi, minimumApi);
    } else {
      targetAndroidNdkApi = null;
    }

    final targetIOSVersion =
        codeConfig.targetOS == OS.iOS ? codeConfig.iOS.targetVersion : null;
    final targetMacOSVersion =
        codeConfig.targetOS == OS.macOS ? codeConfig.macOS.targetVersion : null;

    final architecture = codeConfig.targetArchitecture;
    final sourceFilePaths = sources.map((e) => e.toFilePath()).toList();
    final objectFiles = <Uri>[];

    // 1. Compile all sources individually to object files.
    for (var i = 0; i < sourceFilePaths.length; i++) {
      final sourceFilePath = sourceFilePaths[i];
      final objectFile = outDir.resolve('out$i.o');
      await _compile(
        tool,
        architecture,
        targetAndroidNdkApi,
        targetIosSdk,
        targetIOSVersion,
        targetMacOSVersion,
        sourceFilePath, // Pass single source file path
        objectFile, // Output is an object file
        environment,
        compileOnly: true, // Indicate this is a compile-only step
      );
      objectFiles.add(objectFile);
    }

    // 2. Link object files or create static library.
    if (staticLibrary != null) {
      // Create static library from object files.
      await runProcess(
        executable: archiver_!,
        arguments: [
          'rc',
          outDir.resolveUri(staticLibrary!).toFilePath(),
          ...objectFiles.map((objectFile) => objectFile.toFilePath()),
        ],
        logger: logger,
        captureOutput: false,
        throwOnUnexpectedExitCode: true,
        environment: environment,
      );
    } else {
      // Link object files into an executable or dynamic library.
      final outputUri = executable != null
          ? outDir.resolveUri(executable!)
          : outDir.resolveUri(dynamicLibrary!);
      await _link(
        tool,
        architecture,
        targetAndroidNdkApi,
        targetIosSdk,
        targetIOSVersion,
        targetMacOSVersion,
        objectFiles, // Pass object files for linking
        outputUri, // Final output target
        environment,
      );
    }
  }

  /// Compiles a single source file into an object file.
  /// [toolInstance] must be a compiler.
  Future<void> _compile(
    ToolInstance toolInstance,
    Architecture? architecture,
    int? targetAndroidNdkApi,
    IOSSdk? targetIosSdk,
    int? targetIOSVersion,
    int? targetMacOSVersion,
    String sourceFilePath,
    Uri objectFile,
    Map<String, String> environment, {
    required bool compileOnly, // Flag to control behavior/command capture
  }) async {
    // Construct the arguments list first.
    final arguments = <String>[
      // === Compilation Flags ===
      if (codeConfig.targetOS == OS.android) ...[
        '--target='
            '${androidNdkClangTargetFlags[architecture]!}'
            '${targetAndroidNdkApi!}',
        '--sysroot=${androidSysroot(toolInstance).toFilePath()}',
      ],
      if (codeConfig.targetOS == OS.windows)
        '--target=${clangWindowsTargetFlags[architecture]!}',
      if (codeConfig.targetOS == OS.macOS)
        '--target=${appleClangMacosTargetFlags[architecture]!}',
      if (codeConfig.targetOS == OS.iOS)
        '--target=${appleClangIosTargetFlags[architecture]![targetIosSdk]!}',
      if (targetIOSVersion != null) '-mios-version-min=$targetIOSVersion',
      if (targetMacOSVersion != null) '-mmacos-version-min=$targetMacOSVersion',
      if (codeConfig.targetOS == OS.iOS) ...[
        '-isysroot',
        (await iosSdk(targetIosSdk!, logger: logger)).toFilePath(),
      ],
      if (codeConfig.targetOS == OS.macOS) ...[
        '-isysroot',
        (await macosSdk(logger: logger)).toFilePath(),
      ],
      if (pic != null &&
          toolInstance.tool.isClangLike &&
          codeConfig.targetOS != OS.windows) ...[
        if (pic!) ...[
          // Always use PIC/PIE flags suitable for the final target type,
          // even when compiling individual object files.
          if (dynamicLibrary != null) '-fPIC',
          if (staticLibrary != null) '-fPIC', // Assume linked into PIC/PIE
          if (executable != null) '-fPIE',
        ] else ...[
          '-fno-PIC',
          '-fno-PIE',
        ],
      ],
      if (std != null) '-std=$std',
      if (language == Language.cpp) ...[
        '-x',
        'c++',
      ],
      if (optimizationLevel != OptimizationLevel.unspecified)
        optimizationLevel.clangFlag(),
      ...flags,
      for (final MapEntry(key: name, :value) in defines.entries)
        if (value == null) '-D$name' else '-D$name=$value',
      for (final include in includes) '-I${include.toFilePath()}',
      for (final forcedInclude in forcedIncludes)
        '-include${forcedInclude.toFilePath()}',
      // === Input/Output ===
      '-c', // Compile only flag
      sourceFilePath,
      '-o',
      objectFile.toFilePath(),
    ];

    // Capture compilation command precisely as requested if it's a compile-only step.
    if (compileOnly) {
      // Ensure keys and values match the requirement exactly.
      final commandMap = {
        'directory': input.outputDirectory.toFilePath(), // Use input.outputDirectory
        'file': sourceFilePath, // The single source file for this step
        'arguments': arguments, // The exact arguments list for runProcess
      };
      this.compilationCommands.add(commandMap);
    }

    // Now run the process with the constructed arguments.
    await runProcess(
      executable: toolInstance.uri,
      environment: environment,
      arguments: arguments,
      logger: logger,
      captureOutput: false,
      throwOnUnexpectedExitCode: true,
    );
  }

  /// Links object files into an executable or dynamic library.
  /// [toolInstance] can be a compiler (acting as linker driver) or a linker.
  Future<void> _link(
    ToolInstance toolInstance,
    Architecture? architecture,
    int? targetAndroidNdkApi,
    IOSSdk? targetIosSdk,
    int? targetIOSVersion,
    int? targetMacOSVersion,
    Iterable<Uri> objectFiles, // Changed from sourceFiles
    Uri outFile, // Changed from optional outFile
    Map<String, String> environment,
  ) async {
    // Determine if the tool is acting as a linker driver (like clang)
    // or is a direct linker invocation (like ld).
    final isLinkerDriver = toolInstance.tool.isClangLike;
    final isLinker = toolInstance.tool.isLdLike;

    final arguments = <String>[
      // === Target/Sysroot Flags (mostly for compiler driver) ===
      // Linkers often infer the target or have different flags.
      if (isLinkerDriver) ...[
        if (codeConfig.targetOS == OS.android) ...[
          '--target='
              '${androidNdkClangTargetFlags[architecture]!}'
              '${targetAndroidNdkApi!}',
          '--sysroot=${androidSysroot(toolInstance).toFilePath()}',
        ],
        if (codeConfig.targetOS == OS.windows)
          '--target=${clangWindowsTargetFlags[architecture]!}',
        if (codeConfig.targetOS == OS.macOS)
          '--target=${appleClangMacosTargetFlags[architecture]!}',
        if (codeConfig.targetOS == OS.iOS)
          '--target=${appleClangIosTargetFlags[architecture]![targetIosSdk]!}',
        if (targetIOSVersion != null) '-mios-version-min=$targetIOSVersion',
        if (targetMacOSVersion != null)
          '-mmacos-version-min=$targetMacOSVersion',
        if (codeConfig.targetOS == OS.iOS) ...[
          '-isysroot',
          (await iosSdk(targetIosSdk!, logger: logger)).toFilePath(),
        ],
        if (codeConfig.targetOS == OS.macOS) ...[
          '-isysroot',
          (await macosSdk(logger: logger)).toFilePath(),
        ],
      ],
      // === Linker Specific Flags ===
      if (installName != null) ...[
        // Clang uses -install_name, ld might use something else or it's implied
        if (isLinkerDriver) '-install_name',
        if (isLinkerDriver) installName!.toFilePath(),
        // Add equivalent for ld if needed and different
      ],
      if (pic != null) ...[
        // Flags for position independence are often passed to the linker driver
        if (isLinkerDriver) ...[
          if (pic!) ...[
            if (executable != null) '-pie', // Request PIE executable
          ] else ...[
            if (executable != null) '-no-pie', // Request non-PIE executable
          ],
        ] else if (isLinker) ...[
          // Direct linker flags might differ (e.g., --pie, --no-pie for ld)
          if (pic!) ...[
            if (executable != null) '--pie',
          ] else ...[
            if (executable != null) '--no-pie',
          ],
        ]
      ],
      if (language == Language.cpp) ...[
        // Linker needs C++ library if C++ sources were involved
        if (isLinkerDriver)
          '-l${cppLinkStdLib ?? defaultCppLinkStdLib[codeConfig.targetOS]!}',
        // Linker might need different flag, e.g. -lc++ for ld
        if (isLinker && codeConfig.targetOS != OS.windows)
           '-l${cppLinkStdLib ?? defaultCppLinkStdLib[codeConfig.targetOS]!}',
      ],
       // Pass optimization flags to linker driver (might affect LTO)
      if (isLinkerDriver && optimizationLevel != OptimizationLevel.unspecified)
        optimizationLevel.clangFlag(),

      // Pass linker options pre-sources (now pre-objects)
      ...linkerOptions?.preSourcesFlags(
              toolInstance.tool, objectFiles.map((e) => e.path)) ??
          [],

      // Support Android 15 page size by default, can be overridden by
      // passing [flags]. Linker flag usually starts with -Wl,
      if (codeConfig.targetOS == OS.android)
         isLinkerDriver ? '-Wl,-z,max-page-size=16384' : '-z max-page-size=16384', // Example for ld

      // General flags (some might be linker flags needing -Wl, prefix)
      // Need careful filtering or prefixing based on tool type
      ...flags, // TODO: Filter/prefix flags appropriately for linker vs driver

      // === Inputs ===
      ...objectFiles.map((e) => e.toFilePath()), // Use object files

      // === Libraries and Frameworks ===
      if (language == Language.objectiveC) ...[
        // Frameworks are usually handled by the linker driver
        if (isLinkerDriver)
          for (final framework in frameworks) ...['-framework', framework],
      ],
      // Library search paths
      for (final directory in libraryDirectories)
         isLinkerDriver ? '-L${directory.toFilePath()}' : '-L ${directory.toFilePath()}', // ld might need space
      // Libraries to link
      for (final library in libraries)
         isLinkerDriver ? '-l$library' : '-l $library', // ld might need space

      // === Output ===
      if (dynamicLibrary != null) ...[
         isLinkerDriver ? '--shared' : '-shared', // ld uses -shared
      ],
      isLinkerDriver ? '-o' : '-o', // Both often use -o
      outFile.toFilePath(),

      // Pass linker options post-sources (now post-objects)
      ...linkerOptions?.postSourcesFlags(
              toolInstance.tool, objectFiles.map((e) => e.path)) ??
          [],

      // === Rpath ===
      if (codeConfig.targetOS case OS.android || OS.linux)
        // Setting rpath allows the binary to find other shared libs.
        if (linkerOptions != null) // Assuming linkerOptions implies linking
          isLinkerDriver ? '-rpath=\$ORIGIN' : '-rpath \$ORIGIN' // ld might need space
        else // If not using linkerOptions, assume direct driver call
          isLinkerDriver ? '-Wl,-rpath=\$ORIGIN' : '-rpath \$ORIGIN', // ld might need space
    ];

    await runProcess(
      executable: toolInstance.uri,
      environment: environment,
      arguments: arguments,
      logger: logger,
      captureOutput: false,
      throwOnUnexpectedExitCode: true,
    );
  }

  // Remove the placeholder _compile_old method entirely
  // Future<void> _compile_old(...) async { ... }

  Future<void> runCl({required ToolInstance tool}) async {
    final environment = await _resolver.resolveEnvironment(tool);
    final sourceFilePaths = sources.map((e) => e.toFilePath()).toList();
    final objectFiles = <Uri>[];

    final isStaticLib = staticLibrary != null;
    Uri? archiver_;
    if (isStaticLib) {
      archiver_ = await archiver();
    }

    // Step 1: Compile all sources individually to object files (.obj)
    for (var i = 0; i < sourceFilePaths.length; i++) {
      final sourceFilePath = sourceFilePaths[i];
      // Use .obj extension for MSVC object files
      final objectFile = outDir.resolve('out$i.obj');

      final compileArgs = <String>[
        // Common flags for compilation
        if (optimizationLevel != OptimizationLevel.unspecified)
          optimizationLevel.msvcFlag(),
        if (std != null) '/std:$std',
        if (language == Language.cpp) '/TP', // Treat file as C++
        ...flags, // General flags
        // Defines
        for (final MapEntry(key: name, :value) in defines.entries)
          if (value == null) '/D$name' else '/D$name=$value',
        // Includes
        for (final directory in includes) '/I${directory.toFilePath()}',
        // Forced includes
        for (final forcedInclude in forcedIncludes)
          '/FI${forcedInclude.toFilePath()}',
        // Compile flag
        '/c',
        // Input source file
        sourceFilePath,
        // Output object file path
        '/Fo${objectFile.toFilePath()}',
      ];

      // Capture compilation command before running the process
      final commandMap = {
        'directory': outDir.toFilePath(), // Use outDir as specified
        'file': sourceFilePath,
        'arguments': compileArgs,
      };
      this.compilationCommands.add(commandMap);

      // Run compilation for this single file
      await runProcess(
        executable: tool.uri,
        arguments: compileArgs,
        workingDirectory: outDir, // Run compiler in the output directory
        environment: environment,
        logger: logger,
        captureOutput: false,
        throwOnUnexpectedExitCode: true,
      );

      objectFiles.add(objectFile);
    }

    // Step 2: Link object files or create static library
    if (isStaticLib) {
      // Archive object files into a static library using lib.exe
      await runProcess(
        executable: archiver_!, // Should be lib.exe resolved earlier
        arguments: [
          '/out:${outDir.resolveUri(staticLibrary!).toFilePath()}',
          // Pass the list of generated object files
          ...objectFiles.map((f) => f.toFilePath()),
        ],
        workingDirectory: outDir,
        environment: environment,
        logger: logger,
        captureOutput: false,
        throwOnUnexpectedExitCode: true,
      );
    } else {
      // Link object files into an executable or dynamic library using cl.exe driver
      final linkArgs = <String>[
        // Common flags (passed again to linker driver)
        if (optimizationLevel != OptimizationLevel.unspecified)
          optimizationLevel.msvcFlag(),
        // '/std' and '/TP' might not be needed for linker, but flags could be
        ...flags,
        // Input object files - must come before /link
        ...objectFiles.map((f) => f.toFilePath()),
        // Linker command
        '/link',
        // Output file
        if (executable != null)
          '/out:${outDir.resolveUri(executable!).toFilePath()}'
        else // dynamicLibrary != null
          '/out:${outDir.resolveUri(dynamicLibrary!).toFilePath()}',
        // DLL flag if creating dynamic library
        if (dynamicLibrary != null) '/DLL',
        // Library paths
        for (final directory in libraryDirectories)
          '/LIBPATH:${directory.toFilePath()}',
        // Link libraries (name only, linker adds .lib)
        for (final library in libraries) '$library.lib',
      ];

      // Run the linker via the compiler driver
      await runProcess(
        executable: tool.uri, // Use cl.exe as the linker driver
        arguments: linkArgs,
        workingDirectory: outDir,
        environment: environment,
        logger: logger,
        captureOutput: false,
        throwOnUnexpectedExitCode: true,
      );
    }
    // No single 'result' to assert on as compilation/linking are separate steps now
  }

  static const androidNdkClangTargetFlags = {
    Architecture.arm: 'armv7a-linux-androideabi',
    Architecture.arm64: 'aarch64-linux-android',
    Architecture.ia32: 'i686-linux-android',
    Architecture.x64: 'x86_64-linux-android',
    Architecture.riscv64: 'riscv64-linux-android',
  };

  static const appleClangMacosTargetFlags = {
    Architecture.arm64: 'arm64-apple-darwin',
    Architecture.x64: 'x86_64-apple-darwin',
  };

  static const appleClangIosTargetFlags = {
    Architecture.arm64: {
      IOSSdk.iPhoneOS: 'arm64-apple-ios',
      IOSSdk.iPhoneSimulator: 'arm64-apple-ios-simulator',
    },
    Architecture.x64: {IOSSdk.iPhoneSimulator: 'x86_64-apple-ios-simulator'},
  };

  static const clangWindowsTargetFlags = {
    Architecture.arm64: 'arm64-pc-windows-msvc',
    Architecture.ia32: 'i386-pc-windows-msvc',
    Architecture.x64: 'x86_64-pc-windows-msvc',
  };

  static const defaultCppLinkStdLib = {
    OS.android: 'c++_shared',
    OS.fuchsia: 'c++',
    OS.iOS: 'c++',
    OS.linux: 'stdc++',
    OS.macOS: 'c++',
  };
}
