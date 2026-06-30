import '../../../shared/data/network/api_client.dart';
import '../../../shared/data/network/result.dart';

// author: Samuel Bonifacio
//
// Cliente concreto de los endpoints de Analytics. Arma las peticiones y
// delega en [ApiClient]; el parseo a modelos vive en el store.

/// Servicio HTTP de Analytics (rutas /api/analytics/*, /api/redemptions/*).
class AnalyticsWebService {
  /// Crea un [AnalyticsWebService] sobre el [ApiClient] compartido.
  AnalyticsWebService(this._api);

  final ApiClient _api;

  static const String _base = '/api/analytics';
  static const String _redemptionsBase = '/api/redemptions';

  /// Obtiene las métricas de una campaña.
  Future<Result<dynamic>> getCampaignMetrics(String campaignId) =>
      _api.get('$_base/campaign/$campaignId');

  /// Lista las redenciones de un negocio (usado para contar por promoción).
  Future<Result<dynamic>> getRedemptionsByBusiness(String businessId) =>
      _api.get('$_redemptionsBase/businesses/$businessId');
}
