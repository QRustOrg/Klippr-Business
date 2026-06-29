import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/bloc/auth_bloc.dart';
import '../views/forgot_password_screen.dart';
import '../views/reset_password_screen.dart';
import '../views/sign_in_screen.dart';
import '../views/sign_up_screen.dart';
import '../views/splash_session_screen.dart';

// author: Samuel Bonifacio
//
// Router del bounded context IAM. Expone constructores de [Route] para cada
// destino, de modo que el resto de la app navegue a través de un punto único
// en vez de instanciar cada pantalla inline. La app usa Navigator imperativo
// (no go_router); este router solo centraliza el armado de las rutas.

/// Construye las [Route] del flujo de autenticación.
abstract final class IamRouter {
  /// Ruta de la pantalla de splash/verificación de sesión.
  static Route<void> splash() {
    return MaterialPageRoute(builder: (_) => const SplashSessionScreen());
  }

  /// Ruta de la pantalla de inicio de sesión.
  static Route<void> signIn() {
    return MaterialPageRoute(builder: (_) => const SignInScreen());
  }

  /// Ruta del formulario de registro de negocio.
  static Route<void> signUp() {
    return MaterialPageRoute(builder: (_) => const SignUpScreen());
  }

  /// Ruta del paso 1 de recuperación (verificación de email).
  static Route<void> forgotPassword() {
    return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
  }

  /// Ruta del paso 2 de recuperación (nueva contraseña).
  static Route<void> resetPassword() {
    return MaterialPageRoute(builder: (_) => const ResetPasswordScreen());
  }

  /// Construye una ruta para [child] compartiendo el [AuthBloc] activo, para
  /// los destinos del propio flujo de auth que necesitan seguir escuchando
  /// el mismo bloc (p. ej. SignIn -> SignUp).
  static Route<void> withSharedBloc(AuthBloc bloc, Widget child) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider<AuthBloc>.value(value: bloc, child: child),
    );
  }
}
