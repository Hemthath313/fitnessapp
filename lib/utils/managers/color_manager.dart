import 'package:flutter/material.dart';

/// Hevy-Inspired Color Palette
/// Light Mode is the default (proven by 13M+ Hevy users).
/// Dark Mode available as a toggle.
class ColorManager {
  // ═══════════════════════════════════════
  // PRIMARY BRAND COLORS (theme-independent)
  // ═══════════════════════════════════════

  /// Primary – Teal (brand, buttons, progress)
  static const Color primary = Color(0xFF60D1BB);
  static const Color primaryDark = Color(0xFF3FA895);
  static const Color primaryLight = Color(0xFF86E3D1);

  /// Gradient – Teal Gradient
  static const Color gradientStart = Color(0xFF3FA895);
  static const Color gradientEnd = Color(0xFF60D1BB);

  /// Accent – Coral Red (PRs, calories, alerts, streaks)
  static const Color accent = Color(0xFFFF4757);
  static const Color accentLight = Color(0xFFFF6B78);

  /// Accent – Neon Volt Green (for high-energy actions, buttons, and badges)
  static const Color neonVolt = Color(0xFFD4FF2A);

  /// Reference-design tokens (Daily Companion look)
  static const Color ringAmber = Color(0xFFF4B03E);   // progress ring arcs
  static const Color iconChip = Color(0xFF31343B);    // dark circle behind ring icons
  static const Color barDim = Color(0xFF376D5E);      // completed (past) bars
  static const Color barMuted = Color(0xFF3D4145);    // empty bars
  // Hero gradients are dark enough for white text (>= 4.5:1 contrast).
  static const Color heroTealStart = Color(0xFF328078);
  static const Color heroTealMid = Color(0xFF1F5651);
  static const Color coralStart = Color(0xFFA85A3C);
  static const Color coralEnd = Color(0xFFA35A63);

  /// Text/icons placed ON the mint primary colour (9.2:1; white is only 1.85:1).
  static const Color onMint = Color(0xFF06201B);

  /// Brighter secondary text for dark surfaces (readable on `surface`).
  static const Color textMuted = Color(0xFFB8BDC6);

