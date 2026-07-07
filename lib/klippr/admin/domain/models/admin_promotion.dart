import '../../../shared/domain/models/id.dart';

class AdminPromotion {
  const AdminPromotion({
    required this.id,
    required this.businessId,
    required this.title,
    this.description,
    this.discountAmount,
    this.discountType,
    this.startDate,
    this.endDate,
    this.status,
    this.businessName,
    this.isActive = true,
  });

  final Id id;
  final Id businessId;
  final String title;
  final String? description;
  final double? discountAmount;
  final String? discountType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;
  final String? businessName;
  final bool isActive;

  factory AdminPromotion.fromJson(Map<String, dynamic> json) {
    return AdminPromotion(
      id: Id(json['promotionId']?.toString() ?? json['id']?.toString() ?? ''),
      businessId: Id(json['businessId']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      discountType: json['discountType']?.toString(),
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? ''),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? ''),
      status: json['status']?.toString(),
      businessName: json['businessName']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
