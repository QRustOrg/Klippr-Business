import '../../../shared/domain/models/id.dart';

// author: Samuel Bonifacio
//
// Entidad de dominio pura de una promoción y sus enums. Sin anotaciones de
// serialización ni conocimiento del contrato HTTP: el mapeo string<->enum y
// el parseo de fechas viven en [PromotionDto.toDomain].

/// Tipo de descuento de una promoción.
enum DiscountType {
  percentage,
  fixed;

  /// Etiqueta del descuento ("50% OFF" / "S/ 10 OFF").
  String label(double amount) => switch (this) {
        DiscountType.percentage => '${amount.toStringAsFixed(0)}% OFF',
        DiscountType.fixed => 'S/ ${amount.toStringAsFixed(0)} OFF',
      };
}

/// Estado del ciclo de vida de una promoción.
enum PromotionStatus {
  draft,
  published,
  cancelled,
  expired,
  unknown;

  /// Etiqueta legible en español.
  String get label => switch (this) {
        PromotionStatus.draft => 'Borrador',
        PromotionStatus.published => 'Publicada',
        PromotionStatus.cancelled => 'Cancelada',
        PromotionStatus.expired => 'Expirada',
        PromotionStatus.unknown => '—',
      };
}

/// Promoción de un negocio.
class Promotion {
  /// Crea una [Promotion] inmutable.
  const Promotion({
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

  final Id id;
  final Id businessId;
  final String title;
  final String description;
  final double discountAmount;
  final DiscountType discountType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? redemptionCap;
  final String? imageKey;
  final PromotionStatus status;
  final bool isActive;

  /// Etiqueta del descuento ("50% OFF" / "S/ 10 OFF").
  String get discountLabel => discountType.label(discountAmount);

  /// True si ya pasó la fecha de fin.
  bool get isExpired =>
      status == PromotionStatus.expired ||
      (endDate != null && endDate!.isBefore(DateTime.now()));

  /// Devuelve una copia sobreescribiendo solo los campos provistos.
  Promotion copyWith({
    Id? id,
    Id? businessId,
    String? title,
    String? description,
    double? discountAmount,
    DiscountType? discountType,
    DateTime? startDate,
    DateTime? endDate,
    int? redemptionCap,
    String? imageKey,
    PromotionStatus? status,
    bool? isActive,
  }) {
    return Promotion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      title: title ?? this.title,
      description: description ?? this.description,
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      redemptionCap: redemptionCap ?? this.redemptionCap,
      imageKey: imageKey ?? this.imageKey,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Promotion &&
        other.id == id &&
        other.businessId == businessId &&
        other.title == title &&
        other.description == description &&
        other.discountAmount == discountAmount &&
        other.discountType == discountType &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.redemptionCap == redemptionCap &&
        other.imageKey == imageKey &&
        other.status == status &&
        other.isActive == isActive;
  }

  @override
  int get hashCode => Object.hash(
        id,
        businessId,
        title,
        description,
        discountAmount,
        discountType,
        startDate,
        endDate,
        redemptionCap,
        imageKey,
        status,
        isActive,
      );
}
