import 'dart:convert';
import 'dart:io';

import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  final linkConfig = await LinkInput.fromArgs(args).config;
  final linkOutput = LinkOutput(
    // Missing assets, dependencies, metadata which are required.
  );
  await linkOutput.writeToFile(linkConfig.outputFile);
}
