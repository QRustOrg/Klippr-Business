import 'package:flutter/material.dart';

import 'package:klippr/klippr/core/prefs/prefs_helper.dart';
import 'package:klippr/klippr/core/theme/app_theme.dart';

// author: Samuel Bonifacio
//
// Punto de entrada de la app Klippr Business. Inicializa la persistencia ligera
// y aplica el tema de marca (claro) definido en core/theme.

Future<void> main() async {
  // Necesario antes de usar plugins (shared_preferences) previo a runApp.
  WidgetsFlutterBinding.ensureInitialized();
  await PrefsHelper.instance.init();
  runApp(const KlipprBusinessApp());
}

class KlipprBusinessApp extends StatelessWidget {
  const KlipprBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klippr Business',
      debugShowCheckedModeBanner: false,
      // La app fuerza el tema claro (identidad visual de Klippr).
      theme: AppTheme.light,
      home: const _Placeholder(),
    );
  }
}

/// Pantalla temporal hasta cablear la navegación por bounded context.
class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Klippr Business')),
    );
  }
}
