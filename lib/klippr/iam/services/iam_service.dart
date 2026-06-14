import '../../core/network/api_client.dart';
import '../../core/utils/result.dart';
import '../models/auth_request.dart';

// author: Samuel Bonifacio
//
// Cliente concreto de los endpoints de autenticación. Solo arma las peticiones
// y delega en ApiClient; el parseo a modelos vive en el repositorio. Todos los
// endpoints son públicos (auth: false).

/// Servicio HTTP de IAM (rutas /api/Authentication/*).
class IamService {
  IamService(this._api);

  final ApiClient _api;

  static const String _signIn = '/api/Authentication/sign-in';
  static const String _signUpBusiness = '/api/Authentication/sign-up/business';
  static const String _forgotPassword = '/api/Authentication/forgot-password';
  static const String _resetPassword = '/api/Authentication/reset-password';

  Future<Result<dynamic>> signIn(SignInRequest body) =>
      _api.post(_signIn, body: body.toJson(), auth: false);

  Future<Result<dynamic>> signUpBusiness(SignUpBusinessRequest body) =>
      _api.post(_signUpBusiness, body: body.toJson(), auth: false);

  Future<Result<dynamic>> forgotPassword(ForgotPasswordRequest body) =>
      _api.post(_forgotPassword, body: body.toJson(), auth: false);

  Future<Result<dynamic>> resetPassword(ResetPasswordRequest body) =>
      _api.put(_resetPassword, body: body.toJson(), auth: false);
}
