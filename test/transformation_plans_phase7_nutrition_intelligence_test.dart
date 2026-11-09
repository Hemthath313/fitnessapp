import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/model/meal_model.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/model/water_model.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/diet_nutrition/diet_main.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/data/transformation_food_library.dart';
import 'package:fitness_app/presentation/transformation_plans/models/transformation_meal_plan_model.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_nutrition_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/utils/transformation_meal_plan_generator.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/transformation_log_meal_dialog.dart';
import 'package:fitness_app/utils/tdee_calculator.dart';

class MockConsumptionProvider extends ChangeNotifier
    implements ConsumptionProvider {
  final List<MealModel> _mockMeals = [];
  final List<Map<String, dynamic>> loggedMealCalls = [];

  @override
  List<MealModel> get meals => [..._mockMeals];

  @override
  List<WaterModel> get water => [];

  @override
  double kCalaDay = 0.0;

  @override
  double waterADay = 0.0;

  @override
  int consumedCalories = 0;

  @override
  Future<void> addNewMeal({
    required String title,
    required double amount,
    required double calories,
    required double fats,
    required double carbs,
    required double proteins,
    required DateTime dateTime,
  }) async {
    loggedMealCalls.add({
      'title': title,
      'amount': amount,
      'calories': calories,
      'fats': fats,
      'carbs': carbs,
      'proteins': proteins,
      'dateTime': dateTime,
    });
    consumedCalories += calories.round();
    _mockMeals.add(MealModel(
      id: 'meal_${_mockMeals.length + 1}',
      title: title,
      calories: calories,
      amount: amount,
      carbs: carbs,
      fats: fats,
      proteins: proteins,
      dateTime: dateTime,
    ));
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHomeProvider extends ChangeNotifier implements HomeProvider {
  @override
  Map<String, dynamic> userData = {
    'name': 'Alex Johnson',
    'age': 28,
    'gender': 'Male',
    'height': 178.0,
    'weight': 75.0,
    'activity': 'MODERATE',
    'fitnessGoal': 'BUILD',
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSubscriptionProvider extends ChangeNotifier implements SubscriptionProvider {
  @override
  bool get isPremium => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 7 — Personalised Nutrition Calculation & Consistency', () {
    test('1. Complete Beginner – 30 Days calculates maintenance calories (100% TDEE) and 1.8g/kg protein', () {
      final result = TDEECalculator.calculateProgrammeNutrition(
        programmeId: 'beginner_fitness_30',
        gender: 'Male',
        weightKg: 70.0,
        heightCm: 175.0,
        age: 25,
        activityLevel: 'MODERATE',
      );

      expect((result.targetCalories - result.tdee).abs(), lessThanOrEqualTo(5.0));
      expect(result.proteinGrams, equals(70.0 * 1.8)); // 126g
      expect(result.isMathematicallyConsistent, isTrue);
      expect(result.isUnusuallyLow, isFalse);
    });

    test('2. Weight Loss – 60 Days calculates 20% deficit, 2.2g/kg protein, and flags unusually low targets', () {
      // Normal weight user: healthy deficit
      final normalResult = TDEECalculator.calculateProgrammeNutrition(
        programmeId: 'weight_loss_60',
        gender: 'Male',
        weightKg: 85.0,
        heightCm: 180.0,
        age: 30,
        activityLevel: 'MODERATE',
      );

      expect((normalResult.proteinGrams - (85.0 * 2.2)).abs(), lessThanOrEqualTo(0.01)); // 187g
      expect(normalResult.isMathematicallyConsistent, isTrue);
      expect(normalResult.isUnusuallyLow, isFalse);

      // Very low weight female with sedentary activity: flags review for extreme deficit
      final lowWeightResult = TDEECalculator.calculateProgrammeNutrition(
        programmeId: 'weight_loss_60',
        gender: 'Female',
        weightKg: 42.0,
        heightCm: 150.0,
        age: 22,
        activityLevel: 'SEDENTARY',
      );

      expect(lowWeightResult.isUnusuallyLow, isTrue);
      expect(lowWeightResult.needsReview, isTrue);
      expect(lowWeightResult.reviewNote, contains('metabolic safety recommendations'));
      expect(lowWeightResult.targetCalories, greaterThanOrEqualTo(1200.0));
      expect(lowWeightResult.isMathematicallyConsistent, isTrue);
    });

    test('3. Muscle Building – 90 Days calculates moderate surplus (+12%), 2.0g/kg protein, and high carbs', () {
      final result = TDEECalculator.calculateProgrammeNutrition(
        programmeId: 'muscle_building_90',
        gender: 'Male',
        weightKg: 75.0,
        heightCm: 178.0,
        age: 26,
        activityLevel: 'ACTIVE',
      );

      expect(result.targetCalories, greaterThan(result.tdee));
      expect(result.proteinGrams, equals(75.0 * 2.0)); // 150g
      expect(result.carbGrams, greaterThan(250.0)); // High carbs for hypertrophy
      expect(result.isMathematicallyConsistent, isTrue);
      expect(result.isUnusuallyHigh, isFalse);
    });

    test('4. Macro consistency check strictly satisfies (4*P + 4*C + 9*F = targetCalories)', () {
      for (final programme in ['beginner_fitness_30', 'weight_loss_60', 'muscle_building_90']) {
        final res = TDEECalculator.calculateProgrammeNutrition(
          programmeId: programme,
          gender: 'Male',
          weightKg: 80.0,
          heightCm: 180.0,
          age: 28,
          activityLevel: 'MODERATE',
        );
        final calculatedTotal = (res.proteinGrams * 4.0) + (res.carbGrams * 4.0) + (res.fatGrams * 9.0);
        expect((calculatedTotal - res.targetCalories).abs(), lessThanOrEqualTo(5.0));
      }
    });
  });

  group('Phase 7 — TransformationMealPlanGenerator & Dietary Variety', () {
    test('5. Generates complete 5-meal schedule with daily sum matching targets within reasonable tolerance', () {
      final mealPlan = TransformationMealPlanGenerator.generateDailyMealPlan(
        dayNumber: 1,
        targetCalories: 2200.0,
        targetMacros: {'protein': 160.0, 'carbs': 240.0, 'fat': 60.0},
        dietaryPreference: 'Non-vegetarian',
        allergies: [],
        programmeId: 'weight_loss_60',
      );

      expect(mealPlan.meals.length, equals(5));
      expect(mealPlan.meals.map((m) => m.name).toList(), [
        'Breakfast',
        'Mid-Morning Snack',
        'Lunch',
        'Evening Snack',
        'Dinner',
      ]);

      // Daily totals match within 5%
      expect((mealPlan.actualTotalCalories - 2200.0).abs(), lessThanOrEqualTo(120.0));
      expect(mealPlan.isSafe, isTrue);
      expect(mealPlan.flaggedForReview, isFalse);
    });

    test('6. Generates valid Vegetarian meal plan containing paneer, milk, curd, dal and no meat or fish', () {
      final vegPlan = TransformationMealPlanGenerator.generateDailyMealPlan(
        dayNumber: 1,
        targetCalories: 2000.0,
        targetMacros: {'protein': 140.0, 'carbs': 230.0, 'fat': 55.0},
        dietaryPreference: 'Vegetarian',
        allergies: [],
      );

      final allFoodNames = vegPlan.meals.expand((m) => m.foods.map((f) => f.name.toLowerCase())).toList();
      expect(allFoodNames.any((n) => n.contains('chicken') || n.contains('fish') || n.contains('tuna')), isFalse);
      expect(allFoodNames.any((n) => n.contains('paneer') || n.contains('dal') || n.contains('curd') || n.contains('yogurt')), isTrue);
      expect(vegPlan.isSafe, isTrue);
    });

    test('7. Generates valid Non-Vegetarian meal plan containing chicken, fish, eggs, and grains', () {
      final nonVegPlan = TransformationMealPlanGenerator.generateDailyMealPlan(
        dayNumber: 1,
        targetCalories: 2400.0,
        targetMacros: {'protein': 170.0, 'carbs': 260.0, 'fat': 65.0},
        dietaryPreference: 'Non-vegetarian',
        allergies: [],
      );

      final allFoodNames = nonVegPlan.meals.expand((m) => m.foods.map((f) => f.name.toLowerCase())).toList();
      expect(allFoodNames.any((n) => n.contains('chicken') || n.contains('egg') || n.contains('fish')), isTrue);
      expect(nonVegPlan.isSafe, isTrue);
    });

    test('8. Generates valid Vegan meal plan containing tofu, soya chunks, dal, legumes, and no animal products', () {
      final veganPlan = TransformationMealPlanGenerator.generateDailyMealPlan(
        dayNumber: 1,
        targetCalories: 1900.0,
        targetMacros: {'protein': 130.0, 'carbs': 220.0, 'fat': 50.0},
        dietaryPreference: 'Vegan',
        allergies: [],
      );

      final allFoodNames = veganPlan.meals.expand((m) => m.foods.map((f) => f.name.toLowerCase())).toList();
      // Ensure no animal products (meat, poultry, fish, eggs, dairy) are present in vegan plan
      expect(allFoodNames.any((n) => n.contains('chicken') || n.contains('fish') || n.contains('egg') || n.contains('paneer') || n.contains('cow milk') || n.contains('ghee') || n.contains('curd') || n.contains('yogurt')), isFalse);
      expect(allFoodNames.any((n) => n.contains('tofu') || n.contains('soya') || n.contains('dal') || n.contains('chana')), isTrue);
      expect(veganPlan.isSafe, isTrue);
    });

    test('9. Day-to-day rotational variety: meal plan rotates across days', () {
      final day1 = TransformationMealPlanGenerator.generateDailyMealPlan(
        dayNumber: 1,
        targetCalories: 2000.0,
        targetMacros: {'protein': 140.0, 'carbs': 220.0, 'fat': 55.0},
        dietaryPreference: 'Non-vegetarian',
        allergies: [],
      );
      final day2 = TransformationMealPlanGenerator.generateDailyMealPlan(
        dayNumber: 2,
        targetCalories: 2000.0,
        targetMacros: {'protein': 140.0, 'carbs': 220.0, 'fat': 55.0},
        dietaryPreference: 'Non-vegetarian',
        allergies: [],
      );

      final day1Foods = day1.meals[0].foods.map((f) => f.name).join(', ');
      final day2Foods = day2.meals[0].foods.map((f) => f.name).join(', ');
      expect(day1Foods, isNot(equals(day2Foods)), reason: 'Breakfast on Day 1 should differ from Day 2');
    });
  });

  group('Phase 7 — Allergy Filtering & Safe Substitutions', () {
    test('10. Filters Dairy allergen (replaces paneer with tofu, milk with soy milk, ghee with olive oil)', () {
      final dairyAllergicPlan = TransformationMealPlanGenerator.generateDailyMealPlan(
        dayNumber: 1,
        targetCalories: 2000.0,
        targetMacros: {'protein': 140.0, 'carbs': 220.0, 'fat': 55.0},
        dietaryPreference: 'Vegetarian',
        allergies: ['Dairy'],
      );

      for (final meal in dairyAllergicPlan.meals) {
        for (final food in meal.foods) {
          expect(food.allergens.contains('dairy'), isFalse, reason: '${food.name} contains dairy');
        }
      }
    });

    test('11. Filters Gluten allergen (replaces roti/bread with rice/quinoa)', () {
      final glutenAllergicPlan = TransformationMealPlanGenerator.generateDailyMealPlan(
        dayNumber: 1,
        targetCalories: 2000.0,
        targetMacros: {'protein': 140.0, 'carbs': 220.0, 'fat': 55.0},
        dietaryPreference: 'Non-vegetarian',
        allergies: ['Gluten'],
      );

      for (final meal in glutenAllergicPlan.meals) {
        for (final food in meal.foods) {
          expect(food.allergens.contains('gluten'), isFalse, reason: '${food.name} contains gluten');
        }
      }
    });

    test('12. Filters Nut allergen (replaces almonds and peanut butter with seeds and fruits)', () {
      final nutAllergicPlan = TransformationMealPlanGenerator.generateDailyMealPlan(
        dayNumber: 1,
        targetCalories: 2000.0,
        targetMacros: {'protein': 140.0, 'carbs': 220.0, 'fat': 55.0},
        dietaryPreference: 'Non-vegetarian',
        allergies: ['Nuts'],
      );

      for (final meal in nutAllergicPlan.meals) {
        for (final food in meal.foods) {
          expect(food.allergens.contains('nuts'), isFalse, reason: '${food.name} contains nuts');
        }
      }
    });

    test('13. Filters Egg allergen for non-veg users without reintroducing allergens', () {
      final eggAllergicPlan = TransformationMealPlanGenerator.generateDailyMealPlan(
        dayNumber: 1,
        targetCalories: 2000.0,
        targetMacros: {'protein': 140.0, 'carbs': 220.0, 'fat': 55.0},
        dietaryPreference: 'Non-vegetarian',
        allergies: ['Eggs'],
      );

      for (final meal in eggAllergicPlan.meals) {
        for (final food in meal.foods) {
          expect(food.allergens.contains('eggs'), isFalse, reason: '${food.name} contains eggs');
        }
      }
    });

    test('14. Conflicting/unsafe restrictions (Vegan + Soy + Nuts) flag review without generating unsafe meals', () {
      final unsafePlan = TransformationMealPlanGenerator.generateDailyMealPlan(
        dayNumber: 1,
        targetCalories: 2200.0,
        targetMacros: {'protein': 150.0, 'carbs': 250.0, 'fat': 60.0},
        dietaryPreference: 'Vegan',
        allergies: ['Soy', 'Nuts'],
      );

      expect(unsafePlan.isSafe, isFalse);
      expect(unsafePlan.flaggedForReview, isTrue);
      expect(unsafePlan.reviewMessage, contains('severe allergen restrictions'));
      expect(unsafePlan.meals, isEmpty);
    });
  });

  group('Phase 7 — Food Library, Raw vs Cooked Weights & Data Persistence', () {
    test('15. Explicitly differentiates raw vs cooked weight designations', () {
      final chicken = TransformationFoodLibrary.getById('grilled_chicken_breast')!;
      expect(chicken.isRawWeight, isTrue);
      expect(chicken.preparationNote, contains('Raw weight'));

      final rice = TransformationFoodLibrary.getById('cooked_brown_rice')!;
      expect(rice.isRawWeight, isFalse);
      expect(rice.preparationNote, contains('Cooked weight'));
    });

    test('16. Persists selected allergies and custom food substitutions in UserTransformationState', () {
      final state = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Weight Loss Challenge',
        startDate: DateTime.now(),
        targetEndDate: DateTime.now().add(const Duration(days: 60)),
        currentDay: 1,
        totalDays: 60,
        targetCalories: 2000.0,
        targetMacros: {'protein': 160.0, 'carbs': 180.0, 'fat': 60.0},
        allergies: ['Dairy', 'Gluten'],
        mealSubstitutions: {'day_1_meal_lunch_food_1': 'steamed_white_fish'},
      );

      final map = state.toMap();
      expect(map['allergies'], equals(['Dairy', 'Gluten']));
      expect(map['mealSubstitutions'], equals({'day_1_meal_lunch_food_1': 'steamed_white_fish'}));

      final restored = UserTransformationState.fromMap(map);
      expect(restored.allergies, equals(['Dairy', 'Gluten']));
      expect(restored.mealSubstitutions, equals({'day_1_meal_lunch_food_1': 'steamed_white_fish'}));
    });

    test('17. Backward compatibility: old Firestore documents without allergies or mealSubstitutions deserialize cleanly', () {
      final legacyDoc = {
        'planId': 'weight_loss_60',
        'planTitle': '60-Day Weight Loss Challenge',
        'startDate': '2026-10-15T00:00:00.000',
        'targetEndDate': '2026-12-14T00:00:00.000',
        'currentDay': 10,
        'totalDays': 60,
        'targetCalories': 2100.0,
        'targetMacros': {'protein': 150.0, 'carbs': 200.0, 'fat': 60.0},
        'foodRestrictions': 'Nuts, Shellfish',
        // 'allergies' and 'mealSubstitutions' omitted deliberately
      };

      final restored = UserTransformationState.fromMap(legacyDoc);
      expect(restored.allergies, equals(['Nuts', 'Shellfish']));
      expect(restored.mealSubstitutions, isEmpty);
    });
  });

  group('Phase 7 — UI & ConsumptionProvider Integration', () {
    testWidgets('18. TransformationNutritionScreen renders 5 meals, day tabs, and nutrition summary', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockTransformationProvider = TransformationProvider(autoLoad: false);
      mockTransformationProvider.activeDocFetcherForTesting = (_) => {
        'planId': 'weight_loss_60',
        'planTitle': '60-Day Weight Loss Challenge',
        'startDate': '2026-11-01T00:00:00.000',
        'targetEndDate': '2026-12-30T00:00:00.000',
        'currentDay': 1,
        'totalDays': 60,
        'targetCalories': 2000.0,
        'targetMacros': {'protein': 160.0, 'carbs': 180.0, 'fat': 60.0},
        'dietaryPreference': 'Non-vegetarian',
        'allergies': ['Dairy'],
      };
      mockTransformationProvider.userIdOverrideForTesting = 'test_user';
      await mockTransformationProvider.loadTransformation();

      final mockConsumptionProvider = MockConsumptionProvider();

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(430, 932),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, _) => MultiProvider(
            providers: [
              ChangeNotifierProvider<TransformationProvider>.value(
                value: mockTransformationProvider,
              ),
              ChangeNotifierProvider<ConsumptionProvider>.value(
                value: mockConsumptionProvider,
              ),
            ],
            child: const MaterialApp(
              home: TransformationNutritionScreen(initialDayNumber: 1),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header and Daily Summary
      expect(find.text('Daily Meal Plan'), findsOneWidget);
      expect(find.text('Daily Target Breakdown'), findsOneWidget);
      expect(find.text('Scheduled Daily Meals (5)'), findsOneWidget);

      // Verify Meals
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
      expect(find.byKey(const Key('log_meal_breakfast_button')), findsOneWidget);
    });

    testWidgets('19. Logging a meal via TransformationLogMealDialog calls ConsumptionProvider and marks meal logged', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockTransformationProvider = TransformationProvider(autoLoad: false);
      mockTransformationProvider.activeDocFetcherForTesting = (_) => {
        'planId': 'weight_loss_60',
        'planTitle': '60-Day Weight Loss Challenge',
        'startDate': '2026-11-01T00:00:00.000',
        'targetEndDate': '2026-12-30T00:00:00.000',
        'currentDay': 1,
        'totalDays': 60,
        'targetCalories': 2000.0,
        'targetMacros': {'protein': 160.0, 'carbs': 180.0, 'fat': 60.0},
        'dietaryPreference': 'Non-vegetarian',
      };
      mockTransformationProvider.userIdOverrideForTesting = 'test_user';
      await mockTransformationProvider.loadTransformation();

      final mockConsumptionProvider = MockConsumptionProvider();

      final sampleMeal = const TransformationMeal(
        id: 'breakfast',
        name: 'Breakfast',
        timeGuidance: '8:00 AM – 9:00 AM',
        foods: [
          TransformationFoodItem(
            id: 'boiled_whole_egg',
            name: 'Whole Boiled Egg',
            quantity: 2.0,
            unit: 'piece',
            isRawWeight: false,
            preparationNote: 'Cooked',
            calories: 144.0,
            protein: 12.6,
            carbs: 0.8,
            fat: 9.6,
            dietaryCategory: 'non_vegetarian',
          ),
        ],
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(430, 932),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, _) => MultiProvider(
            providers: [
              ChangeNotifierProvider<TransformationProvider>.value(
                value: mockTransformationProvider,
              ),
              ChangeNotifierProvider<ConsumptionProvider>.value(
                value: mockConsumptionProvider,
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    key: const Key('open_log_dialog'),
                    onPressed: () => TransformationLogMealDialog.show(
                      context: ctx,
                      meal: sampleMeal,
                      dayNumber: 1,
                      provider: mockTransformationProvider,
                    ),
                    child: const Text('Open Dialog'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Dialog
      await tester.tap(find.byKey(const Key('open_log_dialog')));
      await tester.pumpAndSettle();

      expect(find.text('Log Breakfast'), findsOneWidget);
      expect(find.byKey(const Key('confirm_log_meal_button')), findsOneWidget);

      // Tap Confirm Log
      await tester.tap(find.byKey(const Key('confirm_log_meal_button')));
      await tester.pumpAndSettle();

      // Verify ConsumptionProvider received the meal
      expect(mockConsumptionProvider.loggedMealCalls.length, equals(1));
      expect(mockConsumptionProvider.loggedMealCalls.first['title'], equals('Transformation Breakfast'));
      expect(mockConsumptionProvider.loggedMealCalls.first['calories'], equals(144.0));
      expect(mockTransformationProvider.isMealLoggedToday('day_1_meal_breakfast'), isTrue);
    });

    testWidgets('20. Existing static DietMain and diet JSONs remain functional', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockHome = MockHomeProvider();
      mockHome.userData = {
        'goal': 'LOSE',
        'weight': 75.0,
        'activity': 'MODERATE',
        'bmr': 1750.0,
      };
      final mockSub = MockSubscriptionProvider();

      await tester.pumpWidget(
        ScreenUtilInit(
          key: UniqueKey(),
          designSize: const Size(600, 1000),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, _) => MultiProvider(
            providers: [
              ChangeNotifierProvider<HomeProvider>.value(value: mockHome),
              ChangeNotifierProvider<SubscriptionProvider>.value(value: mockSub),
            ],
            child: const MaterialApp(
              home: DietMain(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nutrition Hub'), findsOneWidget);
      expect(find.text('Cutting Phase'), findsOneWidget);
      expect(find.text('Cutting Meal Plan'), findsOneWidget);
      expect(find.text('Tools & Resources'), findsOneWidget);

      // Verify static diet JSON assets parse properly
      final cuttingJson = await rootBundle.loadString('assets/json/cuttingdiet.json');
      final cuttingData = json.decode(cuttingJson) as Map<String, dynamic>;
      expect(cuttingData['meals'], isNotEmpty);
      expect(cuttingData['mealLibrary'], isNotEmpty);

      final bulkingJson = await rootBundle.loadString('assets/json/bulkingdiet.json');
      final bulkingData = json.decode(bulkingJson) as Map<String, dynamic>;
      expect(bulkingData['meals'], isNotEmpty);

      final maintainJson = await rootBundle.loadString('assets/json/maintaindiet.json');
      final maintainData = json.decode(maintainJson) as Map<String, dynamic>;
      expect(maintainData['meals'], isNotEmpty);
    });
  });
}
