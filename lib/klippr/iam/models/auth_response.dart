// author: Samuel Bonifacio
//
// Modelos de respuesta de autenticación del backend de Klippr.

/// Respuesta de sign-in: identidad + token de acceso
/// (`AuthenticatedUserResource`).
class AuthenticatedUser {
  const AuthenticatedUser({
    required this.userId,
    required this.email,
    required this.role,
    required this.token,
  });

  final String userId;
  final String email;
  final String role;
  final String token;

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUser(
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      token: json['token'] as String? ?? '',
    );
  }
}

/// Respuesta de sign-up/business (`UserResource`, 201): crea el usuario pero
/// NO devuelve token. Tras registrarse, el repositorio hace un sign-in
/// automático para obtener la sesión.
class BusinessUserResource {
  const BusinessUserResource({
    required this.userId,
    required this.email,
    required this.role,
    this.businessName,
    this.taxId,
  });

  final String userId;
  final String email;
  final String role;
  final String? businessName;
  final String? taxId;

  factory BusinessUserResource.fromJson(Map<String, dynamic> json) {
    return BusinessUserResource(
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      businessName: json['businessName'] as String?,
      taxId: json['taxId'] as String?,
    );
  }
}
