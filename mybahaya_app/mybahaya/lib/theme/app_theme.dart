import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // Background gradient
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A0A0A),
      Color(0xFF2D1010),
      Color(0xFF1A0A14),
    ],
  );

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
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}

// Glass widget builder helper
class GlassBox extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? bgColor;
  final Color? borderColor;
  final double blurSigma;
  final BorderRadius? customRadius;

  const GlassBox({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.width,
    this.height,
    this.bgColor,
    this.borderColor,
    this.blurSigma = 20,
    this.customRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: customRadius ?? BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ColorFilter.matrix([
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor ?? AppTheme.glassWhite,
            borderRadius: customRadius ?? BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? AppTheme.glassBorder,
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// Improved Glass Box with blur
class LiquidGlassBox extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? bgColor;
  final Color? borderColor;
  final BorderRadius? customRadius;
  final List<BoxShadow>? shadows;

  const LiquidGlassBox({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.width,
    this.height,
    this.bgColor,
    this.borderColor,
    this.customRadius,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: customRadius ?? BorderRadius.circular(borderRadius),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: customRadius ?? BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor ?? Colors.white.withOpacity(0.08),
            borderRadius: customRadius ?? BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? Colors.white24,
              width: 1.0,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.04),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
