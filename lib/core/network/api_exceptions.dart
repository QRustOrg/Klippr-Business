/// Typed API error hierarchy used across the network layer.
///
/// Every failed request resolves to one of these subtypes so that BLoCs and
/// repositories can pattern-match on the concrete error instead of inspecting
/// raw status codes or string messages.
sealed class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  /// Human-readable description, safe to surface in the UI.
  final String message;

  /// HTTP status code when the failure originated from a response.
  /// Null for transport-level failures (no connection, timeout, parse error).
  final int? statusCode;

  /// Maps an HTTP status code to its concrete [ApiException] subtype.
  factory ApiException.fromStatus(int code, String message) {
    return switch (code) {
      400 || 422 => ValidationException(message, statusCode: code),
      401 => UnauthorizedException(message),
      403 => ForbiddenException(message),
      404 => NotFoundException(message),
      >= 500 => ServerException(message, statusCode: code),
      _ => UnknownApiException(message, statusCode: code),
    };
  }

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// No connectivity / DNS / socket failure before reaching the server.
class NetworkException extends ApiException {
  const NetworkException([super.message = 'Sin conexión a internet.']);
}

/// The request exceeded [ApiConfig.timeout].
class TimeoutApiException extends ApiException {
  const TimeoutApiException([super.message = 'La solicitud tardó demasiado.']);
}

/// 401 — missing or invalid credentials / token.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'No autorizado.'])
      : super(statusCode: 401);
}

/// 403 — authenticated but not allowed.
class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = 'Acceso denegado.'])
      : super(statusCode: 403);
}

/// 404 — resource not found.
class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Recurso no encontrado.'])
      : super(statusCode: 404);
}

/// 400 / 422 — invalid payload. [errors] holds field-level details when present.
class ValidationException extends ApiException {
  const ValidationException(
    super.message, {
    super.statusCode,
    this.errors,
  });

  /// Optional field -> messages map extracted from the response body.
  final Map<String, dynamic>? errors;
}

/// 5xx — server-side failure.
class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode});
}

/// Response body was not valid JSON when JSON was expected.
class ParseException extends ApiException {
  const ParseException([super.message = 'Respuesta inválida del servidor.']);
}

/// Any status code not covered by the cases above.
class UnknownApiException extends ApiException {
  const UnknownApiException(super.message, {super.statusCode});
}
