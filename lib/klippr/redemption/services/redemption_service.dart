import '../../core/network/api_client.dart';
import '../../core/utils/result.dart';

class RedemptionService {
  RedemptionService(this._api);
  final ApiClient _api;
  static const String _base = '/api/redemptions';

  Future<Result<dynamic>> getRedemptionsByBusiness(String businessId) =>
      _api.get('$_base/businesses/$businessId');

  Future<Result<dynamic>> confirmByToken(String uniqueToken) =>
      _api.post('$_base/tokens/$uniqueToken/confirm');
}
