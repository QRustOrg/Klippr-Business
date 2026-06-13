// author: Samuel Bonifacio
//
// Jerarquía de errores tipados de la API, usada en toda la capa de red.
//
// Cada request fallida se resuelve en uno de estos subtipos, de modo que los
// BLoCs y repositorios puedan hacer pattern-matching sobre el error concreto
// en lugar de inspeccionar códigos de estado o mensajes crudos.

/// Tipo base sellado para todos los errores de la API.
sealed class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  /// Descripción legible, segura para mostrar en la UI.
  final String message;

  /// Código de estado HTTP cuando el fallo viene de una respuesta.
  /// Null para fallos de transporte (sin conexión, timeout, error de parseo).
  final int? statusCode;

  /// Mapea un código de estado HTTP a su subtipo concreto de [ApiException].
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

/// Sin conectividad / DNS / fallo de socket antes de llegar al servidor.
class NetworkException extends ApiException {
  const NetworkException([super.message = 'Sin conexión a internet.']);
}

/// La solicitud superó [ApiConfig.timeout].
class TimeoutApiException extends ApiException {
  const TimeoutApiException([super.message = 'La solicitud tardó demasiado.']);
}

/// 401 — credenciales o token ausentes/ inválidos.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'No autorizado.'])
      : super(statusCode: 401);
}

/// 403 — autenticado pero sin permiso.
class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = 'Acceso denegado.'])
      : super(statusCode: 403);
}

/// 404 — recurso no encontrado.
class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Recurso no encontrado.'])
      : super(statusCode: 404);
}

/// 400 / 422 — payload inválido. [errors] guarda el detalle por campo si existe.
class ValidationException extends ApiException {
  const ValidationException(
    super.message, {
    super.statusCode,
    this.errors,
  });

  /// Mapa opcional campo -> mensajes extraído del cuerpo de la respuesta.
  final Map<String, dynamic>? errors;
}

/// 5xx — fallo del lado del servidor.
class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode});
}

/// El cuerpo de la respuesta no era JSON válido cuando se esperaba JSON.
class ParseException extends ApiException {
  const ParseException([super.message = 'Respuesta inválida del servidor.']);
}

/// Cualquier código de estado no cubierto por los casos anteriores.
class UnknownApiException extends ApiException {
  const UnknownApiException(super.message, {super.statusCode});
}
