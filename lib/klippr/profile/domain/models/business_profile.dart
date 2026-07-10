import '../../../shared/domain/models/id.dart';

class BusinessProfile {
  const BusinessProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    this.taxId,
    this.email,
    this.role = 'BUSINESS',
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

  final Id id;
  final Id userId;
  final String businessName;
  final String? taxId;
  final String? email;
  final String role;
  final String? description;
  final BusinessCategory? category;
  final BusinessLocation? location;
  final String? verificationStatus;
  final double averageRating;
  final int totalReviews;
  final String? documentUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  String get displayName =>
      businessName.trim().isEmpty ? 'Negocio Klippr' : businessName.trim();

  String get statusLabel {
    final raw = (verificationStatus ?? '').trim().toLowerCase();
    if (raw.isEmpty || raw == 'none' || raw == 'null') return 'Pendiente';
    return switch (raw) {
      'verified' ||
      'approved' ||
      'verificado' ||
      'active' ||
      'activo' =>
        'Verificado',
      'rejected' || 'rechazado' || 'denied' => 'Rechazado',
      'pending' ||
      'pendiente' ||
      'submitted' ||
      'in_review' ||
      'inreview' ||
      'under_review' =>
        'Pendiente',
      _ => verificationStatus?.trim().isNotEmpty == true
          ? verificationStatus!.trim()
          : 'Pendiente',
    };
  }

  bool get isVerified {
    final raw = (verificationStatus ?? '').trim().toLowerCase();
    return raw == 'verified' ||
        raw == 'approved' ||
        raw == 'verificado' ||
        raw == 'active' ||
        raw == 'activo' ||
        statusLabel.toLowerCase() == 'verificado';
  }

  BusinessProfile copyWith({
    Id? id,
    Id? userId,
    String? businessName,
    String? taxId,
    String? email,
    String? role,
    String? description,
    BusinessCategory? category,
    BusinessLocation? location,
    String? verificationStatus,
    double? averageRating,
    int? totalReviews,
    String? documentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      taxId: taxId ?? this.taxId,
      email: email ?? this.email,
      role: role ?? this.role,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      documentUrl: documentUrl ?? this.documentUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class BusinessCategory {
  const BusinessCategory({this.name, this.description});

  final String? name;
  final String? description;
}

class BusinessLocation {
  const BusinessLocation({
    this.street,
    this.city,
    this.state,
    this.country,
    this.postalCode,
  });

  final String? street;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;

  String get display {
    final parts = [
      street,
      city,
      state,
      country,
    ].where((p) => p != null && p.trim().isNotEmpty).cast<String>().toList();
    return parts.isEmpty ? '--' : parts.join(', ');
  }
}
