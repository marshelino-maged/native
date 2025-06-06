// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:file/local.dart';
import 'package:hooks_runner/src/locking/locking.dart';

void main(List<String> args) async {
  const fileSystem = LocalFileSystem();
  final directory = fileSystem.directory(Uri.directory(args[0]));
  Duration? timeout;
  if (args.length >= 2) {
    timeout = Duration(milliseconds: int.parse(args[1]));
  }

  print('locking directory');
  await runUnderDirectoryLock<void>(
    fileSystem,
    directory.uri,
    timeout: timeout,
    () async {
      print('directory locked');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      print('hello world!');
    },
  );
  print('directory released');
}
