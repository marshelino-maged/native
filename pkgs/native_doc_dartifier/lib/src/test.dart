import 'dart:io';

Future<String> analyzeAndFix(String code, String bindingsPath) async {
  code = '''
import 'package:jni/jni.dart';
import '$bindingsPath';

$code''';

  final directory = File(bindingsPath).parent;

  final file = File('${directory.path}/snippet.dart');
  await file.writeAsString(code);

  print('Code written to: ${file.path}\n');

  final fix = await Process.run('dart', [
    'fix',
    '--dry-run',
  ], workingDirectory: directory.path);
  print('--- Dart Fix Suggestions ---\n${fix.stdout}${fix.stderr}');

  final fixApply = await Process.run('dart', [
    'fix',
    '--apply',
  ], workingDirectory: directory.path);
  print('--- Dart Fix Applied ---\n${fixApply.stdout}${fixApply.stderr}');

  final format = await Process.run('dart', [
    'format',
    file.path,
  ], workingDirectory: directory.path);
  print('--- Dart Format Output ---\n${format.stdout}${format.stderr}');

  final analyze = await Process.run('dart', ['analyze', file.path]);
  print('--- Dart Analyze Output ---\n${analyze.stdout}${analyze.stderr}');

  final formattedCode = await file.readAsString();
  final cleanedCode = formattedCode
      .split('\n')
      .where((line) => !line.trim().startsWith('import'))
      .join('\n');

  return cleanedCode;
}