  /// Mint gradient used by selected toggles and small primary buttons.
  static const LinearGradient mintGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6FDCC6), Color(0xFF3FA895)],
  );

  /// Success – Teal Green (completed sets, goals met)
  static const Color success = Color(0xFF2ECC71);
  static const Color successLight = Color(0xFF58D68D);

  /// Warning
  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFF5B942);

  /// Error
  static const Color error = Color(0xFFE74C3C);
  static const Color errorLight = Color(0xFFEC7063);

  /// Info
  static const Color info = Color(0xFF3498DB);

  // ═══════════════════════════════════════
  // LIGHT THEME (default)
  // ═══════════════════════════════════════
  static const Color lightBackground = Color(0xFFF1F5F4);       // Soft mint-white
  static const Color lightBackgroundDark = Color(0xFFE4ECEA);   // Slightly deeper mint-grey
  static const Color lightBackgroundLight = Color(0xFFFFFFFF);  // Pure white

  static const Color lightSurface = Color(0xFFFFFFFF);          // White cards
  static const Color lightSurfaceDark = Color(0xFFF0F4F8);      // Chip/tag backgrounds
  static const Color lightSurfaceLight = Color(0xFFF7FAF9);     // Near-white sections

  static const Color lightTextPrimary = Color(0xFF1E2140);      // Dark blue-charcoal
  static const Color lightTextSecondary = Color(0xFF6B7280);    // Muted grey
  static const Color lightTextTertiary = Color(0xFF9CA3AF);     // Light grey
  static const Color lightTextDisabled = Color(0xFFD1D5DB);

  static const Color lightDivider = Color(0xFFE5E7EB);

  // ═══════════════════════════════════════
  // DARK THEME (toggle)
  // ═══════════════════════════════════════
  static const Color darkBackground = Color(0xFF040910);        // Near-black navy
  static const Color darkBackgroundDark = Color(0xFF02060B);    // Deeper variant
  static const Color darkBackgroundLight = Color(0xFF0B111A);   // Lighter variant

  static const Color darkSurface = Color(0xFF23262E);           // Dark neutral card
  static const Color darkSurfaceDark = Color(0xFF1B1E25);
  static const Color darkSurfaceLight = Color(0xFF2C303A);      // Elevated elements

  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8E9198);
  static const Color darkTextTertiary = Color(0xFF717378);
  static const Color darkTextDisabled = Color(0xFF374151);

  static const Color darkDivider = Color(0xFF2F333B);

  // ═══════════════════════════════════════
  // DYNAMIC THEME COLORS (updated at runtime)
  // ═══════════════════════════════════════
  static Color background = lightBackground;
  static Color backgroundDark = lightBackgroundDark;
  static Color backgroundLight = lightBackgroundLight;
  static Color surface = lightSurface;
  static Color surfaceDark = lightSurfaceDark;
  static Color surfaceLight = lightSurfaceLight;
  static Color textPrimary = lightTextPrimary;
  static Color textSecondary = lightTextSecondary;
  static Color textTertiary = lightTextTertiary;
  static Color textDisabled = lightTextDisabled;
  static Color divider = lightDivider;

  /// Call this whenever the theme mode changes
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
      divider = darkDivider;
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
      divider = lightDivider;
    }

    // Sync legacy aliases
    _syncLegacy(isDarkMode);
  }

  static void _syncLegacy(bool isDarkMode) {
    // 'black' = background color; 'white' = primary text color — both adapt to theme
    black    = isDarkMode ? darkBackground  : lightBackground;
    black54  = isDarkMode ? const Color.fromARGB(138, 4, 9, 16) : const Color.fromARGB(138, 241, 245, 244);
    black87  = isDarkMode ? const Color.fromARGB(222, 4, 9, 16) : const Color.fromARGB(222, 241, 245, 244);
    white    = isDarkMode ? darkTextPrimary  : lightTextPrimary;
    white70  = isDarkMode ? darkTextSecondary : lightTextSecondary;
    white2   = isDarkMode ? darkTextTertiary  : lightTextTertiary;
    darkGrey = isDarkMode ? darkBackgroundLight : lightSurfaceDark;
    grey     = isDarkMode ? darkTextTertiary    : lightTextTertiary;
    lighGrey = isDarkMode ? darkTextSecondary   : lightTextSecondary;
    grey3    = isDarkMode ? darkSurface  : lightSurface;
    limerGreen2   = primary;
    drinkDarkGrey = isDarkMode ? darkSurfaceDark : lightSurfaceDark;
    grey2         = isDarkMode ? darkTextTertiary : lightTextTertiary;
    brightThemeGrey = isDarkMode ? darkTextSecondary : lightTextSecondary;
    secondary     = accent;
    secondaryDark = accentLight;
    secondaryLight = accentLight;
  }

  // ═══════════════════════════════════════
  // LEGACY ALIASES (backward compatibility)
  // ═══════════════════════════════════════
  static Color black = lightBackground;
  static Color black54 = const Color.fromARGB(138, 241, 245, 244);
  static Color black87 = const Color.fromARGB(222, 241, 245, 244);
  static Color white = lightTextPrimary;          // adapts: dark bg→white text, light bg→dark text
  static Color white70 = lightTextSecondary;
  static Color white2 = lightTextTertiary;
  static Color darkGrey = lightSurfaceDark;
  static Color grey = lightTextTertiary;
  static Color lighGrey = lightTextSecondary;
  static Color grey3 = lightSurface;
  static Color limerGreen2 = primary;
  static Color drinkDarkGrey = lightSurfaceDark;
  static Color grey2 = lightTextTertiary;
  static Color brightThemeGrey = lightTextSecondary;
  // secondary / secondaryDark kept for backward compat — mapped to accent
  static Color secondary = accent;
  static Color secondaryDark = accentLight;
  static Color secondaryLight = accentLight;

  // ═══════════════════════════════════════
  // UTILITY ALIASES
  // ═══════════════════════════════════════
  static const Color red = error;
  static const Color yellow = warning;
  static const Color blue = info;
  static const Color orange = accent;
  static const Color orange2 = Color.fromARGB(67, 255, 71, 87);
  static const Color limeGreen = primary;
  static const Color limeGreenOp = Color.fromARGB(73, 13, 148, 136);

  // Overlays
  static Color overlay = const Color.fromARGB(160, 0, 0, 0);
  static Color overlayLight = const Color.fromARGB(100, 0, 0, 0);
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

/// App Theme — centralized Material ColorScheme + Gradients
class AppTheme {
  // ── LIGHT COLOR SCHEME ──
  static const ColorScheme lightColorScheme = ColorScheme.light(
    primary: ColorManager.primary,
    onPrimary: Color(0xFF06201B),
    secondary: ColorManager.accent,
    onSecondary: Colors.white,
    surface: ColorManager.lightSurface,
    onSurface: ColorManager.lightTextPrimary,
    error: ColorManager.error,
    onError: Colors.white,
    brightness: Brightness.light,
    tertiary: ColorManager.success,
    onTertiary: Colors.white,
  );

  // ── DARK COLOR SCHEME ──
  static const ColorScheme darkColorScheme = ColorScheme.dark(
    primary: ColorManager.primary,
    onPrimary: Colors.black,
    secondary: ColorManager.accent,
    onSecondary: Colors.white,
    surface: ColorManager.darkSurface,
    onSurface: ColorManager.darkTextPrimary,
    error: ColorManager.error,
    onError: Colors.white,
    brightness: Brightness.dark,
    tertiary: ColorManager.success,
    onTertiary: Colors.white,
  );

  /// Legacy default → now points to light
  static const ColorScheme colorScheme = lightColorScheme;

  // ── GRADIENTS ──
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [ColorManager.gradientStart, ColorManager.gradientEnd],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F2A2E), ColorManager.primary],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [ColorManager.accent, ColorManager.accentLight],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [ColorManager.success, ColorManager.successLight],
  );
}
