import '../../core/prefs/prefs_helper.dart';
import '../../core/utils/result.dart';
import '../mappers/auth_mapper.dart';
import '../models/auth_request.dart';
import '../models/auth_response.dart';
import '../services/iam_service.dart';

// author: Samuel Bonifacio
//
// Repositorio de IAM: abstrae el origen de datos para el BLoC. Parsea las
// respuestas a modelos, persiste el token de sesión y replica la lógica del
// proyecto Android (sign-up/business no devuelve token -> auto sign-in).

/// Coordina autenticación y persistencia de sesión.
class IamRepository {
  IamRepository(this._service, {PrefsHelper? prefs})
      : _prefs = prefs ?? PrefsHelper.instance;

  final IamService _service;
  final PrefsHelper _prefs;

  /// Inicia sesión. En éxito persiste el token y devuelve el usuario.
  Future<Result<AuthenticatedUser>> signIn(String email, String password) async {
    final res = await _service.signIn(
      SignInRequest(email: email.trim(), password: password),
    );
    return res.when(
      onSuccess: (json) async =>
          _persistAndReturn(AuthMapper.toAuthenticatedUser(json)),
      onFailure: (e) async => Failure<AuthenticatedUser>(e),
    );
  }

  /// Registra un negocio. El backend no devuelve token, así que tras un alta
  /// exitosa se hace un sign-in automático para obtener la sesión.
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

  /// Verifica que el email exista (paso 1 del flujo de recuperación).
  Future<Result<void>> forgotPassword(String email) async {
    final res = await _service.forgotPassword(
      ForgotPasswordRequest(email: email.trim()),
    );
    return res.when(
      onSuccess: (_) => const Success<void>(null),
      onFailure: (e) => Failure<void>(e),
    );
  }

  /// Fija la nueva contraseña del usuario identificado por email (paso 2).
  Future<Result<void>> resetPassword(String email, String newPassword) async {
    final res = await _service.resetPassword(
      ResetPasswordRequest(email: email.trim(), newPassword: newPassword),
    );
    return res.when(
      onSuccess: (_) => const Success<void>(null),
      onFailure: (e) => Failure<void>(e),
    );
  }

  /// Cierra sesión: borra el token persistido.
  Future<void> signOut() => _prefs.clearToken();

  Future<Result<AuthenticatedUser>> _persistAndReturn(
    AuthenticatedUser user,
  ) async {
    if (user.token.isNotEmpty) {
      await _prefs.setToken(user.token);
    }
    return Success<AuthenticatedUser>(user);
  }
}
