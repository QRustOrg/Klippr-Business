class CampaignMetrics {
  const CampaignMetrics({
    required this.campaignId,
    required this.businessId,
    required this.views,
    required this.redemptions,
    required this.averageRating,
    required this.conversionRate,
  });

  final String campaignId;
  final String businessId;
  final int views;
  final int redemptions;
  final double averageRating;
  final double conversionRate;

  factory CampaignMetrics.fromJson(Map<String, dynamic> json) {
    return CampaignMetrics(
      campaignId: json['campaignId']?.toString() ?? '',
      businessId: json['businessId']?.toString() ?? '',
      views: (json['views'] as num?)?.toInt() ?? 0,
      redemptions: (json['redemptions'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      conversionRate: (json['conversionRate'] as num?)?.toDouble() ?? 0,
    );
  }
}
