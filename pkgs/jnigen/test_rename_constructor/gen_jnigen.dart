import "package:jnigen/jnigen.dart";


class UserRenamer extends Visitor {
  @override
  void visitMethod(Method method) {
    if (method.originalName == '<init>') {
      method.name = 'renamedConstructor';
    }
  }
}

void main(){
  generateJniBindings(
    Config(
      outputConfig: OutputConfig(
        dartConfig: DartCodeOutputConfig(
          path: Uri.file("bin/generated.dart"),
          structure: OutputStructure.singleFile,
        )
      ),
      classes: ["com.example.Calculator"],
      sourcePath: [Uri.directory("java_src")],
      visitors: [UserRenamer()],
    ),
  );
}
