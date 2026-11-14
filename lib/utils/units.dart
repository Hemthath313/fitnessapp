import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lifting-weight units. Weights are always STORED in kilograms; this only
/// changes how they are shown and typed. Body weight stays in kg for now.
///
/// In kg mode every helper returns exactly what the old `toStringAsFixed`
/// code produced, so existing screens and tests are unchanged.
class Units {
  Units._();

  static const String _prefsKey = 'weight_unit_lb';
  static const double kgPerLb = 0.45359237;

  /// Rebuild listeners (e.g. a ValueListenableBuilder) when the unit changes.
  static final ValueNotifier<bool> useLbNotifier = ValueNotifier<bool>(false);

  static bool get useLb => useLbNotifier.value;

  /// 'kg' or 'lb'.
  static String get label => useLb ? 'lb' : 'kg';

  /// Load the saved choice. Call once at startup.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      useLbNotifier.value = prefs.getBool(_prefsKey) ?? false;
    } catch (_) {}
  }

  static Future<void> setUseLb(bool value) async {
    useLbNotifier.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {}
  }

  @visibleForTesting
  static void setForTesting(bool lb) => useLbNotifier.value = lb;

  /// Kilograms -> the user's unit.
  static double toDisplay(double kg) => useLb ? kg / kgPerLb : kg;

  /// The user's unit -> kilograms (for saving what they typed).
  static double toKg(double value) => useLb ? value * kgPerLb : value;

  /// Like `kg.toStringAsFixed(decimals)`, in the user's unit.
  static String fmt(double kg, [int decimals = 1]) =>
      toDisplay(kg).toStringAsFixed(decimals);

  /// Whole number when it is one, else 1 decimal (the old "% 1 == 0" style).
  static String fmtSmart(double kg) {
    final v = toDisplay(kg);
    return v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
  }

  /// Like `kg.toInt()`, in the user's unit.
  static int intOf(double kg) => toDisplay(kg).toInt();

  /// Value to pre-fill a weight input with: lb are rounded to the nearest
  /// 0.5 so a converted 60 kg shows 132.5, not 132.3.
  static String inputText(double kg) {
    if (kg <= 0) return '';
    var v = toDisplay(kg);
    if (useLb) v = (v * 2).round() / 2;
    return v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
  }

  /// Parse what the user typed (in their unit) into kilograms.
  static double? parseToKg(String text) {
    final v = double.tryParse(text.trim().replaceAll(',', '.'));
    if (v == null) return null;
    return toKg(v);
  }
}
