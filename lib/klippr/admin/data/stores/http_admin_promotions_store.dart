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
      onSuccess: (json) {
        if (json is List) {
          final promotions = json
              .whereType<Map<String, dynamic>>()
              .map(AdminPromotion.fromJson)
              .toList();
          return Success<List<AdminPromotion>>(promotions);
        }
        return const Success<List<AdminPromotion>>([]);
      },
      onFailure: (e) => Failure<List<AdminPromotion>>(e),
    );
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
