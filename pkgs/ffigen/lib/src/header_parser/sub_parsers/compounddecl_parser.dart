// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:logging/logging.dart';

import '../../code_generator.dart';
import '../../config_provider/config.dart';
import '../../config_provider/config_types.dart';
import '../../strings.dart' as strings;
import '../clang_bindings/clang_bindings.dart' as clang_types;
import '../data.dart';
import '../utils.dart';
import 'api_availability.dart';

final _logger = Logger('ffigen.header_parser.compounddecl_parser');

/// Holds temporary information regarding [compound] while parsing.
class _ParsedCompound {
  Compound compound;
  bool unimplementedMemberType = false;
  bool flexibleArrayMember = false;
  bool bitFieldMember = false;
  bool dartHandleMember = false;
  bool incompleteCompoundMember = false;

  _ParsedCompound(this.compound);

  bool get isIncomplete =>
      unimplementedMemberType ||
      flexibleArrayMember ||
      bitFieldMember ||
      (dartHandleMember && config.useDartHandle) ||
      incompleteCompoundMember ||
      alignment == clang_types.CXTypeLayoutError.CXTypeLayoutError_Incomplete;

  // A struct without any attribute is definitely not packed. #pragma pack(...)
  // also adds an attribute, but it's unexposed and cannot be travesed.
  bool hasAttr = false;

  // A struct which as a __packed__ attribute is definitely packed.
  bool hasPackedAttr = false;

  // Stores the maximum alignment from all the children.
  int maxChildAlignment = 0;

  // Alignment of this struct.
  int alignment = 0;

  bool get _isPacked {
    if (!hasAttr || isIncomplete) return false;
    if (hasPackedAttr) return true;

    return maxChildAlignment > alignment;
  }

  /// Returns pack value of a struct depending on config, returns null for no
  /// packing.
  int? get packValue {
    if (compound.isStruct && _isPacked && !isIncomplete) {
      if (strings.packingValuesMap.containsKey(alignment)) {
        return alignment;
      } else {
        _logger.warning(
          'Unsupported pack value "$alignment" for Struct '
          '"${compound.name}".',
        );
        return null;
      }
    } else {
      return null;
    }
  }
}

/// Parses a compound declaration.
Compound? parseCompoundDeclaration(
  clang_types.CXCursor cursor,
  CompoundType compoundType, {

  /// To track if the declaration was used by reference(i.e T*). (Used to only
  /// generate these as opaque if `dependency-only` was set to opaque).
  bool pointerReference = false,
}) {
  // Set includer functions according to compoundType.
  final DeclarationFilters configDecl;
  final className = _compoundTypeDebugName(compoundType);
  switch (compoundType) {
    case CompoundType.struct:
      configDecl = config.structDecl;
      break;
    case CompoundType.union:
      configDecl = config.unionDecl;
      break;
  }

  // Parse the cursor definition instead, if this is a forward declaration.
  final declUsr = cursor.usr();
  final String declName;

  // Only set name using USR if the type is not Anonymous (A struct is anonymous
  // if it has no name, is not inside any typedef and declared inline inside
  // another declaration).
  if (clang.clang_Cursor_isAnonymous(cursor) == 0) {
    // This gives the significant name, i.e name of the struct if defined or
    // name of the first typedef declaration that refers to it.
    declName = declUsr.split('@').last;
  } else {
    // Empty names are treated as inline declarations.
    declName = '';
  }

  final apiAvailability = ApiAvailability.fromCursor(cursor);
  if (apiAvailability.availability == Availability.none) {
    _logger.info('Omitting deprecated $className $declName');
    return null;
  }

  final decl = Declaration(usr: declUsr, originalName: declName);
  if (declName.isEmpty) {
    cursor = cursorIndex.getDefinition(cursor);
    return Compound.fromType(
      type: compoundType,
      name: incrementalNamer.name('Unnamed$className'),
      usr: declUsr,
      dartDoc: getCursorDocComment(
        cursor,
        availability: apiAvailability.dartDoc,
      ),
      objCBuiltInFunctions: objCBuiltInFunctions,
      nativeType: cursor.type().spelling(),
    );
  } else {
    cursor = cursorIndex.getDefinition(cursor);
    _logger.fine(
      '++++ Adding $className: Name: $declName, '
      '${cursor.completeStringRepr()}',
    );
    return Compound.fromType(
      type: compoundType,
      usr: declUsr,
      originalName: declName,
      name: configDecl.rename(decl),
      dartDoc: getCursorDocComment(
        cursor,
        availability: apiAvailability.dartDoc,
      ),
      objCBuiltInFunctions: objCBuiltInFunctions,
      nativeType: cursor.type().spelling(),
    );
  }
}

