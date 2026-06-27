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

  /// Convierte el JSON del backend REST (RedemptionResource) a [Redemption].
  static Redemption fromBackendJson(Map<String, dynamic> json) {
    return Redemption(
      id: json['id']?.toString() ?? '',
      promotionId: json['promotionId']?.toString() ?? '',
      promotionTitle: json['promotionTitle']?.toString() ?? '',
      customerId: json['consumerId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      uniqueToken: json['uniqueToken']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      status: _parseStatus(json['status'] as String?),
      validationMethod: json['validationMethod']?.toString() ?? '',
      discountAppliedAmount:
          (json['discountAppliedAmount'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(json['generatedAt'] as String? ?? '') ??
          DateTime.now(),
      confirmedAt: DateTime.tryParse(json['redeemedAt'] as String? ?? ''),
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
      blockedAt: DateTime.tryParse(json['blockedAt'] as String? ?? ''),
    );
  }

  static RedemptionTokenStatus _parseStatus(String? raw) {
    return switch ((raw ?? '').toLowerCase()) {
      'redeemed' => RedemptionTokenStatus.confirmed,
      'generated' => RedemptionTokenStatus.pending,
      'blocked' => RedemptionTokenStatus.expired,
      'expired' => RedemptionTokenStatus.expired,
      _ => RedemptionTokenStatus.unknown,
    };
  }
}
