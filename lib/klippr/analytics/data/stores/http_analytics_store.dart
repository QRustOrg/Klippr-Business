import '../../../shared/data/network/api_exceptions.dart';
import '../../../shared/data/network/result.dart';
import '../../domain/stores/analytics_store.dart';
import '../../domain/models/business_dashboard_metrics.dart';
import '../../models/campaign_metrics.dart';
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
  Future<Result<BusinessDashboardMetrics>> loadDashboard(
    String businessId,
  ) async {
    final res = await _service.getDashboard(businessId);
    return res.when(
      onSuccess: (json) {
        if (json is Map<String, dynamic>) {
          return Success<BusinessDashboardMetrics>(
            BusinessDashboardMetrics.fromJson(json),
          );
        }
        return const Success<BusinessDashboardMetrics>(
          BusinessDashboardMetrics(
            businessId: '',
            totalPromotions: 0,
            activePromotions: 0,
            totalRedemptions: 0,
            usedRedemptions: 0,
            views: 0,
            averageRating: 0,
          ),
        );
      },
      onFailure: (error) => Failure<BusinessDashboardMetrics>(error),
    );
  }

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

  @override
  Future<Result<CampaignMetrics>> loadCampaignMetrics(String campaignId) async {
    final res = await _service.getCampaignMetrics(campaignId);
    return res.when(
      onSuccess: (json) {
        if (json is Map<String, dynamic>) {
          return Success<CampaignMetrics>(CampaignMetrics.fromJson(json));
        }
        return const Success<CampaignMetrics>(
          CampaignMetrics(
            campaignId: '',
            businessId: '',
            views: 0,
            redemptions: 0,
            averageRating: 0,
            conversionRate: 0,
          ),
        );
      },
      onFailure: (error) => Failure<CampaignMetrics>(error),
    );
  }

  @override
  Future<Result<void>> updateMetrics({
    required String businessId,
    String? campaignId,
    int? viewsToAdd,
    int? redemptionsToAdd,
    double? newRating,
  }) async {
    final res = await _service.updateMetrics({
      'campaignId': campaignId,
      'businessId': businessId,
      'viewsToAdd': viewsToAdd,
      'redemptionsToAdd': redemptionsToAdd,
      'newRating': newRating,
    });
    return res.when(
      onSuccess: (_) => const Success<void>(null),
      onFailure: (error) => Failure<void>(error),
    );
  }
}
