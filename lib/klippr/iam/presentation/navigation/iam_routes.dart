// author: Samuel Bonifacio
//
// Catálogo canónico de los nombres de ruta del bounded context IAM.
// Centraliza los literales para mantener consistentes la navegación y los
// puntos de invocación. Las rutas se concretan en [IamRouter] como
// [MaterialPageRoute] (la app usa Navigator imperativo, no go_router).

/// Nombres simbólicos de las rutas del flujo de autenticación.
abstract final class IamRoutes {
  /// Pantalla de splash / verificación de sesión (punto de entrada).
  static const String splash = 'iam-splash';

  /// Pantalla de inicio de sesión.
  static const String signIn = 'iam-sign-in';

  /// Formulario de registro de negocio.
  static const String signUp = 'iam-sign-up';

  /// Paso 1 de recuperación: verificación de email.
  static const String forgotPassword = 'iam-forgot-password';

  /// Paso 2 de recuperación: nueva contraseña.
  static const String resetPassword = 'iam-reset-password';
}
