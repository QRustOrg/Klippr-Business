import 'package:flutter/material.dart';

import '../iam/views/auth_colors.dart';

// author: Samuel Bonifacio
//
// Pantalla temporal tras autenticarse. Se reemplazará al cablear el dashboard
// Business real.

/// Placeholder de inicio post-login.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AuthColors.screenBg,
      body: Center(
        child: Text(
          'Klippr Business',
          style: TextStyle(
            color: AuthColors.textDark,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
