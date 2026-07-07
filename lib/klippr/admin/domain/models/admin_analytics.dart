import '../../../shared/domain/models/id.dart';

class PlatformAnalytics {
  const PlatformAnalytics({
    this.totalUsers = 0,
    this.totalPromotions = 0,
    this.totalAbuseReports = 0,
    this.pendingAbuseReports = 0,
    this.reviewedAbuseReports = 0,
    this.resolvedAbuseReports = 0,
  });

  final int totalUsers;
  final int totalPromotions;
  final int totalAbuseReports;
  final int pendingAbuseReports;
  final int reviewedAbuseReports;
  final int resolvedAbuseReports;

  factory PlatformAnalytics.fromJson(Map<String, dynamic> json) {
    return PlatformAnalytics(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalPromotions: (json['totalPromotions'] as num?)?.toInt() ?? 0,
      totalAbuseReports: (json['totalAbuseReports'] as num?)?.toInt() ?? 0,
      pendingAbuseReports: (json['pendingAbuseReports'] as num?)?.toInt() ?? 0,
      reviewedAbuseReports: (json['reviewedAbuseReports'] as num?)?.toInt() ?? 0,
      resolvedAbuseReports: (json['resolvedAbuseReports'] as num?)?.toInt() ?? 0,
    );
  }
}

class AbuseReport {
  const AbuseReport({
    required this.id,
    this.reporterId,
    this.targetId,
    this.targetType,
    this.reason,
    this.description,
    this.status = 'PENDING',
    this.createdAt,
    this.updatedAt,
  });

  final Id id;
  final String? reporterId;
  final String? targetId;
  final String? targetType;
  final String? reason;
  final String? description;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isReviewed => status.toUpperCase() == 'REVIEWED';
  bool get isResolved => status.toUpperCase() == 'RESOLVED';

  String get statusLabel => switch (status.toUpperCase()) {
        'PENDING' => 'Pendiente',
        'REVIEWED' => 'Revisado',
        'RESOLVED' => 'Resuelto',
        _ => status,
      };

  factory AbuseReport.fromJson(Map<String, dynamic> json) {
    return AbuseReport(
      id: Id(json['id']?.toString() ?? json['reportId']?.toString() ?? ''),
      reporterId: json['reporterId']?.toString(),
      targetId: json['targetId']?.toString(),
      targetType: json['targetType']?.toString(),
      reason: json['reason']?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}
