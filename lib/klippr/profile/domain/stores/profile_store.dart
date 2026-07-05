import '../../../shared/data/network/result.dart';
import '../models/business_profile.dart';
import '../models/business_profile_update.dart';
import '../models/verification_document.dart';

abstract interface class ProfileStore {
  Future<Result<BusinessProfile>> loadBusinessProfile();

  Future<Result<BusinessProfile>> updateBusinessProfile(
    BusinessProfileUpdate update,
  );

  Future<Result<void>> submitVerification(VerificationDocument document);
}
