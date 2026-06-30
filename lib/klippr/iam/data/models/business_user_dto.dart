import '../../../shared/domain/models/id.dart';
import '../../domain/models/business_user.dart';

// author: Samuel Bonifacio
//
// DTO que refleja la respuesta de sign-up/business (`UserResource`, 201): crea
// el usuario pero NO devuelve token. El mapeo a dominio ocurre solo en
// [toDomain].

/// DTO de la respuesta de registro de negocio (sin token).
class BusinessUserDto {
  /// Crea un [BusinessUserDto].
  const BusinessUserDto({
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

  /// Construye un [BusinessUserDto] desde un mapa JSON decodificado.
  factory BusinessUserDto.fromJson(Map<String, dynamic> json) {
    return BusinessUserDto(
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      businessName: json['businessName'] as String?,
      taxId: json['taxId'] as String?,
    );
  }

  /// Proyecta este DTO a la entidad de dominio pura [BusinessUser].
  BusinessUser toDomain() {
    return BusinessUser(
      id: Id(userId),
      email: email,
      role: role,
      businessName: businessName,
      taxId: taxId,
    );
  }
}
