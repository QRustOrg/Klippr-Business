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
    final res = await _service.lookupByToken(uniqueToken);
    return res.when(
      onSuccess: (json) =>
          Success<Redemption>(RedemptionMapper.toRedemption(json)),
      onFailure: (e) => Failure<Redemption>(e),
    );
  }

  Future<Result<Redemption>> confirmToken(String uniqueToken) async {
    final res = await _service.confirmByToken(uniqueToken);
    return res.when(
      onSuccess: (json) =>
          Success<Redemption>(RedemptionMapper.toRedemption(json)),
      onFailure: (e) => Failure<Redemption>(e),
    );
  }

  Future<Result<List<Redemption>>> loadHistory(String promotionId) async {
    final res = await _service.loadByPromotion(promotionId);
    return res.when(
      onSuccess: (json) =>
          Success<List<Redemption>>(RedemptionMapper.toRedemptionList(json)),
      onFailure: (e) => Failure<List<Redemption>>(e),
    );
  }
}
