import '../../../shared/data/network/api_exceptions.dart';
import '../../../shared/data/network/result.dart';
import '../../../shared/data/pref/prefs_helper.dart';
import '../../../shared/data/pref/session_identity.dart';
import '../../domain/models/promotion.dart';
import '../../domain/stores/promotions_store.dart';
import '../models/promotion_dto.dart';
import '../network/promotions_web_service.dart';
import '../network/requests/create_promotion_request.dart';
import '../network/requests/update_promotion_request.dart';

// author: Samuel Bonifacio
//
// Adaptador (hexagonal) que implementa el puerto [PromotionsStore] sobre el
// backend HTTP de Klippr, vía [PromotionsWebService].

/// Adaptador HTTP del puerto [PromotionsStore].
class HttpPromotionsStore implements PromotionsStore {
  /// Crea un [HttpPromotionsStore] sobre [_service].
  HttpPromotionsStore(this._service, {PrefsHelper? prefs})
    : _prefs = prefs ?? PrefsHelper.instance;

  final PromotionsWebService _service;
  final PrefsHelper _prefs;

  /// El backend (PromotionController.Create) ignora el businessId del body y
  /// persiste la promo con `businessProfile.Id` (profileId), no con userId.
  ///
  /// Tras un create exitoso, [create] cachea ese profileId leyendo la promo.
  Future<List<String>> _lookupBusinessIds() async {
    final ids = <String>{};
    final userId = await SessionIdentity.ensureUserId(_prefs);
    if (userId != null && userId.isNotEmpty) ids.add(userId);

    final profileId = _prefs.profileId;
    if (profileId != null && profileId.isNotEmpty) ids.add(profileId);

    return ids.toList(growable: false);
  }

  Future<String?> _requestBusinessId() async {
    // El body se sobreescribe en el backend; enviamos userId (requerido UUID).
    final userId = await SessionIdentity.ensureUserId(_prefs);
    if (userId != null && userId.isNotEmpty) return userId;
    final profileId = _prefs.profileId;
    if (profileId != null && profileId.isNotEmpty) return profileId;
    return null;
  }

  Future<void> _cacheOwnerFromPromotion(dynamic json) async {
    if (json is! Map) return;
    final businessId = json['businessId']?.toString();
    if (businessId == null || businessId.isEmpty) return;
    if (_prefs.profileId == businessId) return;
    await _prefs.setProfileId(businessId);
  }

  @override
  Future<Result<List<Promotion>>> loadMine() async {
    final ids = await _lookupBusinessIds();
    if (ids.isEmpty) {
      return const Failure(UnauthorizedException('Sesion no disponible.'));
    }

    final byId = <String, Promotion>{};
    ApiException? lastError;
    var anySuccess = false;

    for (final id in ids) {
      final res = await _service.getByBusiness(id);
      res.when(
        onSuccess: (json) {
          anySuccess = true;
          for (final promo in _toPromotionList(json)) {
            byId[promo.id.value] = promo;
          }
        },
        onFailure: (e) => lastError = e,
      );
    }

    if (!anySuccess) {
      return Failure<List<Promotion>>(
        lastError ?? const UnauthorizedException('Sesion no disponible.'),
      );
    }
    return Success<List<Promotion>>(byId.values.toList(growable: false));
  }

  @override
  Future<Result<List<Promotion>>> loadActive() async {
    final res = await _service.getActive();
    return res.when(
      onSuccess: (json) => Success<List<Promotion>>(_toPromotionList(json)),
      onFailure: (e) => Failure<List<Promotion>>(e),
    );
  }

  @override
  Future<Result<List<Promotion>>> loadActiveMine() async {
    final ids = await _lookupBusinessIds();
    if (ids.isEmpty) {
      return const Failure(UnauthorizedException('Sesion no disponible.'));
    }
    final idSet = ids.toSet();
    final res = await loadActive();
    return res.when(
      onSuccess: (promotions) {
        final active = promotions
            .where((p) => idSet.contains(p.businessId.value))
            .toList();
        return Success<List<Promotion>>(active);
      },
      onFailure: (e) => Failure<List<Promotion>>(e),
    );
  }

  @override
  Future<Result<Promotion>> getById(String id) async {
    final res = await _service.getById(id);
    final err = res.errorOrNull;
    if (err != null) return Failure<Promotion>(err);
    final json = res.dataOrNull;
    await _cacheOwnerFromPromotion(json);
    return Success<Promotion>(_toPromotion(json));
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
    final id = await _requestBusinessId();
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

    final err = res.errorOrNull;
    if (err != null) return Failure<String>(err);

    final json = res.dataOrNull;
    final newId = json is Map
        ? (json['promotionId'] ?? json['PromotionId'])?.toString()
        : null;

    // Backend guarda businessId = profile.Id. Lo aprendemos de la promo creada
    // para que el siguiente loadMine consulte el id correcto.
    if (newId != null && newId.isNotEmpty) {
      final detail = await _service.getById(newId);
      await _cacheOwnerFromPromotion(detail.dataOrNull);
    }

    return Success<String>(newId ?? '');
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
  Future<Result<void>> delete(String id) async =>
      _toVoid(await _service.delete(id));

  @override
  Future<Result<void>> publish(String id) async =>
      _toVoid(await _service.publish(id));

  @override
  Future<Result<void>> cancel(String id) async =>
      _toVoid(await _service.cancel(id));

  Result<void> _toVoid(Result<dynamic> res) => res.when(
    onSuccess: (_) => const Success<void>(null),
    onFailure: (e) => Failure<void>(e),
  );

  Promotion _toPromotion(dynamic json) {
    if (json is Map<String, dynamic>) {
      return PromotionDto.fromJson(json).toDomain();
    }
    if (json is Map) {
      return PromotionDto.fromJson(Map<String, dynamic>.from(json)).toDomain();
    }
    return PromotionDto.fromJson(const <String, dynamic>{}).toDomain();
  }

  List<Promotion> _toPromotionList(dynamic json) {
    if (json is List) {
      return json
          .map((item) {
            if (item is Map<String, dynamic>) {
              return PromotionDto.fromJson(item).toDomain();
            }
            if (item is Map) {
              return PromotionDto.fromJson(
                Map<String, dynamic>.from(item),
              ).toDomain();
            }
            return null;
          })
          .whereType<Promotion>()
          .toList();
    }
    if (json is Map<String, dynamic>) {
      for (final key in const ['data', 'items', 'content', 'promotions']) {
        final nested = json[key];
        if (nested is List) return _toPromotionList(nested);
      }
    }
    return const [];
  }
}
