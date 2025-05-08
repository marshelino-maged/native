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
  for (final package in [
    'wrong_build_output',
    'wrong_build_output_2',
    'wrong_build_output_3',
  ]) {
    test('wrong build output $package', timeout: longTimeout, () async {
      await inTempDir((tempUri) async {
        await copyTestProjects(targetUri: tempUri);
        final packageUri = tempUri.resolve('$package/');

        await runPubGet(workingDirectory: packageUri, logger: logger);

        // Run twice, failures should not be cached and return the same errors.
        for (final _ in [1, 2]) {
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

          if (package == 'wrong_build_output_3') {
            // Should re-execute the process on second run.
            expect(fullLog, contains('build.dart returned with exit code: 1.'));
            expect(failure.type, FailureType.ProcessExecutionFailed);
            expect(failure.message,
                contains('Hook execution failed with exit code 1'));
          } else {
            expect(fullLog, contains('output.json contained a format error.'));
            expect(failure.type, FailureType.FileOperationFailed);
            expect(failure.message,
                contains('Failed to read hook output: format error'));
          }
        }
      });
    });
  }
}
