// author: Samuel Bonifacio
//
// Cuerpos de las peticiones de autenticación. Los nombres de campo coinciden
// exactamente con el contrato del backend de Klippr.

/// Cuerpo de POST /api/Authentication/sign-in.
class SignInRequest {
  const SignInRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

/// Cuerpo de POST /api/Authentication/sign-up/business.
class SignUpBusinessRequest {
  const SignUpBusinessRequest({
    required this.email,
    required this.password,
    required this.businessName,
    required this.taxId,
  });

  final String email;
  final String password;
  final String businessName;
  final String taxId;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'businessName': businessName,
        'taxId': taxId,
      };
}

/// Cuerpo de POST /api/Authentication/forgot-password (verifica el email).
class ForgotPasswordRequest {
  const ForgotPasswordRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email};
}

/// Cuerpo de PUT /api/Authentication/reset-password (fija la nueva contraseña).
class ResetPasswordRequest {
  const ResetPasswordRequest({required this.email, required this.newPassword});

  final String email;
  final String newPassword;

  Map<String, dynamic> toJson() => {
        'email': email,
        'newPassword': newPassword,
      };
}
