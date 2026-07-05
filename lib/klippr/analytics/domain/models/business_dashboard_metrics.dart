class BusinessDashboardMetrics {
  const BusinessDashboardMetrics({
    required this.businessId,
    required this.totalPromotions,
    required this.activePromotions,
    required this.totalRedemptions,
    required this.usedRedemptions,
    required this.views,
    required this.averageRating,
  });

  final String businessId;
  final int totalPromotions;
  final int activePromotions;
  final int totalRedemptions;
  final int usedRedemptions;
  final int views;
  final double averageRating;

  factory BusinessDashboardMetrics.fromJson(Map<String, dynamic> json) {
    int intOf(String key) => (json[key] as num?)?.toInt() ?? 0;
    return BusinessDashboardMetrics(
      businessId: json['businessId']?.toString() ?? '',
      totalPromotions: intOf('totalPromotions') == 0
          ? intOf('promotions')
          : intOf('totalPromotions'),
      activePromotions: intOf('activePromotions'),
      totalRedemptions: intOf('totalRedemptions') == 0
          ? intOf('redemptions')
          : intOf('totalRedemptions'),
      usedRedemptions: intOf('usedRedemptions') == 0
          ? intOf('redeemed')
          : intOf('usedRedemptions'),
      views: intOf('views'),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
    );
  }
}
