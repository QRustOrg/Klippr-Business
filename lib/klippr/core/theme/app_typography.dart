// author: Samuel Bonifacio
//
// Tipografía de Klippr. Portada desde el proyecto Android (ui/theme/Type.kt).
// Mantiene el estilo base bodyLarge con los mismos valores (16sp, line-height
// 24sp -> height 1.5, letterSpacing 0.5).

import 'package:flutter/material.dart';

/// Estilos de texto base de la app.
class AppTypography {
  const AppTypography._();

  /// TextTheme equivalente al `Typography` de Material3 en Android.
  static const TextTheme textTheme = TextTheme(
    bodyLarge: TextStyle(
      fontFamily: null, // FontFamily.Default
      fontWeight: FontWeight.w400, // FontWeight.Normal
      fontSize: 16, // 16.sp
      height: 1.5, // lineHeight 24.sp / fontSize 16.sp
      letterSpacing: 0.5, // 0.5.sp
    ),
    // Otros estilos por defecto a sobreescribir en el futuro (titleLarge,
    // labelSmall, etc.), tal como están comentados en Type.kt.
  );
}
