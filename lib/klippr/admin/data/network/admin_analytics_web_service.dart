import '../../../shared/data/network/api_client.dart';
import '../../../shared/data/network/result.dart';

class AdminAnalyticsWebService {
  AdminAnalyticsWebService(this._api);

  final ApiClient _api;

  static const String _base = '/api/admin/analytics';

  Future<Result<dynamic>> getPlatformAnalytics() =>
      _api.get('$_base/platform');

  Future<Result<dynamic>> getAbuseReports({String? status}) =>
      _api.get(
        '$_base/abuse-reports',
        query: status != null ? {'status': status} : null,
      );

  Future<Result<dynamic>> updateAbuseReportStatus(
    String reportId,
    String status,
  ) =>
      _api.put(
        '$_base/abuse-reports/$reportId/status',
        body: {'status': status},
      );
}
