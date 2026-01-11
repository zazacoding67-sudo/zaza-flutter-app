import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CyberpunkTheme {
  // Cyberpunk Colors - Pink, Purple, Cyan
  static const Color primaryPink = Color(0xFFFF006E);
  static const Color primaryPurple = Color(0xFF8338EC);
  static const Color primaryCyan = Color(0xFF06FFF0);
  static const Color primaryBlue = Color(0xFF06FFF0); // Alias for cyan
  static const Color darkPurple = Color(0xFF3A0CA3);
  static const Color deepBlack = Color(0xFF0A0E27);
  static const Color cardDark = Color(0xFF1A1F3A);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color accentGreen = Color(0xFF39FF14); // Alias
  static const Color accentOrange = Color(0xFFFF6B35);

  // Background colors
  static const Color background = deepBlack;
  static const Color surfaceDark = cardDark;
  static const Color surfaceLight = Color(0xFF2A2F4A);

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB8B8D1);
  static const Color textMuted = Color(0xFF6B6B8A);

  // Status colors
  static const Color statusBorrowed = accentOrange;
  static const Color statusMaintenance = primaryPurple;
  static const Color statusAvailable = neonGreen;

  // Gradients
  static const LinearGradient pinkPurpleGradient = LinearGradient(
    colors: [primaryPink, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleCyanGradient = LinearGradient(
    colors: [primaryPurple, primaryCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkCyanGradient = LinearGradient(
    colors: [primaryPink, primaryCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = pinkPurpleGradient; // Alias

  static const LinearGradient darkGradient = LinearGradient(
    colors: [deepBlack, cardDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF39FF14), Color(0xFF00D9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF006E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles with Cyberpunk Fonts
  static TextStyle heading1 = GoogleFonts.orbitron(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 2,
  );

  static TextStyle heading2 = GoogleFonts.orbitron(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 1.5,
  );

  static TextStyle heading3 = GoogleFonts.orbitron(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 1,
  );

  static TextStyle bodyText = GoogleFonts.rajdhani(
    fontSize: 16,
    color: Colors.white70,
    fontWeight: FontWeight.w500,
  );

  static TextStyle buttonText = GoogleFonts.orbitron(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 2,
  );

  static TextStyle neonText = GoogleFonts.orbitron(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: neonGreen,
    letterSpacing: 1.5,
    shadows: [Shadow(color: neonGreen, blurRadius: 10)],
  );

  // Card Decoration
  static BoxDecoration glassCard({Color? color}) {
    return BoxDecoration(
      color: color ?? cardDark.withOpacity(0.3),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: primaryCyan.withOpacity(0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: primaryPurple.withOpacity(0.2),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration neonCard({required Color color}) {
    return BoxDecoration(
      color: cardDark.withOpacity(0.5),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color, width: 2),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.5),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }

  // Button Styles
  static ButtonStyle primaryButton =
      ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: primaryPink, width: 2),
        ),
        elevation: 0,
      ).copyWith(
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.pressed)) {
            return primaryPink.withOpacity(0.2);
          }
          return Colors.transparent;
        }),
      );

  static ButtonStyle neonButton(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color, width: 2),
      ),
      elevation: 0,
    ).copyWith(shadowColor: MaterialStateProperty.all(color.withOpacity(0.5)));
  }

  // Dark Theme Data
  static ThemeData get darkTheme => theme;

  // Theme Data
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepBlack,
      primaryColor: primaryPink,
      cardColor: cardDark,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 2,
        ),
        iconTheme: const IconThemeData(color: primaryCyan),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardDark.withOpacity(0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryCyan.withOpacity(0.3)),
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

      // Icon Theme
      iconTheme: const IconThemeData(color: primaryCyan, size: 24),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryCyan.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryCyan.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryPink, width: 2),
        ),
        labelStyle: GoogleFonts.rajdhani(color: Colors.white70, fontSize: 16),
        hintStyle: GoogleFonts.rajdhani(color: Colors.white30, fontSize: 14),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardDark,
        selectedItemColor: primaryPink,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.orbitron(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.rajdhani(fontSize: 12),
      ),

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryPink,
        secondary: primaryPurple,
        tertiary: primaryCyan,
        surface: cardDark,
        background: deepBlack,
        error: Color(0xFFFF3366),
      ),
    );
  }

  // Neon Glow Effect
  static List<BoxShadow> neonGlow(Color color, {double intensity = 1.0}) {
    return [
      BoxShadow(
        color: color.withOpacity(0.6 * intensity),
        blurRadius: 20,
        spreadRadius: 2,
      ),
      BoxShadow(
        color: color.withOpacity(0.3 * intensity),
        blurRadius: 40,
        spreadRadius: 5,
      ),
    ];
  }

  // Animated Container Decoration
  static BoxDecoration animatedBorder({
    required Color color1,
    required Color color2,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        colors: [color1, color2, color1],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
}

// CyberButton Widget
class CyberButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Gradient? gradient;
  final Color? glowColor;
  final IconData? icon;
  final bool isSmall;

  const CyberButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradient,
    this.glowColor,
    this.icon,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGlowColor = glowColor ?? CyberpunkTheme.primaryPink;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? CyberpunkTheme.pinkPurpleGradient,
        borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
        boxShadow: CyberpunkTheme.neonGlow(effectiveGlowColor),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 16 : 24,
            vertical: isSmall ? 10 : 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: isSmall ? 16 : 20),
              SizedBox(width: isSmall ? 6 : 8),
            ],
            Text(
              text,
              style: CyberpunkTheme.buttonText.copyWith(
                fontSize: isSmall ? 11 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// CyberCard Widget
class CyberCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final Color? backgroundColor;

  const CyberCard({
    super.key,
    required this.child,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? CyberpunkTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? CyberpunkTheme.primaryCyan.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (borderColor ?? CyberpunkTheme.primaryPurple).withOpacity(
              0.2,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
