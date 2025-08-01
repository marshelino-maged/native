// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:ffigen/ffigen.dart';
import 'package:ffigen/src/strings.dart' as strings;
import 'package:file/local.dart';
import 'package:glob/glob.dart';
import 'package:json_schema/json_schema.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../test_utils.dart';

void main() {
  group('json_schema_test', () {
    final schema = YamlConfig.getsRootConfigSpec(
      Logger.root,
    ).generateJsonSchema(strings.ffigenJsonSchemaId);

    test('Schema Changes', () {
      final actualJsonSchema =
          const JsonEncoder.withIndent(strings.ffigenJsonSchemaIndent).convert(
            YamlConfig.getsRootConfigSpec(
              Logger.root,
            ).generateJsonSchema(strings.ffigenJsonSchemaId),
          );
      final expectedJsonSchema = File(
        path.join(packagePathForTests, strings.ffigenJsonSchemaFileName),
      ).readAsStringSync().replaceAll('\r\n', '\n');
      expect(actualJsonSchema, expectedJsonSchema);
    });

    final jsonSchema = JsonSchema.create(schema);
    test('Valid json schema', () {
      expect(jsonSchema, isNot(null));
    });

    // Find all ffigen config files in the repo.
    final configYamlGlob = Glob('**config.yaml');
    final configYamlFiles = configYamlGlob.listFileSystemSync(
      const LocalFileSystem(),
      root: packagePathForTests,
    );
    test('$configYamlGlob files not empty', () {
      expect(configYamlFiles.isNotEmpty, true);
    });

    final sharedBindingsConfigYamlGlob = Glob(
      'example/shared_bindings/ffigen_configs/**.yaml',
    );
    final sharedBindingsConfigYamlFiles = sharedBindingsConfigYamlGlob
        .listFileSystemSync(const LocalFileSystem(), root: packagePathForTests);
    test('$sharedBindingsConfigYamlGlob files not emty', () {
      expect(sharedBindingsConfigYamlFiles.isNotEmpty, true);
    });

    final allConfigFiles = configYamlFiles + sharedBindingsConfigYamlFiles;

    for (final fe in allConfigFiles) {
      test('validate config file: ${fe.path}', () {
        final yamlDoc = loadYaml(File(fe.absolute.path).readAsStringSync());
        final validationResult = jsonSchema.validate(yamlDoc);
        expect(
          validationResult.errors.isEmpty,
          true,
          reason: 'Schema Errors: ${validationResult.errors}',
        );
        expect(
          validationResult.warnings.isEmpty,
          true,
          reason: 'Schema Warnings: ${validationResult.errors}',
        );
      });
    }

    test('Bare minimal input', () {
      expect(
        jsonSchema
            .validate({
              'output': 'abcd.dart',
              'headers': {
                'entry-points': ['a.h'],
              },
            })
            .errors
            .isEmpty,
        true,
      );
    });
    test('Fail input', () {
      expect(jsonSchema.validate(null).errors.isNotEmpty, true);
      expect(jsonSchema.validate({'a': 1}).errors.isNotEmpty, true);
      expect(
        jsonSchema.validate({'output': 'abcd.dart'}).errors.isNotEmpty,
        true,
      );
    });
  });
}
