// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../helpers.dart';
import 'helpers.dart';

const Timeout longTimeout = Timeout(Duration(minutes: 5));

void main() async {
  test(
    'simple_link linking',
    timeout: longTimeout,
    skip: 'Until https://dart-review.googlesource.com/c/sdk/+/338380 is merged',
    () async {
      await inTempDir((tempUri) async {
        await copyTestProjects(targetUri: tempUri);
        final packageUri = tempUri.resolve('simple_link/');

        // First, run `pub get`, we need pub to resolve our dependencies.
        await runPubGet(
          workingDirectory: packageUri,
          logger: logger,
        );

        // Trigger a build, should invoke build for libraries with native assets.
        {
          final logMessages = <String>[];
          final buildResult = await build(
            packageUri,
            logger,
            dartExecutable,
            capturedLogs: logMessages,
            copyAssets: false,
          );
          const buildAssets = 10;
          expect(buildResult.assets.length, buildAssets);

          final linkResult = await link(
            packageUri,
            logger,
            dartExecutable,
            capturedLogs: logMessages,
          );
          const assetsForOtherLinker = 6;
          const inputForLinker = buildAssets - assetsForOtherLinker;
          const skippedAssets = 2;
          const linkedAssets = inputForLinker - skippedAssets;
          expect(linkResult.assets.length, linkedAssets);
        }
      });
    },
  );
}