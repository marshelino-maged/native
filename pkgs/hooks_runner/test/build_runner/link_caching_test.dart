// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:hooks_runner/hooks_runner.dart';
import 'package:hooks_runner/src/either.dart';
import 'package:hooks_runner/src/failure.dart';
import 'package:test/test.dart';

import '../helpers.dart';
import 'helpers.dart';

void main() async {
  const packageName = 'simple_link';

  test('link hook caching', () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('$packageName/');

      // First, run `pub get`, we need pub to resolve our dependencies.
      await runPubGet(workingDirectory: packageUri, logger: logger);

      final logMessages = <String>[];
      late BuildResult buildResult;
      late LinkResult linkResult;
      Future<void> runBuild() async {
        logMessages.clear();
        final buildResultEither = await buildDataAssets(
          packageUri,
          linkingEnabled: true,
          capturedLogs: logMessages,
        );
        expect(buildResultEither.isLeft, true,
            reason:
                "Expected build to succeed, but got Failure: ${buildResultEither.rightOrNull?.message}");
        buildResult = buildResultEither.leftOrNull!;
        expect(await buildResult.encodedAssets.allExist(), true);
        for (final encodedAssetsForLinking
            in buildResult.encodedAssetsForLinking.values) {
          expect(await encodedAssetsForLinking.allExist(), true);
        }
      }

      Future<void> runLink() async {
        logMessages.clear();
        final linkResultEither = await link(
          packageUri,
          logger,
          dartExecutable,
          buildResult: buildResult,
          buildAssetTypes: [BuildAssetType.data],
          capturedLogs: logMessages,
        );
        expect(linkResultEither.isLeft, true,
            reason:
                "Expected link to succeed, but got Failure: ${linkResultEither.rightOrNull?.message}");
        linkResult = linkResultEither.leftOrNull!;
        expect(await linkResult.encodedAssets.allExist(), true);
      }

      await runBuild();
      // expect(buildResult, isNotNull); // Already checked in runBuild
      expect(
        logMessages.join('\n'),
        stringContainsInOrder([
          'Running',
          'compile kernel',
          '$packageName${Platform.pathSeparator}hook'
              '${Platform.pathSeparator}build.dart',
          'Running',
          'hook.dill',
        ]),
      );

      await runLink();
      // expect(linkResult, isNotNull); // Already checked in runLink
      expect(
        logMessages.join('\n'),
        stringContainsInOrder([
          'Running',
          'compile kernel',
          '$packageName${Platform.pathSeparator}hook'
              '${Platform.pathSeparator}link.dart',
          'Running',
          'hook.dill',
        ]),
      );

      await runBuild();
      // expect(buildResult, isNotNull); // Already checked in runBuild
      expect(
        logMessages.join('\n'),
        contains('Skipping build for $packageName'),
      );

      await runLink();
      // expect(linkResult, isNotNull); // Already checked in runLink
      expect(
        logMessages.join('\n'),
        contains('Skipping link for $packageName'),
      );

      await copyTestProjects(
        sourceUri: testDataUri.resolve('simple_link_change_asset/'),
        targetUri: packageUri,
      );

      await runBuild();
      // expect(buildResult, isNotNull); // Already checked in runBuild
      expect(
        logMessages.join('\n'),
        stringContainsInOrder(['Running', 'hook.dill']),
      );

      await runLink();
      // expect(linkResult, isNotNull); // Already checked in runLink
      expect(
        logMessages.join('\n'),
        stringContainsInOrder(['Running', 'hook.dill']),
      );

      await runBuild();
      // expect(buildResult, isNotNull); // Already checked in runBuild
      expect(
        logMessages.join('\n'),
        contains('Skipping build for $packageName'),
      );

      await runLink();
      // expect(linkResult, isNotNull); // Already checked in runLink
      expect(
        logMessages.join('\n'),
        contains('Skipping link for $packageName'),
      );
    });
  });
}
