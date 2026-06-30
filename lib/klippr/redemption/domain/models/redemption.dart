import '../../../shared/domain/models/id.dart';

// author: Samuel Bonifacio
//
// Entidad de dominio pura de una redención. Sin anotaciones de
// serialización: el mapeo string<->enum y el parseo de fechas viven en
// [RedemptionDto.toDomain].

/// Estado del token de redención.
enum RedemptionTokenStatus {
  pending,
  confirmed,
  expired,
  unknown;

  /// Etiqueta legible en español.
  String get label => switch (this) {
        RedemptionTokenStatus.pending => 'Pendiente',
        RedemptionTokenStatus.confirmed => 'Confirmado',
        RedemptionTokenStatus.expired => 'Expirado',
        RedemptionTokenStatus.unknown => 'Desconocido',
      };
}

/// Redención de una promoción por parte de un cliente.
class Redemption {
  /// Crea un [Redemption] inmutable.
  const Redemption({
    required this.id,
    required this.promotionId,
    required this.promotionTitle,
    required this.customerId,
    required this.customerName,
    required this.uniqueToken,
    required this.code,
    required this.status,
    required this.validationMethod,
    required this.discountAppliedAmount,
    required this.createdAt,
    this.confirmedAt,
    this.expiresAt,
    this.blockedAt,
  });

  final Id id;
  final Id promotionId;
  final String promotionTitle;
  final Id customerId;
  final String customerName;
  final String uniqueToken;
  final String code;
  final RedemptionTokenStatus status;
  final String validationMethod;
  final double discountAppliedAmount;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? expiresAt;
  final DateTime? blockedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Redemption &&
        other.id == id &&
        other.promotionId == promotionId &&
        other.promotionTitle == promotionTitle &&
        other.customerId == customerId &&
        other.customerName == customerName &&
        other.uniqueToken == uniqueToken &&
        other.code == code &&
        other.status == status &&
        other.validationMethod == validationMethod &&
        other.discountAppliedAmount == discountAppliedAmount &&
        other.createdAt == createdAt &&
        other.confirmedAt == confirmedAt &&
        other.expiresAt == expiresAt &&
        other.blockedAt == blockedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        promotionId,
        promotionTitle,
        customerId,
        customerName,
        uniqueToken,
        code,
        status,
        validationMethod,
        discountAppliedAmount,
        createdAt,
        confirmedAt,
        expiresAt,
        blockedAt,
      );
}
