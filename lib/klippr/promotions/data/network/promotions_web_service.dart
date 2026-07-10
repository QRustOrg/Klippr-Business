import '../../../shared/data/network/api_client.dart';
import '../../../shared/data/network/result.dart';
import 'requests/create_promotion_request.dart';
import 'requests/update_promotion_request.dart';

// author: Samuel Bonifacio
//
// Cliente concreto de los endpoints de Promotions. Arma las peticiones y
// delega en [ApiClient]; el parseo a modelos vive en el store. Todos
// requieren token (auth: true).

/// Servicio HTTP de Promotions (rutas /api/promotions/*).
class PromotionsWebService {
  /// Crea un [PromotionsWebService] sobre el [ApiClient] compartido.
  PromotionsWebService(this._api);

  final ApiClient _api;

  static const String _base = '/api/promotions';

  /// Crea una promoción.
  Future<Result<dynamic>> create(CreatePromotionRequest body) =>
      _api.post(_base, body: body.toJson());

  /// Lista las promociones de un negocio.
  Future<Result<dynamic>> getByBusiness(String businessId) =>
      _api.get('$_base/businesses/$businessId');

  /// Lista las promociones activas (de todos los negocios).
  Future<Result<dynamic>> getActive() => _api.get('$_base/active');

  /// Obtiene una promoción por id.
  Future<Result<dynamic>> getById(String id) => _api.get('$_base/$id');

  /// Actualiza una promoción.
  Future<Result<dynamic>> update(String id, UpdatePromotionRequest body) =>
      _api.put('$_base/$id', body: body.toJson());

  /// Elimina una promoción.
  Future<Result<dynamic>> delete(String id) => _api.delete('$_base/$id');

  /// Publica una promoción.
  Future<Result<dynamic>> publish(String id) => _api.post('$_base/$id/publish');

  /// Cancela una promoción.
  Future<Result<dynamic>> cancel(String id) => _api.post('$_base/$id/cancel');
}
