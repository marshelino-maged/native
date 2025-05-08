// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:code_assets/code_assets.dart';
import 'package:hooks_runner/src/either.dart';
import 'package:hooks_runner/src/failure.dart';
import 'package:hooks_runner/src/model/build_result.dart';
import 'package:test/test.dart';

import '../helpers.dart';
import 'helpers.dart';

const Timeout longTimeout = Timeout(Duration(minutes: 5));

void main() async {
  test('link mode preference', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('native_add/');

      // First, run `pub get`, we need pub to resolve our dependencies.
      await runPubGet(workingDirectory: packageUri, logger: logger);

      final resultDynamicEither = await build(
        packageUri,
        logger,
        dartExecutable,
        linkModePreference: LinkModePreference.dynamic,
        buildAssetTypes: [BuildAssetType.code],
      );
      expect(resultDynamicEither.isLeft, true,
          reason:
              "Expected build (dynamic) to succeed, but got Failure: ${resultDynamicEither.rightOrNull?.message}");
      final resultDynamic = resultDynamicEither.leftOrNull!;
      expect(await resultDynamic.encodedAssets.allExist(), true);
      for (final encodedAssetsForLinking
          in resultDynamic.encodedAssetsForLinking.values) {
        expect(await encodedAssetsForLinking.allExist(), true);
      }

      final resultPreferDynamicEither = await build(
        packageUri,
        logger,
        dartExecutable,
        linkModePreference: LinkModePreference.preferDynamic,
        buildAssetTypes: [BuildAssetType.code],
      );
      expect(resultPreferDynamicEither.isLeft, true,
          reason:
              "Expected build (preferDynamic) to succeed, but got Failure: ${resultPreferDynamicEither.rightOrNull?.message}");
      final resultPreferDynamic = resultPreferDynamicEither.leftOrNull!;
      expect(await resultPreferDynamic.encodedAssets.allExist(), true);
      for (final encodedAssetsForLinking
          in resultPreferDynamic.encodedAssetsForLinking.values) {
        expect(await encodedAssetsForLinking.allExist(), true);
      }

      final resultStaticEither = await build(
        packageUri,
        logger,
        dartExecutable,
        linkModePreference: LinkModePreference.static,
        buildAssetTypes: [BuildAssetType.code],
      );
      expect(resultStaticEither.isLeft, true,
          reason:
              "Expected build (static) to succeed, but got Failure: ${resultStaticEither.rightOrNull?.message}");
      final resultStatic = resultStaticEither.leftOrNull!;
      expect(await resultStatic.encodedAssets.allExist(), true);
      for (final encodedAssetsForLinking
          in resultStatic.encodedAssetsForLinking.values) {
        expect(await encodedAssetsForLinking.allExist(), true);
      }

      final resultPreferStaticEither = await build(
        packageUri,
        logger,
        dartExecutable,
        linkModePreference: LinkModePreference.preferStatic,
        buildAssetTypes: [BuildAssetType.code],
      );
      expect(resultPreferStaticEither.isLeft, true,
          reason:
              "Expected build (preferStatic) to succeed, but got Failure: ${resultPreferStaticEither.rightOrNull?.message}");
      final resultPreferStatic = resultPreferStaticEither.leftOrNull!;
      expect(await resultPreferStatic.encodedAssets.allExist(), true);
      for (final encodedAssetsForLinking
          in resultPreferStatic.encodedAssetsForLinking.values) {
        expect(await encodedAssetsForLinking.allExist(), true);
      }

      // This package honors preferences.
      expect(
        CodeAsset.fromEncoded(resultDynamic.encodedAssets.single).linkMode,
        DynamicLoadingBundled(),
      );
      expect(
        CodeAsset.fromEncoded(
          resultPreferDynamic.encodedAssets.single,
        ).linkMode,
        DynamicLoadingBundled(),
      );
      expect(
        CodeAsset.fromEncoded(resultStatic.encodedAssets.single).linkMode,
        StaticLinking(),
      );
      expect(
        CodeAsset.fromEncoded(resultPreferStatic.encodedAssets.single).linkMode,
        StaticLinking(),
      );
    });
  });
}
