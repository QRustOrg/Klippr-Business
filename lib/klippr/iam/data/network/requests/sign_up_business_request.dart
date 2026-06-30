// author: Samuel Bonifacio
//
// Cuerpo de POST /api/Authentication/sign-up/business.

/// Petición de registro de un nuevo negocio.
class SignUpBusinessRequest {
  /// Crea un [SignUpBusinessRequest].
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

  /// Serializa esta petición a un mapa JSON-compatible.
  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'businessName': businessName,
        'taxId': taxId,
      };
}
