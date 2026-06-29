import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

// author: Samuel Bonifacio
//
// Tema de Klippr. Portado desde el proyecto Android (ui/theme/Theme.kt).
// Replica los ColorScheme claro y oscuro con los mismos colores de marca.
//
// La app fuerza el tema claro (fondo blanco en todas las pantallas), igual que
// `KlipprTheme(darkTheme = false)` en Kotlin. El color dinámico de Material You
// queda deshabilitado para preservar la identidad visual de Klippr.

/// Construye los [ThemeData] de la aplicación.
class AppTheme {
  const AppTheme._();

  /// Esquema claro — equivalente a `LightColorScheme` en Theme.kt.
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.klipprPurple,
    onPrimary: AppColors.white,
    // primaryContainer se usa para indicadores de navegación, chips, etc.
    primaryContainer: AppColors.klipprLavender,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.klipprPurpleDark,
    onSecondary: AppColors.white,
    error: Color(0xFFB3261E),
    onError: AppColors.white,
    surface: AppColors.white,
    onSurface: AppColors.onSurface,
    surfaceContainerHighest: AppColors.surfaceVariant,
  );

  /// Esquema oscuro — equivalente a `DarkColorScheme` en Theme.kt.
  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.klipprPurple,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.klipprLavender,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.purpleGrey80,
    onSecondary: AppColors.white,
    tertiary: AppColors.pink80,
    onTertiary: AppColors.white,
    error: Color(0xFFB3261E),
    onError: AppColors.white,
    surface: AppColors.onSurface,
    onSurface: AppColors.white,
  );

  /// Tema claro (el usado por defecto en la app).
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: _lightScheme,
        textTheme: AppTypography.textTheme,
        scaffoldBackgroundColor: AppColors.white,
      );

  /// Tema oscuro (disponible, pero no activo: la app fuerza claro).
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: _darkScheme,
        textTheme: AppTypography.textTheme,
      );
}
