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
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  tearDown(() => ColorManager.updateTheme(false));

  group('text on blue', () {
    test('blue primary fills take white text', () {
      expect(ColorManager.onColor(ColorManager.primary), ColorManager.onMint);
      expect(ColorManager.onMint, Colors.white);
      expect(_contrast(ColorManager.onMint, ColorManager.primary), greaterThanOrEqualTo(4.5));
    });

    test('light fills (gold Pro) take dark ink', () {
      expect(ColorManager.onColor(ColorManager.premium), ColorManager.inkOnLight);
      expect(_contrast(ColorManager.inkOnLight, ColorManager.premium), greaterThanOrEqualTo(4.5));
    });

    test('dark hero blue takes white', () {
      for (final c in [ColorManager.heroTealStart, ColorManager.heroTealMid]) {
        expect(ColorManager.onColor(c), Colors.white);
        expect(_contrast(Colors.white, c), greaterThanOrEqualTo(4.5));
      }
    });

    test('button theme colours use the same dark ink', () {
      expect(AppTheme.lightColorScheme.onPrimary, ColorManager.onMint);
      expect(AppTheme.darkColorScheme.onPrimary, ColorManager.onMint);
    });
  });

  group('light mode', () {
    test('text tokens are readable on white cards and the page background', () {
      for (final bg in [ColorManager.lightSurface, ColorManager.lightBackground]) {
        expect(_contrast(ColorManager.lightTextPrimary, bg), greaterThanOrEqualTo(7));
        expect(_contrast(ColorManager.lightTextSecondary, bg), greaterThanOrEqualTo(4.5));
        expect(_contrast(ColorManager.lightTextTertiary, bg), greaterThanOrEqualTo(4.5));
        expect(_contrast(ColorManager.lightPrimaryText, bg), greaterThanOrEqualTo(4.5));
      }
    });

    test('theme switch swaps the blue text colour and the card shadow', () {
      ColorManager.updateTheme(false);
      expect(ColorManager.primaryText, ColorManager.lightPrimaryText);
      expect(ColorManager.cardShadow, isNotEmpty);

      ColorManager.updateTheme(true);
      expect(ColorManager.primaryText, ColorManager.darkPrimaryText);
      expect(ColorManager.cardShadow, isEmpty);
    });

    test('light scheme does not tint white surfaces green', () {
      expect(AppTheme.lightColorScheme.surfaceTint, Colors.transparent);
    });
  });
}
