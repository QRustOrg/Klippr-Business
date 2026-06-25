import '../models/redemption_model.dart';

class RedemptionMapper {
  const RedemptionMapper._();

  static Redemption toRedemption(dynamic json) {
    if (json is Map<String, dynamic>) return Redemption.fromJson(json);
    return Redemption.fromJson(<String, dynamic>{});
  }

  static List<Redemption> toRedemptionList(dynamic json) {
    if (json is List) {
      return json
          .whereType<Map<String, dynamic>>()
          .map(Redemption.fromJson)
          .toList();
    }
    return const [];
  }
}
