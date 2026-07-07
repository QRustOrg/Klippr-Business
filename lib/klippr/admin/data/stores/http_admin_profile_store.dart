import '../../../shared/data/network/api_exceptions.dart';
import '../../../shared/data/network/result.dart';
import '../../domain/models/admin_business_profile.dart';
import '../../domain/stores/admin_profile_store.dart';
import '../network/admin_profile_web_service.dart';

class HttpAdminProfileStore implements AdminProfileStore {
  HttpAdminProfileStore(this._service);

  final AdminProfileWebService _service;

  @override
  Future<Result<List<AdminBusinessProfile>>> getPendingVerifications({
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final res = await _service.getPendingVerifications(
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
    return res.when(
      onSuccess: (json) {
        if (json is Map<String, dynamic> && json['data'] is List) {
          final profiles = (json['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map(AdminBusinessProfile.fromJson)
              .toList();
          return Success<List<AdminBusinessProfile>>(profiles);
        }
        return const Success<List<AdminBusinessProfile>>([]);
      },
      onFailure: (e) => Failure<List<AdminBusinessProfile>>(e),
    );
  }

  @override
  Future<Result<AdminBusinessProfile>> getProfileByUser(String userId) async {
    final res = await _service.getProfileByUser(userId);
    return res.when(
      onSuccess: (json) {
        if (json is Map<String, dynamic> && json['data'] is Map) {
          return Success<AdminBusinessProfile>(
            AdminBusinessProfile.fromJson(json['data'] as Map<String, dynamic>),
          );
        }
        return Failure<AdminBusinessProfile>(
          const NotFoundException('Perfil no encontrado'),
        );
      },
      onFailure: (e) => Failure<AdminBusinessProfile>(e),
    );
  }

  @override
  Future<Result<void>> approveVerification(String profileId) async {
    final res = await _service.approveVerification(profileId);
    return res.when(
      onSuccess: (_) => const Success<void>(null),
      onFailure: (e) => Failure<void>(e),
    );
  }

  @override
  Future<Result<void>> rejectVerification(String profileId) async {
    final res = await _service.rejectVerification(profileId);
    return res.when(
      onSuccess: (_) => const Success<void>(null),
      onFailure: (e) => Failure<void>(e),
    );
  }

  @override
  Future<Result<void>> deactivateProfile(String profileId) async {
    final res = await _service.deactivateProfile(profileId);
    return res.when(
      onSuccess: (_) => const Success<void>(null),
      onFailure: (e) => Failure<void>(e),
    );
  }

  @override
  Future<Result<void>> reactivateProfile(String profileId) async {
    final res = await _service.reactivateProfile(profileId);
    return res.when(
      onSuccess: (_) => const Success<void>(null),
      onFailure: (e) => Failure<void>(e),
    );
  }
}
