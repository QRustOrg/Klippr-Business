class ConfirmRedemptionRequest {
  const ConfirmRedemptionRequest({
    required this.businessId,
    required this.validationMethod,
    required this.confirmedAt,
  });

  final String businessId;
  final String validationMethod;
  final DateTime confirmedAt;

  Map<String, dynamic> toJson() => {
    'businessId': businessId,
    'validationMethod': validationMethod,
    'confirmedAt': confirmedAt.toUtc().toIso8601String(),
  };
}
