import 'dart:convert';
import 'dart:io';

import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  final buildConfig = await BuildInput.fromArgs(args).config;
  final buildOutput = BuildOutput(
    // Missing assets, dependencies, metadata which are required.
  );
  await buildOutput.writeToFile(buildConfig.outputFile);
}
