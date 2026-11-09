import 'package:fitness_app/presentation/diet_nutrition/nutrition_targets.dart';
import 'package:fitness_app/utils/tdee_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

NutritionTargetSet _estimate(String goal, {String activity = 'MODERATE'}) =>
    NutritionTargets.estimate(
      gender: 'Male',
      weightKg: 80,
      heightCm: 180,
      age: 30,
      activity: activity,
      goal: goal,
    );

Future<NutritionTargetSet> _forUser(
  WidgetTester tester,
  Map<String, dynamic> userData,
) async {
  late NutritionTargetSet result;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          result = NutritionTargets.forUser(context, userData);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return result;
}

void main() {
  group('NutritionTargets.estimate', () {
    test('applies the goal adjustment exactly once', () {
      final tdee = TDEECalculator.calculateTDEE(
        gender: 'Male',
        weightKg: 80,
        heightCm: 180,
        age: 30,
        activityLevel: 'MODERATE',
      );
      final maintain = _estimate('MAINTAIN');
      final lose = _estimate('LOSE');
      final gain = _estimate('GAIN');

      expect(maintain.calories, tdee.round());
      expect(lose.calories / maintain.calories, closeTo(0.80, 0.005));
      expect(gain.calories / maintain.calories, closeTo(1.15, 0.005));
      expect(lose.calories, lessThan(maintain.calories));
      expect(gain.calories, greaterThan(maintain.calories));
    });

    test('macros add back up to the calorie target', () {
      for (final goal in ['LOSE', 'MAINTAIN', 'GAIN']) {
        final t = _estimate(goal);
        final fromMacros = t.protein * 4 + t.carbs * 4 + t.fats * 9;
        expect((fromMacros - t.calories).abs(), lessThan(20),
            reason: '$goal macros should match calories');
      }
    });

    test('protein is highest per kg when cutting', () {
      expect(_estimate('LOSE').protein,
          greaterThan(_estimate('MAINTAIN').protein));
    });

    test('missing profile values fall back instead of producing nonsense', () {
      final t = NutritionTargets.estimate(
        gender: '',
        weightKg: 0,
        heightCm: 0,
        age: 0,
        activity: '',
        goal: 'MAINTAIN',
      );
      expect(t.calories, greaterThan(1200));
      expect(t.protein, greaterThan(0));
    });

    test('caption describes the real adjustment', () {
      expect(NutritionTargets.adjustmentLabel('LOSE'), contains('20%'));
      expect(NutritionTargets.adjustmentLabel('GAIN'), contains('15%'));
      expect(NutritionTargets.adjustmentLabel('MAINTAIN'),
          contains('Maintenance'));
    });
  });

  group('NutritionTargets.forUser (same number as Home)', () {
    testWidgets('a configured target is used exactly, with no extra adjustment',
        (tester) async {
      final t = await _forUser(tester, {
        'goal': 'GAIN',
        'weight': 80.0,
        'targetCalories': 2400.0,
      });
      expect(t.calories, 2400);
    });

    testWidgets('profile values give the same target as the estimator',
        (tester) async {
      final t = await _forUser(tester, {
        'goal': 'LOSE',
        'gender': 'Male',
        'weight': 80.0,
        'height': 180.0,
        'age': 30,
        'activity': 'MODERATE',
      });
      expect(t.calories, _estimate('LOSE').calories);
      expect(t.protein, _estimate('LOSE').protein);
    });

    testWidgets('the stored goal-adjusted bmr field is never used as maintenance',
        (tester) async {
      final base = {
        'goal': 'LOSE',
        'gender': 'Male',
        'weight': 80.0,
        'height': 180.0,
        'age': 30,
        'activity': 'MODERATE',
      };
      final without = await _forUser(tester, base);
      final withBmr = await _forUser(tester, {...base, 'bmr': 2000.0});
      expect(withBmr.calories, without.calories);
    });

    testWidgets('an empty profile gives a safe estimate', (tester) async {
      final t = await _forUser(tester, {});
      expect(t.calories, 2000);
      expect(t.source, 'Estimate');
    });
  });
}
