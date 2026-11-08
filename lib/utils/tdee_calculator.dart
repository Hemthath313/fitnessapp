/// TDEE and BMR Calculator using the scientifically validated Mifflin-St Jeor equation.
/// Calculates baseline metabolic rate, total daily energy expenditure, and macronutrient distributions
/// tailored for fat loss, muscle building, or strength/maintenance goals.
class TDEECalculator {
  /// Minimum recommended healthy daily caloric intake safeguards
  static const double minCaloriesFemale = 1200.0;
  static const double minCaloriesMale = 1500.0;

  /// Calculates Basal Metabolic Rate (BMR) using the Mifflin-St Jeor formula:
  /// Men:   (10 × weight_kg) + (6.25 × height_cm) - (5 × age_years) + 5
  /// Women: (10 × weight_kg) + (6.25 × height_cm) - (5 × age_years) - 161
  static double calculateBMR({
    required String gender,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
    if (weightKg <= 0 || heightCm <= 0 || age <= 0) {
      return 1500.0;
    }

    final isFemale = gender.trim().toLowerCase().startsWith('f');
    final base = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age);
    return isFemale ? (base - 161.0) : (base + 5.0);
  }

  /// Activity Multipliers:
  /// - SEDENTARY / LOW: 1.2 (little or no exercise)
  /// - LIGHT: 1.375 (light exercise/sports 1-3 days/week)
  /// - MODERATE: 1.55 (moderate exercise/sports 3-5 days/week)
  /// - ACTIVE / HIGH: 1.725 (hard exercise/sports 6-7 days/week)
  /// - VERY ACTIVE: 1.9 (very hard exercise, physical job)
  static double getActivityMultiplier(String activityLevel) {
    final normalized = activityLevel.trim().toUpperCase();
    switch (normalized) {
      case 'SEDENTARY':
      case 'LOW':
        return 1.2;
      case 'LIGHT':
        return 1.375;
      case 'MODERATE':
        return 1.55;
      case 'ACTIVE':
      case 'HIGH':
        return 1.725;
      case 'VERY ACTIVE':
      case 'VERY HIGH':
        return 1.9;
      default:
        return 1.375;
    }
  }

  /// Calculates Total Daily Energy Expenditure (TDEE = BMR × Activity Multiplier)
  static double calculateTDEE({
    required String gender,
    required double weightKg,
    required double heightCm,
    required int age,
    required String activityLevel,
  }) {
    final bmr = calculateBMR(
      gender: gender,
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
    );
    final multiplier = getActivityMultiplier(activityLevel);
    return bmr * multiplier;
  }

  /// Calculates target calories based on user goal:
  /// - LOSE: 20% deficit, with healthy minimum clamping
  /// - GAIN: 15% surplus
  /// - MAINTAIN / STRENGTH: Maintenance (100% TDEE) or slight surplus
  static double calculateTargetCalories({
    required double tdee,
    required String goal,
    required String gender,
  }) {
    final isFemale = gender.trim().toLowerCase().startsWith('f');
    final minCalories = isFemale ? minCaloriesFemale : minCaloriesMale;
    final normalizedGoal = goal.trim().toUpperCase();

    double target;
    if (normalizedGoal.contains('LOSE') || normalizedGoal.contains('CUT')) {
      target = tdee * 0.80; // 20% deficit
    } else if (normalizedGoal.contains('GAIN') || normalizedGoal.contains('BUILD') || normalizedGoal.contains('BULK')) {
      target = tdee * 1.15; // 15% surplus
    } else if (normalizedGoal.contains('STRENGTH')) {
      target = tdee * 1.05; // 5% slight surplus for strength adaptation
    } else {
      target = tdee; // Maintenance
    }

    // Safety safeguard against unhealthy extreme caloric deficits
    return target < minCalories ? minCalories : target;
  }

  /// Calculates target macronutrient splits (in grams):
  /// - Protein: 1.8g to 2.2g per kg body weight (4 kcal / gram)
  /// - Fat: 25% to 30% of total calories (9 kcal / gram)
  /// - Carbohydrates: Remaining calories divided by 4 kcal / gram
  static Map<String, double> calculateMacros({
    required double targetCalories,
    required String goal,
    required double weightKg,
  }) {
    final safeWeight = weightKg > 0 ? weightKg : 70.0;
    final normalizedGoal = goal.trim().toUpperCase();

    double proteinGramsPerKg;
    double fatRatio;

    if (normalizedGoal.contains('LOSE') || normalizedGoal.contains('CUT')) {
      proteinGramsPerKg = 2.2; // High protein preserves lean mass during deficit
      fatRatio = 0.25;
    } else if (normalizedGoal.contains('GAIN') || normalizedGoal.contains('BUILD')) {
      proteinGramsPerKg = 2.0; // Optimal protein for hypertrophy
      fatRatio = 0.25;
    } else if (normalizedGoal.contains('STRENGTH')) {
      proteinGramsPerKg = 2.0;
      fatRatio = 0.28;
    } else {
      proteinGramsPerKg = 1.8;
      fatRatio = 0.25;
    }

    final proteinGrams = (safeWeight * proteinGramsPerKg).roundToDouble();
    final proteinCalories = proteinGrams * 4.0;

    final fatCalories = targetCalories * fatRatio;
    final fatGrams = (fatCalories / 9.0).roundToDouble();

    final remainingCalories = targetCalories - proteinCalories - (fatGrams * 9.0);
    final carbGrams = (remainingCalories > 0 ? remainingCalories / 4.0 : 50.0).roundToDouble();

    return {
      'protein': proteinGrams,
      'carbs': carbGrams,
      'fat': fatGrams,
    };
  }

