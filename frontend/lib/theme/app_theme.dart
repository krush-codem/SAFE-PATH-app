import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const darkBackground = Color(0xFF000000); // Pure Black
  static const lightBackground = Color(0xFFF8F9FE);
  
  static const surfaceDark = Color(0xFF111111); // Very deep gray surface
  static const surfaceLight = Colors.white;
  
  static const textDark = Color(0xFF0F1724);
  static const textLight = Color(0xFFE0E0E0); // Soft Ivory/White
  static const textMutedDark = Color(0xFF5A6275);
  static const textMutedLight = Color(0xFF888888); // Muted Silver
  
  static const accentSmooth = Color(0xFF5C79FF); // Smooth Steel Blue
}

class AppTheme {
  static ThemeData getTheme(ThemeMode mode, Color primaryColor, Color secondaryColor) {
    final isDark = mode == ThemeMode.dark;
    final brightness = isDark ? Brightness.dark : Brightness.light;
    
    final background = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final onSurface = isDark ? AppColors.textLight : AppColors.textDark;
    final onSurfaceMuted = isDark ? AppColors.textMutedLight : AppColors.textMutedDark;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: primaryColor,
        surface: surface,
        onSurface: onSurface,
        background: background,
        onBackground: onSurface,
        secondary: secondaryColor,
        onSecondary: isDark ? Colors.white : Colors.black,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.manrope(
          color: onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 32,
        ),
        displayMedium: GoogleFonts.manrope(
          color: onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 24,
        ),
        displaySmall: GoogleFonts.manrope(
          color: onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        headlineLarge: GoogleFonts.manrope(
          color: onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        headlineMedium: GoogleFonts.manrope(
          color: onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        titleLarge: GoogleFonts.manrope(
          color: onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        titleMedium: GoogleFonts.manrope(
          color: onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: GoogleFonts.inter(
          color: onSurface,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.inter(
          color: onSurfaceMuted,
          fontSize: 14,
        ),
        bodySmall: GoogleFonts.inter(
          color: onSurfaceMuted,
          fontSize: 12,
        ),
        labelLarge: GoogleFonts.manrope(
          color: onSurfaceMuted,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.manrope(
          color: onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      dividerColor: onSurface.withValues(alpha: 0.1),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isDark ? Colors.white : Colors.black,
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E2633) : const Color(0xFFF0F2F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.inter(
          color: onSurfaceMuted.withValues(alpha: 0.5),
        ),
      ),
    );
  }
  
  // Helper to get appropriate text color based on brightness
  static Color getTextColor(BuildContext context, {bool muted = false}) {
    final brightness = Theme.of(context).brightness;
    if (muted) {
      return brightness == Brightness.dark ? AppColors.textMutedLight : AppColors.textMutedDark;
    }
    return brightness == Brightness.dark ? AppColors.textLight : AppColors.textDark;
  }
  
  static Color getBackgroundColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? AppColors.darkBackground : AppColors.lightBackground;
  }
  
  static Color getSurfaceColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surfaceLight;
  }
}
