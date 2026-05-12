import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF061B0E);
  static const Color secondary = Color(0xFFA23F00);
  
  // Light Palette
  static const Color background = Color(0xFFFBF9F5);
  static const Color surface = Color(0xFFFBF9F5);
  static const Color outline = Color(0xFF737973);
  static const Color outlineVariant = Color(0xFFC3C8C1);
  
  // Dark Palette (Outdoor Premium)
  static const Color darkBackground = Color(0xFF0D0F0D);
  static const Color darkSurface = Color(0xFF141A16);
  static const Color darkSurfaceContainer = Color(0xFF1B231E);
  static const Color darkOutline = Color(0xFF8B938B);
  static const Color darkPrimary = Color(0xFFB4CDB8);
  static const Color darkSecondary = Color(0xFFFFB590);
  
  // Shared
  static const Color error = Color(0xFFBA1A1A);

  // Fixed/Accent Colors
  static const Color primaryFixedDim = Color(0xFFB4CDB8);
  static const Color secondaryFixedDim = Color(0xFFEBB9A7);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onSurface: Color(0xFF1B1C1A),
        onSurfaceVariant: Color(0xFF434843),
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: _textTheme(AppColors.primary),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkSecondary,
        surface: AppColors.darkSurface,
        onSurface: Colors.white,
        onSurfaceVariant: Color(0xFFC3C8C1),
        outline: AppColors.darkOutline,
        outlineVariant: Color(0xFF3F4940),
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: _textTheme(Colors.white),
      cardColor: AppColors.darkSurfaceContainer,
    );
  }

  static TextTheme _textTheme(Color baseTextColor) {
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.64,
        color: baseTextColor,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.24,
        color: baseTextColor,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: baseTextColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: baseTextColor.withValues(alpha: 0.8),
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: baseTextColor.withValues(alpha: 0.8),
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: baseTextColor.withValues(alpha: 0.5),
      ),
    );
  }
}
