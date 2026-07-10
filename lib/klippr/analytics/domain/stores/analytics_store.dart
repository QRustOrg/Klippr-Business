// NOTA: [Result]/[ApiException] viven en shared/data/network por decision
// consciente (se mantuvo Result<T> en vez de migrar a excepciones); es la
// unica concesion a la pureza hexagonal estricta en este puerto.

import '../../../shared/data/network/result.dart';
import '../models/business_dashboard_metrics.dart';
import '../../models/campaign_metrics.dart';

// author: Samuel Bonifacio
//
// Puerto (hexagonal) que describe las capacidades de analítica que necesita
// la capa de aplicación. Agnóstico del origen de datos concreto; el
// adaptador HTTP vive en `data/stores/`.

/// Puerto de analítica del bounded context Analytics.
abstract interface class AnalyticsStore {
  /// Obtiene el dashboard agregado del negocio.
  Future<Result<BusinessDashboardMetrics>> loadDashboard(String businessId);

  /// Cuenta las redenciones confirmadas de una promoción de un negocio.
  Future<Result<int>> loadPromotionRedemptions(
    String businessId,
    String promotionId,
  );

  /// Cuenta redenciones confirmadas agrupadas por `promotionId` para un negocio.
  ///
  /// Una sola llamada de red; útil para el dashboard (total + por promo).
  Future<Result<Map<String, int>>> loadPromotionRedemptionCounts(
    String businessId,
  );

  /// Obtiene métricas de una campaña/promoción concreta.
  Future<Result<CampaignMetrics>> loadCampaignMetrics(String campaignId);

  /// Actualiza métricas agregadas cuando exista un flujo claro que lo invoque.
  Future<Result<void>> updateMetrics({
    required String businessId,
    String? campaignId,
    int? viewsToAdd,
    int? redemptionsToAdd,
    double? newRating,
  });
}
