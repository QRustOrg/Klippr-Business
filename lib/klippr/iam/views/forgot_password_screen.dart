import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/klippr_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'auth_colors.dart';
import 'reset_password_screen.dart';

// author: Samuel Bonifacio
//
// Paso 1 del flujo "olvidé mi contraseña": el usuario ingresa su email. Al
// verificarse (emailVerified) navega a ResetPasswordScreen. Port de
// ForgotPasswordScreen.kt.

/// Pantalla de recuperación de contraseña (paso 1).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.screenBg,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.emailVerified) {
            final bloc = context.read<AuthBloc>();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: const ResetPasswordScreen(),
                ),
              ),
            );
            bloc.add(const ResetFlagsConsumed());
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
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AuthColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 48),
                    KlipprField(
                      controller: _email,
                      value: _email.text,
                      onChanged: (_) {},
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
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
                            : () => context
                                .read<AuthBloc>()
                                .add(VerifyEmailRequested(_email.text)),
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
                                'Recover password',
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
