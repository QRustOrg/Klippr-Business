import '../../../shared/domain/models/id.dart';
import '../../domain/models/promotion.dart';

// author: Samuel Bonifacio
//
// DTO que refleja `PromotionResource` del backend. Fechas llegan como String
// ISO-8601; el mapeo string<->enum y el parseo de fechas ocurren solo aquí,
// en [toDomain] — la entidad de dominio pura nunca ve estos formatos crudos.

/// DTO de una promoción tal como la devuelve el backend.
class PromotionDto {
  /// Crea un [PromotionDto].
  const PromotionDto({
    required this.id,
    required this.businessId,
    required this.title,
    required this.description,
    required this.discountAmount,
    required this.discountType,
    required this.startDate,
    required this.endDate,
    this.redemptionCap,
    this.imageKey,
    required this.status,
    required this.isActive,
  });

  final String id;
  final String businessId;
  final String title;
  final String description;
  final double discountAmount;
  final String discountType;
  final String? startDate;
  final String? endDate;
  final int? redemptionCap;
  final String? imageKey;
  final String status;
  final bool isActive;

  /// Construye un [PromotionDto] desde un mapa JSON decodificado.
  factory PromotionDto.fromJson(Map<String, dynamic> json) {
    return PromotionDto(
      id: json['id'] as String? ?? '',
      businessId: json['businessId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      discountType: json['discountType'] as String? ?? '',
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      redemptionCap: (json['redemptionCap'] as num?)?.toInt(),
      imageKey: json['imageKey'] as String?,
      status: json['status'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  /// Proyecta este DTO a la entidad de dominio pura [Promotion].
  Promotion toDomain() {
    return Promotion(
      id: Id(id),
      businessId: Id(businessId),
      title: title,
      description: description,
      discountAmount: discountAmount,
      discountType: _parseDiscountType(discountType),
      startDate: startDate != null ? DateTime.tryParse(startDate!) : null,
      endDate: endDate != null ? DateTime.tryParse(endDate!) : null,
      redemptionCap: redemptionCap,
      imageKey: imageKey,
      status: _parseStatus(status),
      isActive: isActive,
    );
  }

  static DiscountType _parseDiscountType(String? raw) {
    return switch ((raw ?? '').toLowerCase()) {
      'fixed' => DiscountType.fixed,
      _ => DiscountType.percentage,
    };
  }

  static PromotionStatus _parseStatus(String? raw) {
    return switch ((raw ?? '').toLowerCase()) {
      'draft' => PromotionStatus.draft,
      'published' => PromotionStatus.published,
      'cancelled' || 'canceled' => PromotionStatus.cancelled,
      'expired' => PromotionStatus.expired,
      _ => PromotionStatus.unknown,
    };
  }
}

/// Helpers de mapeo dominio -> contrato HTTP (valor exacto que espera el
/// backend en el body de creación/actualización).
extension DiscountTypeApi on DiscountType {
  /// Valor exacto que espera el backend en el body.
  String get api => switch (this) {
        DiscountType.percentage => 'PERCENTAGE',
        DiscountType.fixed => 'FIXED',
      };
}
