import 'package:path/path.dart' as path;

import 'ast/_core/interfaces/declaration.dart';

const defaultTempDirPrefix = 'swift2objc_temp_';
const symbolgraphFileSuffix = '.symbols.json';

class Command {
  final String executable;
  final List<String> args;

  Command({
    required this.executable,
    required this.args,
  });
}

/// Used to configure Swift2ObjC wrapper generation.
class Config {
  /// The input to generate a wrapper for.
  /// See `FilesInputConfig` and `ModuleInputConfig`;
  final InputConfig input;

  /// Specify where the wrapper swift file will be output.
  final Uri outputFile;

  /// Text inserted into the [outputFile] before the generated output.
  final String? preamble;

  /// Specify where to output the intermidiate files (i.g the symbolgraph json).
  /// If this is null, a teemp directory will be generated in the system temp
  /// directory (using `Directory.systemTemp`) and then deleted.
  /// Specifying a temp directory would prevent the tool from deleting the
  /// intermediate files after generating the wrapper.
  final Uri? tempDir;

  /// Filter function to filter APIs
  ///
  /// APIs can be filtered by name
  ///
  /// Includes all declarations by default
  final bool Function(Declaration declaration) include;

  static bool _defaultInclude(Declaration _) => true;

  const Config(
      {required this.input,
      required this.outputFile,
      this.tempDir,
      this.preamble,
      this.include = Config._defaultInclude});
}

/// Used to specify the inputs in the `config` object.
/// See `FilesInputConfig` and `ModuleInputConfig` for concrete implementation;
sealed class InputConfig {
  Command? get symbolgraphCommand;
}

/// Used to generate a objc wrapper for one or more swift files.
class FilesInputConfig implements InputConfig {
  /// The swift file(s) to generate a wrapper for.
  final List<Uri> files;

  /// The name of the module files generated by `swiftc in `tempDir`.
  final String generatedModuleName;

  FilesInputConfig({
    required this.files,
    this.generatedModuleName = 'symbolgraph_module',
  });

  @override
  Command? get symbolgraphCommand => Command(
        executable: 'swiftc',
        args: [
          ...files.map((uri) => path.absolute(uri.path)),
          '-emit-module',
          '-emit-symbol-graph',
          '-emit-symbol-graph-dir',
          '.',
          '-module-name',
          generatedModuleName
        ],
      );
}

/// Used to generate a objc wrapper for a built-in swift module.
/// (e.g, AVFoundation)
class ModuleInputConfig implements InputConfig {
  /// The swift module to generate a wrapper for.
  final String module;

  /// The target to generate code for.
  /// (e.g `x86_64-apple-ios17.0-simulator`)
  final String target;

  /// The sdk to compile against.
  /// (e.g `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sd`)
  final Uri sdk;

  ModuleInputConfig({
    required this.module,
    required this.target,
    required this.sdk,
  });

  @override
  Command? get symbolgraphCommand => Command(
        executable: 'swift',
        args: [
          'symbolgraph-extract',
          '-module-name',
          module,
          '-target',
          target,
          '-sdk',
          path.absolute(sdk.path),
          '-output-dir',
          '.',
        ],
      );
}

/// Used to generate wrappers directly from a JSON symbolgraph, for debugging.
class JsonFileInputConfig implements InputConfig {
  /// The JSON symbolgraph file.
  final Uri jsonFile;

  JsonFileInputConfig({required this.jsonFile});

  @override
  Command? get symbolgraphCommand => null;
}
