// author: Samuel Bonifacio
//
// Eventos del BLoC de autenticación. Disparados por las vistas IAM.

/// Evento base de autenticación.
sealed class AuthEvent {
  const AuthEvent();
}

/// Solicita iniciar sesión.
class SignInRequested extends AuthEvent {
  const SignInRequested({
    required this.email,
    required this.password,
    this.rememberMe = true,
  });

  final String email;
  final String password;
  final bool rememberMe;
}

/// Solicita registrar un negocio.
class SignUpBusinessRequested extends AuthEvent {
  const SignUpBusinessRequested({
    required this.businessName,
    required this.taxId,
    required this.email,
    required this.password,
  });

  final String businessName;
  final String taxId;
  final String email;
  final String password;
}

/// Paso 1 recuperación: verifica que el email exista.
class VerifyEmailRequested extends AuthEvent {
  const VerifyEmailRequested(this.email);

  final String email;
}

/// Paso 2 recuperación: fija la nueva contraseña.
class ResetPasswordRequested extends AuthEvent {
  const ResetPasswordRequested({
    required this.newPassword,
    required this.confirmPassword,
  });

  final String newPassword;
  final String confirmPassword;
}

/// Limpia los flags del flujo de recuperación tras navegar.
class ResetFlagsConsumed extends AuthEvent {
  const ResetFlagsConsumed();
}

/// Limpia el error actual.
class ErrorConsumed extends AuthEvent {
  const ErrorConsumed();
}

/// Limpia el flag de bloqueo de customer tras mostrar el modal.
class CustomerBlockConsumed extends AuthEvent {
  const CustomerBlockConsumed();
}
