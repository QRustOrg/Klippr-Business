import '../../../domain/models/promotion.dart';
import '../../models/promotion_dto.dart';

// author: Samuel Bonifacio
//
// Cuerpo de POST /api/promotions. Casing exacto del backend; fechas en
// ISO-8601 (UTC).

/// Petición de creación de una promoción.
class CreatePromotionRequest {
  /// Crea un [CreatePromotionRequest].
  const CreatePromotionRequest({
    required this.businessId,
    required this.title,
    required this.description,
    required this.discountAmount,
    required this.discountType,
    required this.startDate,
    required this.endDate,
    required this.imageKey,
    this.redemptionCap,
  });

  final String businessId;
  final String title;
  final String description;
  final double discountAmount;
  final DiscountType discountType;
  final DateTime startDate;
  final DateTime endDate;
  final String imageKey;
  final int? redemptionCap;

  /// Serializa esta petición a un mapa JSON-compatible.
  Map<String, dynamic> toJson() => {
        'businessId': businessId,
        'title': title,
        'description': description,
        'discountAmount': discountAmount,
        'discountType': discountType.api,
        'startDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate.toUtc().toIso8601String(),
        'imageKey': imageKey,
        if (redemptionCap != null) 'redemptionCap': redemptionCap,
      };
}
