// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:file/local.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:quiver/pattern.dart' as quiver;
import 'package:yaml/yaml.dart';

import '../code_generator.dart';
import '../code_generator/unique_namer.dart';
import '../header_parser/type_extractor/cxtypekindmap.dart';
import '../strings.dart' as strings;
import 'config_types.dart';
import 'utils.dart';

Map<String, LibraryImport> libraryImportsExtractor(
  Map<String, String>? typeMap,
) {
  final resultMap = <String, LibraryImport>{};
  if (typeMap != null) {
    for (final kv in typeMap.entries) {
      resultMap[kv.key] = LibraryImport(kv.key, kv.value);
    }
  }
  return resultMap;
}

void loadImportedTypes(
  YamlMap fileConfig,
  Map<String, ImportedType> usrTypeMappings,
  LibraryImport libraryImport,
) {
  final symbols = fileConfig['symbols'] as YamlMap;
  for (final key in symbols.keys) {
    final usr = key as String;
    final value = symbols[usr]! as YamlMap;
    final name = value[strings.name] as String;
    final dartName = (value[strings.dartName] as String?) ?? name;
    usrTypeMappings[usr] = ImportedType(
      libraryImport,
      name,
      dartName,
      name,
      importedDartType: true,
    );
  }
}

YamlMap loadSymbolFile(
  String symbolFilePath,
  String? configFileName,
  PackageConfig? packageConfig,
) {
  final path = symbolFilePath.startsWith('package:')
      ? packageConfig!.resolve(Uri.parse(symbolFilePath))!.toFilePath()
      : normalizePath(symbolFilePath, configFileName);

  return loadYaml(File(path).readAsStringSync()) as YamlMap;
}

Map<String, ImportedType> symbolFileImportExtractor(
  Logger logger,
  List<String> yamlConfig,
  Map<String, LibraryImport> libraryImports,
  String? configFileName,
  PackageConfig? packageConfig,
) {
  final resultMap = <String, ImportedType>{};
  for (final item in yamlConfig) {
    String symbolFilePath;
    symbolFilePath = item;
    final symbolFile = loadSymbolFile(
      symbolFilePath,
      configFileName,
      packageConfig,
    );
    final formatVersion = symbolFile[strings.formatVersion] as String;
    if (formatVersion.split('.')[0] !=
        strings.symbolFileFormatVersion.split('.')[0]) {
      logger.severe(
        'Incompatible format versions for file $symbolFilePath: '
        '${strings.symbolFileFormatVersion}(ours), $formatVersion(theirs).',
      );
      exit(1);
    }
    final uniqueNamer = UniqueNamer()
      ..markAllUsed(libraryImports.keys)
      ..markUsed(strings.defaultSymbolFileImportPrefix);
    final files = symbolFile[strings.files] as YamlMap;
    for (final file in files.keys) {
      final existingImports = libraryImports.values.where(
        (element) => element.importPath(false) == file,
      );
      if (existingImports.isEmpty) {
        final name = uniqueNamer.makeUnique(
          strings.defaultSymbolFileImportPrefix,
        );
        libraryImports[name] = LibraryImport(name, file as String);
      }
      final libraryImport = libraryImports.values.firstWhere(
        (element) => element.importPath(false) == file,
      );
      loadImportedTypes(files[file] as YamlMap, resultMap, libraryImport);
    }
  }
  return resultMap;
}

Map<String, List<String>> typeMapExtractor(Map<dynamic, dynamic>? yamlConfig) {
  // Key - type_name, Value - [lib, cType, dartType].
  final resultMap = <String, List<String>>{};
  final typeMap = yamlConfig;
  if (typeMap != null) {
    for (final typeName in typeMap.keys) {
      final typeConfigItem = typeMap[typeName] as Map;
      resultMap[typeName as String] = [
        typeConfigItem[strings.lib] as String,
        typeConfigItem[strings.cType] as String,
        typeConfigItem[strings.dartType] as String,
      ];
    }
  }
  return resultMap;
}

