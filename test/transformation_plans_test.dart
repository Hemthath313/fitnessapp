import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/utils/tdee_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TDEECalculator Tests', () {
    test('calculateBMR uses Mifflin-St Jeor equation correctly', () {
      // Male: 10 * 80 + 6.25 * 180 - 5 * 25 + 5 = 800 + 1125 - 125 + 5 = 1805
      final maleBmr = TDEECalculator.calculateBMR(
        gender: 'Male',
        weightKg: 80.0,
        heightCm: 180.0,
        age: 25,
      );
      expect(maleBmr, equals(1805.0));

      // Female: 10 * 60 + 6.25 * 165 - 5 * 30 - 161 = 600 + 1031.25 - 150 - 161 = 1320.25
      final femaleBmr = TDEECalculator.calculateBMR(
        gender: 'Female',
        weightKg: 60.0,
        heightCm: 165.0,
        age: 30,
      );
      expect(femaleBmr, equals(1320.25));
    });

    test('calculateTDEE applies appropriate activity multipliers', () {
      final tdeeSedentary = TDEECalculator.calculateTDEE(
        gender: 'Male',
        weightKg: 80.0,
        heightCm: 180.0,
        age: 25,
        activityLevel: 'LOW',
      );
      expect(tdeeSedentary, equals(1805.0 * 1.2));

      final tdeeModerate = TDEECalculator.calculateTDEE(
        gender: 'Male',
        weightKg: 80.0,
        heightCm: 180.0,
        age: 25,
        activityLevel: 'MODERATE',
      );
      expect(tdeeModerate, equals(1805.0 * 1.55));
    });

    test('calculateTargetCalories enforces goal offsets and safeguards', () {
      // 20% deficit for fat loss
      final fatLossTarget = TDEECalculator.calculateTargetCalories(
        tdee: 2500.0,
        goal: 'LOSE',
        gender: 'Male',
      );
      expect(fatLossTarget, equals(2000.0));

      // 15% surplus for muscle gain
      final surplusTarget = TDEECalculator.calculateTargetCalories(
        tdee: 2000.0,
        goal: 'GAIN',
        gender: 'Male',
      );
      expect(surplusTarget, equals(2300.0));

      // Safeguard check: Women minimum 1200 kcal
      final clampedFemale = TDEECalculator.calculateTargetCalories(
        tdee: 1300.0,
        goal: 'LOSE',
        gender: 'Female',
      );
      expect(clampedFemale, equals(1200.0));
    });

    test('calculateMacros computes balanced gram targets', () {
      final macros = TDEECalculator.calculateMacros(
        targetCalories: 2000.0,
        goal: 'LOSE',
        weightKg: 80.0,
      );
      // Protein: 80 * 2.2 = 176g
      expect(macros['protein'], equals(176.0));
      // Fat: 25% of 2000 = 500 kcal / 9 = ~56g
      expect(macros['fat'], equals(56.0));
      // Carbs: (2000 - 176*4 - 56*9) / 4 = (2000 - 704 - 504)/4 = 792/4 = 198g
      expect(macros['carbs'], equals(198.0));
    });
  });

  group('Transformation Plans Blueprint & Model Tests', () {
    test('TransformationPlansData blueprints are defined and valid', () {
      expect(TransformationPlansData.primaryPlans.length, equals(3));
      expect(TransformationPlansData.specialisedPlans.length, equals(1));
      expect(TransformationPlansData.allPlans.length, equals(4));

      final beg = TransformationPlansData.beginnerFitness30;
      expect(beg.durationDays, equals(30));
      expect(beg.phases.isNotEmpty, isTrue);

      final wl = TransformationPlansData.weightLoss60;
      expect(wl.durationDays, equals(60));
      expect(wl.phases.isNotEmpty, isTrue);

      final mb = TransformationPlansData.muscleBuilding90;
      expect(mb.durationDays, equals(90));
      expect(mb.phases.isNotEmpty, isTrue);

      final st = TransformationPlansData.strength12Week;
      expect(st.durationDays, equals(84));
      expect(st.phases.isNotEmpty, isTrue);
    });

    test('getDayBlueprint maps day numbers correctly to workouts', () {
      final wl = TransformationPlansData.weightLoss60;
      // Day 1 should be a workout day
      final day1 = wl.getDayBlueprint(1);
      expect(day1, isNotNull);
      expect(day1!.dayType, equals('workout'));
      expect(day1.exerciseNames.isNotEmpty, isTrue);

      // Day 3 should be active recovery / rest
      final day3 = wl.getDayBlueprint(3);
      expect(day3, isNotNull);
      expect(day3!.isRestDay, isTrue);
    });

    test('UserTransformationState serialization works seamlessly', () {
      final now = DateTime.now();
      final state = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Weight Loss Challenge',
        startDate: now,
        targetEndDate: now.add(const Duration(days: 60)),
        currentDay: 12,
        totalDays: 60,
        completedDayIndices: [1, 2, 4, 5, 8],
        targetCalories: 1950.0,
        targetMacros: const {'protein': 160.0, 'carbs': 180.0, 'fat': 55.0},
        workoutLocation: 'gym',
        experienceLevel: 'Intermediate',
        availableEquipment: const ['Barbell', 'Dumbbell'],
      );

      expect(state.completionPercentage, closeTo(5 / 60.0, 0.001));
      expect(state.currentWeekNumber, equals(2));

      final map = state.toMap();
      final restored = UserTransformationState.fromMap(map);

      expect(restored.planId, equals(state.planId));
      expect(restored.currentDay, equals(state.currentDay));
      expect(restored.completedDayIndices.length, equals(5));
      expect(restored.targetCalories, equals(1950.0));
      expect(restored.workoutLocation, equals('gym'));
    });
  });

  group('TransformationProvider In-Memory State Tests', () {
    test('Enrollment and day completion toggle updates state correctly', () async {
      Map<String, dynamic>? inMemoryDoc;

      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_123';
      provider.activeDocSaverForTesting = (uid, data) async {
        inMemoryDoc = data;
      };
      provider.activeDocFetcherForTesting = (uid) => inMemoryDoc;

      expect(provider.hasActiveTransformation, isFalse);

      final blueprint = TransformationPlansData.weightLoss60;
      await provider.enrollInPlan(
        blueprint: blueprint,
        targetCalories: 2000.0,
        targetMacros: const {'protein': 160.0, 'carbs': 190.0, 'fat': 55.0},
        workoutLocation: 'gym',
        experienceLevel: 'Beginner',
      );

      expect(provider.hasActiveTransformation, isTrue);
      expect(provider.activeTransformation?.planId, equals('weight_loss_60'));
      expect(provider.isDayCompleted(1), isFalse);

      // Toggle day 1 complete
      await provider.toggleDayCompletion(1);
      expect(provider.isDayCompleted(1), isTrue);

      // Toggle day 1 incomplete
      await provider.toggleDayCompletion(1);
      expect(provider.isDayCompleted(1), isFalse);

      // Complete plan moves it to history
      await provider.completePlan();
      expect(provider.hasActiveTransformation, isFalse);
      expect(provider.history.length, equals(1));
      expect(provider.history.first.status, equals('completed'));
    });
  });
}
