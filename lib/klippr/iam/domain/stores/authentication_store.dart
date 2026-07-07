// NOTA: [Result]/[ApiException] viven en shared/data/network por decision
// consciente (se mantuvo Result<T> en vez de migrar a excepciones); es la
// unica concesion a la pureza hexagonal estricta en este puerto.

import '../../../shared/data/network/result.dart';
import '../models/authenticated_user.dart';

// author: Samuel Bonifacio
//
// Puerto (hexagonal) que describe las capacidades de identidad y acceso que
// necesita la capa de aplicación. Se expresa únicamente en términos de tipos
// de dominio y [Result], agnóstico del origen de datos concreto (HTTP, mock).
// El adaptador concreto vive en `data/stores/`.

/// Puerto de autenticación del bounded context IAM.
abstract interface class AuthenticationStore {
  /// Inicia sesión con email/password y persiste el token en éxito.
  Future<Result<AuthenticatedUser>> signIn(String email, String password);

  /// Registra un negocio y persiste el token. El backend devuelve
  /// AuthenticatedUser con token, userId, email y role.
  Future<Result<AuthenticatedUser>> signUpBusiness({
    required String email,
    required String password,
    required String businessName,
    required String taxId,
  });

  /// Verifica que el email exista (paso 1 de recuperación de contraseña).
  Future<Result<void>> forgotPassword(String email);

  /// Fija la nueva contraseña del usuario identificado por email (paso 2).
  Future<Result<void>> resetPassword(String email, String newPassword);

  /// Cierra la sesión activa, eliminando las credenciales persistidas.
  Future<void> signOut();
}