Map<String, ImportedType> makeImportTypeMapping(
  Map<String, List<String>> rawTypeMappings,
  Map<String, LibraryImport> libraryImportsMap,
) {
  final typeMappings = <String, ImportedType>{};
  for (final key in rawTypeMappings.keys) {
    final lib = rawTypeMappings[key]![0];
    final cType = rawTypeMappings[key]![1];
    final dartType = rawTypeMappings[key]![2];
    final nativeType = key;
    if (strings.predefinedLibraryImports.containsKey(lib)) {
      typeMappings[key] = ImportedType(
        strings.predefinedLibraryImports[lib]!,
        cType,
        dartType,
        nativeType,
      );
    } else if (libraryImportsMap.containsKey(lib)) {
      typeMappings[key] = ImportedType(
        libraryImportsMap[lib]!,
        cType,
        dartType,
        nativeType,
      );
    } else {
      throw Exception('Please declare $lib under library-imports.');
    }
  }
  return typeMappings;
}

Type makePointerToType(Type type, int pointerCount) {
  for (var i = 0; i < pointerCount; i++) {
    type = PointerType(type);
  }
  return type;
}

String makePostfixFromRawVarArgType(List<String> rawVarArgType) {
  return rawVarArgType
      .map(
        (e) => e
            .replaceAll('*', 'Ptr')
            .replaceAll(RegExp(r'_t$'), '')
            .replaceAll(' ', '')
            .replaceAll(RegExp('[^A-Za-z0-9_]'), ''),
      )
      .map((e) => e.length > 1 ? '${e[0].toUpperCase()}${e.substring(1)}' : e)
      .join('');
}

Type makeTypeFromRawVarArgType(
  String rawVarArgType,
  Map<String, LibraryImport> libraryImportsMap,
) {
  Type baseType;
  var rawBaseType = rawVarArgType.trim();
  // Split the raw type based on pointer usage. E.g -
  // int => [int]
  // char* => [char,*]
  // ffi.Hello ** => [ffi.Hello,**]
  final typeStringRegexp = RegExp(r'([a-zA-Z0-9_\s\.]+)(\**)$');
  if (!typeStringRegexp.hasMatch(rawBaseType)) {
    throw Exception('Cannot parse variadic argument type - $rawVarArgType.');
  }
  final regExpMatch = typeStringRegexp.firstMatch(rawBaseType)!;
  final groups = regExpMatch.groups([1, 2]);
  rawBaseType = groups[0]!;
  // Handle basic supported types.
  if (cxTypeKindToImportedTypes.containsKey(rawBaseType)) {
    baseType = cxTypeKindToImportedTypes[rawBaseType]!;
  } else if (supportedTypedefToImportedType.containsKey(rawBaseType)) {
    baseType = supportedTypedefToImportedType[rawBaseType]!;
  } else if (suportedTypedefToSuportedNativeType.containsKey(rawBaseType)) {
    baseType = NativeType(suportedTypedefToSuportedNativeType[rawBaseType]!);
  } else {
    // Use library import if specified (E.g - ffi.UintPtr or custom.MyStruct)
    final rawVarArgTypeSplit = rawBaseType.split('.');
    if (rawVarArgTypeSplit.length == 1) {
      final typeName = rawVarArgTypeSplit[0].replaceAll(' ', '');
      baseType = SelfImportedType(typeName, typeName);
    } else if (rawVarArgTypeSplit.length == 2) {
      final lib = rawVarArgTypeSplit[0];
      final libraryImport =
          strings.predefinedLibraryImports[lib] ??
          libraryImportsMap[rawVarArgTypeSplit[0]];
      if (libraryImport == null) {
        throw Exception('Please declare $lib in library-imports.');
      }
      final typeName = rawVarArgTypeSplit[1].replaceAll(' ', '');
      baseType = ImportedType(libraryImport, typeName, typeName, typeName);
    } else {
      throw Exception(
        'Invalid type $rawVarArgType : Expected 0 or 1 .(dot) separators.',
      );
    }
  }

  // Handle pointers
  final pointerCount = groups[1]!.length;
  return makePointerToType(baseType, pointerCount);
}

