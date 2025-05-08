// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart' hide build, link;
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

      // First, run `pub get`, we need pub to resolve our dependencies.
      await runPubGet(workingDirectory: packageUri, logger: logger);

      final buildResultEither =
          await buildDataAssets(packageUri, linkingEnabled: true);
      expect(buildResultEither.isLeft, true,
          reason:
              "Expected build to succeed, but got Failure: ${buildResultEither.rightOrNull?.message}");
      final buildResult = buildResultEither.leftOrNull!;
      expect(buildResult.encodedAssets.length, 0);
      // No assets, so no allExist check needed here for buildResult.encodedAssets
      // but check encodedAssetsForLinking
      for (final encodedAssetsForLinking
          in buildResult.encodedAssetsForLinking.values) {
        expect(await encodedAssetsForLinking.allExist(), true);
      }


      final linkResultEither = await link(
        packageUri,
        logger,
        dartExecutable,
        buildResult: buildResult,
        buildAssetTypes: [BuildAssetType.data],
      );
      expect(linkResultEither.isLeft, true,
          reason:
              "Expected link to succeed, but got Failure: ${linkResultEither.rightOrNull?.message}");
      final linkResult = linkResultEither.leftOrNull!;
      expect(linkResult.encodedAssets.length, 2);
      expect(await linkResult.encodedAssets.allExist(), true);

      final buildNoLinkResultEither =
          await buildDataAssets(packageUri, linkingEnabled: false);
      expect(buildNoLinkResultEither.isLeft, true,
          reason:
              "Expected build (no link) to succeed, but got Failure: ${buildNoLinkResultEither.rightOrNull?.message}");
      final buildNoLinkResult = buildNoLinkResultEither.leftOrNull!;
      expect(buildNoLinkResult.encodedAssets.length, 4);
      expect(await buildNoLinkResult.encodedAssets.allExist(), true);
      for (final encodedAssetsForLinking
          in buildNoLinkResult.encodedAssetsForLinking.values) {
        expect(await encodedAssetsForLinking.allExist(), true);
      }
    });
  });

  test('complex_link linking', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      // From package:complex_link_helper.
      const builtHelperAssets = [
        'assets/data_helper_0.json',
        'assets/data_helper_1.json',
      ];
      const helperAssetsForLinking = [
        'assets/data_helper_2.json',
        'assets/data_helper_3.json',
      ];
      // From package:complex_link.
      const mainAssetsForLinking = ['assets/data_0.json', 'assets/data_1.json'];
      final encodedAssetsForLinking = [
        ...helperAssetsForLinking,
        ...mainAssetsForLinking,
      ];
      final linkedAssets = encodedAssetsForLinking.skip(1);

      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('complex_link/');

      // First, run `pub get`, we need pub to resolve our dependencies.
      await runPubGet(workingDirectory: packageUri, logger: logger);

      final buildResultEither = await buildDataAssets(
        packageUri,
        linkingEnabled: true,
      );
      expect(buildResultEither.isLeft, true,
          reason:
              "Expected build to succeed, but got Failure: ${buildResultEither.rightOrNull?.message}");
      final buildResult = buildResultEither.leftOrNull!;
      expect(await buildResult.encodedAssets.allExist(), true);
      for (final encodedAssetsForLinking
          in buildResult.encodedAssetsForLinking.values) {
        expect(await encodedAssetsForLinking.allExist(), true);
      }
      expect(
        _getNames(buildResult.encodedAssets),
        unorderedEquals(builtHelperAssets),
      );
      expect(
        _getNames(buildResult.encodedAssetsForLinking['complex_link']!),
        unorderedEquals(encodedAssetsForLinking),
      );

      final linkResultEither = await link(
        packageUri,
        logger,
        dartExecutable,
        buildResult: buildResult,
        buildAssetTypes: [BuildAssetType.data],
      );
      expect(linkResultEither.isLeft, true,
          reason:
              "Expected link to succeed, but got Failure: ${linkResultEither.rightOrNull?.message}");
      final linkResult = linkResultEither.leftOrNull!;
      expect(await linkResult.encodedAssets.allExist(), true);

      expect(
        _getNames(buildResult.encodedAssets),
        unorderedEquals(builtHelperAssets),
      );
      expect(
        _getNames(linkResult.encodedAssets),
        unorderedEquals(linkedAssets),
      );
    });
  });

  test('no_asset_for_link', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('no_asset_for_link/');

      // First, run `pub get`, we need pub to resolve our dependencies.
      await runPubGet(workingDirectory: packageUri, logger: logger);

      final buildResultEither =
          await buildDataAssets(packageUri, linkingEnabled: true);
      expect(buildResultEither.isLeft, true,
          reason:
              "Expected build to succeed, but got Failure: ${buildResultEither.rightOrNull?.message}");
      final buildResult = buildResultEither.leftOrNull!;
      expect(buildResult.encodedAssets.length, 0);
      // No assets, so no allExist check needed here for buildResult.encodedAssets
      expect(buildResult.encodedAssetsForLinking.length, 0);

      final logMessages = <String>[];
      final linkResultEither = await link(
        packageUri,
        logger,
        dartExecutable,
        buildResult: buildResult,
        capturedLogs: logMessages,
        buildAssetTypes: [BuildAssetType.data],
      );
      expect(linkResultEither.isLeft, true,
          reason:
              "Expected link to succeed, but got Failure: ${linkResultEither.rightOrNull?.message}");
      final linkResult = linkResultEither.leftOrNull!;
      expect(linkResult.encodedAssets.length, 0);
      // No assets, so no allExist check needed here for linkResult.encodedAssets
      expect(
        logMessages,
        contains(
          'Skipping link hooks from no_asset_for_link due to '
          'no assets provided to link for these link hooks.',
        ),
      );
    });
  });

  if (Platform.isMacOS || Platform.isWindows) {
    // https://github.com/dart-lang/native/issues/1376.
    return;
  }

  test('treeshaking assets using CLinker', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('treeshaking_native_libs/');

      // First, run `pub get`, we need pub to resolve our dependencies.
      await runPubGet(workingDirectory: packageUri, logger: logger);

      final buildResultEither = await build(
        packageUri,
        logger,
        dartExecutable,
        linkingEnabled: true,
        buildAssetTypes: [BuildAssetType.code],
      );
      expect(buildResultEither.isLeft, true,
          reason:
              "Expected build to succeed, but got Failure: ${buildResultEither.rightOrNull?.message}");
      final buildResult = buildResultEither.leftOrNull!;
      expect(buildResult.encodedAssets.length, 0);
      // No assets, so no allExist check needed here for buildResult.encodedAssets
      expect(buildResult.encodedAssetsForLinking.length, 1);
      for (final encodedAssetsForLinking
          in buildResult.encodedAssetsForLinking.values) {
        expect(await encodedAssetsForLinking.allExist(), true);
      }

      final logMessages = <String>[];
      final linkResultEither = await link(
        packageUri,
        logger,
        dartExecutable,
        buildResult: buildResult,
        capturedLogs: logMessages,
        buildAssetTypes: [BuildAssetType.code],
      );
      expect(linkResultEither.isLeft, true,
          reason:
              "Expected link to succeed, but got Failure: ${linkResultEither.rightOrNull?.message}");
      final linkResult = linkResultEither.leftOrNull!;
      expect(linkResult.encodedAssets.length, 1);
      expect(await linkResult.encodedAssets.allExist(), true);
      expect(linkResult.encodedAssets.first.isCodeAsset, isTrue);
    });
  });
}

Iterable<String> _getNames(List<EncodedAsset> assets) =>
    assets.where((e) => e.isDataAsset).map((e) => e.asDataAsset.name);
