import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/data/pref/prefs_helper.dart';
import '../../../shared/presentation/widgets/klippr_field.dart';
import '../../../promotions/presentation/navigation/promotions_router.dart';
import '../../application/bloc/auth_bloc.dart';
import '../../application/bloc/auth_event.dart';
import '../../application/bloc/auth_state.dart';
import '../navigation/iam_router.dart';
import 'auth_colors.dart';
import 'customer_blocked_dialog.dart';
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
  void initState() {
    super.initState();
    _loadRememberedUser();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _pushShared(Widget child) {
    final bloc = context.read<AuthBloc>();
    Navigator.of(context).push(IamRouter.withSharedBloc(bloc, child));
  }

  Future<void> _loadRememberedUser() async {
    final prefs = PrefsHelper.instance;
    final remember = prefs.rememberMe;
    final email = prefs.rememberedEmail;
    final password = prefs.rememberedPassword;
    if (!mounted) return;
    setState(() {
      _rememberMe = remember;
      if (remember && email != null && email.isNotEmpty) {
        _email.text = email;
      }
      if (remember && password != null && password.isNotEmpty) {
        _password.text = password;
      }
    });
  }

  Future<void> _syncRememberedUser() async {
    final prefs = PrefsHelper.instance;
    if (_rememberMe) {
      await prefs.setRememberedUser(
        email: _email.text,
        password: _password.text,
      );
    } else {
      await prefs.clearRememberedUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.screenBg,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state.isAuthenticated) {
            await _syncRememberedUser();
            if (!context.mounted) return;
            Navigator.of(context).pushReplacement(
              PromotionsRouter.home(),
            );
          } else if (state.customerBlocked) {
            context.read<AuthBloc>().add(const CustomerBlockConsumed());
            final goSignUp = await showCustomerBlockedDialog(context);
            if (goSignUp && context.mounted) {
              _pushShared(const SignUpScreen());
            }
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
