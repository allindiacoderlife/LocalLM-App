import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Apple Glass Design System for iOS 26 — LocalLM
/// Translucent glassmorphism, specular highlights, spatial ambient depth,
/// and luminous Apple accent tints.
class AppTheme {
  AppTheme._();

  // ── Obsidian Glass (Dark Mode) ──
  static const Color darkBackground = Color(0xFF07080A);
  static const Color darkSurface = Color(0xFF101217);
  static const Color darkSurfaceVariant = Color(0xFF181B22);
  static const Color darkGlass = Color(0x22FFFFFF); // ~13% white frosted overlay
  static const Color darkGlassElevated = Color(0x30FFFFFF);
  static const Color darkGlassBorder = Color(0x28FFFFFF); // Specular rim
  static const Color darkGlassHairline = Color(0x18FFFFFF);

  // ── Crystal Glass (Light Mode) ──
  static const Color lightBackground = Color(0xFFF3F5F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFE9EDF2);
  static const Color lightGlass = Color(0x85FFFFFF); // ~52% white frosted overlay
  static const Color lightGlassElevated = Color(0xA8FFFFFF);
  static const Color lightGlassBorder = Color(0x28000000);
  static const Color lightGlassHairline = Color(0x14000000);

  // ── Luminous Accents ──
  static const Color accent = Color(0xFF0A84FF);
  static const Color accentLight = Color(0xFF409CFF);
  static const Color accentGlow = Color(0xFF00F2FE); // Spatial cyan reflection
  static const Color violetGlow = Color(0xFF5E5CE6);

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentLight,
        surface: darkSurface,
        surfaceContainerHighest: darkSurfaceVariant,
        onSurface: Color(0xFFFFFFFF),
      ),
      textTheme: GoogleFonts.interTextTheme(baseTextTheme).apply(
        bodyColor: const Color(0xFFFFFFFF),
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: darkSurface.withValues(alpha: 0.70),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkGlassBorder, width: 0.6),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface.withValues(alpha: 0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: darkGlassBorder, width: 0.7),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0071E3),
        secondary: accent,
        surface: lightSurface,
        surfaceContainerHighest: lightSurfaceVariant,
        onSurface: Color(0xFF0A0B0E),
      ),
      textTheme: GoogleFonts.interTextTheme(baseTextTheme).apply(
        bodyColor: const Color(0xFF0A0B0E),
        displayColor: const Color(0xFF0A0B0E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF0A0B0E)),
      ),
      cardTheme: CardThemeData(
        color: lightSurface.withValues(alpha: 0.75),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightGlassBorder, width: 0.6),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface.withValues(alpha: 0.88),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: lightGlassBorder, width: 0.7),
        ),
      ),
    );
  }
}
