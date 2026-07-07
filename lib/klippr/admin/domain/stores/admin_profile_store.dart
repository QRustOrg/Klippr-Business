import '../../../shared/data/network/result.dart';
import '../models/admin_business_profile.dart';

abstract class AdminProfileStore {
  Future<Result<List<AdminBusinessProfile>>> getPendingVerifications({
    int pageNumber = 1,
    int pageSize = 10,
  });

  Future<Result<AdminBusinessProfile>> getProfileByUser(String userId);
  Future<Result<void>> approveVerification(String profileId);
  Future<Result<void>> rejectVerification(String profileId);
  Future<Result<void>> deactivateProfile(String profileId);
  Future<Result<void>> reactivateProfile(String profileId);
}
