// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/referred_type.dart';
import 'can_throw.dart';
import 'declaration.dart';

/// Describes a variable-like entity.
///
/// This declaration [CanThrow] because Swift variables can have explicit
/// getters, which can be marked with `throws`. Such variables may not have a
/// setter.
abstract interface class VariableDeclaration implements Declaration, CanThrow {
  abstract final bool isConstant;
  abstract final ReferredType type;
}
