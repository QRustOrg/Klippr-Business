import '../../domain/models/business_profile_update.dart';
import '../../domain/models/verification_document.dart';

sealed class ProfileEvent {
  const ProfileEvent();
}

class LoadBusinessProfile extends ProfileEvent {
  const LoadBusinessProfile();
}

class UpdateBusinessProfileRequested extends ProfileEvent {
  const UpdateBusinessProfileRequested(this.update);
  final BusinessProfileUpdate update;
}

class SubmitVerificationRequested extends ProfileEvent {
  const SubmitVerificationRequested(this.document);
  final VerificationDocument document;
}

class ProfileFlagsConsumed extends ProfileEvent {
  const ProfileFlagsConsumed();
}
