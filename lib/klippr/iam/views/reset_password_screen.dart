import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/klippr_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'auth_colors.dart';

// author: Samuel Bonifacio
//
// Paso 2 del flujo "olvidé mi contraseña": fija la nueva contraseña. El email
// validado se lee del AuthBloc (forgotEmail). Al éxito (resetSuccess) vuelve a
// SignIn. Port de ResetPasswordScreen.kt.

/// Pantalla de recuperación de contraseña (paso 2).
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.screenBg,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.resetSuccess) {
            // Vuelve a la primera pantalla (SignIn) y limpia los flags.
            Navigator.of(context).popUntil((route) => route.isFirst);
            context.read<AuthBloc>().add(const ResetFlagsConsumed());
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 64),
                    const Text(
                      'Reset password',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AuthColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 48),
                    KlipprField(
                      controller: _newPassword,
                      value: _newPassword.text,
                      onChanged: (_) {},
                      label: 'New password',
                      isPassword: true,
                    ),
                    const SizedBox(height: 20),
                    KlipprField(
                      controller: _confirmPassword,
                      value: _confirmPassword.text,
                      onChanged: (_) {},
                      label: 'Confirm new password',
                      isPassword: true,
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        state.error!,
                        style: const TextStyle(
                            color: AuthColors.errorRed, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state.isLoading
                            ? null
                            : () => context.read<AuthBloc>().add(
                                  ResetPasswordRequested(
                                    newPassword: _newPassword.text,
                                    confirmPassword: _confirmPassword.text,
                                  ),
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AuthColors.buttonPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: state.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Change password',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back,
                        color: AuthColors.textDark),
                    tooltip: 'Volver',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
