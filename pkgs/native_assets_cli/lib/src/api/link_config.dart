// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../native_assets_cli.dart';
import '../../native_assets_cli_internal.dart';
import '../model/resource_identifiers.dart';
import '../utils/map.dart';
import 'build_config.dart';
import 'linkable_asset.dart';

part '../model/link_config.dart';

/// The input to the linking script.
///
/// It consists of a subset of the fields from the [BuildConfig] already passed
/// to the build script, the [assets] from the build step, and the [resources]
/// generated during the kernel compilation.
abstract class LinkConfig {
  /// The directory in which all output and intermediate artifacts should be
  /// placed.
  Uri get outputDirectory;

  /// The name of the package the assets are linked for.
  String get packageName;

  /// The root of the package the assets are linked for.
  ///
  /// Often a package's assets are built because a package is a dependency of
  /// another. For this it is convenient to know the packageRoot.
  Uri get packageRoot;

  /// The list of assets to be linked. These are the assets generated by a
  /// `build.dart` script destined for this packages `link.dart`.
  List<LinkableAsset> get assets;

  /// A collection of methods annotated with `@ResourceIdentifier`, which are
  /// called in the tree-shaken Dart code. This information can be used to
  /// dispose unused [assets].
  List<Resource> get resources;

  /// Generate the [LinkConfig] from the input arguments to the linking script.
  factory LinkConfig(List<String> arguments) =>
      LinkConfigImpl.fromArguments(arguments);
}
