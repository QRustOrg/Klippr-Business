import '../../core/network/api_exceptions.dart';
import '../../core/prefs/prefs_helper.dart';
import '../../core/utils/result.dart';
import '../mappers/promotion_mapper.dart';
import '../models/promotion.dart';
import '../models/promotion_request.dart';
import '../services/promotions_service.dart';

// author: Samuel Bonifacio
//
// Repositorio de Promotions: abstrae el origen de datos para el BLoC.

class PromotionsRepository {
  PromotionsRepository(this._service, {PrefsHelper? prefs})
      : _prefs = prefs ?? PrefsHelper.instance;

  final PromotionsService _service;
  final PrefsHelper _prefs;

  String? get businessId => _prefs.userId;

  Future<Result<List<Promotion>>> loadMine() async {
    final id = businessId;
    if (id == null || id.isEmpty) {
      return const Failure(UnauthorizedException('Sesion no disponible.'));
    }
    final res = await _service.getByBusiness(id);
    return res.when(
      onSuccess: (json) =>
          Success<List<Promotion>>(PromotionMapper.toPromotionList(json)),
      onFailure: (e) => Failure<List<Promotion>>(e),
    );
  }

  Future<Result<List<Promotion>>> loadActiveMine() async {
    final id = businessId;
    if (id == null || id.isEmpty) {
      return const Failure(UnauthorizedException('Sesion no disponible.'));
    }
    final res = await _service.getActive();
    return res.when(
      onSuccess: (json) {
        final active = PromotionMapper.toPromotionList(json)
            .where((p) => p.businessId == id)
            .toList();
        return Success<List<Promotion>>(active);
      },
      onFailure: (e) => Failure<List<Promotion>>(e),
    );
  }

  Future<Result<Promotion>> getById(String id) async {
    final res = await _service.getById(id);
    return res.when(
      onSuccess: (json) => Success<Promotion>(PromotionMapper.toPromotion(json)),
      onFailure: (e) => Failure<Promotion>(e),
    );
  }

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
    final id = businessId;
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

  Future<Result<void>> delete(String id) async =>
      _toVoid(await _service.delete(id));

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

  Future<Result<void>> cancel(String id) async =>
      _toVoid(await _service.cancel(id));

  Result<void> _toVoid(Result<dynamic> res) => res.when(
        onSuccess: (_) => const Success<void>(null),
        onFailure: (e) => Failure<void>(e),
      );
}
