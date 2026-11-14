import 'dart:math' as math;

import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  tearDown(() => ColorManager.updateTheme(false));

  test('light mode status text is readable on white cards and the page', () {
    ColorManager.updateTheme(false);
    for (final bg in [ColorManager.surface, ColorManager.background]) {
      expect(_contrast(ColorManager.primaryText, bg), greaterThanOrEqualTo(4.5));
      expect(_contrast(ColorManager.successText, bg), greaterThanOrEqualTo(4.5));
      expect(_contrast(ColorManager.warningText, bg), greaterThanOrEqualTo(4.5));
      expect(_contrast(ColorManager.infoText, bg), greaterThanOrEqualTo(4.5));
    }
  });

  test('dark mode status text is readable on dark cards and the page', () {
    ColorManager.updateTheme(true);
    for (final bg in [ColorManager.surface, ColorManager.background]) {
      expect(_contrast(ColorManager.primaryText, bg), greaterThanOrEqualTo(4.5));
      expect(_contrast(ColorManager.successText, bg), greaterThanOrEqualTo(4.5));
      expect(_contrast(ColorManager.warningText, bg), greaterThanOrEqualTo(4.5));
      expect(_contrast(ColorManager.infoText, bg), greaterThanOrEqualTo(4.5));
    }
  });

  test('raw fills fail as text, which is why text uses the *Text tokens', () {
    ColorManager.updateTheme(false);
    expect(_contrast(Colors.green, ColorManager.surface), lessThan(4.5));
    ColorManager.updateTheme(true);
    expect(_contrast(ColorManager.primary, ColorManager.surface), lessThan(4.5));
  });
}
