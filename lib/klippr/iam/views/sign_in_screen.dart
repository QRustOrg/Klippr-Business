import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/klippr_field.dart';
import '../../promotions/views/business_home_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'auth_colors.dart';
import 'forgot_password_screen.dart';
import 'sign_up_screen.dart';

// author: Samuel Bonifacio
//
// Pantalla de inicio de sesión. Port 1:1 de SignInScreen.kt (mismos textos,
// espaciados y formas), cableada al AuthBloc.

/// Pantalla de inicio de sesión.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _pushShared(Widget child) {
    final bloc = context.read<AuthBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(value: bloc, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.screenBg,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.isAuthenticated) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const BusinessHomeScreen()),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
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
                    'Welcome to\nKlippr!',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AuthColors.textDark,
                      height: 42 / 34,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: AuthColors.buttonPurple,
                            onChanged: (v) =>
                                setState(() => _rememberMe = v ?? false),
                          ),
                          const Text(
                            'Remember me',
                            style: TextStyle(
                                color: AuthColors.textDark, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          _pushShared(const ForgotPasswordScreen()),
                      child: const Text(
                        'Forgot your password?',
                        style: TextStyle(
                          color: AuthColors.linkPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      state.error!,
                      style: const TextStyle(
                          color: AuthColors.errorRed, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: state.isLoading
                        ? null
                        : () => context.read<AuthBloc>().add(
                              SignInRequested(
                                email: _email.text,
                                password: _password.text,
                                rememberMe: _rememberMe,
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
                            'Log in',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => _pushShared(const SignUpScreen()),
                  child: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(
                            color: AuthColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        TextSpan(
                          text: 'Sign up',
                          style: TextStyle(
                            color: AuthColors.linkPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
