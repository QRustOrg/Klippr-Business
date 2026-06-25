import '../../core/network/api_exceptions.dart';
import '../../core/utils/result.dart';
import '../models/campaign_metrics.dart';
import '../services/analytics_service.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._service);

  final AnalyticsService _service;

  Future<Result<int>> loadPromotionRedemptions(String promotionId) async {
    final res = await _service.getCampaignMetrics(promotionId);
    return res.when(
      onSuccess: (json) {
        if (json is Map<String, dynamic>) {
          return Success<int>(CampaignMetrics.fromJson(json).redemptions);
        }
        return const Failure<int>(ParseException());
      },
      onFailure: (error) {
        if (error is NotFoundException) return const Success<int>(0);
        return Failure<int>(error);
      },
    );
  }
}
