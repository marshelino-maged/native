// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:file/local.dart';
import 'package:hooks_runner/src/dependencies_hash_file/dependencies_hash_file.dart';
import 'package:test/test.dart';

import '../helpers.dart';

void main() async {
  final environment = Platform.environment;
  const fileSystem = LocalFileSystem();

  test('json format', () async {
    await inTempDir((tempUri) async {
      final hashes = FileSystemHashes(
        files: [FilesystemEntityHash(tempUri.resolve('foo.dll'), 1337)],
      );
      final hashes2 = FileSystemHashes.fromJson(hashes.toJson());
      expect(hashes.files.single.path, equals(hashes2.files.single.path));
      expect(hashes.files.single.hash, equals(hashes2.files.single.hash));
    });
  });

  test('dependencies hash file', () async {
    await inTempDir((tempUri) async {
      final tempFile = fileSystem.file(tempUri.resolve('foo.txt'));
      final tempSubDir = fileSystem.directory(tempUri.resolve('subdir/'));
      final subFile = fileSystem.file(tempSubDir.uri.resolve('bar.txt'));

      final hashesFileUri = tempUri.resolve('hashes.json');
      final hashes = DependenciesHashFile(fileSystem, fileUri: hashesFileUri);

      Future<void> reset() async {
        await tempFile.create(recursive: true);
        await tempSubDir.create(recursive: true);
        await subFile.create(recursive: true);
        await tempFile.writeAsString('hello');
        await subFile.writeAsString('world');

        await hashes.hashDependencies(
          [tempFile.uri, tempSubDir.uri],
          (await tempFile.lastModified()).add(const Duration(minutes: 1)),
          environment,
        );
      }

      await reset();

      // No changes
      expect(await hashes.findOutdatedDependency(environment), isNull);

      // Change file contents.
      await tempFile.writeAsString('asdf');
      expect(
        await hashes.findOutdatedDependency(environment),
        contains(tempFile.uri.toFilePath()),
      );
      await reset();

      // Delete file.
      await tempFile.delete();
      expect(
        await hashes.findOutdatedDependency(environment),
        contains(tempFile.uri.toFilePath()),
      );
      await reset();

      // Add file to tracked directory.
      final subFile2 = fileSystem.file(tempSubDir.uri.resolve('baz.txt'));
      await subFile2.create(recursive: true);
      await subFile2.writeAsString('hello');
      expect(
        await hashes.findOutdatedDependency(environment),
        contains(tempSubDir.uri.toFilePath()),
      );
      await reset();

      // Delete file from tracked directory.
      await subFile.delete();
      expect(
        await hashes.findOutdatedDependency(environment),
        contains(tempSubDir.uri.toFilePath()),
      );
      await reset();

      // Delete tracked directory.
      await tempSubDir.delete(recursive: true);
      expect(
        await hashes.findOutdatedDependency(environment),
        contains(tempSubDir.uri.toFilePath()),
      );
      await reset();

      // Add directory to tracked directory.
      final subDir2 = fileSystem.directory(tempSubDir.uri.resolve('baz/'));
      await subDir2.create(recursive: true);
      expect(
        await hashes.findOutdatedDependency(environment),
        contains(tempSubDir.uri.toFilePath()),
      );
      await reset();

      // Overwriting a file with identical contents.
      await tempFile.writeAsString('something something');
      await tempFile.writeAsString('hello');
      expect(await hashes.findOutdatedDependency(environment), isNull);
      await reset();

      // If a file is modified after the valid timestamp, it should be marked
      // as changed.
      await hashes.hashDependencies(
        [tempFile.uri],
        (await tempFile.lastModified()).subtract(const Duration(seconds: 1)),
        environment,
      );
      expect(
        await hashes.findOutdatedDependency(environment),
        contains(tempFile.uri.toFilePath()),
      );
    });
  });
}
