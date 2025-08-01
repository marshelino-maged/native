// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Objective C support is only available on mac.
@TestOn('mac-os')
library;

import 'package:ffigen/src/header_parser.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('objective_c_example_test', () {
    setUpAll(() {
      logWarnings(Level.SEVERE);
    });

    test('objective_c', () {
      final config = testConfigFromPath(
        path.join(packagePathForTests, 'example', 'objective_c', 'config.yaml'),
      );
      final output = parse(testContext(config)).generate();

      // Verify that the output contains all the methods and classes that the
      // example app uses.
      expect(output, contains('class AVAudioPlayer extends objc.NSObject {'));
      expect(
        output,
        contains(
          'AVAudioPlayer? initWithContentsOfURL(objc.NSURL url, '
          '{required ffi.Pointer<ffi.Pointer<objc.ObjCObject>> error}) {',
        ),
      );
      expect(output, contains('double get duration {'));
      expect(output, contains('bool play() {'));
    });
  });
}
