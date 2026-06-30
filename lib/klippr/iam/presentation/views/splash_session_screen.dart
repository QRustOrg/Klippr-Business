import 'package:flutter/material.dart';

import '../../../shared/data/pref/prefs_helper.dart';
import '../../../promotions/presentation/navigation/promotions_router.dart';
import '../navigation/iam_router.dart';
import 'auth_colors.dart';

// author: Samuel Bonifacio
//
// Pantalla de splash que verifica si existe una sesión activa (token guardado).
// Si hay token, navega directamente al BusinessHomeScreen.
// Si no hay token o el recordado está vacío, navega al SignInScreen.

/// Splash que restaura la sesión si hay token válido.
class SplashSessionScreen extends StatefulWidget {
  const SplashSessionScreen({super.key});

  @override
  State<SplashSessionScreen> createState() => _SplashSessionScreenState();
}

class _SplashSessionScreenState extends State<SplashSessionScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final prefs = PrefsHelper.instance;
    final token = prefs.token;
    final hasRemembered = prefs.rememberMe;

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.of(context).pushReplacement(PromotionsRouter.home());
    } else if (hasRemembered) {
      Navigator.of(context).pushReplacement(IamRouter.signIn());
    } else {
      Navigator.of(context).pushReplacement(IamRouter.signIn());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.screenBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/klippr_lockup.png',
              height: 160,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: AuthColors.buttonPurple,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
