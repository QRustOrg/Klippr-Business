sealed class AdminEvent {
  const AdminEvent();
}

class LoadAdminData extends AdminEvent {
  const LoadAdminData();
}

class LoadPendingVerifications extends AdminEvent {
  const LoadPendingVerifications({this.pageNumber = 1, this.pageSize = 10});
  final int pageNumber;
  final int pageSize;
}

class ApproveVerificationRequested extends AdminEvent {
  const ApproveVerificationRequested(this.profileId);
  final String profileId;
}

class RejectVerificationRequested extends AdminEvent {
  const RejectVerificationRequested(this.profileId);
  final String profileId;
}

class TakedownPromotionRequested extends AdminEvent {
  const TakedownPromotionRequested(this.promotionId);
  final String promotionId;
}

class DeletePromotionRequested extends AdminEvent {
  const DeletePromotionRequested(this.promotionId);
  final String promotionId;
}

class DeactivateProfileRequested extends AdminEvent {
  const DeactivateProfileRequested(this.profileId);
  final String profileId;
}

class ReactivateProfileRequested extends AdminEvent {
  const ReactivateProfileRequested(this.profileId);
  final String profileId;
}

class UpdateAbuseReportStatusRequested extends AdminEvent {
  const UpdateAbuseReportStatusRequested(this.reportId, this.status);
  final String reportId;
  final String status;
}

class AdminErrorConsumed extends AdminEvent {
  const AdminErrorConsumed();
}

class AdminMessageConsumed extends AdminEvent {
  const AdminMessageConsumed();
}
