import '../../../shared/domain/models/id.dart';
import '../../domain/models/business_profile.dart';

class BusinessProfileDto {
  const BusinessProfileDto({
    required this.id,
    required this.userId,
    required this.businessName,
    this.taxId,
    this.email,
    this.role,
    this.description,
    this.category,
    this.location,
    this.verificationStatus,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.documentUrl,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  final String id;
  final String userId;
  final String businessName;
  final String? taxId;
  final String? email;
  final String? role;
  final String? description;
  final BusinessCategory? category;
  final BusinessLocation? location;
  final String? verificationStatus;
  final double averageRating;
  final int totalReviews;
  final String? documentUrl;
  final String? createdAt;
  final String? updatedAt;
  final bool isActive;

  factory BusinessProfileDto.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'];
    return BusinessProfileDto(
      id: json['id']?.toString() ?? json['profileId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      businessName: json['businessName']?.toString() ?? '',
      taxId: json['taxId']?.toString(),
      email: json['email']?.toString(),
      role: json['role']?.toString(),
      description: json['description']?.toString(),
      category: _category(json['category']),
      location: _location(json['location']),
      verificationStatus: json['verificationStatus']?.toString(),
      averageRating: rating is Map<String, dynamic>
          ? (rating['averageRating'] as num?)?.toDouble() ?? 0
          : 0,
      totalReviews: rating is Map<String, dynamic>
          ? (rating['totalReviews'] as num?)?.toInt() ?? 0
          : 0,
      documentUrl: json['documentUrl']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  BusinessProfile toDomain({Map<String, dynamic>? userJson}) {
    return BusinessProfile(
      id: Id(id),
      userId: Id(
        userId.isEmpty ? (userJson?['userId']?.toString() ?? '') : userId,
      ),
      businessName: businessName.isEmpty
          ? (userJson?['businessName']?.toString() ?? '')
          : businessName,
      taxId: taxId ?? userJson?['taxId']?.toString(),
      email: email ?? userJson?['email']?.toString(),
      role: role ?? userJson?['role']?.toString() ?? 'BUSINESS',
      description: description,
      category: category,
      location: location,
      verificationStatus: verificationStatus,
      averageRating: averageRating,
      totalReviews: totalReviews,
      documentUrl: documentUrl,
      createdAt:
          DateTime.tryParse(createdAt ?? '') ??
          DateTime.tryParse(userJson?['createdAt']?.toString() ?? ''),
      updatedAt:
          DateTime.tryParse(updatedAt ?? '') ??
          DateTime.tryParse(userJson?['updatedAt']?.toString() ?? ''),
      isActive: isActive,
    );
  }

  static BusinessCategory? _category(Object? json) {
    if (json is Map<String, dynamic>) {
      return BusinessCategory(
        name: json['name']?.toString(),
        description: json['description']?.toString(),
      );
    }
    if (json is String && json.isNotEmpty) {
      return BusinessCategory(name: json);
    }
    return null;
  }

  static BusinessLocation? _location(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return BusinessLocation(
      street: json['street']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      postalCode: json['postalCode']?.toString() ?? json['zipCode']?.toString(),
    );
  }
}
