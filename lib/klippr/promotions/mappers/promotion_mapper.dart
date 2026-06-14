import '../models/promotion.dart';

// author: Samuel Bonifacio
//
// Conversión del JSON decodificado (dynamic) que devuelve ApiClient a modelos
// de dominio de Promotions.

/// Helpers de mapeo de promociones.
class PromotionMapper {
  const PromotionMapper._();

  /// Convierte un objeto JSON en [Promotion].
  static Promotion toPromotion(dynamic json) {
    if (json is Map<String, dynamic>) return Promotion.fromJson(json);
    return Promotion.fromJson(<String, dynamic>{});
  }

  /// Convierte un array JSON en lista de [Promotion].
  static List<Promotion> toPromotionList(dynamic json) {
    if (json is List) {
      return json
          .whereType<Map<String, dynamic>>()
          .map(Promotion.fromJson)
          .toList();
    }
    return const [];
  }
}
