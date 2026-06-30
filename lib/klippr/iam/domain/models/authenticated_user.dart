import '../../../shared/domain/models/id.dart';

// author: Samuel Bonifacio
//
// Entidad de dominio pura que representa al usuario autenticado (negocio o
// admin) junto con las credenciales emitidas por el backend. Sin anotaciones
// de serialización ni dependencias de infraestructura: el mapeo desde la
// respuesta del backend vive en [AuthenticatedUserDto.toDomain].

/// Usuario autenticado con su token de sesión.
class AuthenticatedUser {
  /// Crea un [AuthenticatedUser] inmutable.
  const AuthenticatedUser({
    required this.id,
    required this.email,
    required this.role,
    required this.token,
  });

  /// Identificador estable del usuario/negocio.
  final Id id;

  /// Email institucional del usuario.
  final String email;

  /// Rol asignado por el backend (BUSINESS, ADMIN, CONSUMER).
  final String role;

  /// Token bearer que autoriza las siguientes peticiones.
  final String token;

  /// Devuelve una copia sobreescribiendo solo los campos provistos.
  AuthenticatedUser copyWith({
    Id? id,
    String? email,
    String? role,
    String? token,
  }) {
    return AuthenticatedUser(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      token: token ?? this.token,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthenticatedUser &&
        other.id == id &&
        other.email == email &&
        other.role == role &&
        other.token == token;
  }

  @override
  int get hashCode => Object.hash(id, email, role, token);

  @override
  String toString() => 'AuthenticatedUser(id: $id, email: $email, role: $role)';
}
