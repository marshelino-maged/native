// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The type of failure.
enum FailureType {
  /// Failed to build.
  BuildFailed,

  /// Failed to link.
  LinkFailed,

  /// Failed to compile.
  CompilationFailed,

  /// Failed to validate input.
  InputValidationFailed,

  /// Failed to validate output.
  OutputValidationFailed,

  /// Failed due to user defines.
  UserDefinesFailed,

  /// Failed to execute a process.
  ProcessExecutionFailed,

  /// Failed to perform a file operation.
  FileOperationFailed,
}

/// A failure that occurred during a hook.
class Failure {
  /// The type of failure.
  final FailureType type;

  /// A message describing the failure.
  final String message;

  /// The exception that caused the failure, if any.
  final Object? exception;

  /// The stack trace of the exception that caused the failure, if any.
  final StackTrace? stackTrace;

  /// Creates a new failure.
  Failure({
    required this.type,
    required this.message,
    this.exception,
    this.stackTrace,
  });
}
