import '../network/api_exceptions.dart';

/// Typed outcome of an operation that can succeed with [T] or fail with an
/// [ApiException]. Lets callers handle both branches exhaustively instead of
/// throwing across layers.
sealed class Result<T> {
  const Result();

  /// True when this is a [Success].
  bool get isSuccess => this is Success<T>;

  /// The value on success, or null on failure.
  T? get dataOrNull => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>() => null,
      };

  /// The error on failure, or null on success.
  ApiException? get errorOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final error) => error,
      };

  /// Exhaustively folds both branches into a single value of type [R].
  R when<R>({
    required R Function(T data) onSuccess,
    required R Function(ApiException error) onFailure,
  }) {
    return switch (this) {
      Success<T>(:final data) => onSuccess(data),
      Failure<T>(:final error) => onFailure(error),
    };
  }
}

/// Successful outcome carrying [data].
class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

/// Failed outcome carrying a typed [error].
class Failure<T> extends Result<T> {
  const Failure(this.error);
  final ApiException error;
}
