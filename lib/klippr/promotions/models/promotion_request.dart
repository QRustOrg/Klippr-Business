import 'promotion.dart';

// author: Samuel Bonifacio
//
// Cuerpos de las peticiones de Promotions. Casing exacto del backend; fechas en
// ISO-8601 (UTC).

/// Cuerpo de POST /api/promotions.
class CreatePromotionRequest {
  const CreatePromotionRequest({
    required this.businessId,
    required this.title,
    required this.description,
    required this.discountAmount,
    required this.discountType,
    required this.startDate,
    required this.endDate,
    this.redemptionCap,
  });

  final String businessId;
  final String title;
  final String description;
  final double discountAmount;
  final DiscountType discountType;
  final DateTime startDate;
  final DateTime endDate;
  final int? redemptionCap;

  Map<String, dynamic> toJson() => {
        'businessId': businessId,
        'title': title,
        'description': description,
        'discountAmount': discountAmount,
        'discountType': discountType.api,
        'startDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate.toUtc().toIso8601String(),
        if (redemptionCap != null) 'redemptionCap': redemptionCap,
      };
}

/// Cuerpo de PUT /api/promotions/{id} (igual a crear, sin businessId).
class UpdatePromotionRequest {
  const UpdatePromotionRequest({
    required this.title,
    required this.description,
    required this.discountAmount,
    required this.discountType,
    required this.startDate,
    required this.endDate,
    this.redemptionCap,
  });

  final String title;
  final String description;
  final double discountAmount;
  final DiscountType discountType;
  final DateTime startDate;
  final DateTime endDate;
  final int? redemptionCap;

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'discountAmount': discountAmount,
        'discountType': discountType.api,
        'startDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate.toUtc().toIso8601String(),
        if (redemptionCap != null) 'redemptionCap': redemptionCap,
      };
}

/// Cuerpo de POST /api/promotions/{id}/publish.
class PublishRequest {
  const PublishRequest({required this.isBusinessVerified});

  final bool isBusinessVerified;

  Map<String, dynamic> toJson() => {'isBusinessVerified': isBusinessVerified};
}
