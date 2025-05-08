// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:hooks_runner/src/either.dart';
import 'package:hooks_runner/src/failure.dart';
import 'package:hooks_runner/src/model/build_result.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../helpers.dart';
import 'helpers.dart';

const Timeout longTimeout = Timeout(Duration(minutes: 5));

void main() async {
  test('wrong asset id', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('wrong_namespace_asset/');

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
        expect(
          fullLog,
          contains('does not start with "package:wrong_namespace_asset/"'),
        );
        expect(
            failure.message,
            contains(
                'Build hook of package:wrong_namespace_asset has invalid output'));
      }
    });
  });

  test('right asset id but other directory', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      final packageUri = tempUri.resolve('different_root_dir/');
      await copyTestProjects(targetUri: tempUri);
      await copyTestProjects(
        sourceUri: testDataUri.resolve('native_add/'),
        targetUri: packageUri,
      );

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
        expect(await result.encodedAssets.allExist(), true);
        for (final encodedAssetsForLinking
            in result.encodedAssetsForLinking.values) {
          expect(await encodedAssetsForLinking.allExist(), true);
        }
      }
    });
  });
}
