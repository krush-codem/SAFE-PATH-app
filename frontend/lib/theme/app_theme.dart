import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Deep Obsidian (Tinted Neutral)
  static const darkBackground = Color(0xFF0A0C10); 
  static const lightBackground = Color(0xFFF8F9FE);
  
  // Elevated Surfaces
  static const surfaceDark = Color(0xFF14171C); 
  static const surfaceLight = Colors.white;
  
  // Accents
  static const primaryBlue = Color(0xFF5C79FF); // Electric Blue
  static const secondaryCrimson = Color(0xFFF43F5E); // Urgent Rose/Crimson
  static const successEmerald = Color(0xFF10B981); // Success Green
  
  // Borders
  static const borderDark = Color(0xFF22262E); 
  static const borderLight = Color(0xFFE2E8F0);
  
  // Text
  static const textHighDark = Color(0xFFF1F5F9); 
  static const textHighLight = Color(0xFF0F172A);
  static const textMutedDark = Color(0xFF94A3B8);
  static const textMutedLight = Color(0xFF64748B);
}

class AppTheme {
  static ThemeData getTheme(ThemeMode mode, Color primaryColor, Color secondaryColor) {
    final isDark = mode == ThemeMode.dark;
    final brightness = isDark ? Brightness.dark : Brightness.light;
    
    final background = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final onSurface = isDark ? AppColors.textHighDark : AppColors.textHighLight;
    final onSurfaceMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: AppColors.primaryBlue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        brightness: brightness,
        primary: AppColors.primaryBlue,
        surface: surface,
        onSurface: onSurface,
        secondary: AppColors.secondaryCrimson,
        error: AppColors.secondaryCrimson,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.manrope(
          color: onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 32,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.manrope(
          color: onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 24,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.manrope(
          color: onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        headlineLarge: GoogleFonts.manrope(
          color: onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        headlineMedium: GoogleFonts.manrope(
          color: onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        titleLarge: GoogleFonts.manrope(
          color: onSurface,
          fontWeight: FontWeight.w600,
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
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          color: onSurfaceMuted,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          color: onSurfaceMuted,
          fontSize: 12,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: onSurface, size: 24),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 56),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF0F1216) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
        hintStyle: GoogleFonts.inter(color: onSurfaceMuted),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: GoogleFonts.inter(color: onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
      ),
    );
  }
  
  // Helper to get appropriate text color based on brightness
  static Color getTextColor(BuildContext context, {bool muted = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (muted) {
      return isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    }
    return isDark ? AppColors.textHighDark : AppColors.textHighLight;
  }
  
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? AppColors.darkBackground 
        : AppColors.lightBackground;
  }
  
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? AppColors.surfaceDark 
        : AppColors.surfaceLight;
  }
}
