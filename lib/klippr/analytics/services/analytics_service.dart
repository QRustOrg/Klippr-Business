import '../../core/network/api_client.dart';
import '../../core/utils/result.dart';

class AnalyticsService {
  AnalyticsService(this._api);

  final ApiClient _api;

  static const String _base = '/api/analytics';

  Future<Result<dynamic>> getCampaignMetrics(String campaignId) =>
      _api.get('$_base/campaign/$campaignId');
}
