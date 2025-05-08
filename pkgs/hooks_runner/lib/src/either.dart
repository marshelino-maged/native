// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A generic sealed class that represents a value of one of two possible types.
///
/// An instance of `Either` is either an instance of [Left] or [Right].
///
/// By convention, `Left` is used to represent an error or failure, and `Right`
/// is used to represent a success or a correct value.
sealed class Either<L, R> {
  /// Creates a new [Left] instance.
  const factory Either.left(L value) = Left<L, R>;

  /// Creates a new [Right] instance.
  const factory Either.right(R value) = Right<L, R>;

  /// Private constructor to prevent direct instantiation.
  const Either._();

  /// Returns `true` if this is a [Left] instance.
  bool get isLeft => this is Left<L, R>;

  /// Returns `true` if this is a [Right] instance.
  bool get isRight => this is Right<L, R>;

  /// Applies [ifLeft] if this is a [Left] or [ifRight] if this is a [Right].
  ///
  /// Returns the result of the applied function.
  T fold<T>(T Function(L left) ifLeft, T Function(R right) ifRight);

  /// Maps the [Right] value of this [Either] to a new value of type [NR].
  ///
  /// If this is a [Left], it returns itself.
  Either<L, NR> map<NR>(NR Function(R right) fn);

  /// Maps the [Left] value of this [Either] to a new value of type [NL].
  ///
  /// If this is a [Right], it returns itself.
  Either<NL, R> mapLeft<NL>(NL Function(L left) fn);

  /// Binds the given function across the [Right] value of this [Either].
  ///
  /// If this is a [Left], it returns itself.
  Either<L, NR> flatMap<NR>(Either<L, NR> Function(R right) fn);

  /// Returns the [Left] value if this is a [Left], otherwise `null`.
  L? get leftOrNull;

  /// Returns the [Right] value if this is a [Right], otherwise `null`.
  R? get rightOrNull;
}

/// Represents the left side of an [Either] value, typically an error or failure.
class Left<L, R> extends Either<L, R> {
  /// The value of this [Left].
  final L value;

  /// Creates a new [Left] instance.
  const Left(this.value) : super._();

  @override
  T fold<T>(T Function(L left) ifLeft, T Function(R right) ifRight) =>
      ifLeft(value);

  @override
  Either<L, NR> map<NR>(NR Function(R right) fn) => Left<L, NR>(value);

  @override
  Either<NL, R> mapLeft<NL>(NL Function(L left) fn) =>
      Either.left(fn(value));

  @override
  Either<L, NR> flatMap<NR>(Either<L, NR> Function(R right) fn) =>
      Left<L, NR>(value);

  @override
  L? get leftOrNull => value;

  @override
  R? get rightOrNull => null;
}

/// Represents the right side of an [Either] value, typically a success or correct value.
class Right<L, R> extends Either<L, R> {
  /// The value of this [Right].
  final R value;

  /// Creates a new [Right] instance.
  const Right(this.value) : super._();

  @override
  T fold<T>(T Function(L left) ifLeft, T Function(R right) ifRight) =>
      ifRight(value);

  @override
  Either<L, NR> map<NR>(NR Function(R right) fn) => Either.right(fn(value));

  @override
  Either<NL, R> mapLeft<NL>(NL Function(L left) fn) =>
      Right<NL, R>(value);

  @override
  Either<L, NR> flatMap<NR>(Either<L, NR> Function(R right) fn) => fn(value);

  @override
  L? get leftOrNull => null;

  @override
  R? get rightOrNull => value;
}
