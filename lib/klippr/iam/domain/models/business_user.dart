import '../../../shared/domain/models/id.dart';

// author: Samuel Bonifacio
//
// Entidad de dominio pura que representa el perfil de un negocio recién
// registrado (respuesta del alta, sin token). Mapeada desde
// [BusinessUserDto.toDomain].

/// Negocio registrado en el sistema.
class BusinessUser {
  /// Crea un [BusinessUser] inmutable.
  const BusinessUser({
    required this.id,
    required this.email,
    required this.role,
    this.businessName,
    this.taxId,
  });

  /// Identificador estable del negocio.
  final Id id;

  /// Email institucional del negocio.
  final String email;

  /// Rol asignado por el backend.
  final String role;

  /// Nombre comercial del negocio.
  final String? businessName;

  /// RUC/identificador tributario del negocio.
  final String? taxId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusinessUser &&
        other.id == id &&
        other.email == email &&
        other.role == role &&
        other.businessName == businessName &&
        other.taxId == taxId;
  }

  @override
  int get hashCode => Object.hash(id, email, role, businessName, taxId);
}
