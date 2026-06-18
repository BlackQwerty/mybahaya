import 'package:flutter/material.dart';

class AppTheme {
  // Deep Maroon Background Palette
  static const Color backgroundDeep = Color(0xFF1A0A0A);
  static const Color backgroundMid = Color(0xFF2D1010);
  static const Color backgroundAccent = Color(0xFF3D1515);
  static const Color maroonPrimary = Color(0xFF8B1A1A);
  static const Color maroonLight = Color(0xFFB22222);
  static const Color maroonGlow = Color(0xFFFF3333);

  // Liquid Glass Colors
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassBorderBright = Color(0x4DFFFFFF);
  static const Color glassText = Color(0xFFFFFFFF);
  static const Color glassSubText = Color(0xB3FFFFFF);
  static const Color glassHint = Color(0x66FFFFFF);

  // Alert Colors
  static const Color alertRed = Color(0xFFFF3B30);
  static const Color alertYellow = Color(0xFFFFCC00);
  static const Color alertGreen = Color(0xFF34C759);

  // Plain background — no gradient
  static const Color solidBg = Color(0xFF341515);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: solidBg,
      colorScheme: const ColorScheme.dark(
        primary: maroonLight,
        secondary: maroonGlow,
        surface: backgroundMid,
        error: alertRed,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }

  static TextStyle get sourceSerif4 => TextStyle(
        fontWeight: FontWeight.w700,
      );

  static TextStyle get sourceSans3 => TextStyle(
        fontWeight: FontWeight.w400,
      );
}