Map<String, List<VarArgFunction>> makeVarArgFunctionsMapping(
  Map<String, List<RawVarArgFunction>> rawVarArgMappings,
  Map<String, LibraryImport> libraryImportsMap,
) {
  final mappings = <String, List<VarArgFunction>>{};
  for (final key in rawVarArgMappings.keys) {
    final varArgList = <VarArgFunction>[];
    for (final rawVarArg in rawVarArgMappings[key]!) {
      var postfix = rawVarArg.postfix ?? '';
      final types = <Type>[];
      for (final rva in rawVarArg.rawTypeStrings) {
        types.add(makeTypeFromRawVarArgType(rva, libraryImportsMap));
      }
      if (postfix.isEmpty) {
        if (rawVarArgMappings[key]!.length == 1) {
          postfix = '';
        } else {
          postfix = makePostfixFromRawVarArgType(rawVarArg.rawTypeStrings);
        }
      }
      // Extract postfix from config and/or deduce from var names.
      varArgList.add(VarArgFunction(postfix, types));
    }
    mappings[key] = varArgList;
  }
  return mappings;
}

final _quoteMatcher = RegExp(r'''^["'](.*)["']$''', dotAll: true);
final _cmdlineArgMatcher = RegExp(r'''['"](\\"|[^"])*?['"]|[^ ]+''');
List<String> compilerOptsToList(String compilerOpts) {
  final list = <String>[];
  _cmdlineArgMatcher.allMatches(compilerOpts).forEach((element) {
    var match = element.group(0);
    if (match != null) {
      if (quiver.matchesFull(_quoteMatcher, match)) {
        match = _quoteMatcher.allMatches(match).first.group(1)!;
      }
      list.add(match);
    }
  });

  return list;
}

List<String> compilerOptsExtractor(List<String> value) {
  final list = <String>[];
  for (final el in value) {
    list.addAll(compilerOptsToList(el));
  }
  return list;
}

YamlHeaders headersExtractor(
  Logger logger,
  Map<dynamic, List<String>> yamlConfig,
  String? configFilename,
) {
  final entryPoints = <String>[];
  final includeGlobs = <quiver.Glob>[];
  for (final key in yamlConfig.keys) {
    if (key == strings.entryPoints) {
      for (final h in yamlConfig[key]!) {
        final headerGlob = normalizePath(substituteVars(h), configFilename);
        // Add file directly to header if it's not a Glob but a File.
        if (File(headerGlob).existsSync()) {
          final osSpecificPath = headerGlob;
          entryPoints.add(osSpecificPath);
          logger.fine('Adding header/file: $headerGlob');
        } else {
          final glob = Glob(headerGlob);
          for (final file in glob.listFileSystemSync(
            const LocalFileSystem(),
            followLinks: true,
          )) {
            final fixedPath = file.path;
            entryPoints.add(fixedPath);
            logger.fine('Adding header/file: $fixedPath');
          }
        }
      }
    }
    if (key == strings.includeDirectives) {
      for (final h in yamlConfig[key]!) {
        final headerGlob = normalizePath(substituteVars(h), configFilename);
        includeGlobs.add(quiver.Glob(headerGlob));
      }
    }
  }
  return YamlHeaders(
    entryPoints: entryPoints,
    includeFilter: GlobHeaderFilter(includeGlobs: includeGlobs),
  );
}

String? _findLibInConda() {
  final condaEnvPath = Platform.environment['CONDA_PREFIX'] ?? '';
  if (condaEnvPath.isNotEmpty) {
    final locations = [
      p.join(condaEnvPath, 'lib'),
      p.join(p.dirname(p.dirname(condaEnvPath)), 'lib'),
    ];
    for (final l in locations) {
      final k = findLibclangDylib(l);
      if (k != null) return k;
    }
  }
  return null;
}

