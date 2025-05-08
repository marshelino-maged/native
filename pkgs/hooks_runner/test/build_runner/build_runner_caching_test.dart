// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks_runner/src/build_runner/build_runner.dart';
import 'package:hooks_runner/src/either.dart';
import 'package:hooks_runner/src/failure.dart';
import 'package:hooks_runner/src/model/build_result.dart';
import 'package:test/test.dart';

import '../helpers.dart';
import 'helpers.dart';

const Timeout longTimeout = Timeout(Duration(minutes: 5));

void main() async {
  test('cached build', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('native_add/');

      await runPubGet(workingDirectory: packageUri, logger: logger);

      {
        final logMessages = <String>[];
        final resultEither = await build(
          packageUri,
          logger,
          dartExecutable,
          capturedLogs: logMessages,
          buildAssetTypes: [BuildAssetType.code],
        );
        expect(resultEither.isLeft, true,
            reason:
                "Expected build to succeed, but got Failure: ${resultEither.rightOrNull?.message}");
        final result = resultEither.leftOrNull!;
        expect(
          logMessages.join('\n'),
          contains(
            'native_add${Platform.pathSeparator}hook'
            '${Platform.pathSeparator}build.dart',
          ),
        );
        expect(
          result.dependencies,
          contains(packageUri.resolve('src/native_add.c')),
        );
        expect(await result.encodedAssets.allExist(), true);
        for (final encodedAssetsForLinking
            in result.encodedAssetsForLinking.values) {
          expect(await encodedAssetsForLinking.allExist(), true);
        }
      }

      {
        final logMessages = <String>[];
        final resultEither = await build(
          packageUri,
          logger,
          dartExecutable,
          capturedLogs: logMessages,
          buildAssetTypes: [BuildAssetType.code],
        );
        expect(resultEither.isLeft, true,
            reason:
                "Expected build to succeed, but got Failure: ${resultEither.rightOrNull?.message}");
        final result = resultEither.leftOrNull!;
        final hookUri = packageUri.resolve('hook/build.dart');
        expect(
          logMessages.join('\n'),
          isNot(contains('Recompiling ${hookUri.toFilePath()}')),
        );
        expect(
          logMessages.join('\n'),
          contains('Skipping build for native_add'),
        );
        expect(
          logMessages.join('\n'),
          isNot(
            contains(
              'native_add${Platform.pathSeparator}hook'
              '${Platform.pathSeparator}build.dart',
            ),
          ),
        );
        expect(
          result.dependencies,
          contains(packageUri.resolve('src/native_add.c')),
        );
        expect(await result.encodedAssets.allExist(), true);
        for (final encodedAssetsForLinking
            in result.encodedAssetsForLinking.values) {
          expect(await encodedAssetsForLinking.allExist(), true);
        }
      }
    });
  });

  test('modify C file', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('native_add/');

      final logMessages = <String>[];
      final logger = createCapturingLogger(logMessages);

      await runPubGet(workingDirectory: packageUri, logger: logger);
      logMessages.clear();

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
        expect(await result.encodedAssets.allExist(), true);
        for (final encodedAssetsForLinking
            in result.encodedAssetsForLinking.values) {
          expect(await encodedAssetsForLinking.allExist(), true);
        }
        await expectSymbols(
          asset: CodeAsset.fromEncoded(result.encodedAssets.single),
          symbols: ['add'],
        );
        logMessages.clear();
      }

      await copyTestProjects(
        sourceUri: testDataUri.resolve('native_add_add_symbol/'),
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
        expect(await result.encodedAssets.allExist(), true);
        for (final encodedAssetsForLinking
            in result.encodedAssetsForLinking.values) {
          expect(await encodedAssetsForLinking.allExist(), true);
        }

        final cUri = packageUri.resolve('src/').resolve('native_add.c');
        expect(
          logMessages.join('\n'),
          stringContainsInOrder([
            'Rerunning build for native_add in',
            'File contents changed: ${cUri.toFilePath()}.',
          ]),
        );

        await expectSymbols(
          asset: CodeAsset.fromEncoded(result.encodedAssets.single),
          symbols: ['add', 'subtract'],
        );
      }
    });
  });

  test('add C file, modify hook', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('native_add/');

      final logMessages = <String>[];
      final logger = createCapturingLogger(logMessages);

      await runPubGet(workingDirectory: packageUri, logger: logger);
      logMessages.clear();

      final resultEitherInitial = await build(
        packageUri,
        logger,
        dartExecutable,
        buildAssetTypes: [BuildAssetType.code],
      );
      expect(resultEitherInitial.isLeft, true,
          reason:
              "Expected build to succeed, but got Failure: ${resultEitherInitial.rightOrNull?.message}");
      final resultInitial = resultEitherInitial.leftOrNull!;
      expect(await resultInitial.encodedAssets.allExist(), true);
      for (final encodedAssetsForLinking
          in resultInitial.encodedAssetsForLinking.values) {
        expect(await encodedAssetsForLinking.allExist(), true);
      }
      {
        final compiledHook =
            logMessages
                .where(
                  (m) =>
                      m.contains('dart compile kernel') ||
                      m.contains('dart.exe compile kernel'),
                )
                .isNotEmpty;
        expect(compiledHook, isTrue);
      }
      logMessages.clear();
      await expectSymbols(
        asset: CodeAsset.fromEncoded(resultInitial.encodedAssets.single),
        symbols: ['add'],
      );

      await copyTestProjects(
        sourceUri: testDataUri.resolve('native_add_add_source/'),
        targetUri: packageUri,
      );

      {
        final resultEitherModified = await build(
          packageUri,
          logger,
          dartExecutable,
          buildAssetTypes: [BuildAssetType.code],
        );
        expect(resultEitherModified.isLeft, true,
            reason:
                "Expected build to succeed, but got Failure: ${resultEitherModified.rightOrNull?.message}");
        final resultModified = resultEitherModified.leftOrNull!;
        expect(await resultModified.encodedAssets.allExist(), true);
        for (final encodedAssetsForLinking
            in resultModified.encodedAssetsForLinking.values) {
          expect(await encodedAssetsForLinking.allExist(), true);
        }

        final hookUri = packageUri.resolve('hook/build.dart');
        expect(
          logMessages.join('\n'),
          contains('Recompiling ${hookUri.toFilePath()}'),
        );

        logMessages.clear();
        await expectSymbols(
          asset: CodeAsset.fromEncoded(resultModified.encodedAssets.single),
          symbols: ['add', 'multiply'],
        );
      }
    });
  });

  for (final modifiedEnvKey in ['PATH', 'CUSTOM_KEY_123']) {
    test('change environment $modifiedEnvKey', timeout: longTimeout, () async {
      await inTempDir((tempUri) async {
        await copyTestProjects(targetUri: tempUri);
        final packageUri = tempUri.resolve('native_add/');

        final logMessages = <String>[];
        final logger = createCapturingLogger(logMessages);

        await runPubGet(workingDirectory: packageUri, logger: logger);
        logMessages.clear();

        final initialBuildResultEither = await build(
          packageUri,
          logger,
          dartExecutable,
          buildAssetTypes: [BuildAssetType.code],
          hookEnvironment:
              modifiedEnvKey == 'PATH'
                  ? null
                  : filteredEnvironment(
                    NativeAssetsBuildRunner.hookEnvironmentVariablesFilter,
                  ),
        );
        expect(initialBuildResultEither.isLeft, true,
            reason:
                "Expected build to succeed, but got Failure: ${initialBuildResultEither.rightOrNull?.message}");
        final initialBuildResult = initialBuildResultEither.leftOrNull!;
        expect(await initialBuildResult.encodedAssets.allExist(), true);
        for (final encodedAssetsForLinking
            in initialBuildResult.encodedAssetsForLinking.values) {
          expect(await encodedAssetsForLinking.allExist(), true);
        }
        logMessages.clear();

        // Simulate that the environment variables changed by augmenting the
        // persisted environment from the last invocation.
        final dependenciesHashFile = File.fromUri(
          (Directory.fromUri(
                    packageUri.resolve('.dart_tool/hooks_runner/native_add/'),
                  ).listSync().single
                  as Directory)
              .uri
              .resolve('dependencies.dependencies_hash_file.json'),
        );
        expect(await dependenciesHashFile.exists(), true);
        final dependenciesContent =
            jsonDecode(await dependenciesHashFile.readAsString())
                as Map<Object, Object?>;
        (dependenciesContent['environment'] as List<dynamic>).add({
          'key': modifiedEnvKey,
          'hash': 123456789,
        });
        await dependenciesHashFile.writeAsString(
          jsonEncode(dependenciesContent),
        );

        final modifiedBuildResultEither = await build(
          packageUri,
          logger,
          dartExecutable,
          buildAssetTypes: [BuildAssetType.code],
        );
        expect(modifiedBuildResultEither.isLeft, true,
            reason:
                "Expected build to succeed, but got Failure: ${modifiedBuildResultEither.rightOrNull?.message}");
        final modifiedBuildResult = modifiedBuildResultEither.leftOrNull!;
        expect(await modifiedBuildResult.encodedAssets.allExist(), true);
        for (final encodedAssetsForLinking
            in modifiedBuildResult.encodedAssetsForLinking.values) {
          expect(await encodedAssetsForLinking.allExist(), true);
        }
        expect(logMessages.join('\n'), contains('hook.dill'));
        expect(
          logMessages.join('\n'),
          isNot(contains('Skipping build for native_add')),
        );
        expect(
          logMessages.join('\n'),
          contains('Environment variable changed: $modifiedEnvKey.'),
        );
        logMessages.clear();
      });
    });
  }
}
