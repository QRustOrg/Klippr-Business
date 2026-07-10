import '../../../shared/data/network/api_client.dart';
import '../../../shared/data/network/result.dart';

class AdminPromotionsWebService {
  AdminPromotionsWebService(this._api);

  final ApiClient _api;

  static const String _base = '/api/admin/promotions';

  /// Lista todas las promociones: GET /api/promotions (body completo).
  Future<Result<dynamic>> getAllPromotions() => _api.get('/api/promotions');

  Future<Result<dynamic>> takedownPromotion(String promotionId) =>
      _api.post('$_base/$promotionId/takedown');

  Future<Result<dynamic>> deletePromotion(String promotionId) =>
      _api.delete('$_base/$promotionId');
}
