import '../../../shared/domain/models/id.dart';
import '../../domain/models/authenticated_user.dart';

// author: Samuel Bonifacio
//
// DTO que refleja la forma del payload de sign-in/sign-up
// (`AuthenticatedUserResource` del backend). El mapeo a dominio ocurre solo
// en [toDomain]; la capa `domain/` pura nunca ve este tipo.

/// DTO de la respuesta de autenticación (sign-in / auto-login post sign-up).
class AuthenticatedUserDto {
  /// Crea un [AuthenticatedUserDto].
  const AuthenticatedUserDto({
    required this.userId,
    required this.email,
    required this.role,
    required this.token,
  });

  /// Identificador devuelto por el backend.
  final String userId;

  /// Email del usuario.
  final String email;

  /// Rol asignado (BUSINESS, ADMIN, CONSUMER).
  final String role;

  /// Token bearer emitido.
  final String token;

  /// Construye un [AuthenticatedUserDto] desde un mapa JSON decodificado.
  factory AuthenticatedUserDto.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUserDto(
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      token: json['token'] as String? ?? '',
    );
  }

  /// Proyecta este DTO a la entidad de dominio pura [AuthenticatedUser].
  AuthenticatedUser toDomain() {
    return AuthenticatedUser(
      id: Id(userId),
      email: email,
      role: role,
      token: token,
    );
  }
}
