import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/presentation/widgets/klippr_field.dart';
import '../../../promotions/presentation/navigation/promotions_router.dart';
import '../../application/bloc/auth_bloc.dart';
import '../../application/bloc/auth_event.dart';
import '../../application/bloc/auth_state.dart';
import 'auth_colors.dart';

// author: Samuel Bonifacio
//
// Pantalla de registro. Port de SignUpScreen.kt adaptado al perfil Business:
// los campos son Business Name + Tax ID + Email + Password (el backend espera
// businessName y taxId). Tras un alta exitosa, el repositorio hace auto sign-in.

/// Pantalla de registro de negocio.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _businessName = TextEditingController();
  final _taxId = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _businessName.dispose();
    _taxId.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.screenBg,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.isAuthenticated) {
            Navigator.of(context).pushReplacement(
              PromotionsRouter.home(),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(
                          'assets/images/klippr_lockup.png',
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Create an account',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AuthColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    KlipprField(
                      controller: _businessName,
                      value: _businessName.text,
                      onChanged: (_) {},
                      label: 'Business Name',
                      hint: 'Ej: Pizzería Don Mario',
                    ),
                    const SizedBox(height: 16),
                    KlipprField(
                      controller: _taxId,
                      value: _taxId.text,
                      onChanged: (_) {},
                      label: 'Tax ID',
                      hint: 'Ej: 20123456789',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    KlipprField(
                      controller: _email,
                      value: _email.text,
                      onChanged: (_) {},
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    KlipprField(
                      controller: _password,
                      value: _password.text,
                      onChanged: (_) {},
                      label: 'Password',
                      isPassword: true,
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          state.error!,
                          style: const TextStyle(
                              color: AuthColors.errorRed, fontSize: 13),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state.isLoading
                            ? null
                            : () => context.read<AuthBloc>().add(
                                  SignUpBusinessRequested(
                                    businessName: _businessName.text,
                                    taxId: _taxId.text,
                                    email: _email.text,
                                    password: _password.text,
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
                                'Sign Up',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
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
