import '../../../shared/data/network/result.dart';
import '../../../shared/data/pref/prefs_helper.dart';
import '../../domain/models/authenticated_user.dart';
import '../../domain/stores/authentication_store.dart';
import '../models/authenticated_user_dto.dart';
import '../network/iam_web_service.dart';
import '../network/requests/forgot_password_request.dart';
import '../network/requests/reset_password_request.dart';
import '../network/requests/sign_in_request.dart';
import '../network/requests/sign_up_business_request.dart';

// author: Samuel Bonifacio
//
// Adaptador (hexagonal) que implementa el puerto [AuthenticationStore] sobre
// el backend HTTP de Klippr, vía [IamWebService]. Parsea las respuestas a
// entidades de dominio, persiste el token de sesión y replica la lógica del
// proyecto Android (sign-up/business no devuelve token -> auto sign-in).

/// Adaptador HTTP del puerto [AuthenticationStore].
class HttpAuthenticationStore implements AuthenticationStore {
  /// Crea un [HttpAuthenticationStore] sobre [_service].
  HttpAuthenticationStore(this._service, {PrefsHelper? prefs})
    : _prefs = prefs ?? PrefsHelper.instance;

  final IamWebService _service;
  final PrefsHelper _prefs;

  @override
  Future<Result<AuthenticatedUser>> signIn(
    String email,
    String password,
  ) async {
    final res = await _service.signIn(
      SignInRequest(email: email.trim(), password: password),
    );
    return res.when(
      onSuccess: (json) async => _persistAndReturn(
        AuthenticatedUserDto.fromJson(_asMap(json)).toDomain(),
      ),
      onFailure: (e) async => Failure<AuthenticatedUser>(e),
    );
  }

  @override
  Future<Result<AuthenticatedUser>> signUpBusiness({
    required String email,
    required String password,
    required String businessName,
    required String taxId,
  }) async {
    final res = await _service.signUpBusiness(
      SignUpBusinessRequest(
        email: email.trim(),
        password: password,
        businessName: businessName.trim(),
        taxId: taxId.trim(),
      ),
    );
    return res.when(
      onSuccess: (_) => signIn(email, password), // auto-login
      onFailure: (e) async => Failure<AuthenticatedUser>(e),
    );
  }

  @override
  Future<Result<void>> forgotPassword(String email) async {
    final res = await _service.forgotPassword(
      ForgotPasswordRequest(email: email.trim()),
    );
    return res.when(
      onSuccess: (_) => const Success<void>(null),
      onFailure: (e) => Failure<void>(e),
    );
  }

  @override
  Future<Result<void>> resetPassword(String email, String newPassword) async {
    final res = await _service.resetPassword(
      ResetPasswordRequest(email: email.trim(), newPassword: newPassword),
    );
    return res.when(
      onSuccess: (_) => const Success<void>(null),
      onFailure: (e) => Failure<void>(e),
    );
  }

  @override
  Future<void> signOut() async {
    await _prefs.clearToken();
    await _prefs.clearUserId();
    await _prefs.clearProfileId();
  }

  Future<Result<AuthenticatedUser>> _persistAndReturn(
    AuthenticatedUser user,
  ) async {
    if (user.token.isNotEmpty) {
      await _prefs.setToken(user.token);
    }
    if (user.id.isNotEmpty) {
      await _prefs.setUserId(user.id.value);
    }
    return Success<AuthenticatedUser>(user);
  }

  Map<String, dynamic> _asMap(dynamic json) {
    if (json is Map<String, dynamic>) return json;
    return <String, dynamic>{};
  }
}
