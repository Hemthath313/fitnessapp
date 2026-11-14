import 'dart:math' as math;

import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _lum(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _contrast(Color a, Color b) {
  final l1 = _lum(a), l2 = _lum(b);
  final hi = math.max(l1, l2), lo = math.min(l1, l2);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('text on the blue primary passes WCAG AA', () {
    expect(_contrast(ColorManager.onMint, ColorManager.primary),
        greaterThanOrEqualTo(4.5));
    for (final c in ColorManager.mintGradient.colors) {
      expect(_contrast(ColorManager.onMint, c), greaterThanOrEqualTo(4.5));
    }
  });

  test('white text on hero gradients passes WCAG AA', () {
    for (final c in [
      ColorManager.heroTealStart,
      ColorManager.heroTealMid,
      ColorManager.coralStart,
      ColorManager.coralEnd,
    ]) {
      expect(_contrast(Colors.white, c), greaterThanOrEqualTo(4.5));
    }
  });

  test('muted secondary text is readable on surface', () {
    expect(_contrast(ColorManager.textMuted, ColorManager.darkSurface),
        greaterThanOrEqualTo(4.5));
  });
}
