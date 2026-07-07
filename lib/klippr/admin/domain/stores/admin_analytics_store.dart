import '../../../shared/data/network/result.dart';
import '../models/admin_analytics.dart';

abstract class AdminAnalyticsStore {
  Future<Result<PlatformAnalytics>> getPlatformAnalytics();
  Future<Result<List<AbuseReport>>> getAbuseReports({String? status});
  Future<Result<void>> updateAbuseReportStatus(String reportId, String status);
}
