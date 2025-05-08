import 'dart:io';

import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  final buildConfig = await BuildInput.fromArgs(args).config;
  // Write a malformed JSON string.
  await File(buildConfig.outputFile.toFilePath()).writeAsString('{"assets": [');
}