/// Returns location of dynamic library by searching default locations. Logs
/// error and throws an Exception if not found.
String findDylibAtDefaultLocations(Logger logger) {
  for (final libclangPath in libclangOverridePaths) {
    final overridableLib = findLibclangDylib(libclangPath);
    if (overridableLib != null) return overridableLib;
  }

  // Assume clang in conda has a higher priority.
  final condaLib = _findLibInConda();
  if (condaLib != null) return condaLib;

  if (Platform.isLinux) {
    for (final l in strings.linuxDylibLocations) {
      final linuxLib = findLibclangDylib(l);
      if (linuxLib != null) return linuxLib;
    }
    Process.runSync('ldconfig', ['-p']);
    final ldConfigResult = Process.runSync('ldconfig', ['-p']);
    if (ldConfigResult.exitCode == 0) {
      final lines = (ldConfigResult.stdout as String).split('\n');
      final paths = [
        for (final line in lines)
          if (line.contains('libclang')) line.split(' => ')[1],
      ];
      for (final location in paths) {
        if (File(location).existsSync()) {
          return location;
        }
      }
    }
  } else if (Platform.isWindows) {
    final dylibLocations = strings.windowsDylibLocations.toList();
    final userHome = Platform.environment['USERPROFILE'];
    if (userHome != null) {
      dylibLocations.add(
        p.join(userHome, 'scoop', 'apps', 'llvm', 'current', 'bin'),
      );
    }
    for (final l in dylibLocations) {
      final winLib = findLibclangDylib(l);
      if (winLib != null) return winLib;
    }
  } else if (Platform.isMacOS) {
    for (final l in strings.macOsDylibLocations) {
      final macLib = findLibclangDylib(l);
      if (macLib != null) return macLib;
    }
    final findLibraryResult = Process.runSync('xcodebuild', [
      '-find-library',
      'libclang.dylib',
    ]);
    if (findLibraryResult.exitCode == 0) {
      final location = (findLibraryResult.stdout as String).split('\n').first;
      if (File(location).existsSync()) {
        return location;
      }
    }
    final xcodePathResult = Process.runSync('xcode-select', ['-print-path']);
    if (xcodePathResult.exitCode == 0) {
      final xcodePath = (xcodePathResult.stdout as String).split('\n').first;
      final location = p.join(
        xcodePath,
        strings.xcodeDylibLocation,
        strings.dylibFileName,
      );
      if (File(location).existsSync()) {
        return location;
      }
    }
  } else {
    throw Exception('Unsupported Platform.');
  }

  logger.severe("Couldn't find dynamic library in default locations.");
  logger.severe(
    "Please supply one or more path/to/llvm in ffigen's config under the key '${strings.llvmPath}'.",
  );
  throw Exception("Couldn't find dynamic library in default locations.");
}

String? findLibclangDylib(String parentFolder) {
  final location = p.join(parentFolder, strings.dylibFileName);
  if (File(location).existsSync()) {
    return location;
  } else {
    return null;
  }
}

String llvmPathExtractor(Logger logger, List<String> value) {
  // Extract libclang's dylib from user specified paths.
  for (final path in value) {
    final dylibPath = findLibclangDylib(
      p.join(path, strings.dynamicLibParentName),
    );
    if (dylibPath != null) {
      logger.fine('Found dynamic library at: $dylibPath');
      return dylibPath;
    }
    // Check if user has specified complete path to dylib.
    final completeDylibPath = path;
    if (p.extension(completeDylibPath).isNotEmpty &&
        File(completeDylibPath).existsSync()) {
      logger.info(
        'Using complete dylib path: $completeDylibPath from llvm-path.',
      );
      return completeDylibPath;
    }
  }
  logger.fine(
    "Couldn't find dynamic library under paths specified by "
    '${strings.llvmPath}.',
  );
  // Extract path from default locations.
  try {
    return findDylibAtDefaultLocations(logger);
  } catch (e) {
    final path = p.join(strings.dynamicLibParentName, strings.dylibFileName);
    logger.severe("Couldn't find $path in specified locations.");
    exit(1);
  }
}

OutputConfig outputExtractor(
  Logger logger,
  dynamic value,
  String? configFilename,
  PackageConfig? packageConfig,
) {
  if (value is String) {
    return OutputConfig(normalizePath(value, configFilename), null, null);
  }
  value = value as Map;
  return OutputConfig(
    normalizePath(value[strings.bindings] as String, configFilename),
    value.containsKey(strings.objCBindings)
        ? normalizePath(value[strings.objCBindings] as String, configFilename)
        : null,
    value.containsKey(strings.symbolFile)
        ? symbolFileOutputExtractor(
            logger,
            value[strings.symbolFile],
            configFilename,
            packageConfig,
          )
        : null,
  );
}

