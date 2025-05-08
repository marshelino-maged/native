// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:hooks_runner/src/either.dart';
import 'package:hooks_runner/src/failure.dart';
import 'package:hooks_runner/src/model/build_result.dart';
import 'package:hooks_runner/src/model/link_result.dart';
import 'package:test/test.dart';

import '../helpers.dart';
import 'helpers.dart';

const Timeout longTimeout = Timeout(Duration(minutes: 5));

void main() async {
  test('simple_link linking', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('simple_link/');

      final resourcesUri = tempUri.resolve('treeshaking_info.json');
      await File.fromUri(resourcesUri).create();

      // First, run `pub get`, we need pub to resolve our dependencies.
      await runPubGet(workingDirectory: packageUri, logger: logger);

      final buildResultEither =
          await buildDataAssets(packageUri, linkingEnabled: true);
      expect(buildResultEither.isLeft, true,
          reason:
              "Expected build to succeed, but got Failure: ${buildResultEither.rightOrNull?.message}");
      final buildResult = buildResultEither.leftOrNull!;
      // Since linkingEnabled is true, buildResult itself might not have many direct assets,
      // but encodedAssetsForLinking should exist if the hook produced them.
      // However, simple_link's build hook doesn't output assets when linkingEnabled.
      // So, checking allExist on buildResult.encodedAssets is fine.
      expect(await buildResult.encodedAssets.allExist(), true);
      for (final encodedAssetsForLinking
          in buildResult.encodedAssetsForLinking.values) {
        expect(await encodedAssetsForLinking.allExist(), true);
      }

      Iterable<String> buildFiles() => Directory.fromUri(
        packageUri.resolve('.dart_tool/hooks_runner/'),
      ).listSync(recursive: true).map((file) => file.path);

      expect(buildFiles(), isNot(anyElement(endsWith('resources.json'))));

      final linkResultEither = await link(
        packageUri,
        logger,
        dartExecutable,
        buildResult: buildResult,
        resourceIdentifiers: resourcesUri,
        buildAssetTypes: [BuildAssetType.data],
      );
      expect(linkResultEither.isLeft, true,
          reason:
              "Expected link to succeed, but got Failure: ${linkResultEither.rightOrNull?.message}");
      final linkResult = linkResultEither.leftOrNull!;
      expect(await linkResult.encodedAssets.allExist(), true);

      expect(buildFiles(), anyElement(endsWith('resources.json')));
    });
  });
}
