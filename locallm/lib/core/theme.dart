import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF141416);
  static const Color darkSurfaceVariant = Color(0xFF1E1E21);
  static const Color accent = Color(0xFF007AFF);
  static const Color accentLight = Color(0xFF0A84FF);

  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F7);
  static const Color lightSurfaceVariant = Color(0xFFEBEBED);

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
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x1FFFFFFF)),
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
        primary: accent,
        secondary: accentLight,
        surface: lightSurface,
        surfaceContainerHighest: lightSurfaceVariant,
        onSurface: Color(0xFF0B0B0C),
      ),
      textTheme: GoogleFonts.interTextTheme(baseTextTheme).apply(
        bodyColor: const Color(0xFF0B0B0C),
        displayColor: const Color(0xFF0B0B0C),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF0B0B0C)),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x1A000000)),
        ),
      ),
    );
  }
}
