import '../../../shared/data/network/api_exceptions.dart';
import '../../../shared/data/network/result.dart';
import '../../../shared/data/pref/prefs_helper.dart';
import '../../../shared/domain/models/id.dart';
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

    // 1) Candidatos conocidos: sesión, mapeo por usuario, userId.
    final candidates = <String>[];
    void addCandidate(String? id) {
      final value = id?.trim() ?? '';
      if (value.isEmpty) return;
      if (!candidates.contains(value)) candidates.add(value);
    }

    addCandidate(_prefs.profileId);
    addCandidate(_prefs.profileIdForUser(userId));
    addCandidate(userId);

    ApiException? lastHardError;
    var sawNotFound = false;

    for (final id in candidates) {
      final res = await _service.getBusinessProfile(id);
      final json = res.dataOrNull;
      if (json != null) {
        final profile = _profileFrom(json);
        if (!_belongsToUser(profile, userId) && id != userId) {
          // ProfileId de otro usuario (cambio de cuenta residual).
          continue;
        }
        return _persistAndReturn(profile);
      }
      final err = res.errorOrNull;
      if (err is NotFoundException) {
        sawNotFound = true;
      } else if (err != null) {
        lastHardError = err;
      }
    }

    // 2) Descubrir profileId real vía promociones / nombre de negocio.
    final discoveredId = await _discoverProfileId(userId);
    if (discoveredId != null && discoveredId.isNotEmpty) {
      final res = await _service.getBusinessProfile(discoveredId);
      final json = res.dataOrNull;
      if (json != null) {
        final profile = _profileFrom(json);
        if (_belongsToUser(profile, userId) || profile.userId.value.isEmpty) {
          return _persistAndReturn(profile);
        }
      } else {
        final err = res.errorOrNull;
        if (err is! NotFoundException && err != null) {
          lastHardError = err;
        } else if (err is NotFoundException) {
          sawNotFound = true;
        }
      }
    }

    // 3) Error de red/servidor: no crear perfil nuevo (perdería verificación).
    if (lastHardError != null && !sawNotFound) {
      return Failure<BusinessProfile>(lastHardError);
    }

    // 4) Solo crear si realmente no existe.
    return _createFromUser(userId);
  }

  /// True si el perfil pertenece al usuario autenticado.
  bool _belongsToUser(BusinessProfile profile, String userId) {
    final owner = profile.userId.value.trim();
    if (owner.isEmpty) return true; // backend a veces omite userId
    return owner == userId || profile.id.value == userId;
  }

  Future<Result<BusinessProfile>> _persistAndReturn(
    BusinessProfile profile,
  ) async {
    if (profile.id.isNotEmpty) {
      await _prefs.setProfileId(profile.id.value);
    }
    return Success<BusinessProfile>(profile);
  }

  /// Intenta recuperar el profileId/businessId existente sin crear uno nuevo.
  Future<String?> _discoverProfileId(String userId) async {
    // a) Promociones asociadas al userId como businessId.
    final byUser = await _service.getPromotionsByBusiness(userId);
    final fromUserPromos = _firstBusinessId(byUser.dataOrNull);
    if (fromUserPromos != null) return fromUserPromos;

    // b) Nombre del negocio en IAM → buscar en listado de promos.
    final userRes = await _service.getUser(userId);
    final userJson = _asMap(userRes.dataOrNull);
    final businessName = userJson['businessName']?.toString().trim() ?? '';
    if (businessName.isEmpty) return null;

    final allRes = await _service.getAllPromotions();
    final ids = _businessIdsForName(allRes.dataOrNull, businessName);
    for (final id in ids) {
      if (id == userId) continue;
      final profileRes = await _service.getBusinessProfile(id);
      final json = profileRes.dataOrNull;
      if (json == null) continue;
      final profile = _profileFrom(json);
      if (_belongsToUser(profile, userId)) return profile.id.value;
      // Si el backend no expone userId, preferir el primer match por nombre.
      if (profile.userId.value.isEmpty) return profile.id.value;
    }
    return ids.isEmpty ? null : ids.first;
  }

  String? _firstBusinessId(dynamic json) {
    final list = _asList(json);
    for (final item in list) {
      if (item is! Map) continue;
      final id = item['businessId']?.toString().trim();
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }

  List<String> _businessIdsForName(dynamic json, String businessName) {
    final target = businessName.toLowerCase();
    final ids = <String>[];
    for (final item in _asList(json)) {
      if (item is! Map) continue;
      final name = item['businessName']?.toString().trim().toLowerCase() ?? '';
      if (name != target) continue;
      final id = item['businessId']?.toString().trim() ?? '';
      if (id.isNotEmpty && !ids.contains(id)) ids.add(id);
    }
    return ids;
  }

  List<dynamic> _asList(dynamic json) {
    if (json is List) return json;
    if (json is Map) {
      for (final key in const ['data', 'items', 'content', 'promotions']) {
        final nested = json[key];
        if (nested is List) return nested;
      }
    }
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic json) {
    if (json is Map<String, dynamic>) return json;
    if (json is Map) return Map<String, dynamic>.from(json);
    return const {};
  }

  Future<Result<BusinessProfile>> _createFromUser(String userId) async {
    final userRes = await _service.getUser(userId);
    final userJson = _asMap(userRes.dataOrNull);
    final createBody = <String, dynamic>{
      'businessName': userJson['businessName'] ?? '',
      'taxId': userJson['taxId'] ?? '',
      'category': {'name': 'OTHER'},
    };
    final createRes = await _service.createBusinessProfile(createBody);
    return createRes.when(
      onSuccess: (json) async {
        final profile = _profileFrom(json, userJson: userJson);
        return _persistAndReturn(profile);
      },
      onFailure: (error) async {
        // Si el perfil ya existe (conflicto), intentar redescubrirlo.
        if (error is ValidationException ||
            error.statusCode == 409 ||
            error.message.toLowerCase().contains('exist') ||
            error.message.toLowerCase().contains('already') ||
            error.message.toLowerCase().contains('ya exist')) {
          final discoveredId = await _discoverProfileId(userId);
          if (discoveredId != null) {
            final res = await _service.getBusinessProfile(discoveredId);
            final json = res.dataOrNull;
            if (json != null) {
              return _persistAndReturn(_profileFrom(json, userJson: userJson));
            }
          }
        }
        final fallbackProfile = BusinessProfile(
          id: Id(userId),
          userId: Id(userId),
          businessName: userJson['businessName']?.toString() ?? 'Mi Negocio',
          taxId: userJson['taxId']?.toString(),
          email: userJson['email']?.toString(),
          verificationStatus: 'NONE',
        );
        return Success<BusinessProfile>(fallbackProfile);
      },
    );
  }

  @override
  Future<Result<BusinessProfile>> updateBusinessProfile(
    BusinessProfileUpdate update,
  ) async {
    final res = await _service.updateBusinessProfile(update.toJson());
    return res.when(
      onSuccess: (json) async {
        if (json is Map && json.isNotEmpty) {
          final profile = _profileFrom(json);
          if (profile.id.isNotEmpty) {
            await _prefs.setProfileId(profile.id.value);
          }
          return Success<BusinessProfile>(profile);
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
    if (json is Map) {
      return BusinessProfileDto.fromJson(
        Map<String, dynamic>.from(json),
      ).toDomain(userJson: userJson);
    }
    return BusinessProfileDto.fromJson(
      const <String, dynamic>{},
    ).toDomain(userJson: userJson);
  }
}
