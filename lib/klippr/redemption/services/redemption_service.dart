import '../../core/network/api_client.dart';
import '../../core/utils/result.dart';

class RedemptionService {
  RedemptionService(this._api);
  final ApiClient _api;
  static const String _base = '/api/redemptions';

  Future<Result<dynamic>> lookupByToken(String uniqueToken) =>
      _api.get('$_base/tokens/$uniqueToken');

  Future<Result<dynamic>> confirmByToken(String uniqueToken) =>
      _api.post('$_base/tokens/$uniqueToken/confirm');

  Future<Result<dynamic>> loadByPromotion(String promotionId) =>
      _api.get('/api/promotions/$promotionId/redemptions');
}
