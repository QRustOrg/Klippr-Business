// author: Samuel Bonifacio
//
// Resultado tipado de una operación que puede tener éxito con [T] o fallar con
// un [ApiException]. Permite a los llamadores manejar ambas ramas de forma
// exhaustiva en vez de lanzar excepciones entre capas.

import '../network/api_exceptions.dart';

/// Tipo sellado que representa éxito ([Success]) o fallo ([Failure]).
sealed class Result<T> {
  const Result();

  /// True cuando es un [Success].
  bool get isSuccess => this is Success<T>;

  /// El valor en caso de éxito, o null en caso de fallo.
  T? get dataOrNull => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>() => null,
      };

  /// El error en caso de fallo, o null en caso de éxito.
  ApiException? get errorOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final error) => error,
      };

  /// Reduce ambas ramas de forma exhaustiva a un único valor de tipo [R].
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

/// Resultado exitoso que transporta [data].
class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

/// Resultado fallido que transporta un [error] tipado.
class Failure<T> extends Result<T> {
  const Failure(this.error);
  final ApiException error;
}
