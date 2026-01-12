// lib/theme/cyberpunk_theme.dart - UPDATED COLORS
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CyberpunkTheme {
  // ==================== UPDATED COLOR PALETTE ====================

  // PRIMARY COLORS - UPDATED
  static const Color primaryPink = Color(0xFFFF10F0); // NEW: Brighter pink
  static const Color deepBlack = Color(
    0xFF000000,
  ); // NEW: Pure black for clean look

  // ORIGINAL COLORS (Keep these for compatibility)
  static const Color primaryCyan = Color(0xFF00F0FF);
  static const Color primaryPurple = Color(0xFFBD00FF);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color accentGreen = Color(0xFF00FF94);
  static const Color primaryBlue = Color(0xFF0080FF);

  // BACKWARDS COMPATIBILITY - Old color names
  static const Color background = deepBlack; // For old code
  static const Color statusBorrowed = primaryBlue; // For old code
  static const Color warningYellow = accentOrange; // For old code

  // SURFACE & BACKGROUND COLORS - UPDATED for cleaner look
  static const Color surfaceDark = Color(
    0xFF0A0A0A,
  ); // Very dark gray, almost black
  static const Color surfaceLight = Color(0xFF151515); // Slightly lighter
  static const Color cardDark = Color(0xFF050505); // Darker than surfaceDark

  // TEXT COLORS
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFE0E0E0);
  static const Color textMuted = Color(0xFF808080);

  // GRADIENTS
  static const LinearGradient pinkPurpleGradient = LinearGradient(
    colors: [primaryPink, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkCyanGradient = LinearGradient(
    colors: [primaryPink, primaryCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [deepBlack, surfaceDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // GLOW EFFECTS
  static List<BoxShadow> neonGlow(Color color, {double intensity = 0.5}) {
    // Clamp intensity to valid range (0.0 - 1.0)
    final validIntensity = intensity.clamp(0.0, 1.0);

    return [
      BoxShadow(
        color: color.withOpacity(validIntensity),
        blurRadius: 30,
        spreadRadius: 5,
      ),
      BoxShadow(
        color: color.withOpacity(validIntensity * 0.5),
        blurRadius: 15,
        spreadRadius: 2,
      ),
    ];
  }

  static BoxShadow pinkGlow = BoxShadow(
    color: primaryPink.withOpacity(0.3),
    blurRadius: 20,
    spreadRadius: 2,
  );

  // GLASS CARD DECORATION (For old code compatibility)
  static BoxDecoration glassCard({Color? color, double? opacity}) {
    return BoxDecoration(
      color: color?.withOpacity(opacity ?? 0.1) ?? surfaceDark,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: primaryPink.withOpacity(0.3), width: 1),
      boxShadow: [
        BoxShadow(color: primaryPink.withOpacity(0.1), blurRadius: 20),
      ],
    );
  }

  // TEXT STYLES
  static TextStyle get heading1 => GoogleFonts.orbitron(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: textPrimary,
    letterSpacing: 2,
  );

  static TextStyle get heading2 => GoogleFonts.orbitron(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 1.5,
  );

  static TextStyle get heading3 => GoogleFonts.rajdhani(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 1,
  );

  static TextStyle get bodyText =>
      GoogleFonts.rajdhani(fontSize: 14, color: textSecondary);

  static TextStyle get neonText => GoogleFonts.orbitron(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: primaryPink,
    letterSpacing: 2,
    shadows: [Shadow(color: primaryPink.withOpacity(0.5), blurRadius: 10)],
  );

  static TextStyle get buttonText => GoogleFonts.rajdhani(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 1,
  );

  // THEME DATA
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryPink,
      scaffoldBackgroundColor: deepBlack,
      colorScheme: ColorScheme.dark(
        primary: primaryPink,
        secondary: primaryCyan,
        surface: surfaceDark,
        error: accentOrange,
      ),
      cardColor: surfaceDark,
      dividerColor: primaryPink.withOpacity(0.2),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: deepBlack,
        elevation: 0,
        titleTextStyle: heading2.copyWith(fontSize: 20),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      // Bottom Navigation Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primaryPink,
        unselectedItemColor: textMuted,
        selectedLabelStyle: GoogleFonts.rajdhani(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.rajdhani(fontSize: 11),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryPink.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryPink.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryPink, width: 2),
        ),
        labelStyle: GoogleFonts.rajdhani(color: textMuted),
        hintStyle: GoogleFonts.rajdhani(color: textMuted),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryPink.withOpacity(0.2)),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPink,
          foregroundColor: textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: buttonText,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryPink,
          side: const BorderSide(color: primaryPink, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: buttonText,
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: heading1,
        displayMedium: heading2,
        displaySmall: heading3,
        bodyLarge: bodyText,
        bodyMedium: bodyText,
      ),
    );
  }
}
