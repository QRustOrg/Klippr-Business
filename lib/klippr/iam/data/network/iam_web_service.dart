import '../../../shared/data/network/api_client.dart';
import '../../../shared/data/network/result.dart';
import 'requests/forgot_password_request.dart';
import 'requests/reset_password_request.dart';
import 'requests/sign_in_request.dart';
import 'requests/sign_up_business_request.dart';

// author: Samuel Bonifacio
//
// Cliente concreto de los endpoints de autenticación. Solo arma las
// peticiones y delega en [ApiClient]; el parseo a modelos vive en el store.
// Todos los endpoints son públicos (auth: false).

/// Servicio HTTP de IAM (rutas /api/Authentication/*).
class IamWebService {
  /// Crea un [IamWebService] sobre el [ApiClient] compartido.
  IamWebService(this._api);

  final ApiClient _api;

  static const String _signIn = '/api/Authentication/sign-in';
  static const String _signUpBusiness = '/api/Authentication/sign-up/business';
  static const String _forgotPassword = '/api/Authentication/forgot-password';
  static const String _resetPassword = '/api/Authentication/reset-password';

  /// Intercambia email/password por una sesión.
  Future<Result<dynamic>> signIn(SignInRequest body) =>
      _api.post(_signIn, body: body.toJson(), auth: false);

  /// Provisiona una cuenta de negocio nueva.
  Future<Result<dynamic>> signUpBusiness(SignUpBusinessRequest body) =>
      _api.post(_signUpBusiness, body: body.toJson(), auth: false);

  /// Verifica que el email exista (paso 1 de recuperación).
  Future<Result<dynamic>> forgotPassword(ForgotPasswordRequest body) =>
      _api.post(_forgotPassword, body: body.toJson(), auth: false);

  /// Fija la nueva contraseña (paso 2 de recuperación).
  Future<Result<dynamic>> resetPassword(ResetPasswordRequest body) =>
      _api.put(_resetPassword, body: body.toJson(), auth: false);
}
