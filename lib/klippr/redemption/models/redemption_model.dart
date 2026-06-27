enum RedemptionTokenStatus {
  pending,
  confirmed,
  expired,
  unknown;

  static RedemptionTokenStatus parse(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return RedemptionTokenStatus.pending;
      case 'confirmed':
        return RedemptionTokenStatus.confirmed;
      case 'expired':
        return RedemptionTokenStatus.expired;
      default:
        return RedemptionTokenStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case RedemptionTokenStatus.pending:
        return 'Pendiente';
      case RedemptionTokenStatus.confirmed:
        return 'Confirmado';
      case RedemptionTokenStatus.expired:
        return 'Expirado';
      case RedemptionTokenStatus.unknown:
        return 'Desconocido';
    }
  }
}

class Redemption {
  const Redemption({
    required this.id,
    required this.promotionId,
    required this.promotionTitle,
    required this.customerId,
    required this.customerName,
    required this.uniqueToken,
    required this.code,
    required this.status,
    required this.validationMethod,
    required this.discountAppliedAmount,
    required this.createdAt,
    this.confirmedAt,
    this.expiresAt,
    this.blockedAt,
  });

  final String id;
  final String promotionId;
  final String promotionTitle;
  final String customerId;
  final String customerName;
  final String uniqueToken;
  final String code;
  final RedemptionTokenStatus status;
  final String validationMethod;
  final double discountAppliedAmount;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? expiresAt;
  final DateTime? blockedAt;

  factory Redemption.fromJson(Map<String, dynamic> json) {
    return Redemption(
      id: json['id'] as String? ?? '',
      promotionId: json['promotionId'] as String? ?? '',
      promotionTitle: json['promotionTitle'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      uniqueToken: json['uniqueToken'] as String? ?? '',
      code: json['code'] as String? ?? '',
      status: RedemptionTokenStatus.parse(json['status'] as String?),
      validationMethod: json['validationMethod'] as String? ?? '',
      discountAppliedAmount:
          (json['discountAppliedAmount'] as num?)?.toDouble() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.tryParse(json['confirmedAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      blockedAt: json['blockedAt'] != null
          ? DateTime.tryParse(json['blockedAt'] as String)
          : null,
    );
  }
}
