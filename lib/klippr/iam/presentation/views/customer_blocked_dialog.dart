import 'package:flutter/material.dart';

import 'auth_colors.dart';

// author: Samuel Bonifacio
//
// Modal mostrado cuando un usuario CONSUMER intenta entrar. Klippr Business es
// solo para negocios; invita a registrarse como Business.

/// Muestra el modal de bloqueo. Devuelve true si el usuario eligió
/// "Registrarme como Business".
Future<bool> showCustomerBlockedDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _CustomerBlockedDialog(),
  );
  return result ?? false;
}

class _CustomerBlockedDialog extends StatelessWidget {
  const _CustomerBlockedDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AuthColors.screenBg,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/klippr_mascot.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Solo para negocios',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AuthColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Esta cuenta es de cliente. Klippr Business es exclusivo para '
              'negocios. Regístrate como Business para crear y gestionar tus '
              'promociones.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AuthColors.textGray),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuthColors.buttonPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: const Text(
                  'Registrarme como Business',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cerrar',
                style: TextStyle(
                  color: AuthColors.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
