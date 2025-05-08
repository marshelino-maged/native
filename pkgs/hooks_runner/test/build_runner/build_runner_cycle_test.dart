// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:hooks_runner/src/either.dart';
import 'package:hooks_runner/src/failure.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../helpers.dart';
import 'helpers.dart';

const Timeout longTimeout = Timeout(Duration(minutes: 5));

void main() async {
  test('cycle', timeout: longTimeout, () async {
    await inTempDir((tempUri) async {
      await copyTestProjects(targetUri: tempUri);
      final packageUri = tempUri.resolve('cyclic_package_1/');

      await runPubGet(workingDirectory: packageUri, logger: logger);

      {
        final logMessages = <String>[];
        final resultEither = await build(
          packageUri,
          createCapturingLogger(logMessages, level: Level.SEVERE),
          dartExecutable,
          buildAssetTypes: [],
        );
        final fullLog = logMessages.join('\n');
        expect(resultEither.isRight, true,
            reason: "Expected build to fail, but it succeeded.");
        final failure = resultEither.rightOrNull!;
        expect(failure.type, FailureType.BuildFailed); // Or a more specific type if applicable
        expect(
          fullLog,
          contains(
            'Cyclic dependency for native asset builds in the following '
            'packages: [cyclic_package_1, cyclic_package_2]',
          ),
        );
        expect(
            failure.message,
            contains(
                'Cyclic dependency for native asset builds in the following packages: [cyclic_package_1, cyclic_package_2]'));
      }
    });
  });
}
