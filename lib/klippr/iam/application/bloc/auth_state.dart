import '../../domain/models/authenticated_user.dart';

// author: Samuel Bonifacio
//
// Estado de la pantalla de autenticación. Port de AuthUiState.kt.

/// Centinela para distinguir "no pasado" de "pasado como null" en copyWith.
const Object _unset = Object();

/// Estado inmutable del flujo de autenticación.
class AuthState {
  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.forgotEmail,
    this.emailVerified = false,
    this.resetSuccess = false,
    this.customerBlocked = false,
  });

  final bool isLoading;
  final AuthenticatedUser? user;
  final String? error;

  // Flujo "olvidé mi contraseña":
  final String? forgotEmail; // email validado, se conserva entre pantallas
  final bool emailVerified; // gatilla navegación a la pantalla de reset
  final bool resetSuccess; // gatilla volver a SignIn tras cambiar la contraseña

  /// True cuando un rol CONSUMER intentó entrar → gatilla el modal de bloqueo.
  final bool customerBlocked;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    Object? user = _unset,
    Object? error = _unset,
    Object? forgotEmail = _unset,
    bool? emailVerified,
    bool? resetSuccess,
    bool? customerBlocked,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user == _unset ? this.user : user as AuthenticatedUser?,
      error: error == _unset ? this.error : error as String?,
      forgotEmail:
          forgotEmail == _unset ? this.forgotEmail : forgotEmail as String?,
      emailVerified: emailVerified ?? this.emailVerified,
      resetSuccess: resetSuccess ?? this.resetSuccess,
      customerBlocked: customerBlocked ?? this.customerBlocked,
    );
  }
}
