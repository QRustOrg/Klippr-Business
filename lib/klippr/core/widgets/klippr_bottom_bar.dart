import 'package:flutter/material.dart';

import '../../promotions/views/promo_colors.dart';

// author: Samuel Bonifacio
//
// Barra de navegación inferior compartida (3 tabs: + QR, Inicio, Mi Lista).
// Portada de KlipprBottomBar/CreateBottomBar del proyecto Android.

/// Pestañas de la barra inferior.
enum KlipprTab { qr, inicio, miLista, historial }

/// Barra de navegación inferior de Klippr Business.
class KlipprBottomBar extends StatelessWidget {
  const KlipprBottomBar({
    super.key,
    required this.current,
    this.onQr,
    this.onInicio,
    this.onMiLista,
    this.onHistorial,
  });

  final KlipprTab current;
  final VoidCallback? onQr;
  final VoidCallback? onInicio;
  final VoidCallback? onMiLista;
  final VoidCallback? onHistorial;

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
      child: NavigationBar(
        height: 68,
        backgroundColor: Colors.white,
        indicatorColor: PromoColors.lavender,
        selectedIndex: current.index,
        onDestinationSelected: (i) {
          switch (KlipprTab.values[i]) {
            case KlipprTab.qr:
              onQr?.call();
            case KlipprTab.inicio:
              onInicio?.call();
            case KlipprTab.miLista:
              onMiLista?.call();
            case KlipprTab.historial:
              onHistorial?.call();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.apps, color: PromoColors.textGray),
            selectedIcon: Icon(Icons.apps, color: PromoColors.purple),
            label: '+ QR',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: PromoColors.textGray),
            selectedIcon: Icon(Icons.home, color: PromoColors.purple),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined, color: PromoColors.textGray),
            selectedIcon: Icon(Icons.inbox, color: PromoColors.purple),
            label: 'Mi Lista',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, color: PromoColors.textGray),
            selectedIcon: Icon(Icons.receipt_long, color: PromoColors.purple),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}
