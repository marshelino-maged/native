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
  test('dart_app build dependencies', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('dart_app/');

      // First, run `pub get`, we need pub to resolve our dependencies.
      await runPubGet(workingDirectory: packageUri, logger: logger);

      // Trigger a build, should invoke build for libraries with native assets.
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
          stringContainsInOrder([
            'native_add${Platform.pathSeparator}hook'
                '${Platform.pathSeparator}build.dart',
            'native_subtract${Platform.pathSeparator}hook'
                '${Platform.pathSeparator}build.dart',
          ]),
        );
        expect(result.encodedAssets.length, 2);
        expect(await result.encodedAssets.allExist(), true);
        for (final encodedAssetsForLinking
            in result.encodedAssetsForLinking.values) {
          expect(await encodedAssetsForLinking.allExist(), true);
        }
        expect(
          result.dependencies,
          containsAll([
            tempUri.resolve('native_add/src/native_add.c'),
            tempUri.resolve('native_subtract/src/native_subtract.c'),
            if (!Platform.isWindows) ...[
              tempUri.resolve('native_add/hook/build.dart'),
              tempUri.resolve('native_subtract/hook/build.dart'),
            ],
          ]),
        );
        if (Platform.isWindows) {
          expect(
            // https://github.com/dart-lang/sdk/issues/59657
            // Deps file on windows sometimes have lowercase drive letters.
            // File.exists will work, but Uri equality doesn't.
            result.dependencies.map(
              (e) => Uri.file(e.toFilePath().toLowerCase()),
            ),
            containsAll(
              [
                tempUri.resolve('native_add/hook/build.dart'),
                tempUri.resolve('native_subtract/hook/build.dart'),
              ].map((e) => Uri.file(e.toFilePath().toLowerCase())),
            ),
          );
        }
      }
    });
  });
}
