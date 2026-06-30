import '../../core/network/api_exceptions.dart';
import '../../core/prefs/prefs_helper.dart';
import '../../core/utils/result.dart';
import '../mappers/redemption_mapper.dart';
import '../models/redemption_model.dart';
import '../services/redemption_service.dart';

class RedemptionRepository {
  RedemptionRepository(this._service, {PrefsHelper? prefs})
      : _prefs = prefs ?? PrefsHelper.instance;
  final RedemptionService _service;
  final PrefsHelper _prefs;

  String? get businessId => _prefs.userId;

  Future<Result<Redemption>> lookupToken(String uniqueToken) async {
    final bid = businessId;
    if (bid == null || bid.isEmpty) {
      return const Failure(UnauthorizedException('Sesion no disponible.'));
    }
    final res = await _service.getRedemptionsByBusiness(bid);
    return res.when(
      onSuccess: (json) {
        if (json is! List) return const Failure(NotFoundException('Token no encontrado.'));
        for (final item in json) {
          if (item is! Map<String, dynamic>) continue;
          final tok = item['uniqueToken']?.toString() ?? '';
          if (tok == uniqueToken) {
            return Success<Redemption>(RedemptionMapper.fromBackendJson(item));
          }
        }
        return const Failure(NotFoundException('Token no encontrado.'));
      },
      onFailure: (e) => Failure<Redemption>(e),
    );
  }

  Future<Result<Redemption>> confirmToken(String uniqueToken) async {
    final res = await _service.confirmByToken(uniqueToken);
    return res.when(
      onSuccess: (json) {
        if (json is Map<String, dynamic>) {
          return Success<Redemption>(RedemptionMapper.fromBackendJson(json));
        }
        return const Failure(ParseException());
      },
      onFailure: (e) => Failure<Redemption>(e),
    );
  }

  Future<Result<List<Redemption>>> loadHistory(String promotionId) async {
    final bid = businessId;
    if (bid == null || bid.isEmpty) {
      return const Failure(UnauthorizedException('Sesion no disponible.'));
    }
    final res = await _service.getRedemptionsByBusiness(bid);
    return res.when(
      onSuccess: (json) {
        if (json is! List) return const Success<List<Redemption>>([]);
        final filtered = json
            .whereType<Map<String, dynamic>>()
            .where((item) => (item['promotionId']?.toString() ?? '') == promotionId)
            .map(RedemptionMapper.fromBackendJson)
            .toList();
        return Success<List<Redemption>>(filtered);
      },
      onFailure: (e) => Failure<List<Redemption>>(e),
    );
  }
}
