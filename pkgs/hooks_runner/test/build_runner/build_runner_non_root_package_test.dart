// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:hooks_runner/src/either.dart';
import 'package:hooks_runner/src/failure.dart';
import 'package:hooks_runner/src/model/build_result.dart';
import 'package:test/test.dart';

import '../helpers.dart';
import 'helpers.dart';

const Timeout longTimeout = Timeout(Duration(minutes: 5));

void main() async {
  test('run ffigen first', timeout: longTimeout, () async {
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
          runPackageName: 'some_dev_dep',
          buildAssetTypes: [BuildAssetType.code],
        );
        expect(resultEither.isLeft, true,
            reason:
                "Expected build to succeed, but got Failure: ${resultEither.rightOrNull?.message}");
        final result = resultEither.leftOrNull!;
        expect(result.encodedAssets, isEmpty);
        expect(result.dependencies, isEmpty);
        // No assets expected, so no allExist check needed here.
      }

      {
        final logMessages = <String>[];
        final resultEither = await build(
          packageUri,
          logger,
          dartExecutable,
          capturedLogs: logMessages,
          runPackageName: 'native_add',
          buildAssetTypes: [BuildAssetType.code],
        );
        expect(resultEither.isLeft, true,
            reason:
                "Expected build to succeed, but got Failure: ${resultEither.rightOrNull?.message}");
        final result = resultEither.leftOrNull!;
        expect(result.encodedAssets, isNotEmpty);
        expect(await result.encodedAssets.allExist(), true);
        for (final encodedAssetsForLinking
            in result.encodedAssetsForLinking.values) {
          expect(await encodedAssetsForLinking.allExist(), true);
        }
        expect(
          result.dependencies,
          contains(packageUri.resolve('src/native_add.c')),
        );
        expect(
          logMessages.join('\n'),
          contains(
            'native_add${Platform.pathSeparator}hook'
            '${Platform.pathSeparator}build.dart',
          ),
        );
      }
    });
  });
}
