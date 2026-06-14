// author: Samuel Bonifacio
//
// Paleta de colores de Klippr. Portada exactamente desde el proyecto Android
// (ui/theme/Color.kt). Los valores ARGB son idénticos a los de Kotlin.

import 'package:flutter/material.dart';

/// Colores de marca y tonos auxiliares de Klippr.
class AppColors {
  const AppColors._();

  // Paleta de marca Klippr.
  static const Color klipprPurple = Color(0xFF887BF3);
  static const Color klipprLavender = Color(0xFFF0D8FF);
  static const Color klipprPurpleDark = Color(0xFF6B5ECC);

  // Tonos claros (80).
  static const Color purple80 = Color(0xFFD0BCFF);
  static const Color purpleGrey80 = Color(0xFFCCC2DC);
  static const Color pink80 = Color(0xFFEFB8C8);

  // Tonos oscuros (40).
  static const Color purple40 = Color(0xFF6650A4);
  static const Color purpleGrey40 = Color(0xFF625B71);
  static const Color pink40 = Color(0xFF7D5260);

  // Colores de soporte usados por el esquema (tomados de Theme.kt).
  static const Color onPrimaryContainer = Color(0xFF21005D);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color surfaceVariant = Color(0xFFF3F3F3);
  static const Color white = Color(0xFFFFFFFF);
}