SymbolFile symbolFileOutputExtractor(
  Logger logger,
  dynamic value,
  String? configFilename,
  PackageConfig? packageConfig,
) {
  value = value as Map;
  var output = Uri.parse(value[strings.output] as String);
  if (output.scheme != 'package') {
    logger.warning(
      'Consider using a Package Uri for ${strings.symbolFile} -> '
      '${strings.output}: $output so that external packages can use it.',
    );
    output = Uri.file(normalizePath(output.toFilePath(), configFilename));
  } else {
    output = packageConfig!.resolve(output)!;
  }
  final importPath = Uri.parse(value[strings.importPath] as String);
  if (importPath.scheme != 'package') {
    logger.warning(
      'Consider using a Package Uri for ${strings.symbolFile} -> '
      '${strings.importPath}: $importPath so that external packages '
      'can use it.',
    );
  }
  return SymbolFile(importPath, output);
}

/// Returns true if [str] is not a full name.
///
/// E.g `abc` is a full name, `abc.*` is not.
bool isFullDeclarationName(String str) =>
    quiver.matchesFull(RegExp('[a-zA-Z_0-9]*'), str);

YamlIncluder extractIncluderFromYaml(Map<dynamic, dynamic> yamlMap) {
  final includeMatchers = <RegExp>[],
      includeFull = <String>{},
      excludeMatchers = <RegExp>[],
      excludeFull = <String>{};

  final include = yamlMap[strings.include] as List<String>?;
  if (include != null) {
    if (include.isEmpty) {
      return YamlIncluder.excludeByDefault();
    }
    for (final str in include) {
      if (isFullDeclarationName(str)) {
        includeFull.add(str);
      } else {
        includeMatchers.add(RegExp(str, dotAll: true));
      }
    }
  }

  final exclude = yamlMap[strings.exclude] as List<String>?;
  if (exclude != null) {
    for (final str in exclude) {
      if (isFullDeclarationName(str)) {
        excludeFull.add(str);
      } else {
        excludeMatchers.add(RegExp(str, dotAll: true));
      }
    }
  }

  return YamlIncluder(
    includeMatchers: includeMatchers,
    includeFull: includeFull,
    excludeMatchers: excludeMatchers,
    excludeFull: excludeFull,
  );
}

Map<String, List<RawVarArgFunction>> varArgFunctionConfigExtractor(
  Map<dynamic, dynamic> yamlMap,
) {
  final result = <String, List<RawVarArgFunction>>{};
  final configMap = yamlMap;
  for (final key in configMap.keys) {
    final vafuncs = <RawVarArgFunction>[];
    for (final rawVaFunc in configMap[key] as List) {
      if (rawVaFunc is List) {
        vafuncs.add(RawVarArgFunction(null, rawVaFunc.cast()));
      } else if (rawVaFunc is Map) {
        vafuncs.add(
          RawVarArgFunction(
            rawVaFunc[strings.postfix] as String?,
            (rawVaFunc[strings.types] as List).cast(),
          ),
        );
      } else {
        throw Exception('Unexpected type in variadic-argument config.');
      }
    }
    result[key as String] = vafuncs;
  }

  return result;
}

