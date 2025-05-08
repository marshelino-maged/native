// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks_runner/src/either.dart';
import 'package:hooks_runner/src/failure.dart';
import 'package:hooks_runner/src/model/build_result.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../helpers.dart';
import 'helpers.dart';

const Timeout longTimeout = Timeout(Duration(minutes: 5));

void main() async {
  test('break build', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('native_add/');

      await runPubGet(workingDirectory: packageUri, logger: logger);

      {
        final resultEither = await build(
          packageUri,
          logger,
          dartExecutable,
          buildAssetTypes: [BuildAssetType.code],
        );
        expect(resultEither.isLeft, true,
            reason:
                "Expected build to succeed, but got Failure: ${resultEither.rightOrNull?.message}");
        final result = resultEither.leftOrNull!;
        expect(result.encodedAssets.length, 1);
        expect(await result.encodedAssets.allExist(), true);
        for (final encodedAssetsForLinking
            in result.encodedAssetsForLinking.values) {
          expect(await encodedAssetsForLinking.allExist(), true);
        }
        await expectSymbols(
          asset: CodeAsset.fromEncoded(result.encodedAssets.single),
          symbols: ['add'],
        );
        expect(
          result.dependencies,
          contains(packageUri.resolve('src/native_add.c')),
        );
      }

      await copyTestProjects(
        sourceUri: testDataUri.resolve('native_add_break_build/'),
        targetUri: packageUri,
      );

      {
        final logMessages = <String>[];
        final resultEither = await build(
          packageUri,
          createCapturingLogger(logMessages, level: Level.SEVERE),
          dartExecutable,
          buildAssetTypes: [BuildAssetType.code],
        );
        final fullLog = logMessages.join('\n');
        expect(resultEither.isRight, true,
            reason: "Expected build to fail, but it succeeded.");
        final failure = resultEither.rightOrNull!;
        expect(failure.type, FailureType.ProcessExecutionFailed);
        expect(fullLog, contains('To reproduce run:'));
        final reproCommand =
            fullLog
                .split('\n')
                .skipWhile((l) => !l.contains('To reproduce run:'))
                .skip(1)
                .first;
        final reproResult = await Process.run(
          reproCommand,
          [],
          runInShell: true,
        );
        expect(reproResult.exitCode, isNot(0));
      }

      await copyTestProjects(
        sourceUri: testDataUri.resolve('native_add_fix_build/'),
        targetUri: packageUri,
      );

      {
        final resultEither = await build(
          packageUri,
          logger,
          dartExecutable,
          buildAssetTypes: [BuildAssetType.code],
        );
        expect(resultEither.isLeft, true,
            reason:
                "Expected build to succeed, but got Failure: ${resultEither.rightOrNull?.message}");
        final result = resultEither.leftOrNull!;
        expect(result.encodedAssets.length, 1);
        expect(await result.encodedAssets.allExist(), true);
        for (final encodedAssetsForLinking
            in result.encodedAssetsForLinking.values) {
          expect(await encodedAssetsForLinking.allExist(), true);
        }
        await expectSymbols(
          asset: CodeAsset.fromEncoded(result.encodedAssets.single),
          symbols: ['add'],
        );
        expect(
          result.dependencies,
          contains(packageUri.resolve('src/native_add.c')),
        );
      }
    });
  });

  test(
    'do not build dependees after build failure',
    timeout: longTimeout,
    () async {
      await inTempDir((tempUri) async {
        await copyTestProjects(targetUri: tempUri);
        final packageUri = tempUri.resolve('depend_on_fail_build_app/');

        await runPubGet(workingDirectory: packageUri, logger: logger);

        final logMessages = <String>[];
        final resultEither = await build(
          packageUri,
          logger,
          capturedLogs: logMessages,
          dartExecutable,
          buildAssetTypes: [BuildAssetType.code],
        );
        // This test expects a failure, but it's a bit subtle.
        // The 'depend_on_fail_build_app' depends on 'fail_build'.
        // 'fail_build' hook is expected to fail.
        // Therefore, the overall build for 'depend_on_fail_build_app' should also reflect this failure.
        expect(resultEither.isRight, true,
            reason:
                "Expected build to fail because a dependency failed, but it succeeded.");
        final failure = resultEither.rightOrNull!;
        // Depending on how NativeAssetsBuildRunner propagates errors from dependencies,
        // this could be ProcessExecutionFailed (if the hook of fail_build itself fails)
        // or BuildFailed (if the planner or runner determines the build cannot proceed).
        // For now, let's assume it's a general build failure.
        expect(failure.type, FailureType.ProcessExecutionFailed);

        Matcher stringContainsBuildHookCompilation(String packageName) =>
            stringContainsInOrder([
              'Running',
              'hook.dill',
              '$packageName${Platform.pathSeparator}'
                  'hook${Platform.pathSeparator}build.dart',
            ]);
        expect(
          logMessages.join('\n'),
          stringContainsBuildHookCompilation('fail_build'),
        );
        expect(
          logMessages.join('\n'),
          isNot(stringContainsBuildHookCompilation('depends_on_fail_build')),
        );
      });
    },
  );

  test('UserDefinesFailed Test', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('user_defines_fail/');
      await runPubGet(workingDirectory: packageUri, logger: logger);

      final resultEither = await build(
        packageUri,
        logger,
        dartExecutable,
        buildAssetTypes: [BuildAssetType.code], // Does not matter for this test
        userDefines: UserDefines(workspacePubspec: packageUri.resolve('pubspec.yaml')),
      );
      expect(resultEither.isRight, true,
          reason: "Expected build to fail due to invalid user_defines, but it succeeded.");
      final failure = resultEither.rightOrNull!;
      expect(failure.type, FailureType.UserDefinesFailed);
      expect(failure.message, contains('pubspec.yaml contains errors'));
    });
  });

  test('OutputValidationFailed Test (Build)', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('output_validation_fail_build/');
      await runPubGet(workingDirectory: packageUri, logger: logger);

      final resultEither = await build(
        packageUri,
        logger,
        dartExecutable,
        buildAssetTypes: [BuildAssetType.code], // Does not matter for this test
      );
      expect(resultEither.isRight, true,
          reason: "Expected build to fail due to invalid build output, but it succeeded.");
      final failure = resultEither.rightOrNull!;
      expect(failure.type, FailureType.OutputValidationFailed);
      expect(failure.message, contains('Build hook of package:output_validation_fail_build has invalid output'));
    });
  });

  test('OutputValidationFailed Test (Link)', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('output_validation_fail_link/');
      await runPubGet(workingDirectory: packageUri, logger: logger);

      final buildResultEither = await build(
        packageUri,
        logger,
        dartExecutable,
        linkingEnabled: true, // Important to enable linking
        buildAssetTypes: [BuildAssetType.data],
      );
      expect(buildResultEither.isLeft, true,
          reason: "Expected initial build to succeed, but got ${buildResultEither.rightOrNull?.message}");
      final buildResult = buildResultEither.leftOrNull!;

      final linkResultEither = await link(
        packageUri,
        logger,
        dartExecutable,
        buildResult: buildResult,
        buildAssetTypes: [BuildAssetType.data],
      );
      expect(linkResultEither.isRight, true,
          reason: "Expected link to fail due to invalid link output, but it succeeded.");
      final failure = linkResultEither.rightOrNull!;
      expect(failure.type, FailureType.OutputValidationFailed);
      expect(failure.message, contains('Link hook of package:output_validation_fail_link has invalid output'));
    });
  });

  test('FileOperationFailed Test (Corrupt Output File Build)', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('corrupt_output_json_build/');
      await runPubGet(workingDirectory: packageUri, logger: logger);

      final resultEither = await build(
        packageUri,
        logger,
        dartExecutable,
        buildAssetTypes: [BuildAssetType.code], // Does not matter for this test
      );
      expect(resultEither.isRight, true,
          reason: "Expected build to fail due to corrupt output.json, but it succeeded.");
      final failure = resultEither.rightOrNull!;
      expect(failure.type, FailureType.FileOperationFailed);
      expect(failure.message, contains('Failed to read hook output: format error'));
    });
  });

  test('CompilationFailed Test (Hook Script Error)', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('hook_compilation_fail/');
      await runPubGet(workingDirectory: packageUri, logger: logger);

      final resultEither = await build(
        packageUri,
        logger,
        dartExecutable,
        buildAssetTypes: [BuildAssetType.code], // Does not matter for this test
      );
      expect(resultEither.isRight, true,
          reason: "Expected build to fail due to hook compilation error, but it succeeded.");
      final failure = resultEither.rightOrNull!;
      expect(failure.type, FailureType.CompilationFailed);
      expect(failure.message, contains('Hook compilation failed with exit code'));
    });
  });

  // The 'break build' test already covers ProcessExecutionFailed for C-compiler failures.
  // This new test case would be for when the hook script itself exits with a non-zero code.
  // Need to create 'test_data/hook_exit_code_fail/' package.
  // Steps:
  // 1. Create pkgs/hooks_runner/test_data/hook_exit_code_fail/pubspec.yaml
  // 2. Create pkgs/hooks_runner/test_data/hook_exit_code_fail/hook/build.dart (with exit(1);)

  test('ProcessExecutionFailed Test (Hook Script Exit Code)', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      // Create hook_exit_code_fail package first
      final packageSourceUri = testDataUri.resolve('hook_exit_code_fail/');
      final packageDestUri = tempUri.resolve('hook_exit_code_fail/');
      await Directory(packageDestUri.toFilePath()).create(recursive: true);
      await File(packageSourceUri.resolve('pubspec.yaml').toFilePath())
          .copy(packageDestUri.resolve('pubspec.yaml').toFilePath());
      await Directory(packageDestUri.resolve('hook').toFilePath()).create();
      await File(packageSourceUri.resolve('hook/build.dart').toFilePath())
          .copy(packageDestUri.resolve('hook/build.dart').toFilePath());
      
      await copyTestProjects(targetUri: tempUri); // Copies other projects
      final packageUri = tempUri.resolve('hook_exit_code_fail/');
      await runPubGet(workingDirectory: packageUri, logger: logger);

      final resultEither = await build(
        packageUri,
        logger,
        dartExecutable,
        buildAssetTypes: [BuildAssetType.code],
      );
      expect(resultEither.isRight, true,
          reason: "Expected build to fail due to hook script non-zero exit, but it succeeded.");
      final failure = resultEither.rightOrNull!;
      expect(failure.type, FailureType.ProcessExecutionFailed);
      expect(failure.message, contains('Hook execution failed with exit code 1'));
    });
  });

}
