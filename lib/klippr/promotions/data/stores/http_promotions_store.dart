import '../../../shared/data/network/api_exceptions.dart';
import '../../../shared/data/network/result.dart';
import '../../../shared/data/pref/prefs_helper.dart';
import '../../domain/models/promotion.dart';
import '../../domain/stores/promotions_store.dart';
import '../models/promotion_dto.dart';
import '../network/promotions_web_service.dart';
import '../network/requests/create_promotion_request.dart';
import '../network/requests/publish_request.dart';
import '../network/requests/update_promotion_request.dart';

// author: Samuel Bonifacio
//
// Adaptador (hexagonal) que implementa el puerto [PromotionsStore] sobre el
// backend HTTP de Klippr, vía [PromotionsWebService]. Parsea las respuestas a
// entidades de dominio puras.

/// Adaptador HTTP del puerto [PromotionsStore].
class HttpPromotionsStore implements PromotionsStore {
  /// Crea un [HttpPromotionsStore] sobre [_service].
  HttpPromotionsStore(this._service, {PrefsHelper? prefs})
      : _prefs = prefs ?? PrefsHelper.instance;

  final PromotionsWebService _service;
  final PrefsHelper _prefs;

  String? get _businessId => _prefs.profileId ?? _prefs.userId;

  @override
  Future<Result<List<Promotion>>> loadMine() async {
    final id = _businessId;
    if (id == null || id.isEmpty) {
      return const Failure(UnauthorizedException('Sesion no disponible.'));
    }
    final res = await _service.getByBusiness(id);
    return res.when(
      onSuccess: (json) => Success<List<Promotion>>(_toPromotionList(json)),
      onFailure: (e) => Failure<List<Promotion>>(e),
    );
  }

  @override
  Future<Result<List<Promotion>>> loadActiveMine() async {
    final id = _businessId;
    if (id == null || id.isEmpty) {
      return const Failure(UnauthorizedException('Sesion no disponible.'));
    }
    final res = await _service.getActive();
    return res.when(
      onSuccess: (json) {
        final active = _toPromotionList(json)
            .where((p) => p.businessId.value == id)
            .toList();
        return Success<List<Promotion>>(active);
      },
      onFailure: (e) => Failure<List<Promotion>>(e),
    );
  }

  @override
  Future<Result<Promotion>> getById(String id) async {
    final res = await _service.getById(id);
    return res.when(
      onSuccess: (json) => Success<Promotion>(_toPromotion(json)),
      onFailure: (e) => Failure<Promotion>(e),
    );
  }

  @override
  Future<Result<String>> create({
    required String title,
    required String description,
    required double discountAmount,
    required DiscountType discountType,
    required DateTime startDate,
    required DateTime endDate,
    required String imageKey,
    int? redemptionCap,
  }) async {
    final id = _businessId;
    if (id == null || id.isEmpty) {
      return const Failure(UnauthorizedException('Sesion no disponible.'));
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
        imageKey: imageKey,
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

  @override
  Future<Result<void>> update(
    String id, {
    required String title,
    required String description,
    required double discountAmount,
    required DiscountType discountType,
    required DateTime startDate,
    required DateTime endDate,
    required String imageKey,
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
        imageKey: imageKey,
        redemptionCap: redemptionCap,
      ),
    );
    return _toVoid(res);
  }

  @override
  Future<Result<void>> delete(String id) async => _toVoid(await _service.delete(id));

  @override
  Future<Result<void>> publish(
    String id, {
    bool isBusinessVerified = true,
  }) async {
    final res = await _service.publish(
      id,
      PublishRequest(isBusinessVerified: isBusinessVerified),
    );
    return _toVoid(res);
  }

  @override
  Future<Result<void>> cancel(String id) async => _toVoid(await _service.cancel(id));

  Result<void> _toVoid(Result<dynamic> res) => res.when(
        onSuccess: (_) => const Success<void>(null),
        onFailure: (e) => Failure<void>(e),
      );

  Promotion _toPromotion(dynamic json) {
    if (json is Map<String, dynamic>) return PromotionDto.fromJson(json).toDomain();
    return PromotionDto.fromJson(const <String, dynamic>{}).toDomain();
  }

  List<Promotion> _toPromotionList(dynamic json) {
    if (json is List) {
      return json
          .whereType<Map<String, dynamic>>()
          .map((item) => PromotionDto.fromJson(item).toDomain())
          .toList();
    }
    return const [];
  }
}
