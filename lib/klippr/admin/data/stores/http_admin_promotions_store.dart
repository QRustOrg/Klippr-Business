import '../../../shared/data/network/result.dart';
import '../../domain/models/admin_promotion.dart';
import '../../domain/stores/admin_promotions_store.dart';
import '../network/admin_promotions_web_service.dart';

class HttpAdminPromotionsStore implements AdminPromotionsStore {
  HttpAdminPromotionsStore(this._service);

  final AdminPromotionsWebService _service;

  @override
  Future<Result<List<AdminPromotion>>> getAllPromotions() async {
    final res = await _service.getAllPromotions();
    return res.when(
      onSuccess: (json) =>
          Success<List<AdminPromotion>>(_toPromotionList(json)),
      onFailure: (e) => Failure<List<AdminPromotion>>(e),
    );
  }

  /// Parsea el body completo de GET /api/promotions (lista o wrapper).
  List<AdminPromotion> _toPromotionList(dynamic json) {
    if (json is List) {
      return json
          .map((item) {
            if (item is Map<String, dynamic>) {
              return AdminPromotion.fromJson(item);
            }
            if (item is Map) {
              return AdminPromotion.fromJson(Map<String, dynamic>.from(item));
            }
            return null;
          })
          .whereType<AdminPromotion>()
          .toList(growable: false);
    }
    if (json is Map) {
      final map = json is Map<String, dynamic>
          ? json
          : Map<String, dynamic>.from(json);
      for (final key in const ['data', 'items', 'content', 'promotions']) {
        final nested = map[key];
        if (nested is List) return _toPromotionList(nested);
      }
    }
    return const [];
  }

  @override
  Future<Result<void>> takedownPromotion(String promotionId) async {
    final res = await _service.takedownPromotion(promotionId);
    return res.when(
      onSuccess: (_) => const Success<void>(null),
      onFailure: (e) => Failure<void>(e),
    );
  }

  @override
  Future<Result<void>> deletePromotion(String promotionId) async {
    final res = await _service.deletePromotion(promotionId);
    return res.when(
      onSuccess: (_) => const Success<void>(null),
      onFailure: (e) => Failure<void>(e),
    );
  }
}
