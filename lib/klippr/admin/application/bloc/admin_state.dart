import '../../domain/models/admin_analytics.dart';
import '../../domain/models/admin_business_profile.dart';
import '../../domain/models/admin_promotion.dart';

const Object _unset = Object();

class AdminState {
  const AdminState({
    this.isLoading = false,
    this.pendingVerifications = const [],
    this.allPromotions = const [],
    this.abuseReports = const [],
    this.platformAnalytics,
    this.error,
    this.actionMessage,
  });

  final bool isLoading;
  final List<AdminBusinessProfile> pendingVerifications;
  final List<AdminPromotion> allPromotions;
  final List<AbuseReport> abuseReports;
  final PlatformAnalytics? platformAnalytics;
  final String? error;
  final String? actionMessage;

  AdminState copyWith({
    bool? isLoading,
    Object? pendingVerifications = _unset,
    Object? allPromotions = _unset,
    Object? abuseReports = _unset,
    Object? platformAnalytics = _unset,
    Object? error = _unset,
    Object? actionMessage = _unset,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      pendingVerifications: pendingVerifications == _unset
          ? this.pendingVerifications
          : pendingVerifications as List<AdminBusinessProfile>,
      allPromotions: allPromotions == _unset
          ? this.allPromotions
          : allPromotions as List<AdminPromotion>,
      abuseReports: abuseReports == _unset
          ? this.abuseReports
          : abuseReports as List<AbuseReport>,
      platformAnalytics: platformAnalytics == _unset
          ? this.platformAnalytics
          : platformAnalytics as PlatformAnalytics?,
      error: error == _unset ? this.error : error as String?,
      actionMessage: actionMessage == _unset
          ? this.actionMessage
          : actionMessage as String?,
    );
  }
}
