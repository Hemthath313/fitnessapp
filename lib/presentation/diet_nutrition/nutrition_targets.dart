import 'package:fitness_app/presentation/home/widgets/fitness_data_widget.dart';
import 'package:fitness_app/utils/tdee_calculator.dart';
import 'package:flutter/widgets.dart';

/// A day's calorie and macro targets.
class NutritionTargetSet {
  final int calories;
  final int protein;
  final int carbs;
  final int fats;

  /// Where the calorie number came from (e.g. "Daily Goal", "TDEE Target").
  final String source;

  const NutritionTargetSet({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.source,
  });
}

/// The single source of truth for calorie and macro targets.
///
/// Home, the Nutrition Hub estimator and the Bulking / Cutting / Maintain plan
/// screens all read their numbers from here, so a user sees the same target
/// everywhere.
///
/// Rule: the calorie target is resolved exactly once (active transformation →
/// configured target → TDEE from the profile, see
/// [FitnessDataWidget.resolveCalorieGoal]). The goal adjustment (deficit /
/// surplus) is applied once, inside [TDEECalculator.calculateTargetCalories].
/// Never add another surplus or deficit on top of a target from here, and never
/// treat the profile's stored `bmr` field as maintenance: it already includes
/// the goal adjustment from onboarding.
///
/// Product rule: logging and tracking meals is a Pro-only feature. These
/// targets are informational and are shown to everyone.
class NutritionTargets {
  const NutritionTargets._();

  static const double _fallbackWeightKg = 70.0;
  static const double _fallbackHeightCm = 170.0;
  static const int _fallbackAge = 25;
  static const int _fallbackCalories = 2000;

  /// Targets for the signed-in user, identical to what Home shows.
  static NutritionTargetSet forUser(
    BuildContext context,
    Map<String, dynamic> userData,
  ) {
    final goal = (userData['goal'] ?? '').toString();
    final weight = _weightOf(userData);
    final info = FitnessDataWidget.resolveCalorieGoal(
      context: context,
      userData: userData,
    );
    final target = info.targetCalories;
    if (info.hasValidTarget && target != null && target > 0) {
      return fromCalories(
        calories: target,
        goal: goal,
        weightKg: weight,
        source: info.sourceDescription,
      );
    }
    return fromCalories(
      calories: _fallbackCalories.toDouble(),
      goal: goal,
      weightKg: weight,
      source: 'Estimate',
    );
  }

  /// Targets computed from explicit inputs (used by the adjustable estimator).
  static NutritionTargetSet estimate({
    required String gender,
    required double weightKg,
    required double heightCm,
    required int age,
    required String activity,
    required String goal,
  }) {
    final safeWeight = weightKg > 0 ? weightKg : _fallbackWeightKg;
    final tdee = TDEECalculator.calculateTDEE(
      gender: gender.isNotEmpty ? gender : 'Male',
      weightKg: safeWeight,
      heightCm: heightCm > 0 ? heightCm : _fallbackHeightCm,
      age: age > 0 ? age : _fallbackAge,
      activityLevel: activity.isNotEmpty ? activity : 'MODERATE',
    );
    final target = TDEECalculator.calculateTargetCalories(
      tdee: tdee,
      goal: goal,
      gender: gender.isNotEmpty ? gender : 'Male',
    );
    return fromCalories(
      calories: target,
      goal: goal,
      weightKg: safeWeight,
      source: 'TDEE Target',
    );
  }

  /// Splits a calorie target into protein / carbs / fats.
  static NutritionTargetSet fromCalories({
    required double calories,
    required String goal,
    required double weightKg,
    required String source,
  }) {
    final macros = TDEECalculator.calculateMacros(
      targetCalories: calories,
      goal: goal,
      weightKg: weightKg > 0 ? weightKg : _fallbackWeightKg,
    );
    return NutritionTargetSet(
      calories: calories.round(),
      protein: (macros['protein'] ?? 0).round(),
      carbs: (macros['carbs'] ?? 0).round(),
      fats: (macros['fat'] ?? 0).round(),
      source: source,
    );
  }

  /// Short, accurate description of the goal adjustment the formulas apply.
  static String adjustmentLabel(String goal) {
    final g = goal.trim().toUpperCase();
    if (g.contains('LOSE') || g.contains('CUT')) {
      return 'Includes a 20% calorie deficit';
    }
    if (g.contains('GAIN') || g.contains('BUILD') || g.contains('BULK')) {
      return 'Includes a 15% calorie surplus';
    }
    return 'Maintenance balance';
  }

  static double _weightOf(Map<String, dynamic> userData) {
    final w = (userData['weight'] as num?)?.toDouble() ?? 0.0;
    return w > 0 ? w : _fallbackWeightKg;
  }
}
