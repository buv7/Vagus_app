/// A Result type for error handling without exceptions
///
/// Usage:
/// ```dart
/// Result<User, String> fetchUser() {
///   try {
///     final user = await api.getUser();
///     return Result.success(user);
///   } catch (e) {
///     return Result.failure('Failed to fetch user: $e');
///   }
/// }
///
/// // Using the result
/// final result = await fetchUser();
/// result.when(
///   success: (user) => print('Got user: ${user.name}'),
///   failure: (error) => print('Error: $error'),
/// );
/// ```
sealed class Result<T, E> {
  const Result();

  /// Create a success result
  factory Result.success(T value) = Success<T, E>;

  /// Create a failure result
  factory Result.failure(E error) = Failure<T, E>;

  /// Check if this is a success
  bool get isSuccess => this is Success<T, E>;

  /// Check if this is a failure
  bool get isFailure => this is Failure<T, E>;

  /// Get the success value or null
  T? get valueOrNull => isSuccess ? (this as Success<T, E>).value : null;

  /// Get the error or null
  E? get errorOrNull => isFailure ? (this as Failure<T, E>).error : null;

  /// Get the success value or throw
  T get value {
    if (this is Success<T, E>) {
      return (this as Success<T, E>).value;
    }
    throw StateError('Called value on a Failure: ${(this as Failure<T, E>).error}');
  }

  /// Get the error or throw
  E get error {
    if (this is Failure<T, E>) {
      return (this as Failure<T, E>).error;
    }
    throw StateError('Called error on a Success');
  }

  /// Get value or provide a default
  T getOrElse(T Function() defaultValue) {
    return isSuccess ? (this as Success<T, E>).value : defaultValue();
  }

  /// Map the success value
  Result<R, E> map<R>(R Function(T value) transform) {
    if (this is Success<T, E>) {
      return Result.success(transform((this as Success<T, E>).value));
    }
    return Result.failure((this as Failure<T, E>).error);
  }

  /// Map the error
  Result<T, F> mapError<F>(F Function(E error) transform) {
    if (this is Failure<T, E>) {
      return Result.failure(transform((this as Failure<T, E>).error));
    }
    return Result.success((this as Success<T, E>).value);
  }

  /// FlatMap (chain async operations)
  Result<R, E> flatMap<R>(Result<R, E> Function(T value) transform) {
    if (this is Success<T, E>) {
      return transform((this as Success<T, E>).value);
    }
    return Result.failure((this as Failure<T, E>).error);
  }

  /// Pattern match on success or failure
  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  }) {
    if (this is Success<T, E>) {
      return success((this as Success<T, E>).value);
    }
    return failure((this as Failure<T, E>).error);
  }

  /// Pattern match with async callbacks
  Future<R> whenAsync<R>({
    required Future<R> Function(T value) success,
    required Future<R> Function(E error) failure,
  }) async {
    if (this is Success<T, E>) {
      return await success((this as Success<T, E>).value);
    }
    return await failure((this as Failure<T, E>).error);
  }
}

/// Success result containing a value
class Success<T, E> extends Result<T, E> {
  const Success(this.value);
  @override
  final T value;

  @override
  String toString() => 'Success($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T, E> && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Failure result containing an error
class Failure<T, E> extends Result<T, E> {
  const Failure(this.error);
  @override
  final E error;

  @override
  String toString() => 'Failure($error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T, E> && error == other.error;

  @override
  int get hashCode => error.hashCode;
}

/// Extension for `Future<Result<T, E>>`
extension ResultFutureExtension<T, E> on Future<Result<T, E>> {
  /// Map the success value in a `Future<Result>`
  Future<Result<R, E>> mapAsync<R>(Future<R> Function(T value) transform) async {
    final result = await this;
    if (result.isSuccess) {
      try {
        final transformed = await transform(result.value);
        return Result.success(transformed);
      } catch (e) {
        // If E is String, convert error to string
        if (E == String) {
          return Result.failure(e.toString() as E);
        }
        rethrow;
      }
    }
    return Result.failure(result.error);
  }

  /// FlatMap for `Future<Result>`
  Future<Result<R, E>> flatMapAsync<R>(
    Future<Result<R, E>> Function(T value) transform,
  ) async {
    final result = await this;
    if (result.isSuccess) {
      return await transform(result.value);
    }
    return Result.failure(result.error);
  }
}

/// Extension for easier error handling
extension ResultExtension<T> on Result<T, String> {
  /// Get value or throw with message
  T getOrThrow() {
    if (isSuccess) return value;
    throw Exception(error);
  }
}

/// Helper to wrap try-catch in Result
Result<T, String> resultOf<T>(T Function() fn) {
  try {
    return Result.success(fn());
  } catch (e, st) {
    return Result.failure('$e\n$st');
  }
}

/// Helper to wrap async try-catch in Result
Future<Result<T, String>> resultOfAsync<T>(Future<T> Function() fn) async {
  try {
    final value = await fn();
    return Result.success(value);
  } catch (e, st) {
    return Result.failure('$e\n$st');
  }
}

