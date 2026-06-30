import '../../../shared/data/network/api_exceptions.dart';
import '../../../shared/data/network/result.dart';
import '../../domain/stores/analytics_store.dart';
import '../network/analytics_web_service.dart';

// author: Samuel Bonifacio
//
// Adaptador (hexagonal) que implementa el puerto [AnalyticsStore] sobre el
// backend HTTP de Klippr, vía [AnalyticsWebService].

/// Adaptador HTTP del puerto [AnalyticsStore].
class HttpAnalyticsStore implements AnalyticsStore {
  /// Crea un [HttpAnalyticsStore] sobre [_service].
  HttpAnalyticsStore(this._service);

  final AnalyticsWebService _service;

  @override
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
