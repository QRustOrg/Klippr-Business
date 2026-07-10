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
      verificationStatus: _readVerificationStatus(json),
      averageRating: rating is Map
          ? ((rating as Map)['averageRating'] as num?)?.toDouble() ?? 0
          : 0,
      totalReviews: rating is Map
          ? ((rating as Map)['totalReviews'] as num?)?.toInt() ?? 0
          : 0,
      documentUrl:
          json['documentUrl']?.toString() ?? json['DocumentUrl']?.toString(),
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

  static String? _readVerificationStatus(Map<String, dynamic> json) {
    for (final key in const [
      'verificationStatus',
      'VerificationStatus',
      'verification_status',
      'status',
    ]) {
      final raw = json[key];
      if (raw == null) continue;
      final text = raw.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    // Algunos backends envían booleano isVerified / verified.
    final verifiedFlag = json['isVerified'] ?? json['verified'];
    if (verifiedFlag is bool) {
      return verifiedFlag ? 'Verified' : 'Pending';
    }
    if (verifiedFlag != null) {
      final text = verifiedFlag.toString().toLowerCase();
      if (text == 'true' || text == '1') return 'Verified';
      if (text == 'false' || text == '0') return 'Pending';
    }
    return null;
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
