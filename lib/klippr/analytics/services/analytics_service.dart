import '../../core/network/api_client.dart';
import '../../core/utils/result.dart';

class AnalyticsService {
  AnalyticsService(this._api);

  final ApiClient _api;

  static const String _base = '/api/analytics';
  static const String _redemptionsBase = '/api/redemptions';

  Future<Result<dynamic>> getCampaignMetrics(String campaignId) =>
      _api.get('$_base/campaign/$campaignId');

  Future<Result<dynamic>> getRedemptionsByBusiness(String businessId) =>
      _api.get('$_redemptionsBase/businesses/$businessId');
}
