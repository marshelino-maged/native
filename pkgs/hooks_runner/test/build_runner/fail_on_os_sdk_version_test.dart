// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:code_assets/code_assets.dart';
import 'package:hooks_runner/src/either.dart';
import 'package:hooks_runner/src/failure.dart';
import 'package:hooks_runner/src/model/build_result.dart';
import 'package:hooks_runner/src/model/link_result.dart';
import 'package:hooks_runner/src/model/target.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../helpers.dart';
import 'helpers.dart';

const Timeout longTimeout = Timeout(Duration(minutes: 5));

// Simulate needing some version of the API.
const minNdkApiVersionForThisPackage = 28;
const minIosVersionForThisPackage = 16;
const minMacOSVersionForThisPackage = 13;

final List<(Target, List<(int sdkVersion, bool success)>)> osInput = [
  (
    Target.androidArm64,
    [
      (minNdkApiVersionForThisPackage, true),
      (minNdkApiVersionForThisPackage - 1, false),
    ],
  ),
  if (OS.current == OS.macOS) ...[
    (
      Target.macOSArm64,
      [
        (minMacOSVersionForThisPackage, true),
        (minMacOSVersionForThisPackage - 1, false),
      ],
    ),
    (
      Target.iOSArm64,
      [
        (minIosVersionForThisPackage, true),
        (minIosVersionForThisPackage - 1, false),
      ],
    ),
  ],
];

final List<(String hook, String testPath)> hooks = [
  ('build', 'fail_on_os_sdk_version/'),
  ('link', 'fail_on_os_sdk_version_link/'),
];

void main() async {
  for (final (target, versions) in osInput) {
    for (final (version, success) in versions) {
      final statusString = success ? 'succeed' : 'fail';
      for (final (hook, packagePath) in hooks) {
        test(
          '$statusString $hook for $target sdk version',
          timeout: longTimeout,
          () async {
            await inTempDir((tempUri) async {
              await copyTestProjects(targetUri: tempUri);
              final packageUri = tempUri.resolve(packagePath);

              await runPubGet(workingDirectory: packageUri, logger: logger);

              {
                final logMessages = <String>[];
                final resultEither = await buildAndLink(
                  target: target,
                  targetIOSSdk: (target.os == OS.iOS) ? IOSSdk.iPhoneOS : null,
                  targetIOSVersion: (target.os == OS.iOS) ? version : null,
                  targetMacOSVersion: (target.os == OS.macOS) ? version : null,
                  targetAndroidNdkApi:
                      (target.os == OS.android) ? version : null,
                  packageUri,
                  createCapturingLogger(logMessages, level: Level.SEVERE),
                  dartExecutable,
                  buildAssetTypes: [BuildAssetType.code, BuildAssetType.data],
                );
                final fullLog = logMessages.join('\n');

                if (success) {
                  expect(resultEither.isLeft, true,
                      reason:
                          "Expected buildAndLink to succeed, but got Failure: ${resultEither.rightOrNull?.message}");
                  final (buildResult, linkResult) = resultEither.leftOrNull!;
                  expect(await buildResult.encodedAssets.allExist(), true);
                  for (final encodedAssetsForLinking
                      in buildResult.encodedAssetsForLinking.values) {
                    expect(await encodedAssetsForLinking.allExist(), true);
                  }
                  expect(await linkResult.encodedAssets.allExist(), true);
                } else {
                  expect(resultEither.isRight, true,
                      reason: "Expected buildAndLink to fail, but it succeeded.");
                  final failure = resultEither.rightOrNull!;
                  // Depending on whether the failure occurs in build or link,
                  // the exact FailureType might vary.
                  // For this test, the message is more important.
                  expect(
                    fullLog,
                    contains(
                      'The native assets for this package require at least',
                    ),
                  );
                  expect(
                      failure.message,
                      contains(
                          'The native assets for this package require at least'));
                }
              }
            });
          },
        );
      }
    }
  }
}
