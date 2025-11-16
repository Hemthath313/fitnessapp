import 'package:flutter/material.dart';

/// Modern Fitness App Color Palette
/// Designed for energy, motivation, and excellent user experience
class ColorManager {
  // ========== PRIMARY COLORS ==========
  /// Primary brand color - Vibrant green (energy, fitness, growth)
  static const Color primary = Color(0xFF00D4AA); // Teal green
  static const Color primaryDark = Color(0xFF00B894);
  static const Color primaryLight = Color(0xFF26E6C7);
  
  // ========== SECONDARY COLORS ==========
  /// Secondary accent - Orange (motivation, action, achievement)
  static const Color secondary = Color(0xFFFF6B35); // Vibrant orange
  static const Color secondaryDark = Color(0xFFE55A2B);
  static const Color secondaryLight = Color(0xFFFF8C5A);
  
  // ========== BACKGROUND COLORS ==========
  /// Main background - Dark but not pure black (easier on eyes)
  static const Color background = Color(0xFF0F1419); // Dark blue-grey
  static const Color backgroundDark = Color(0xFF0A0E12); // Darker variant
  static const Color backgroundLight = Color(0xFF1A1F26); // Lighter variant
  
  /// Card/Surface colors
  static const Color surface = Color(0xFF1E2329); // Card background
  static const Color surfaceDark = Color(0xFF171B21);
  static const Color surfaceLight = Color(0xFF252A32);
  
  // ========== TEXT COLORS ==========
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB8BCC8); // Light grey
  static const Color textTertiary = Color(0xFF8A8D98); // Medium grey
  static const Color textDisabled = Color(0xFF5A5D66); // Dark grey
  
  // ========== ACCENT COLORS ==========
  /// Success/Positive actions
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  
  /// Warning/Caution
  static const Color warning = Color(0xFFFFB74D);
  static const Color warningLight = Color(0xFFFFCC80);
  
  /// Error/Danger
  static const Color error = Color(0xFFEF5350);
  static const Color errorLight = Color(0xFFE57373);
  
  /// Info/Information
  static const Color info = Color(0xFF42A5F5);
  static const Color infoLight = Color(0xFF64B5F6);
  
  // ========== GRADIENT COLORS ==========
  /// Gradient start (for backgrounds, buttons)
  static const Color gradientStart = Color(0xFF00D4AA);
  static const Color gradientEnd = Color(0xFF00A8CC);
  
  /// Secondary gradient
  static const Color gradientSecondaryStart = Color(0xFFFF6B35);
  static const Color gradientSecondaryEnd = Color(0xFFFF8E53);
  
  // ========== LEGACY COLORS (for backward compatibility) ==========
  /// Keep old colors for compatibility, map to new ones
  static const Color black = background;
  static const Color black54 = Color.fromARGB(138, 15, 20, 25);
  static const Color black87 = Color.fromARGB(222, 15, 20, 25);
  static const Color white = textPrimary;
  static const Color white70 = textSecondary;
  static const Color white2 = textTertiary;
  static const Color darkGrey = background;
  static const Color grey = textTertiary;
  static const Color lighGrey = textSecondary;
  static Color grey3 = surface;
  static Color limerGreen2 = primary; // Map old lime green to new primary
  static Color drinkDarkGrey = surfaceDark;
  static final Color grey2 = textTertiary;
  
  // ========== UTILITY COLORS ==========
  static const Color red = error;
  static const Color yellow = warning;
  static const Color blue = info;
  static const Color orange = secondary;
  static const Color orange2 = Color.fromARGB(67, 255, 107, 53);
  static const Color limeGreen = primary;
  static const Color limeGreenOp = Color.fromARGB(73, 0, 212, 170);
  static const Color brightThemeGrey = textSecondary;
  
  // ========== OVERLAY COLORS ==========
  /// For overlays, modals, etc.
  static const Color overlay = Color.fromARGB(200, 0, 0, 0);
  static const Color overlayLight = Color.fromARGB(150, 0, 0, 0);
}

extension HexColor on Color {
  static Color fromHex(String hexColorString) {
    hexColorString = hexColorString.replaceAll('#', '');
    if (hexColorString.length == 6) {
      hexColorString = 'FF$hexColorString';
    }
    return Color(int.parse(hexColorString, radix: 16));
  }
}

/// App Theme Colors - Centralized theme configuration
class AppTheme {
  /// Primary color scheme
  static const ColorScheme colorScheme = ColorScheme.dark(
    primary: ColorManager.primary,
    onPrimary: Colors.black,
    secondary: ColorManager.secondary,
    onSecondary: Colors.white,
    surface: ColorManager.surface,
    onSurface: ColorManager.textPrimary,
    background: ColorManager.background,
    onBackground: ColorManager.textPrimary,
    error: ColorManager.error,
    onError: Colors.white,
    brightness: Brightness.dark,
  );
  
  /// Gradient for buttons and highlights
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ColorManager.gradientStart, ColorManager.gradientEnd],
  );
  
  /// Secondary gradient
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ColorManager.gradientSecondaryStart, ColorManager.gradientSecondaryEnd],
  );
}
