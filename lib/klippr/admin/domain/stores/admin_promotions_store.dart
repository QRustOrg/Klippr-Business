import '../../../shared/data/network/result.dart';
import '../models/admin_promotion.dart';

abstract class AdminPromotionsStore {
  Future<Result<List<AdminPromotion>>> getAllPromotions();
  Future<Result<void>> takedownPromotion(String promotionId);
  Future<Result<void>> deletePromotion(String promotionId);
}
