// author: Samuel Bonifacio
//
// Cuerpo de POST /api/Authentication/forgot-password (verifica el email).

/// Petición que verifica la existencia de un email (paso 1 de recuperación).
class ForgotPasswordRequest {
  /// Crea un [ForgotPasswordRequest].
  const ForgotPasswordRequest({required this.email});

  final String email;

  /// Serializa esta petición a un mapa JSON-compatible.
  Map<String, dynamic> toJson() => {'email': email};
}