YamlDeclarationFilters declarationConfigExtractor(
  Map<dynamic, dynamic> yamlMap,
  bool excludeAllByDefault,
) {
  final renamePatterns = <RegExpRenamer>[];
  final renameFull = <String, String>{};
  final memberRenamePatterns = <RegExpMemberRenamer>[];
  final memberRenamerFull = <String, YamlRenamer>{};

  final includer = extractIncluderFromYaml(yamlMap);

  final symbolIncluder = yamlMap[strings.symbolAddress] as YamlIncluder?;

  final rename = yamlMap[strings.rename] as Map<dynamic, String>?;

  if (rename != null) {
    for (final key in rename.keys) {
      final str = key.toString();
      if (isFullDeclarationName(str)) {
        renameFull[str] = rename[str]!;
      } else {
        renamePatterns.add(
          RegExpRenamer(RegExp(str, dotAll: true), rename[str]!),
        );
      }
    }
  }

  final memberRename =
      yamlMap[strings.memberRename] as Map<dynamic, Map<dynamic, String>>?;
  if (memberRename != null) {
    for (final key in memberRename.keys) {
      final decl = key.toString();
      final renamePatterns = <RegExpRenamer>[];
      final renameFull = <String, String>{};

      final memberRenameMap = memberRename[decl]!;
      for (final member in memberRenameMap.keys) {
        final memberStr = member.toString();
        if (isFullDeclarationName(memberStr)) {
          renameFull[memberStr] = memberRenameMap[member]!;
        } else {
          renamePatterns.add(
            RegExpRenamer(
              RegExp(memberStr, dotAll: true),
              memberRenameMap[member]!,
            ),
          );
        }
      }
      if (isFullDeclarationName(decl)) {
        memberRenamerFull[decl] = YamlRenamer(
          renameFull: renameFull,
          renamePatterns: renamePatterns,
        );
      } else {
        memberRenamePatterns.add(
          RegExpMemberRenamer(
            RegExp(decl, dotAll: true),
            YamlRenamer(renameFull: renameFull, renamePatterns: renamePatterns),
          ),
        );
      }
    }
  }

  final memberIncluderMatchers = <(RegExp, YamlIncluder)>[];
  final memberIncluderFull = <String, YamlIncluder>{};
  final memberFilter =
      yamlMap[strings.memberFilter] as Map<dynamic, YamlIncluder>?;
  if (memberFilter != null) {
    for (final entry in memberFilter.entries) {
      final decl = entry.key.toString();
      if (isFullDeclarationName(decl)) {
        memberIncluderFull[decl] = entry.value;
      } else {
        memberIncluderMatchers.add((RegExp(decl, dotAll: true), entry.value));
      }
    }
  }

  return YamlDeclarationFilters(
    includer: includer,
    renamer: YamlRenamer(
      renameFull: renameFull,
      renamePatterns: renamePatterns,
    ),
    memberRenamer: YamlMemberRenamer(
      memberRenameFull: memberRenamerFull,
      memberRenamePattern: memberRenamePatterns,
    ),
    memberIncluder: YamlMemberIncluder(
      memberIncluderFull: memberIncluderFull,
      memberIncluderMatchers: memberIncluderMatchers,
    ),
    symbolAddressIncluder: symbolIncluder,
    excludeAllByDefault: excludeAllByDefault,
  );
}

StructPackingOverride structPackingOverrideExtractor(
  Map<dynamic, dynamic> value,
) {
  final matcherMap = <(RegExp, int?)>[];
  for (final key in value.keys) {
    matcherMap.add((
      RegExp(key as String, dotAll: true),
      strings.packingValuesMap[value[key]],
    ));
  }
  return StructPackingOverride(matcherMap);
}

FfiNativeConfig ffiNativeExtractor(Logger logger, dynamic yamlConfig) {
  final yamlMap = yamlConfig as Map?;

  // Use the old 'assetId' key if present but give a deprecation warning
  if (yamlMap != null &&
      !yamlMap.containsKey(strings.ffiNativeAsset) &&
      yamlMap.containsKey('assetId')) {
    logger.warning("DEPRECATION WARNING: use 'asset-id' instead of 'assetId'");
    return FfiNativeConfig(
      enabled: true,
      assetId: yamlMap['assetId'] as String?,
    );
  }

  return FfiNativeConfig(
    enabled: true,
    assetId: yamlMap?[strings.ffiNativeAsset] as String?,
  );
}

ExternalVersions externalVersionsExtractor(Map<dynamic, dynamic>? yamlConfig) =>
    ExternalVersions(
      ios: versionsExtractor(yamlConfig?[strings.ios]),
      macos: versionsExtractor(yamlConfig?[strings.macos]),
    );

Versions? versionsExtractor(dynamic yamlConfig) {
  final yamlMap = yamlConfig as Map?;
  if (yamlMap == null) return null;
  return Versions(
    min: versionExtractor(yamlMap[strings.externalVersionsMin]),
    max: versionExtractor(yamlMap[strings.externalVersionsMax]),
  );
}

Version? versionExtractor(dynamic yamlVersion) {
  final versionString = yamlVersion as String?;
  if (versionString == null) return null;
  return Version.parse(versionString);
}
