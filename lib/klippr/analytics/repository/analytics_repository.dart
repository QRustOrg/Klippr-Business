import '../../core/network/api_exceptions.dart';
import '../../core/utils/result.dart';
import '../services/analytics_service.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._service);

  final AnalyticsService _service;

  Future<Result<int>> loadPromotionRedemptions(
    String businessId,
    String promotionId,
  ) async {
    final res = await _service.getRedemptionsByBusiness(businessId);
    return res.when(
      onSuccess: (json) {
        if (json is List) {
          final count = json.where((item) {
            if (item is! Map<String, dynamic>) return false;
            final pid = item['promotionId']?.toString() ?? '';
            final status = item['status']?.toString() ?? '';
            return pid == promotionId && status == 'Redeemed';
          }).length;
          return Success<int>(count);
        }
        return const Success<int>(0);
      },
      onFailure: (error) {
        if (error is NotFoundException) return const Success<int>(0);
        return Failure<int>(error);
      },
    );
  }
}
