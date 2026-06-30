// author: Samuel Bonifacio
//
// Cuerpo de PUT /api/Authentication/reset-password (fija la nueva contraseña).

/// Petición que fija la nueva contraseña (paso 2 de recuperación).
class ResetPasswordRequest {
  /// Crea un [ResetPasswordRequest].
  const ResetPasswordRequest({
    required this.email,
    required this.newPassword,
  });

  final String email;
  final String newPassword;

  /// Serializa esta petición a un mapa JSON-compatible.
  Map<String, dynamic> toJson() => {
        'email': email,
        'newPassword': newPassword,
      };
}
