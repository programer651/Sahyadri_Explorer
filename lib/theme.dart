import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF061B0E);
  static const Color secondary = Color(0xFFA23F00);
  static const Color background = Color(0xFFFBF9F5);
  static const Color surface = Color(0xFFFBF9F5);
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onBackground = Color(0xFF1B1C1A);
  static const Color onSurface = Color(0xFF1B1C1A);
  static const Color primaryContainer = Color(0xFF1B3022);
  static const Color onPrimaryContainer = Color(0xFF819986);
  static const Color secondaryContainer = Color(0xFFFC7127);
  static const Color onSecondaryContainer = Color(0xFF5C2000);
  static const Color surfaceContainerLow = Color(0xFFF5F3EF);
  static const Color surfaceContainer = Color(0xFFEFEEEA);
  static const Color surfaceContainerHigh = Color(0xFFEAE8E4);
  static const Color surfaceContainerHighest = Color(0xFFE4E2DE);
  static const Color outline = Color(0xFF737973);
  static const Color outlineVariant = Color(0xFFC3C8C1);
  static const Color error = Color(0xFFBA1A1A);
  static const Color surfaceVariant = Color(0xFFE4E2DE);
  static const Color onSurfaceVariant = Color(0xFF434843);

  // Profile specific colors
  static const Color primaryFixed = Color(0xFFD0E9D4);
  static const Color onPrimaryFixed = Color(0xFF0B2013);
  static const Color primaryFixedDim = Color(0xFFB4CDB8);
  static const Color secondaryFixed = Color(0xFFFFDBCD);
  static const Color secondaryFixedDim = Color(0xFFEBB9A7);
  static const Color onSecondaryFixed = Color(0xFF351000);
  static const Color tertiaryFixed = Color(0xFFD3E4F8);
  static const Color onTertiaryFixed = Color(0xFF0C1D2B);
  static const Color tertiary = Color(0xFF071826);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceContainerHighest: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.64,
          height: 1.2,
          color: AppColors.primary,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.24,
          height: 1.3,
          color: AppColors.primary,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: AppColors.primary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 1.6,
          color: AppColors.onBackground,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: AppColors.onBackground,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          height: 1.0,
          color: AppColors.outline,
        ),
      ),
      scaffoldBackgroundColor: AppColors.background,
    );
  }
}
