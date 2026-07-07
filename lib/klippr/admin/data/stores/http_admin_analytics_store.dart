import '../../../shared/data/network/result.dart';
import '../../domain/models/admin_analytics.dart';
import '../../domain/stores/admin_analytics_store.dart';
import '../network/admin_analytics_web_service.dart';

class HttpAdminAnalyticsStore implements AdminAnalyticsStore {
  HttpAdminAnalyticsStore(this._service);

  final AdminAnalyticsWebService _service;

  @override
  Future<Result<PlatformAnalytics>> getPlatformAnalytics() async {
    final res = await _service.getPlatformAnalytics();
    return res.when(
      onSuccess: (json) {
        if (json is Map<String, dynamic>) {
          return Success<PlatformAnalytics>(PlatformAnalytics.fromJson(json));
        }
        return const Success<PlatformAnalytics>(PlatformAnalytics());
      },
      onFailure: (e) => Failure<PlatformAnalytics>(e),
    );
  }

  @override
  Future<Result<List<AbuseReport>>> getAbuseReports({String? status}) async {
    final res = await _service.getAbuseReports(status: status);
    return res.when(
      onSuccess: (json) {
        if (json is List) {
          final reports = json
              .whereType<Map<String, dynamic>>()
              .map(AbuseReport.fromJson)
              .toList();
          return Success<List<AbuseReport>>(reports);
        }
        return const Success<List<AbuseReport>>([]);
      },
      onFailure: (e) => Failure<List<AbuseReport>>(e),
    );
  }

  @override
  Future<Result<void>> updateAbuseReportStatus(
    String reportId,
    String status,
  ) async {
    final res = await _service.updateAbuseReportStatus(reportId, status);
    return res.when(
      onSuccess: (_) => const Success<void>(null),
      onFailure: (e) => Failure<void>(e),
    );
  }
}
