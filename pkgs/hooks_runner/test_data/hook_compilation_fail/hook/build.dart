// This file has intentional syntax errors.
import 'dart:io';

import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  final buildConfig = await BuildInput.fromArgs(args).config;
  ThisIsNotValidDartCode; // Syntax Error
  final buildOutput = BuildOutput(
    assets: [],
    dependencies: Dependencies([]),
  );
  await buildOutput.writeToFile(buildConfig.outputFile);
}
