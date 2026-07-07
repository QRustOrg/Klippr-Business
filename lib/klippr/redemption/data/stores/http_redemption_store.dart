import '../../../shared/data/network/api_exceptions.dart';
import '../../../shared/data/network/result.dart';
import '../../../shared/data/pref/prefs_helper.dart';
import '../../domain/models/redemption.dart';
import '../../domain/stores/redemption_store.dart';
import '../models/redemption_dto.dart';
import '../network/redemption_web_service.dart';
import '../network/requests/confirm_redemption_request.dart';

// author: Samuel Bonifacio
//
// Adaptador (hexagonal) que implementa el puerto [RedemptionStore] sobre el
// backend HTTP de Klippr, vía [RedemptionWebService].

/// Adaptador HTTP del puerto [RedemptionStore].
class HttpRedemptionStore implements RedemptionStore {
  /// Crea un [HttpRedemptionStore] sobre [_service].
  HttpRedemptionStore(this._service, {PrefsHelper? prefs})
    : _prefs = prefs ?? PrefsHelper.instance;

  final RedemptionWebService _service;
  final PrefsHelper _prefs;

  String? get _businessId => _prefs.profileId ?? _prefs.userId;

  @override
  Future<Result<Redemption>> lookupToken(String uniqueToken) async {
    final bid = _businessId;
    if (bid == null || bid.isEmpty) {
      return const Failure(UnauthorizedException('Sesion no disponible.'));
    }
    final res = await _service.getRedemptionsByBusiness(bid);
    return res.when(
      onSuccess: (json) {
        if (json is! List) {
          return const Failure(NotFoundException('Token no encontrado.'));
        }
        for (final item in json) {
          if (item is! Map<String, dynamic>) continue;
          final tok = item['uniqueToken']?.toString() ?? '';
          if (tok == uniqueToken) {
            return Success<Redemption>(RedemptionDto.fromJson(item).toDomain());
          }
        }
        return const Failure(NotFoundException('Token no encontrado.'));
      },
      onFailure: (e) => Failure<Redemption>(e),
    );
  }

  @override
  Future<Result<Redemption>> confirmToken(String uniqueToken) async {
    final bid = _businessId;
    if (bid == null || bid.isEmpty) {
      return const Failure(UnauthorizedException('Sesion no disponible.'));
    }
    final res = await _service.confirmByToken(
      uniqueToken,
      _confirmBody(bid, 'QR'),
    );
    return res.when(
      onSuccess: (json) {
        if (json is Map<String, dynamic>) {
          return Success<Redemption>(RedemptionDto.fromJson(json).toDomain());
        }
        return const Failure(ParseException());
      },
      onFailure: (e) => Failure<Redemption>(e),
    );
  }

  @override
  Future<Result<Redemption>> confirmById(String redemptionId) async {
    if (int.tryParse(redemptionId) == null) {
      return const Failure(
        ValidationException('El id de canje no es numerico.'),
      );
    }
    final bid = _businessId;
    if (bid == null || bid.isEmpty) {
      return const Failure(UnauthorizedException('Sesion no disponible.'));
    }
    final res = await _service.confirmById(
      redemptionId,
      _confirmBody(bid, 'MANUAL'),
    );
    return res.when(
      onSuccess: (json) {
        if (json is Map<String, dynamic>) {
          return Success<Redemption>(RedemptionDto.fromJson(json).toDomain());
        }
        return const Failure(ParseException());
      },
      onFailure: (e) => Failure<Redemption>(e),
    );
  }

  @override
  Future<Result<List<Redemption>>> loadHistory(String promotionId) async {
    final bid = _businessId;
    if (bid == null || bid.isEmpty) {
      return const Failure(UnauthorizedException('Sesion no disponible.'));
    }
    final res = await _service.getRedemptionsByBusiness(bid);
    return res.when(
      onSuccess: (json) {
        if (json is! List) return const Success<List<Redemption>>([]);
        final filtered = json
            .whereType<Map<String, dynamic>>()
            .where(
              (item) => (item['promotionId']?.toString() ?? '') == promotionId,
            )
            .map((item) => RedemptionDto.fromJson(item).toDomain())
            .toList();
        return Success<List<Redemption>>(filtered);
      },
      onFailure: (e) => Failure<List<Redemption>>(e),
    );
  }

  ConfirmRedemptionRequest _confirmBody(String businessId, String method) {
    return ConfirmRedemptionRequest(
      businessId: businessId,
      validationMethod: method,
      confirmedAt: DateTime.now(),
    );
  }
}
