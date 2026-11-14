import 'package:flutter/material.dart';

/// Electric Blue + Charcoal palette (matches the blue launcher icon).
/// Dark mode is the default (see ThemeProvider); light mode is a toggle.
///
/// Rules of thumb:
///  * [primary] (blue) is a FILL colour. Text/icons on it use [onMint] (white).
///  * For blue TEXT/ICONS on a theme surface use [primaryText]
///    (#5B9BFF in dark, #1D4ED8 in light). Raw [primary] is only 3.3:1 on
///    the dark cards, so it is not for small text there.
///  * On always-dark art (splash, video, blue hero gradients) use
///    [primaryOnDark].
///  * Dark ink on light fills (gold, amber, light plates): [inkOnLight].
///  * One warm accent ([accent]) for PRs / streaks / calories, one gold
///    ([premium]) for Pro. Status = [success] / [warning] / [error] / [info].
///  * Legacy names (onMint, mintGradient, heroTeal*) are kept so existing
///    screens keep compiling; their values now follow the blue brand.
class ColorManager {
  // ═══════════════════════════════════════
  // PRIMARY BRAND COLORS (theme-independent)
  // ═══════════════════════════════════════

  /// Primary – Electric blue (brand, buttons, progress). White text: 5.2:1.
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF5B9BFF);

  /// Gradient – Blue gradient
  static const Color gradientStart = Color(0xFF1D4ED8);
  static const Color gradientEnd = Color(0xFF2563EB);

  /// Accent – Warm coral-orange (PRs, calories, streaks)
  static const Color accent = Color(0xFFFF6B4A);
  static const Color accentLight = Color(0xFFFF8A6E);

  /// Accent – Neon Volt (legacy, barely used)
  static const Color neonVolt = Color(0xFFD4FF2A);

  /// Reference-design tokens (Daily Companion look)
  static const Color ringAmber = Color(0xFFF4B03E);
  static const Color premium = Color(0xFFF4B03E);
  static const Color iconChip = Color(0xFF2A2C30);
  static const Color barDim = Color(0xFF2D4F9E);
  static const Color barMuted = Color(0xFF3A3D42);
  // Hero gradients are dark enough for white text (>= 4.5:1 contrast).
  static const Color heroTealStart = Color(0xFF1D4ED8);
  static const Color heroTealMid = Color(0xFF1E3A8A);
  static const Color coralStart = Color(0xFFA85A3C);
  static const Color coralEnd = Color(0xFFA35A63);

  /// Text/icons placed ON the blue primary colour (white, 5.2:1).
  /// Name kept for compatibility.
  static const Color onMint = Color(0xFFFFFFFF);

  /// Dark ink for text on LIGHT fills (gold Pro button, amber, light plates).
  static const Color inkOnLight = Color(0xFF111827);

  /// Light blue for text/icons on surfaces that are ALWAYS dark (splash,
  /// video overlays, blue hero gradients) regardless of theme.
  static const Color primaryOnDark = Color(0xFF93C5FD);

  /// Blue text/icons on dark-mode cards (6.1:1 on darkSurface).
  static const Color darkPrimaryText = Color(0xFF5B9BFF);

  /// Metric identity colours (Today's Snapshot, diet rings, header chips).
  /// Use these for tints (`.withValues(alpha: 0.15)`); for icons, arcs and
  /// text use [calorieText] / [waterText], which adapt to the theme.
  static const Color calorie = Color(0xFFFF6B4A); // coral – calories / streak
  static const Color water = Color(0xFF0EA5E9);   // sky blue – hydration

  /// Extra category colour (fats, drop sets, misc. menu icons).
  static const Color violet = Color(0xFF8B5CF6);

  /// Readable text/icon colour for any solid fill: dark ink on light fills
  /// (gold, amber), white on darker ones such as the blue primary.
  static Color onColor(Color background) =>
      background.computeLuminance() > 0.4 ? inkOnLight : Colors.white;

  /// Brighter secondary text for dark surfaces (readable on `surface`).
  static const Color textMuted = Color(0xFFB5B7BD);

  /// Blue gradient used by selected toggles and small primary buttons.
  static const LinearGradient mintGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
  );

  /// Success – Emerald (completed sets, goals met).
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  /// Deep emerald for text on white / 'done' buttons (white on it: 5.5:1).
  static const Color successDark = Color(0xFF047857);
  /// Very dark emerald tint behind 'completed' chips on dark hero cards.
  static const Color successDeep = Color(0xFF0F3D2E);
  /// Near-white emerald for text on [successDeep].
  static const Color successOnDeep = Color(0xFFE6F7EF);

  /// Warning
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);

  /// Error
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);

  /// Info
  static const Color info = Color(0xFF0EA5E9);

  // ═══════════════════════════════════════
  // LIGHT THEME (default)
  // ═══════════════════════════════════════
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightBackgroundDark = Color(0xFFE8ECF2);
  static const Color lightBackgroundLight = Color(0xFFFFFFFF);

  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceDark = Color(0xFFEEF1F6);
  static const Color lightSurfaceLight = Color(0xFFF8FAFC);

  static const Color lightTextPrimary = Color(0xFF18181B);
  static const Color lightTextSecondary = Color(0xFF52525B);
  static const Color lightTextTertiary = Color(0xFF66666E);
  static const Color lightTextDisabled = Color(0xFFD4D4D8);

  static const Color lightDivider = Color(0xFFE3E7EE);

  /// Deeper blue that stays readable as TEXT/ICON on white or the page (6.2:1+).
  static const Color lightPrimaryText = Color(0xFF1D4ED8);

  /// Status colours that stay readable as TEXT on white / mint-white (>= 4.8:1).
  /// The bright [success] / [warning] / [info] are fills and dark-mode text.
  static const Color lightSuccessText = Color(0xFF047857);
  static const Color lightWarningText = Color(0xFF92400E);
  static const Color lightInfoText = Color(0xFF0369A1);
  static const Color darkInfoText = Color(0xFF38BDF8);

  /// Soft card shadow for light mode.
  static const List<BoxShadow> lightCardShadow = [
    BoxShadow(color: Color(0x0F18181B), blurRadius: 18, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x0A18181B), blurRadius: 3, offset: Offset(0, 1)),
  ];

  // ═══════════════════════════════════════
  // DARK THEME (toggle)
  // ═══════════════════════════════════════
  static const Color darkBackground = Color(0xFF121314);
  static const Color darkBackgroundDark = Color(0xFF0B0C0D);
  static const Color darkBackgroundLight = Color(0xFF191A1C);

  static const Color darkSurface = Color(0xFF1C1D1F);
  static const Color darkSurfaceDark = Color(0xFF161719);
  static const Color darkSurfaceLight = Color(0xFF26282B);

  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkTextTertiary = Color(0xFF8E8E96);
  static const Color darkTextDisabled = Color(0xFF3F3F46);

  static const Color darkDivider = Color(0xFF2E3034);

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

  /// Brand blue for text/icons on theme surfaces (deep blue in light mode, bright blue in dark).
  static Color primaryText = lightPrimaryText;

  /// Green / amber / blue for status TEXT on theme surfaces (dark in light
  /// mode, bright in dark mode).
  static Color successText = lightSuccessText;
  static Color warningText = lightWarningText;
  static Color infoText = lightInfoText;

  /// Calorie / water colour for icons, rings and text on theme surfaces
  /// (coral 6.0:1 and sky 7.9:1 on dark cards; deeper shades on white).
  static Color calorieText = const Color(0xFFC2410C);

  /// Red / coral for TEXT on theme surfaces. The [error] and [accent] fills
  /// are only 3.8:1 and 2.8:1 on white, so text uses these instead.
  static Color errorText = const Color(0xFFB91C1C);
  static Color accentText = const Color(0xFFC2410C);
  static Color violetText = const Color(0xFF6D28D9);
  static Color waterText = const Color(0xFF0369A1);

  /// Neutral circle behind icons / empty ring tracks. Dark grey in dark mode,
  /// light grey in light mode (the fixed [iconChip] is dark-mode only).
  static Color chipBackground = lightSurfaceDark;

  /// Card shadow for the current theme (empty in dark mode).
  static List<BoxShadow> cardShadow = lightCardShadow;

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
      primaryText = darkPrimaryText;
      successText = successLight;
      warningText = ringAmber;
      infoText = darkInfoText;
      calorieText = calorie;
      waterText = const Color(0xFF38BDF8);
      errorText = errorLight;
      accentText = accent;
      violetText = const Color(0xFFA78BFA);
      chipBackground = iconChip;
      cardShadow = const [];
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
      primaryText = lightPrimaryText;
      successText = lightSuccessText;
      warningText = lightWarningText;
      infoText = lightInfoText;
      calorieText = const Color(0xFFC2410C);
      waterText = const Color(0xFF0369A1);
      errorText = const Color(0xFFB91C1C);
      accentText = const Color(0xFFC2410C);
      violetText = const Color(0xFF6D28D9);
      chipBackground = lightSurfaceDark;
      cardShadow = lightCardShadow;
    }

    // Sync legacy aliases
    _syncLegacy(isDarkMode);
  }

  static void _syncLegacy(bool isDarkMode) {
    // 'black' = background color; 'white' = primary text color — both adapt to theme
    black    = isDarkMode ? darkBackground  : lightBackground;
    black54  = isDarkMode ? const Color.fromARGB(138, 18, 19, 20) : const Color.fromARGB(138, 245, 246, 242);
    black87  = isDarkMode ? const Color.fromARGB(222, 18, 19, 20) : const Color.fromARGB(222, 245, 246, 242);
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
  static Color black54 = const Color.fromARGB(138, 245, 246, 242);
  static Color black87 = const Color.fromARGB(222, 245, 246, 242);
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
  static const Color orange2 = Color.fromARGB(67, 255, 107, 74);
  static const Color limeGreen = primary;
  static const Color limeGreenOp = Color.fromARGB(73, 37, 99, 235);

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
    onPrimary: ColorManager.onMint,
    secondary: ColorManager.accent,
    onSecondary: Colors.white,
    surface: ColorManager.lightSurface,
    onSurface: ColorManager.lightTextPrimary,
    error: ColorManager.error,
    onError: Colors.white,
    brightness: Brightness.light,
    tertiary: ColorManager.success,
    onTertiary: Colors.white,
    surfaceTint: Colors.transparent,
  );

  // ── DARK COLOR SCHEME ──
  static const ColorScheme darkColorScheme = ColorScheme.dark(
    primary: ColorManager.primary,
    onPrimary: ColorManager.onMint,
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
    colors: [Color(0xFF0B1B3F), ColorManager.primaryDark],
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