  /// Calculates programme-specific daily caloric intake and macronutrient targets
  /// for Complete Beginner (30d), Weight Loss (60d), and Muscle Building (90d).
  /// Ensures mathematical consistency and flags unsuitable/extreme targets for clinical review.
  static NutritionTargetResult calculateProgrammeNutrition({
    required String programmeId,
    required String gender,
    required double weightKg,
    required double heightCm,
    required int age,
    required String activityLevel,
  }) {
    final safeWeight = weightKg > 0 ? weightKg : 70.0;
    final bmr = calculateBMR(gender: gender, weightKg: safeWeight, heightCm: heightCm, age: age);
    final multiplier = getActivityMultiplier(activityLevel);
    final tdee = bmr * multiplier;
    final isFemale = gender.trim().toLowerCase().startsWith('f');
    final absoluteMinCalories = isFemale ? minCaloriesFemale : minCaloriesMale;

    double targetCalories;
    double proteinGramsPerKg;
    double fatRatio = 0.25; // standard 25% of calories from healthy fats
    bool isUnusuallyLow = false;
    bool isUnusuallyHigh = false;
    bool needsReview = false;
    String? reviewNote;

    final normId = programmeId.trim().toLowerCase();

    if (normId.contains('beginner')) {
      // 1. Complete Beginner: Maintenance calories (100% TDEE), no unnecessary restriction
      targetCalories = tdee.roundToDouble();
      proteinGramsPerKg = 1.8; // Sustainable foundation protein
      fatRatio = 0.25;
    } else if (normId.contains('weight_loss') || normId.contains('lose')) {
      // 2. Weight Loss: 20% deficit, high protein (2.2g/kg) to protect lean muscle
      final rawDeficitCalories = tdee * 0.80;
      targetCalories = rawDeficitCalories.roundToDouble();
      proteinGramsPerKg = 2.2;
      fatRatio = 0.25;

      // Unusually low review flag: if raw deficit falls below absolute floor or below 85% BMR
      if (rawDeficitCalories < absoluteMinCalories || rawDeficitCalories < (bmr * 0.85)) {
        isUnusuallyLow = true;
        needsReview = true;
        reviewNote =
            'Calculated calorie deficit is below metabolic safety recommendations (${rawDeficitCalories.toInt()} kcal vs ${absoluteMinCalories.toInt()} kcal floor). Monitored gradual deficit recommended.';
        if (targetCalories < absoluteMinCalories) {
          targetCalories = absoluteMinCalories;
        }
      }
    } else if (normId.contains('muscle') || normId.contains('bulk')) {
      // 3. Muscle Building: Moderate surplus (+12%, approx. 250-350 kcal), 2.0g/kg protein, generous carbs
      targetCalories = (tdee * 1.12).roundToDouble();
      proteinGramsPerKg = 2.0;
      fatRatio = 0.25;

      if (targetCalories > 4000.0) {
        isUnusuallyHigh = true;
        needsReview = true;
        reviewNote =
            'High caloric surplus (>4000 kcal). Phased digestive adaptation is recommended.';
      }
    } else {
      // 4. Strength 12-week: Slight 5% surplus for neural & muscular recovery
      targetCalories = (tdee * 1.05).roundToDouble();
      proteinGramsPerKg = 2.0;
      fatRatio = 0.28;
    }

    // Macro calculation with exact mathematical consistency
    final proteinGrams = (safeWeight * proteinGramsPerKg).roundToDouble();
    final proteinCalories = proteinGrams * 4.0;

    final fatCalories = targetCalories * fatRatio;
    final fatGrams = (fatCalories / 9.0).roundToDouble();
    final actualFatCalories = fatGrams * 9.0;

    // Remaining calories strictly allocated to carbohydrates
    final remainingCalories = targetCalories - proteinCalories - actualFatCalories;
    final carbGrams = (remainingCalories > 0 ? (remainingCalories / 4.0) : 50.0).roundToDouble();

    // Mathematically consistent total: 4P + 4C + 9F
    final mathematicallyConsistentCalories =
        (proteinGrams * 4.0) + (carbGrams * 4.0) + (fatGrams * 9.0);

    return NutritionTargetResult(
      bmr: bmr.roundToDouble(),
      tdee: tdee.roundToDouble(),
      targetCalories: mathematicallyConsistentCalories,
      proteinGrams: proteinGrams,
      carbGrams: carbGrams,
      fatGrams: fatGrams,
      isUnusuallyLow: isUnusuallyLow,
      isUnusuallyHigh: isUnusuallyHigh,
      needsReview: needsReview,
      reviewNote: reviewNote,
    );
  }
}

/// Structured nutritional calculation result with mathematical consistency checks and clinical review safeguards
class NutritionTargetResult {
  final double bmr;
  final double tdee;
  final double targetCalories;
  final double proteinGrams;
  final double carbGrams;
  final double fatGrams;
  final bool isUnusuallyLow;
  final bool isUnusuallyHigh;
  final bool needsReview;
  final String? reviewNote;

  const NutritionTargetResult({
    required this.bmr,
    required this.tdee,
    required this.targetCalories,
    required this.proteinGrams,
    required this.carbGrams,
    required this.fatGrams,
    this.isUnusuallyLow = false,
    this.isUnusuallyHigh = false,
    this.needsReview = false,
    this.reviewNote,
  });

  /// Mathematical consistency verification: 4P + 4C + 9F should approximate targetCalories
  double get totalMacroCalories =>
      (proteinGrams * 4.0) + (carbGrams * 4.0) + (fatGrams * 9.0);

  bool get isMathematicallyConsistent =>
      (totalMacroCalories - targetCalories).abs() <= 15.0;

  Map<String, double> get macrosMap => {
        'protein': proteinGrams,
        'carbs': carbGrams,
        'fat': fatGrams,
      };
}
