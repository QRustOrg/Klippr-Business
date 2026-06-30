import '../../../shared/domain/models/id.dart';
import '../../domain/models/redemption.dart';

// author: Samuel Bonifacio
//
// DTO que refleja `RedemptionResource` del backend (campos `consumerId`,
// `generatedAt`, `redeemedAt`). El mapeo a dominio ocurre solo en [toDomain].
//
// NOTA: el modelo legado tenía un segundo camino de mapeo (`fromJson`, con
// nombres de campo distintos: `customerId`, `createdAt`) que el repositorio
// nunca invocaba en producción — solo se usaba `fromBackendJson`. Esta clase
// replica fielmente ese único camino real para no alterar el comportamiento.

/// DTO de una redención tal como la devuelve el backend.
class RedemptionDto {
  /// Crea un [RedemptionDto].
  const RedemptionDto({
    required this.id,
    required this.promotionId,
    required this.promotionTitle,
    required this.consumerId,
    required this.customerName,
    required this.uniqueToken,
    required this.code,
    required this.status,
    required this.validationMethod,
    required this.discountAppliedAmount,
    required this.generatedAt,
    this.redeemedAt,
    this.expiresAt,
    this.blockedAt,
  });

  final String id;
  final String promotionId;
  final String promotionTitle;
  final String consumerId;
  final String customerName;
  final String uniqueToken;
  final String code;
  final String status;
  final String validationMethod;
  final double discountAppliedAmount;
  final String? generatedAt;
  final String? redeemedAt;
  final String? expiresAt;
  final String? blockedAt;

  /// Construye un [RedemptionDto] desde un mapa JSON decodificado.
  factory RedemptionDto.fromJson(Map<String, dynamic> json) {
    return RedemptionDto(
      id: json['id']?.toString() ?? '',
      promotionId: json['promotionId']?.toString() ?? '',
      promotionTitle: json['promotionTitle']?.toString() ?? '',
      consumerId: json['consumerId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      uniqueToken: json['uniqueToken']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      validationMethod: json['validationMethod']?.toString() ?? '',
      discountAppliedAmount:
          (json['discountAppliedAmount'] as num?)?.toDouble() ?? 0,
      generatedAt: json['generatedAt'] as String?,
      redeemedAt: json['redeemedAt'] as String?,
      expiresAt: json['expiresAt'] as String?,
      blockedAt: json['blockedAt'] as String?,
    );
  }

  /// Proyecta este DTO a la entidad de dominio pura [Redemption].
  Redemption toDomain() {
    return Redemption(
      id: Id(id),
      promotionId: Id(promotionId),
      promotionTitle: promotionTitle,
      customerId: Id(consumerId),
      customerName: customerName,
      uniqueToken: uniqueToken,
      code: code,
      status: _parseStatus(status),
      validationMethod: validationMethod,
      discountAppliedAmount: discountAppliedAmount,
      createdAt: DateTime.tryParse(generatedAt ?? '') ?? DateTime.now(),
      confirmedAt: redeemedAt != null ? DateTime.tryParse(redeemedAt!) : null,
      expiresAt: expiresAt != null ? DateTime.tryParse(expiresAt!) : null,
      blockedAt: blockedAt != null ? DateTime.tryParse(blockedAt!) : null,
    );
  }

  static RedemptionTokenStatus _parseStatus(String? raw) {
    return switch ((raw ?? '').toLowerCase()) {
      'redeemed' => RedemptionTokenStatus.confirmed,
      'generated' => RedemptionTokenStatus.pending,
      'blocked' => RedemptionTokenStatus.expired,
      'expired' => RedemptionTokenStatus.expired,
      _ => RedemptionTokenStatus.unknown,
    };
  }
}