void fillCompoundMembersIfNeeded(
  Compound compound,
  clang_types.CXCursor cursor, {

  /// To track if the declaration was used by reference(i.e T*). (Used to only
  /// generate these as opaque if `dependency-only` was set to opaque).
  bool pointerReference = false,
}) {
  if (compound.parsedDependencies) return;
  final compoundType = compound.compoundType;

  cursor = cursorIndex.getDefinition(cursor);

  final parsed = _ParsedCompound(compound);
  final className = _compoundTypeDebugName(compoundType);
  parsed.hasAttr = clang.clang_Cursor_hasAttrs(cursor) != 0;
  parsed.alignment = cursor.type().alignment();
  compound.parsedDependencies = true; // Break cycles.

  cursor.visitChildren((cursor) => _compoundMembersVisitor(cursor, parsed));

  _logger.finest(
    'Opaque: ${parsed.isIncomplete}, HasAttr: ${parsed.hasAttr}, '
    'AlignValue: ${parsed.alignment}, '
    'MaxChildAlignValue: ${parsed.maxChildAlignment}, '
    'PackValue: ${parsed.packValue}.',
  );
  compound.pack = parsed.packValue;

  if (parsed.unimplementedMemberType) {
    _logger.fine(
      '---- Removed $className members, reason: member with '
      'unimplementedtype ${cursor.completeStringRepr()}',
    );
    _logger.warning(
      'Removed All $className Members from ${compound.name}'
      '(${compound.originalName}), struct member has an unsupported type.',
    );
  } else if (parsed.flexibleArrayMember) {
    _logger.fine(
      '---- Removed $className members, reason: incomplete array '
      'member ${cursor.completeStringRepr()}',
    );
    _logger.warning(
      'Removed All $className Members from ${compound.name}'
      '(${compound.originalName}), Flexible array members not supported.',
    );
  } else if (parsed.bitFieldMember) {
    _logger.fine(
      '---- Removed $className members, reason: bitfield members '
      '${cursor.completeStringRepr()}',
    );
    _logger.warning(
      'Removed All $className Members from ${compound.name}'
      '(${compound.originalName}), Bit Field members not supported.',
    );
  } else if (parsed.dartHandleMember && config.useDartHandle) {
    _logger.fine(
      '---- Removed $className members, reason: Dart_Handle member. '
      '${cursor.completeStringRepr()}',
    );
    _logger.warning(
      'Removed All $className Members from ${compound.name}'
      '(${compound.originalName}), Dart_Handle member not supported.',
    );
  } else if (parsed.incompleteCompoundMember) {
    _logger.fine(
      '---- Removed $className members, reason: Incomplete Nested Struct '
      'member. ${cursor.completeStringRepr()}',
    );
    _logger.warning(
      'Removed All $className Members from ${compound.name}'
      '(${compound.originalName}), Incomplete Nested Struct member not '
      'supported.',
    );
  }

  // Clear all members if declaration is incomplete.
  if (parsed.isIncomplete) {
    compound.members.clear();
  }

  // C allows empty structs/union, but it's undefined behaviour at runtine.
  // So we need to mark a declaration incomplete if it has no members.
  compound.isIncomplete = parsed.isIncomplete || compound.members.isEmpty;
}

/// Visitor for the struct/union cursor
/// [clang_types.CXCursorKind.CXCursor_StructDecl]/
/// [clang_types.CXCursorKind.CXCursor_UnionDecl].
///
/// Child visitor invoked on struct/union cursor.
void _compoundMembersVisitor(
  clang_types.CXCursor cursor,
  _ParsedCompound parsed,
) {
  final decl = Declaration(
    usr: parsed.compound.usr,
    originalName: parsed.compound.originalName,
  );
  try {
    switch (cursor.kind) {
      case clang_types.CXCursorKind.CXCursor_FieldDecl:
        _logger.finer('===== member: ${cursor.completeStringRepr()}');

        // Set maxChildAlignValue.
        final align = cursor.type().alignment();
        if (align > parsed.maxChildAlignment) {
          parsed.maxChildAlignment = align;
        }

        final mt = cursor.toCodeGenType();
        if (mt is IncompleteArray) {
          // TODO(https://github.com/dart-lang/ffigen/issues/68): Structs with
          // flexible Array Members are not supported.
          parsed.flexibleArrayMember = true;
        }
        if (clang.clang_getFieldDeclBitWidth(cursor) != -1) {
          // TODO(https://github.com/dart-lang/ffigen/issues/84): Struct with
          // bitfields are not suppoorted.
          parsed.bitFieldMember = true;
        }
        if (mt is HandleType) {
          parsed.dartHandleMember = true;
        }
        if (mt.isIncompleteCompound) {
          parsed.incompleteCompoundMember = true;
        }
        if (mt.baseType is UnimplementedType) {
          parsed.unimplementedMemberType = true;
        }
        parsed.compound.members.add(
          CompoundMember(
            dartDoc: getCursorDocComment(
              cursor,
              indent: nesting.length + commentPrefix.length,
            ),
            originalName: cursor.spelling(),
            name: config.structDecl.renameMember(decl, cursor.spelling()),
            type: mt,
          ),
        );

        break;

      case clang_types.CXCursorKind.CXCursor_PackedAttr:
        parsed.hasPackedAttr = true;

        break;
      case clang_types.CXCursorKind.CXCursor_UnionDecl:
      case clang_types.CXCursorKind.CXCursor_StructDecl:
        // If the union/struct are anonymous, then we need to add them now,
        // otherwise they will be added in the next iteration.
        if (!cursor.isAnonymousRecordDecl()) break;

        final mt = cursor.toCodeGenType();
        if (mt.isIncompleteCompound) {
          parsed.incompleteCompoundMember = true;
        }

        // Anonymous members are always unnamed. To avoid environment-
        // dependent naming issues with the generated code, we explicitly
        // use the empty string as spelling.
        final spelling = '';

        parsed.compound.members.add(
          CompoundMember(
            dartDoc: getCursorDocComment(
              cursor,
              indent: nesting.length + commentPrefix.length,
            ),
            originalName: spelling,
            name: config.structDecl.renameMember(decl, spelling),
            type: mt,
          ),
        );

        break;
    }
  } catch (e, s) {
    _logger.severe(e);
    _logger.severe(s);
    rethrow;
  }
}

String _compoundTypeDebugName(CompoundType compoundType) {
  return compoundType == CompoundType.struct ? 'Struct' : 'Union';
}
