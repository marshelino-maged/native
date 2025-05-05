// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:native_toolchain_c/src/cbuilder/cbuilder.dart';
import 'package:native_toolchain_c/src/cbuilder/run_cbuilder.dart';
import 'package:native_toolchain_c/src/native_toolchain/apple_clang.dart';
import 'package:native_toolchain_c/src/native_toolchain/clang.dart';
import 'package:native_toolchain_c/src/native_toolchain/msvc.dart';
import 'package:native_toolchain_c/src/tool/tool.dart';
import 'package:native_toolchain_c/src/tool/tool_instance.dart';
import 'package:native_toolchain_c/src/tool/tool_resolver.dart';
import 'package:test/test.dart';

import '../helpers.dart';

void main() {
  final logger = Logger('')
    ..level = Level.ALL
    ..onRecord.listen((record) {
      printOnFailure(
          '${record.level.name}: ${record.time}: ${record.message}');
    });

  // Ensure tool resolvers are registered, especially for finding compilers.
  setUpAll(setUpTesting);

  // Define some dummy source files for testing.
  final sourceFiles = ['source1.c', 'source2.cpp'];

  /// Helper function to run a CBuilder test and check compile_commands.json.
  Future<void> _testCompileCommands({
    required OutputType outputType,
    required LinkModePreference linkModePreference,
    required bool isOutsidePubCache,
    required Uri packageRoot, // Pre-determined based on isOutsidePubCache
    required String? pubCachePath, // Mock value for PUB_CACHE env var
  }) async {
    final buildConfig = testConfig();
    final buildOutput = BuildOutput();
    final tempDir = await Directory.systemTemp.createTemp();
    final outDir = tempDir.uri.resolve('out/');
    await Directory.fromUri(outDir).create();

    // Create dummy source files within the packageRoot.
    for (final source in sourceFiles) {
      final file = File.fromUri(packageRoot.resolve(source));
      await file.parent.create(recursive: true);
      await file.writeAsString('int main() { return 0; }');
    }

    final buildInput = BuildInput(
      buildConfig: buildConfig,
      outputDirectory: outDir,
      packageRoot: packageRoot,
      packageName: 'my_package',
    );

    final CBuilder cbuilder;
    if (outputType == OutputType.executable) {
      cbuilder = CBuilder.executable(
        name: 'my_exe',
        sources: sourceFiles,
        language: Language.cpp, // Test with mixed languages
      );
    } else {
      cbuilder = CBuilder.library(
        name: 'my_lib',
        assetName: 'my_lib.a',
        sources: sourceFiles,
        language: Language.cpp,
        linkModePreference: linkModePreference,
      );
    }

    // Mock the PUB_CACHE environment variable if needed.
    final originalPubCache = Platform.environment['PUB_CACHE'];
    try {
      if (pubCachePath != null) {
        Platform.environment['PUB_CACHE'] = pubCachePath;
      } else {
        Platform.environment.remove('PUB_CACHE'); // Ensure it's not set
      }

      // Run the CBuilder.
      await cbuilder.run(
        input: buildInput,
        output: buildOutput,
        logger: logger,
      );
    } finally {
      // Restore original environment.
      if (originalPubCache != null) {
        Platform.environment['PUB_CACHE'] = originalPubCache;
      } else {
        Platform.environment.remove('PUB_CACHE');
      }
    }


    // Assertions
    final commandsFile = File.fromUri(outDir.resolve('compile_commands.json'));
    if (isOutsidePubCache) {
      expect(await commandsFile.exists(), isTrue,
          reason: 'compile_commands.json should exist when outside pub cache.');

      final content = await commandsFile.readAsString();
      final List<dynamic> commands;
      try {
        commands = jsonDecode(content) as List<dynamic>;
      } catch (e) {
        fail('Failed to parse compile_commands.json: $e\nContent:\n$content');
      }

      expect(commands, isA<List>(), reason: 'JSON should be a list.');
      expect(commands.length, sourceFiles.length,
          reason: 'Should have one command per source file.');

      // Check the first command entry for basic structure and content.
      final firstCommand = commands.first;
      expect(firstCommand, isA<Map>(), reason: 'Command entry should be a map.');
      expect(firstCommand.keys, containsAll(['directory', 'file', 'arguments']),
          reason: 'Command map should contain directory, file, and arguments.');

      final commandDir = firstCommand['directory'] as String;
      final commandFile = firstCommand['file'] as String;
      final commandArgs = firstCommand['arguments'] as List<dynamic>;

      // Directory should be the CBuilder output directory (where .o files go)
      // Note: RunCBuilder uses input.outputDirectory for the command's 'directory'.
      expect(commandDir, buildInput.outputDirectory.toFilePath(),
          reason: 'Directory should match the build output directory.');

      // File should be the absolute path to the source file.
      expect(commandFile, packageRoot.resolve(sourceFiles.first).toFilePath(),
          reason: 'File path should match the source file path.');

      // Arguments should be a list of strings and contain expected flags.
      expect(commandArgs, isA<List<String>>(),
          reason: 'Arguments should be a list of strings.');
      expect(commandArgs, contains('-c'), // Compile flag
          reason: 'Arguments should contain the compile flag "-c".');
      expect(commandArgs.any((arg) => arg.endsWith('.o') || arg.endsWith('.obj')), isTrue,
          reason: 'Arguments should contain an output object file flag.');
      expect(commandArgs.any((arg) => arg.endsWith(sourceFiles.first)), isTrue,
          reason: 'Arguments should contain the source file name.');

    } else {
      expect(await commandsFile.exists(), isFalse,
          reason: 'compile_commands.json should NOT exist when inside pub cache.');
    }

    // Clean up.
    await tempDir.delete(recursive: true);
  }


  group('compile_commands.json generation', () {
    // === Tests simulating being OUTSIDE pub cache ===

    test('executable (outside pub cache)', () async {
      // Simulate package root NOT inside pub cache.
      final packageRoot = Directory.systemTemp.uri.resolve('my_package_outside/');
      await Directory.fromUri(packageRoot).create();
      // Ensure PUB_CACHE is set to something different.
      final fakePubCache = Directory.systemTemp.uri.resolve('fake_pub_cache/');
      await _testCompileCommands(
        outputType: OutputType.executable,
        linkModePreference: LinkModePreference.dynamic, // Not relevant for exe
        isOutsidePubCache: true,
        packageRoot: packageRoot,
        pubCachePath: fakePubCache.toFilePath(),
      );
      await Directory.fromUri(packageRoot).delete(recursive: true);
      await Directory.fromUri(fakePubCache).delete(recursive: true);
    });

    test('dynamic library (outside pub cache)', () async {
       final packageRoot = Directory.systemTemp.uri.resolve('my_package_outside_dyn/');
       await Directory.fromUri(packageRoot).create();
       final fakePubCache = Directory.systemTemp.uri.resolve('fake_pub_cache_dyn/');
       await _testCompileCommands(
         outputType: OutputType.library,
         linkModePreference: LinkModePreference.dynamic,
         isOutsidePubCache: true,
         packageRoot: packageRoot,
         pubCachePath: fakePubCache.toFilePath(),
       );
       await Directory.fromUri(packageRoot).delete(recursive: true);
       await Directory.fromUri(fakePubCache).delete(recursive: true);
    });

     test('static library (outside pub cache)', () async {
       final packageRoot = Directory.systemTemp.uri.resolve('my_package_outside_static/');
       await Directory.fromUri(packageRoot).create();
       final fakePubCache = Directory.systemTemp.uri.resolve('fake_pub_cache_static/');
       await _testCompileCommands(
         outputType: OutputType.library,
         linkModePreference: LinkModePreference.static,
         isOutsidePubCache: true,
         packageRoot: packageRoot,
         pubCachePath: fakePubCache.toFilePath(),
       );
       await Directory.fromUri(packageRoot).delete(recursive: true);
       await Directory.fromUri(fakePubCache).delete(recursive: true);
    });


    // === Tests simulating being INSIDE pub cache ===

    test('executable (inside pub cache)', () async {
      // Simulate package root BEING inside pub cache.
      final fakePubCache = Directory.systemTemp.uri.resolve('actual_pub_cache/');
      final packageRoot = fakePubCache.resolve('hosted/pub.dev/my_package-1.0.0/');
      await Directory.fromUri(packageRoot).create(recursive: true); // Create necessary dirs
      await _testCompileCommands(
        outputType: OutputType.executable,
        linkModePreference: LinkModePreference.dynamic, // Not relevant for exe
        isOutsidePubCache: false, // Expect file NOT to be generated
        packageRoot: packageRoot,
        pubCachePath: fakePubCache.toFilePath(), // PUB_CACHE points here
      );
      await Directory.fromUri(fakePubCache).delete(recursive: true); // Clean up cache dir
    });

     test('dynamic library (inside pub cache)', () async {
      final fakePubCache = Directory.systemTemp.uri.resolve('actual_pub_cache_dyn/');
      final packageRoot = fakePubCache.resolve('hosted/pub.dev/my_package-1.0.0/');
      await Directory.fromUri(packageRoot).create(recursive: true);
      await _testCompileCommands(
        outputType: OutputType.library,
        linkModePreference: LinkModePreference.dynamic,
        isOutsidePubCache: false,
        packageRoot: packageRoot,
        pubCachePath: fakePubCache.toFilePath(),
      );
       await Directory.fromUri(fakePubCache).delete(recursive: true);
    });

     test('static library (inside pub cache)', () async {
      final fakePubCache = Directory.systemTemp.uri.resolve('actual_pub_cache_static/');
      final packageRoot = fakePubCache.resolve('hosted/pub.dev/my_package-1.0.0/');
      await Directory.fromUri(packageRoot).create(recursive: true);
      await _testCompileCommands(
        outputType: OutputType.library,
        linkModePreference: LinkModePreference.static,
        isOutsidePubCache: false,
        packageRoot: packageRoot,
        pubCachePath: fakePubCache.toFilePath(),
      );
       await Directory.fromUri(fakePubCache).delete(recursive: true);
    });

  });
}
