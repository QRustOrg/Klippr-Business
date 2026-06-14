import '../../core/network/api_exceptions.dart';
import '../../core/prefs/prefs_helper.dart';
import '../../core/utils/result.dart';
import '../mappers/promotion_mapper.dart';
import '../models/promotion.dart';
import '../models/promotion_request.dart';
import '../services/promotions_service.dart';

// author: Samuel Bonifacio
//
// Repositorio de Promotions: abstrae el origen de datos para el BLoC. Inyecta el
// businessId (== userId persistido) en las operaciones que lo requieren y parsea
// las respuestas a modelos.

/// Coordina las operaciones de promociones contra el backend.
class PromotionsRepository {
  PromotionsRepository(this._service, {PrefsHelper? prefs})
      : _prefs = prefs ?? PrefsHelper.instance;

  final PromotionsService _service;
  final PrefsHelper _prefs;

  /// businessId del negocio autenticado (== userId del sign-in).
  String? get businessId => _prefs.userId;

  /// Lista las promociones del negocio autenticado.
  Future<Result<List<Promotion>>> loadMine() async {
    final id = businessId;
    if (id == null || id.isEmpty) {
      return const Failure(UnauthorizedException('Sesión no disponible.'));
    }
    final res = await _service.getByBusiness(id);
    return res.when(
      onSuccess: (json) =>
          Success<List<Promotion>>(PromotionMapper.toPromotionList(json)),
      onFailure: (e) => Failure<List<Promotion>>(e),
    );
  }

  /// Crea una promoción. Inyecta el businessId. Devuelve el id creado.
  Future<Result<String>> create({
    required String title,
    required String description,
    required double discountAmount,
    required DiscountType discountType,
    required DateTime startDate,
    required DateTime endDate,
    int? redemptionCap,
  }) async {
    final id = businessId;
    if (id == null || id.isEmpty) {
      return const Failure(UnauthorizedException('Sesión no disponible.'));
    }
    final res = await _service.create(
      CreatePromotionRequest(
        businessId: id,
        title: title,
        description: description,
        discountAmount: discountAmount,
        discountType: discountType,
        startDate: startDate,
        endDate: endDate,
        redemptionCap: redemptionCap,
      ),
    );
    return res.when(
      onSuccess: (json) {
        final newId =
            json is Map<String, dynamic> ? json['promotionId'] as String? : null;
        return Success<String>(newId ?? '');
      },
      onFailure: (e) => Failure<String>(e),
    );
  }

  /// Actualiza una promoción existente.
  Future<Result<void>> update(
    String id, {
    required String title,
    required String description,
    required double discountAmount,
    required DiscountType discountType,
    required DateTime startDate,
    required DateTime endDate,
    int? redemptionCap,
  }) async {
    final res = await _service.update(
      id,
      UpdatePromotionRequest(
        title: title,
        description: description,
        discountAmount: discountAmount,
        discountType: discountType,
        startDate: startDate,
        endDate: endDate,
        redemptionCap: redemptionCap,
      ),
    );
    return _toVoid(res);
  }

  /// Elimina una promoción.
  Future<Result<void>> delete(String id) async => _toVoid(await _service.delete(id));

  /// Publica una promoción (requiere negocio verificado).
  Future<Result<void>> publish(String id, {bool isBusinessVerified = true}) async {
    final res =
        await _service.publish(id, PublishRequest(isBusinessVerified: isBusinessVerified));
    return _toVoid(res);
  }

  /// Cancela una promoción (conserva las redenciones existentes).
  Future<Result<void>> cancel(String id) async => _toVoid(await _service.cancel(id));

  Result<void> _toVoid(Result<dynamic> res) => res.when(
        onSuccess: (_) => const Success<void>(null),
        onFailure: (e) => Failure<void>(e),
      );
}
