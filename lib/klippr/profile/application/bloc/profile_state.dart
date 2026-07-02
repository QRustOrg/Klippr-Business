import '../../domain/models/business_profile.dart';

const Object _unset = Object();

class ProfileState {
  const ProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.isSubmittingVerification = false,
    this.profile,
    this.error,
    this.actionMessage,
    this.verificationSubmitted = false,
  });

  final bool isLoading;
  final bool isSaving;
  final bool isSubmittingVerification;
  final BusinessProfile? profile;
  final String? error;
  final String? actionMessage;
  final bool verificationSubmitted;

  ProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isSubmittingVerification,
    Object? profile = _unset,
    Object? error = _unset,
    Object? actionMessage = _unset,
    bool? verificationSubmitted,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isSubmittingVerification:
          isSubmittingVerification ?? this.isSubmittingVerification,
      profile: profile == _unset ? this.profile : profile as BusinessProfile?,
      error: error == _unset ? this.error : error as String?,
      actionMessage: actionMessage == _unset
          ? this.actionMessage
          : actionMessage as String?,
      verificationSubmitted:
          verificationSubmitted ?? this.verificationSubmitted,
    );
  }
}
