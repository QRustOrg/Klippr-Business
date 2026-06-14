import 'package:bloc/bloc.dart';

import '../models/auth_response.dart';
import '../repository/iam_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

// author: Samuel Bonifacio
//
// BLoC de autenticación. Orquesta eventos/estados y replica la validación local
// del AuthViewModel de Android. La lógica de red vive en IamRepository.

/// Maneja el flujo de autenticación (sign-in, sign-up business, recuperación).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthState()) {
    on<SignInRequested>(_onSignIn);
    on<SignUpBusinessRequested>(_onSignUp);
    on<VerifyEmailRequested>(_onVerifyEmail);
    on<ResetPasswordRequested>(_onResetPassword);
    on<ResetFlagsConsumed>(_onConsumeFlags);
    on<ErrorConsumed>(_onConsumeError);
    on<CustomerBlockConsumed>(_onConsumeCustomerBlock);
  }

  final IamRepository _repo;

  /// Solo se bloquea el rol CONSUMER; BUSINESS y ADMIN entran.
  bool _isAllowed(String role) => role.toUpperCase() != 'CONSUMER';

  Future<void> _onSignIn(SignInRequested e, Emitter<AuthState> emit) async {
    if (e.email.trim().isEmpty || e.password.isEmpty) {
      emit(state.copyWith(error: 'Ingresa email y contraseña'));
      return;
    }
    emit(state.copyWith(isLoading: true, error: null));
    final res = await _repo.signIn(e.email, e.password);
    await res.when(
      onSuccess: (user) => _onAuthSuccess(user, emit),
      onFailure: (err) async => emit(state.copyWith(
        isLoading: false,
        error: err.message,
      )),
    );
  }

  Future<void> _onSignUp(
    SignUpBusinessRequested e,
    Emitter<AuthState> emit,
  ) async {
    if (e.businessName.trim().isEmpty ||
        e.taxId.trim().isEmpty ||
        e.email.trim().isEmpty ||
        e.password.isEmpty) {
      emit(state.copyWith(error: 'Completa todos los campos'));
      return;
    }
    emit(state.copyWith(isLoading: true, error: null));
    final res = await _repo.signUpBusiness(
      email: e.email,
      password: e.password,
      businessName: e.businessName,
      taxId: e.taxId,
    );
    await res.when(
      onSuccess: (user) => _onAuthSuccess(user, emit),
      onFailure: (err) async => emit(state.copyWith(
        isLoading: false,
        error: err.message,
      )),
    );
  }

  /// Maneja un login/registro exitoso: si el rol no está permitido (CONSUMER),
  /// cierra la sesión y gatilla el modal; si está permitido, fija el usuario.
  Future<void> _onAuthSuccess(
    AuthenticatedUser user,
    Emitter<AuthState> emit,
  ) async {
    if (!_isAllowed(user.role)) {
      await _repo.signOut();
      emit(state.copyWith(
        isLoading: false,
        user: null,
        customerBlocked: true,
      ));
      return;
    }
    emit(state.copyWith(isLoading: false, user: user));
  }

  Future<void> _onVerifyEmail(
    VerifyEmailRequested e,
    Emitter<AuthState> emit,
  ) async {
    if (e.email.trim().isEmpty) {
      emit(state.copyWith(error: 'Ingresa tu email'));
      return;
    }
    emit(state.copyWith(isLoading: true, error: null));
    final res = await _repo.forgotPassword(e.email);
    res.when(
      onSuccess: (_) => emit(state.copyWith(
        isLoading: false,
        emailVerified: true,
        forgotEmail: e.email.trim(),
      )),
      onFailure: (err) => emit(state.copyWith(
        isLoading: false,
        error: err.message,
      )),
    );
  }

  Future<void> _onResetPassword(
    ResetPasswordRequested e,
    Emitter<AuthState> emit,
  ) async {
    final email = state.forgotEmail;
    if (email == null || email.isEmpty) {
      emit(state.copyWith(error: 'Email no disponible, reinicia el flujo'));
      return;
    }
    if (e.newPassword.isEmpty || e.confirmPassword.isEmpty) {
      emit(state.copyWith(error: 'Completa todos los campos'));
      return;
    }
    if (e.newPassword != e.confirmPassword) {
      emit(state.copyWith(error: 'Las contraseñas no coinciden'));
      return;
    }
    if (e.newPassword.length < 6) {
      emit(state.copyWith(error: 'Mínimo 6 caracteres'));
      return;
    }
    emit(state.copyWith(isLoading: true, error: null));
    final res = await _repo.resetPassword(email, e.newPassword);
    res.when(
      onSuccess: (_) => emit(state.copyWith(isLoading: false, resetSuccess: true)),
      onFailure: (err) => emit(state.copyWith(
        isLoading: false,
        error: err.message,
      )),
    );
  }

  void _onConsumeFlags(ResetFlagsConsumed e, Emitter<AuthState> emit) {
    // Conserva forgotEmail; limpia el resto de flags del flujo.
    emit(state.copyWith(
      emailVerified: false,
      resetSuccess: false,
      error: null,
    ));
  }

  void _onConsumeError(ErrorConsumed e, Emitter<AuthState> emit) {
    emit(state.copyWith(error: null));
  }

  void _onConsumeCustomerBlock(
    CustomerBlockConsumed e,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(customerBlocked: false));
  }
}
