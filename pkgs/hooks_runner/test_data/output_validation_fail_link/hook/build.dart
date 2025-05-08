import 'dart:io';

import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  final buildConfig = await BuildInput.fromArgs(args).config;
  final buildOutput = BuildOutput(
    assets: [
      Asset(
        name: 'some_asset_for_linking.txt',
        path: AssetPath(AssetPathType.source, 'assets/some_asset_for_linking.txt'),
        targetTypes: [TargetType.androidArm64], // Example target
      )
    ],
    dependencies: Dependencies([]),
  );

  // Create a dummy asset file
  final assetsDir = File(buildConfig.packageRoot.resolve('assets/some_asset_for_linking.txt').toFilePath());
  await assetsDir.parent.create(recursive: true);
  await assetsDir.writeAsString('dummy content');

  await buildOutput.writeToFile(buildConfig.outputFile);
}
