// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:hooks_runner/src/either.dart';
import 'package:hooks_runner/src/failure.dart';
import 'package:hooks_runner/src/model/build_result.dart';
import 'package:hooks_runner/src/model/link_result.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../helpers.dart';
import 'helpers.dart';

const Timeout longTimeout = Timeout(Duration(minutes: 5));

void main() async {
  test('conflicting dylib name', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('native_add_duplicate/');

      await runPubGet(workingDirectory: packageUri, logger: logger);

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
        expect(failure.type, FailureType.OutputValidationFailed);
        expect(fullLog, contains('Duplicate dynamic library file name'));
        expect(failure.message,
            contains('Build hook of package:native_add_duplicate has invalid output'));
      }
    });
  });

  test(
    'conflicting dylib name between link and build',
    timeout: longTimeout,
    () async {
      await inTempDir((tempUri) async {
        await copyTestProjects(targetUri: tempUri);
        final packageUri = tempUri.resolve('native_add_duplicate/');

        await runPubGet(workingDirectory: packageUri, logger: logger);

        final buildResultEither = await build(
          packageUri,
          logger,
          linkingEnabled: true,
          dartExecutable,
          buildAssetTypes: [BuildAssetType.code],
        );
        expect(buildResultEither.isLeft, true,
            reason:
                "Expected initial build to succeed, but got Failure: ${buildResultEither.rightOrNull?.message}");
        final buildResult = buildResultEither.leftOrNull!;
        expect(await buildResult.encodedAssets.allExist(), true);
        for (final encodedAssetsForLinking
            in buildResult.encodedAssetsForLinking.values) {
          expect(await encodedAssetsForLinking.allExist(), true);
        }


        final linkResultEither = await link(
          packageUri,
          logger,
          dartExecutable,
          buildResult: buildResult,
          buildAssetTypes: [BuildAssetType.code],
        );
        // Application validation error due to conflicting dylib name.
        expect(linkResultEither.isRight, true,
            reason: "Expected link to fail, but it succeeded.");
        final linkFailure = linkResultEither.rightOrNull!;
        expect(linkFailure.type, FailureType.OutputValidationFailed);
        expect(linkFailure.message, contains('Application asset verification failed'));
      });
    },
  );
}
