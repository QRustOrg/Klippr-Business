import '../../../shared/data/network/api_client.dart';
import '../../../shared/data/network/result.dart';

// author: Samuel Bonifacio
//
// Cliente concreto de los endpoints de Redemption. Arma las peticiones y
// delega en [ApiClient]; el parseo a modelos vive en el store.

/// Servicio HTTP de Redemption (rutas /api/redemptions/*).
class RedemptionWebService {
  /// Crea un [RedemptionWebService] sobre el [ApiClient] compartido.
  RedemptionWebService(this._api);

  final ApiClient _api;

  static const String _base = '/api/redemptions';

  /// Lista las redenciones de un negocio.
  Future<Result<dynamic>> getRedemptionsByBusiness(String businessId) =>
      _api.get('$_base/businesses/$businessId');

  /// Confirma una redención por su token único.
  Future<Result<dynamic>> confirmByToken(String uniqueToken) =>
      _api.post('$_base/tokens/$uniqueToken/confirm');
}
