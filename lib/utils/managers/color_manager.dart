import 'package:flutter/material.dart';

/// Modern Fitness App Color Palette
/// Designed for energy, motivation, and excellent user experience
/// Supports both Light and Dark themes
class ColorManager {
  // ========== PRIMARY COLORS (Theme Independent) ==========
  /// Primary brand color - Vibrant green (energy, fitness, growth)
  static const Color primary = Color(0xFF00D4AA); // Teal green
  static const Color primaryDark = Color(0xFF00B894);
  static const Color primaryLight = Color(0xFF26E6C7);
  
  // ========== SECONDARY COLORS (Theme Independent) ==========
  /// Secondary accent - Orange (motivation, action, achievement)
  static const Color secondary = Color(0xFFFF6B35); // Vibrant orange
  static const Color secondaryDark = Color(0xFFE55A2B);
  static const Color secondaryLight = Color(0xFFFF8C5A);
  
  // ========== DARK THEME COLORS ==========
  /// Main background - Dark but not pure black (easier on eyes)
  static const Color darkBackground = Color(0xFF0F1419); // Dark blue-grey
  static const Color darkBackgroundDark = Color(0xFF0A0E12); // Darker variant
  static const Color darkBackgroundLight = Color(0xFF1A1F26); // Lighter variant
  
  /// Card/Surface colors
  static const Color darkSurface = Color(0xFF1E2329); // Card background
  static const Color darkSurfaceDark = Color(0xFF171B21);
  static const Color darkSurfaceLight = Color(0xFF252A32);
  
  /// Text colors for dark theme
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFB8BCC8); // Light grey
  static const Color darkTextTertiary = Color(0xFF8A8D98); // Medium grey
  static const Color darkTextDisabled = Color(0xFF5A5D66); // Dark grey
  
  // ========== LIGHT THEME COLORS ==========
  /// Main background - Soft gradient-ready colors
  static const Color lightBackground = Color(0xFFF5F7FA); // Soft blue-grey
  static const Color lightBackgroundDark = Color(0xFFE8ECF1); // Slightly darker
  static const Color lightBackgroundLight = Color(0xFFFFFFFF); // Pure white
  
  /// Card/Surface colors - Clean with subtle warmth
  static const Color lightSurface = Color(0xFFFFFFFF); // White cards
  static const Color lightSurfaceDark = Color(0xFFF0F4F8); // Light blue-grey
  static const Color lightSurfaceLight = Color(0xFFFAFBFC); // Almost white with hint of blue
  
  /// Text colors for light theme - High contrast for readability
  static const Color lightTextPrimary = Color(0xFF1A202C); // Deep charcoal (not pure black)
  static const Color lightTextSecondary = Color(0xFF4A5568); // Medium grey
  static const Color lightTextTertiary = Color(0xFF718096); // Light grey
  static const Color lightTextDisabled = Color(0xFFA0AEC0); // Very light grey
  
  // ========== ACCENT COLORS (Theme Independent) ==========
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
  
  // ========== DYNAMIC THEME COLORS ==========
  // These will be set based on current theme mode
  static Color background = darkBackground;
  static Color backgroundDark = darkBackgroundDark;
  static Color backgroundLight = darkBackgroundLight;
  static Color surface = darkSurface;
  static Color surfaceDark = darkSurfaceDark;
  static Color surfaceLight = darkSurfaceLight;
  static Color textPrimary = darkTextPrimary;
  static Color textSecondary = darkTextSecondary;
  static Color textTertiary = darkTextTertiary;
  static Color textDisabled = darkTextDisabled;
  
  /// Update colors based on theme mode
  static void updateTheme(bool isDarkMode) {
    if (isDarkMode) {
      background = darkBackground;
      backgroundDark = darkBackgroundDark;
      backgroundLight = darkBackgroundLight;
      surface = darkSurface;
      surfaceDark = darkSurfaceDark;
      surfaceLight = darkSurfaceLight;
      textPrimary = darkTextPrimary;
      textSecondary = darkTextSecondary;
      textTertiary = darkTextTertiary;
      textDisabled = darkTextDisabled;
    } else {
      background = lightBackground;
      backgroundDark = lightBackgroundDark;
      backgroundLight = lightBackgroundLight;
      surface = lightSurface;
      surfaceDark = lightSurfaceDark;
      surfaceLight = lightSurfaceLight;
      textPrimary = lightTextPrimary;
      textSecondary = lightTextSecondary;
      textTertiary = lightTextTertiary;
      textDisabled = lightTextDisabled;
    }
  }
  
  // ========== LEGACY COLORS (for backward compatibility) ==========
  static Color black = darkBackground;
  static Color black54 = const Color.fromARGB(138, 15, 20, 25);
  static Color black87 = const Color.fromARGB(222, 15, 20, 25);
  static Color white = darkTextPrimary;
  static Color white70 = darkTextSecondary;
  static Color white2 = darkTextTertiary;
  static Color darkGrey = darkBackground;
  static Color grey = darkTextTertiary;
  static Color lighGrey = darkTextSecondary;
  static Color grey3 = darkSurface;
  static Color limerGreen2 = primary;
  static Color drinkDarkGrey = darkSurfaceDark;
  static Color grey2 = darkTextTertiary;
  
  // ========== UTILITY COLORS ==========
  static const Color red = error;
  static const Color yellow = warning;
  static const Color blue = info;
  static const Color orange = secondary;
  static const Color orange2 = Color.fromARGB(67, 255, 107, 53);
  static const Color limeGreen = primary;
  static const Color limeGreenOp = Color.fromARGB(73, 0, 212, 170);
  static Color brightThemeGrey = darkTextSecondary;
  
  // ========== OVERLAY COLORS ==========
  static Color overlay = const Color.fromARGB(200, 0, 0, 0);
  static Color overlayLight = const Color.fromARGB(150, 0, 0, 0);
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
  /// Dark color scheme
  static const ColorScheme darkColorScheme = ColorScheme.dark(
    primary: ColorManager.primary,
    onPrimary: Colors.black,
    secondary: ColorManager.secondary,
    onSecondary: Colors.white,
    surface: ColorManager.darkSurface,
    onSurface: ColorManager.darkTextPrimary,
    background: ColorManager.darkBackground,
    onBackground: ColorManager.darkTextPrimary,
    error: ColorManager.error,
    onError: Colors.white,
    brightness: Brightness.dark,
  );
  
  /// Light color scheme
  static const ColorScheme lightColorScheme = ColorScheme.light(
    primary: ColorManager.primary,
    onPrimary: Colors.white,
    secondary: ColorManager.secondary,
    onSecondary: Colors.white,
    surface: ColorManager.lightSurface,
    onSurface: ColorManager.lightTextPrimary,
    background: ColorManager.lightBackground,
    onBackground: ColorManager.lightTextPrimary,
    error: ColorManager.error,
    onError: Colors.white,
    brightness: Brightness.light,
  );
  
  /// Legacy - defaults to dark
  static const ColorScheme colorScheme = darkColorScheme;
  
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
