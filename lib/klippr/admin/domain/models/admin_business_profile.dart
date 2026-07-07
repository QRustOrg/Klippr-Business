import '../../../shared/domain/models/id.dart';

class AdminBusinessProfile {
  const AdminBusinessProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    this.taxId,
    this.email,
    this.role,
    this.description,
    this.category,
    this.verificationStatus,
    this.documentUrl,
    this.isActive = true,
    this.createdAt,
  });

  final Id id;
  final Id userId;
  final String businessName;
  final String? taxId;
  final String? email;
  final String? role;
  final String? description;
  final String? category;
  final String? verificationStatus;
  final String? documentUrl;
  final bool isActive;
  final DateTime? createdAt;

  bool get isVerified =>
      verificationStatus?.toLowerCase() == 'verified' ||
      verificationStatus?.toLowerCase() == 'approved';

  bool get isPending =>
      verificationStatus?.toLowerCase() == 'pending';

  bool get isRejected =>
      verificationStatus?.toLowerCase() == 'rejected';

  String get statusLabel {
    final raw = (verificationStatus ?? '').toLowerCase();
    return switch (raw) {
      'verified' || 'approved' => 'Verificado',
      'pending' => 'Pendiente',
      'rejected' => 'Rechazado',
      _ => verificationStatus ?? 'Desconocido',
    };
  }

  factory AdminBusinessProfile.fromJson(Map<String, dynamic> json) {
    return AdminBusinessProfile(
      id: Id(json['id']?.toString() ?? json['profileId']?.toString() ?? ''),
      userId: Id(json['userId']?.toString() ?? ''),
      businessName: json['businessName']?.toString() ?? '',
      taxId: json['taxId']?.toString(),
      email: json['email']?.toString(),
      role: json['role']?.toString(),
      description: json['description']?.toString(),
      category: json['category'] is Map
          ? (json['category'] as Map)['name']?.toString()
          : json['category']?.toString(),
      verificationStatus: json['verificationStatus']?.toString(),
      documentUrl: json['documentUrl']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
