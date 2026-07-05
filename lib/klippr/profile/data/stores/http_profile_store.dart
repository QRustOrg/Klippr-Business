import '../../../shared/data/network/api_exceptions.dart';
import '../../../shared/data/network/result.dart';
import '../../../shared/data/pref/prefs_helper.dart';
import '../../domain/models/business_profile.dart';
import '../../domain/models/business_profile_update.dart';
import '../../domain/models/verification_document.dart';
import '../../domain/stores/profile_store.dart';
import '../models/business_profile_dto.dart';
import '../network/profile_web_service.dart';

class HttpProfileStore implements ProfileStore {
  HttpProfileStore(this._service, {PrefsHelper? prefs})
    : _prefs = prefs ?? PrefsHelper.instance;

  final ProfileWebService _service;
  final PrefsHelper _prefs;

  @override
  Future<Result<BusinessProfile>> loadBusinessProfile() async {
    final userId = _prefs.userId;
    if (userId == null || userId.isEmpty) {
      return const Failure(UnauthorizedException('Sesion no disponible.'));
    }
    final candidateProfileId = _prefs.profileId ?? userId;
    final profileRes = await _service.getBusinessProfile(candidateProfileId);
    return profileRes.when(
      onSuccess: (json) async {
        final profile = _profileFrom(json);
        if (profile.id.isNotEmpty) await _prefs.setProfileId(profile.id.value);
        return Success<BusinessProfile>(profile);
      },
      onFailure: (error) async {
        if (error is! NotFoundException) return Failure<BusinessProfile>(error);
        return _createFromUser(userId);
      },
    );
  }

  Future<Result<BusinessProfile>> _createFromUser(String userId) async {
    final userRes = await _service.getUser(userId);
    final userJson = userRes.dataOrNull is Map<String, dynamic>
        ? userRes.dataOrNull as Map<String, dynamic>
        : <String, dynamic>{};
    final createBody = <String, dynamic>{
      'id': userId,
      'userId': userId,
      'businessName': userJson['businessName'],
      'taxId': userJson['taxId'],
      'verificationStatus': 'Pending',
      'isActive': userJson['isActive'] ?? true,
    };
    final createRes = await _service.createBusinessProfile(createBody);
    return createRes.when(
      onSuccess: (json) async {
        final profile = _profileFrom(json, userJson: userJson);
        if (profile.id.isNotEmpty) await _prefs.setProfileId(profile.id.value);
        return Success<BusinessProfile>(profile);
      },
      onFailure: (error) => Failure<BusinessProfile>(error),
    );
  }

  @override
  Future<Result<BusinessProfile>> updateBusinessProfile(
    BusinessProfileUpdate update,
  ) async {
    final res = await _service.updateBusinessProfile(update.toJson());
    return res.when(
      onSuccess: (json) async {
        if (json is Map<String, dynamic>) {
          return Success<BusinessProfile>(_profileFrom(json));
        }
        return loadBusinessProfile();
      },
      onFailure: (error) => Failure<BusinessProfile>(error),
    );
  }

  @override
  Future<Result<void>> submitVerification(VerificationDocument document) async {
    final res = await _service.submitVerification(document.toJson());
    return res.when(
      onSuccess: (_) => const Success<void>(null),
      onFailure: (error) => Failure<void>(error),
    );
  }

  BusinessProfile _profileFrom(dynamic json, {Map<String, dynamic>? userJson}) {
    if (json is Map<String, dynamic>) {
      return BusinessProfileDto.fromJson(json).toDomain(userJson: userJson);
    }
    return BusinessProfileDto.fromJson(
      const <String, dynamic>{},
    ).toDomain(userJson: userJson);
  }
}
