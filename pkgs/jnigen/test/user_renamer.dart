// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:jnigen/jnigen.dart' as jnigen;
import 'package:jnigen/src/bindings/linker.dart';
import 'package:jnigen/src/bindings/renamer.dart';
import 'package:jnigen/src/elements/elements.dart' as ast;
import 'package:jnigen/src/elements/j_elements.dart';
import 'package:test/test.dart';

extension on Iterable<ast.Method> {
  List<String> get finalNames => map((m) => m.finalName).toList();
}

extension on Iterable<ast.Param> {
  List<String> get finalNames => map((p) => p.finalName).toList();
}

extension on Iterable<ast.Field> {
  List<String> get finalNames => map((f) => f.finalName).toList();
}

// This is customizable by the user
class UserRenamer extends Visitor {
  @override
  void visitClass(ClassDecl c) {
    if (c.binaryName.contains('Foo')) {
      c.newName = c.binaryName.replaceAll('Foo', 'Bar');
    }
  }

  @override
  void visitMethod(Method method) {
    if (method.name.contains('Foo')) {
      method.newName = method.name.replaceAll('Foo', 'Bar');
    }
  }

  @override
  void visitField(Field field) {
    if (field.name.contains('Foo')) {
      field.newName = field.name.replaceAll('Foo', 'Bar');
    }
  }

  @override
  void visitParam(Param parameter) {
    if (parameter.name.contains('Foo')) {
      parameter.newName = parameter.name.replaceAll('Foo', 'Bar');
    }
  }
}

Future<void> rename(ast.Classes classes) async {
  final config = jnigen.Config(
      outputConfig: jnigen.OutputConfig(
        dartConfig: jnigen.DartCodeOutputConfig(
          path: Uri.file('test.dart'),
          structure: jnigen.OutputStructure.singleFile,
        ),
      ),
      classes: []
      );
  await classes.accept(Linker(config));
  classes.accept(Renamer(config));
}

void main() {
  test('rename classes, fields, methods and params using user visitors',
      () async {
    final classes = ast.Classes({
      'Foo': ast.ClassDecl(
        binaryName: 'Foo',
        declKind: ast.DeclKind.classKind,
        superclass: ast.TypeUsage.object,
        methods: [
          ast.Method(name: 'Foo', returnType: ast.TypeUsage.object),
          ast.Method(name: 'Foo', returnType: ast.TypeUsage.object),
          ast.Method(name: 'Foo1', returnType: ast.TypeUsage.object),
          ast.Method(name: 'Foo1', returnType: ast.TypeUsage.object),
        ],
        fields: [
          ast.Field(name: 'Foo', type: ast.TypeUsage.object),
          ast.Field(name: 'Foo', type: ast.TypeUsage.object),
          ast.Field(name: 'Foo1', type: ast.TypeUsage.object),
          ast.Field(name: 'Foo1', type: ast.TypeUsage.object),
        ],
      ),
      'y.Foo': ast.ClassDecl(
        binaryName: 'y.Foo',
        declKind: ast.DeclKind.classKind,
        superclass: ast.TypeUsage.object,
        methods: [
          ast.Method(name: 'Foo', returnType: ast.TypeUsage.object, params: [
            ast.Param(name: 'Foo', type: ast.TypeUsage.object),
            ast.Param(name: 'Foo1', type: ast.TypeUsage.object),
          ]),
        ],
      ),
    });

    final simpleClasses = Classes(classes);
    simpleClasses.accept(UserRenamer());

    await rename(classes);

    expect(classes.decls['y.Foo']?.finalName, 'y.Bar');
    expect(classes.decls['Foo']?.finalName, 'Bar');

    expect(classes.decls['Foo']?.fields.finalNames,
        ['Bar', r'Bar$1', 'Bar1', r'Bar1$1']);

    expect(classes.decls['Foo']?.methods.finalNames,
        [r'Bar$2', r'Bar$3', r'Bar1$2', r'Bar1$3']);

    expect(classes.decls['y.Foo']?.methods.first.params.finalNames,
        ['Bar', 'Bar1']);
  });
}
