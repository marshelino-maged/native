import 'calculator.dart';
import 'package:jni/jni.dart';

void main() {
  Jni.spawn(dylibDir: "../build/jni_libs", classPath: ["java_src/com/example/Calculator.jar"]);
  final calc = Calculator.renamedConstructor$2(5, 5);
  print(calc.add(5, 5));
}
