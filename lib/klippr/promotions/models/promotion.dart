// author: Samuel Bonifacio
//
// Modelo de dominio de una promoción (refleja `PromotionResource` del backend)
// y sus enums. Fechas llegan como String ISO-8601; se parsean a DateTime.

/// Tipo de descuento.
enum DiscountType {
  percentage,
  fixed;

  /// Valor exacto que espera el backend en el body.
  String get api => switch (this) {
        DiscountType.percentage => 'PERCENTAGE',
        DiscountType.fixed => 'FIXED',
      };

  /// Parsea el valor devuelto por el backend ("Percentage"/"Fixed").
  static DiscountType parse(String? raw) {
    return switch ((raw ?? '').toLowerCase()) {
      'fixed' => DiscountType.fixed,
      _ => DiscountType.percentage,
    };
  }
}

/// Estado de la promoción.
enum PromotionStatus {
  draft,
  published,
  cancelled,
  expired,
  unknown;

  static PromotionStatus parse(String? raw) {
    return switch ((raw ?? '').toLowerCase()) {
      'draft' => PromotionStatus.draft,
      'published' => PromotionStatus.published,
      'cancelled' || 'canceled' => PromotionStatus.cancelled,
      'expired' => PromotionStatus.expired,
      _ => PromotionStatus.unknown,
    };
  }

  /// Etiqueta legible en español.
  String get label => switch (this) {
        PromotionStatus.draft => 'Borrador',
        PromotionStatus.published => 'Publicada',
        PromotionStatus.cancelled => 'Cancelada',
        PromotionStatus.expired => 'Expirada',
        PromotionStatus.unknown => '—',
      };
}

/// Promoción del negocio.
class Promotion {
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
    required this.status,
    required this.isActive,
  });

  final String id;
  final String businessId;
  final String title;
  final String description;
  final double discountAmount;
  final DiscountType discountType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? redemptionCap;
  final PromotionStatus status;
  final bool isActive;

  /// Etiqueta del descuento ("50% OFF" / "S/ 10 OFF").
  String get discountLabel => switch (discountType) {
        DiscountType.percentage => '${discountAmount.toStringAsFixed(0)}% OFF',
        DiscountType.fixed => 'S/ ${discountAmount.toStringAsFixed(0)} OFF',
      };

  /// True si ya pasó la fecha de fin.
  bool get isExpired =>
      status == PromotionStatus.expired ||
      (endDate != null && endDate!.isBefore(DateTime.now()));

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] as String? ?? '',
      businessId: json['businessId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      discountType: DiscountType.parse(json['discountType'] as String?),
      startDate: DateTime.tryParse(json['startDate'] as String? ?? ''),
      endDate: DateTime.tryParse(json['endDate'] as String? ?? ''),
      redemptionCap: (json['redemptionCap'] as num?)?.toInt(),
      status: PromotionStatus.parse(json['status'] as String?),
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}
