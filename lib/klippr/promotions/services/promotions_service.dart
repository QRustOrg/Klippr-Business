import '../../core/network/api_client.dart';
import '../../core/utils/result.dart';
import '../models/promotion_request.dart';

// author: Samuel Bonifacio
//
// Cliente concreto de los endpoints de Promotions. Arma las peticiones y delega
// en ApiClient; el parseo a modelos vive en el repositorio. Todos requieren
// token (auth: true).

/// Servicio HTTP de Promotions (rutas /api/promotions/*).
class PromotionsService {
  PromotionsService(this._api);

  final ApiClient _api;

  static const String _base = '/api/promotions';

  Future<Result<dynamic>> create(CreatePromotionRequest body) =>
      _api.post(_base, body: body.toJson());

  Future<Result<dynamic>> getByBusiness(String businessId) =>
      _api.get('$_base/businesses/$businessId');

  Future<Result<dynamic>> getActive() => _api.get('$_base/active');

  Future<Result<dynamic>> getById(String id) => _api.get('$_base/$id');

  Future<Result<dynamic>> update(String id, UpdatePromotionRequest body) =>
      _api.put('$_base/$id', body: body.toJson());

  Future<Result<dynamic>> delete(String id) => _api.delete('$_base/$id');

  Future<Result<dynamic>> publish(String id, PublishRequest body) =>
      _api.post('$_base/$id/publish', body: body.toJson());

  Future<Result<dynamic>> cancel(String id) => _api.post('$_base/$id/cancel');
}
