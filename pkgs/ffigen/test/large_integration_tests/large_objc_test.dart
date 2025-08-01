// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Objective C support is only available on mac.
@TestOn('mac-os')
// This is a slow test.
@Timeout(Duration(minutes: 5))
library;

import 'dart:async';
import 'dart:io';

import 'package:ffigen/ffigen.dart';
import 'package:ffigen/src/code_generator/utils.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

Future<int> run(String exe, List<String> args) async {
  final process = await Process.start(
    exe,
    args,
    mode: ProcessStartMode.inheritStdio,
  );
  return await process.exitCode;
}

void main() {
  test('Large ObjC integration test', () async {
    // Reducing the bindings to a random subset so that the test completes in a
    // reasonable amount of time.
    // TODO(https://github.com/dart-lang/sdk/issues/56247): Remove this.
    const inclusionRatio = 0.1;
    const seed = 1234;
    bool randInclude(String kind, Declaration clazz, [String? method]) =>
        fnvHash32('$seed.$kind.${clazz.usr}.$method') <
        ((1 << 32) * inclusionRatio);
    DeclarationFilters randomFilter(String kind) => DeclarationFilters(
      shouldInclude: (Declaration clazz) => randInclude(kind, clazz),
      shouldIncludeMember: (Declaration clazz, String method) =>
          randInclude('$kind.memb', clazz, method),
    );

    final outFile = path.join(
      packagePathForTests,
      'test',
      'large_integration_tests',
      'large_objc_bindings.dart',
    );
    final outObjCFile = path.join(
      packagePathForTests,
      'test',
      'large_integration_tests',
      'large_objc_bindings.m',
    );
    final config = FfiGen(
      Logger.root,
      wrapperName: 'LargeObjCLibrary',
      language: Language.objc,
      output: Uri.file(outFile),
      outputObjC: Uri.file(outObjCFile),
      entryPoints: [
        Uri.file(
          path.join(
            packagePathForTests,
            'test',
            'large_integration_tests',
            'large_objc_test.h',
          ),
        ),
      ],
      formatOutput: false,
      includeTransitiveObjCInterfaces: false,
      includeTransitiveObjCProtocols: false,
      includeTransitiveObjCCategories: false,
      functionDecl: randomFilter('functionDecl'),
      structDecl: randomFilter('structDecl'),
      unionDecl: randomFilter('unionDecl'),
      enumClassDecl: randomFilter('enumClassDecl'),
      unnamedEnumConstants: randomFilter('unnamedEnumConstants'),
      globals: randomFilter('globals'),
      typedefs: randomFilter('typedefs'),
      objcInterfaces: randomFilter('objcInterfaces'),
      objcProtocols: randomFilter('objcProtocols'),
      objcCategories: randomFilter('objcCategories'),
      externalVersions: ExternalVersions(
        ios: Versions(min: Version(12, 0, 0)),
        macos: Versions(min: Version(10, 14, 0)),
      ),
      preamble: '''
// ignore_for_file: camel_case_types
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: unnecessary_non_null_assertion
// ignore_for_file: unused_element
// ignore_for_file: unused_field
''',
    );

    final timer = Stopwatch()..start();
    config.generate(Logger.root..level = Level.SEVERE);
    expect(File(outFile).existsSync(), isTrue);
    expect(File(outObjCFile).existsSync(), isTrue);

    print('\n\t\tFfigen generation: ${timer.elapsed}\n');
    timer.reset();

    // Verify Dart bindings pass analysis.
    expect(await run('dart', ['analyze', outFile]), 0);

    print('\n\t\tAnalyze dart: ${timer.elapsed}\n');
    timer.reset();

    // Verify ObjC bindings compile.
    expect(
      await run('clang', [
        '-x',
        'objective-c',
        outObjCFile,
        '-fpic',
        '-fobjc-arc',
        '-shared',
        '-framework',
        'Foundation',
        '-o',
        '/dev/null',
      ]),
      0,
    );

    print('\n\t\tCompile ObjC: ${timer.elapsed}\n');
    timer.reset();
  });
}
