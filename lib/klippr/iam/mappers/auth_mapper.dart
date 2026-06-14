import '../models/auth_response.dart';

// author: Samuel Bonifacio
//
// Conversión entre el JSON decodificado (dynamic) que devuelve ApiClient y los
// modelos de dominio de IAM.

/// Helpers de mapeo para las respuestas de autenticación.
class AuthMapper {
  const AuthMapper._();

  /// Convierte la respuesta de sign-in en [AuthenticatedUser].
  static AuthenticatedUser toAuthenticatedUser(dynamic json) {
    return AuthenticatedUser.fromJson(_asMap(json));
  }

  /// Convierte la respuesta de sign-up/business en [BusinessUserResource].
  static BusinessUserResource toBusinessUser(dynamic json) {
    return BusinessUserResource.fromJson(_asMap(json));
  }

  static Map<String, dynamic> _asMap(dynamic json) {
    if (json is Map<String, dynamic>) return json;
    return <String, dynamic>{};
  }
}
