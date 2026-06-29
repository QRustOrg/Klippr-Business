// author: Samuel Bonifacio
//
// Cuerpo de POST /api/Authentication/sign-in.

/// Petición de inicio de sesión con email/password.
class SignInRequest {
  /// Crea un [SignInRequest].
  const SignInRequest({required this.email, required this.password});

  final String email;
  final String password;

  /// Serializa esta petición a un mapa JSON-compatible.
  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}
