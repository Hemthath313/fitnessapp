import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/model/meal_model.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/model/water_model.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/models/transformation_daily_log_model.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_progress_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_roadmap_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/transformation_daily_checklist.dart';

class MockConsumptionProvider extends ChangeNotifier implements ConsumptionProvider {
  final List<MealModel> _mockMeals = [];
  final List<WaterModel> _mockWater = [];

  @override
  List<MealModel> get meals => [..._mockMeals];

  @override
  List<WaterModel> get water => [..._mockWater];

  @override
  double kCalaDay = 0.0;

  @override
  double waterADay = 0.0;

  @override
  int consumedCalories = 0;

  void setMockMeals(List<MealModel> meals) {
    _mockMeals.clear();
    _mockMeals.addAll(meals);
    notifyListeners();
  }

  void setMockWater(List<WaterModel> water) {
    _mockWater.clear();
    _mockWater.addAll(water);
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHomeProvider extends ChangeNotifier implements HomeProvider {
  @override
  Map<String, dynamic> userData = {
    'name': 'Alex Fitness',
    'age': 28,
    'gender': 'Male',
    'height': 180.0,
    'weight': 82.5,
    'activity': 'MODERATE',
    'fitnessGoal': 'BUILD',
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void _configureTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _wrapWithTestProviders({
  required Widget child,
  required TransformationProvider transformationProvider,
  ConsumptionProvider? consumptionProvider,
  HomeProvider? homeProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TransformationProvider>.value(value: transformationProvider),
      ChangeNotifierProvider<ConsumptionProvider>.value(
        value: consumptionProvider ?? MockConsumptionProvider(),
      ),
      ChangeNotifierProvider<HomeProvider>.value(
        value: homeProvider ?? MockHomeProvider(),
      ),
    ],
    child: ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        home: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Gym Buddy Phase 8 – Daily Accountability & Consumption Adherence Tests', () {
    // 1. Daily log serialization / deserialization
    test('1. TransformationDailyLog toMap and fromMap serialization preserves all fields', () {
      final now = DateTime(2026, 11, 2, 12, 0);
      final log = TransformationDailyLog(
        planId: 'weight_loss_60',
        dayNumber: 5,
        dateString: '2026-11-02',
        workoutStatus: AccountabilityStatus.completed,
        calorieStatus: AccountabilityStatus.partiallyCompleted,
        proteinStatus: AccountabilityStatus.completed,
        waterStatus: AccountabilityStatus.completed,
        recoveryStatus: AccountabilityStatus.completed,
        dailyAdherenceScore: 90.0,
        lastUpdated: now,
        actualCalories: 1950.0,
        targetCalories: 2000.0,
        actualProtein: 155.0,
        targetProtein: 160.0,
        actualWaterMl: 2600.0,
        targetWaterMl: 2500.0,
        recoveryLevel: 'good',
        recoveryNote: 'Slept 8 hours',
        isRestDay: false,
      );

      final map = log.toMap();
      expect(map['planId'], 'weight_loss_60');
      expect(map['dayNumber'], 5);
      expect(map['dateString'], '2026-11-02');
      expect(map['workoutStatus'], AccountabilityStatus.completed);
      expect(map['calorieStatus'], AccountabilityStatus.partiallyCompleted);
      expect(map['dailyAdherenceScore'], 90.0);
      expect(map['recoveryLevel'], 'good');
      expect(map['recoveryNote'], 'Slept 8 hours');
      expect(map['isRestDay'], isFalse);

      final restored = TransformationDailyLog.fromMap(map);
      expect(restored.planId, log.planId);
      expect(restored.dayNumber, log.dayNumber);
      expect(restored.dateString, log.dateString);
      expect(restored.workoutStatus, log.workoutStatus);
      expect(restored.calorieStatus, log.calorieStatus);
      expect(restored.dailyAdherenceScore, log.dailyAdherenceScore);
      expect(restored.actualCalories, log.actualCalories);
      expect(restored.actualWaterMl, log.actualWaterMl);
      expect(restored.recoveryLevel, 'good');
      expect(restored.recoveryNote, 'Slept 8 hours');
      expect(restored.isRestDay, isFalse);
    });

    // 2. Daily adherence score calculation (5 components, 20 pts each)
    test('2. Adherence score calculation on training days gives 20 pts per completed component (100% total)', () {
      final log = TransformationDailyLog.calculate(
        planId: 'weight_loss_60',
        dayNumber: 1,
        dateString: '2026-11-02',
        workoutCompleted: true,
        isRestDay: false,
        actualCalories: 2000.0,
        targetCalories: 2000.0,
        actualProtein: 150.0,
        targetProtein: 150.0,
        actualWaterMl: 2500.0,
        targetWaterMl: 2500.0,
        recoveryLevel: 'good',
        isToday: true,
      );

      expect(log.workoutStatus, AccountabilityStatus.completed);
      expect(log.calorieStatus, AccountabilityStatus.completed);
      expect(log.proteinStatus, AccountabilityStatus.completed);
      expect(log.waterStatus, AccountabilityStatus.completed);
      expect(log.recoveryStatus, AccountabilityStatus.completed);
      expect(log.dailyAdherenceScore, 100.0);
      expect(log.totalAssessableComponents, 5);
      expect(log.trackedComponentsCount, 5);
      expect(log.hasEnoughData, isTrue);
    });

    // 3. Rest-day workout exclusion from denominator (4 components, max 80 pts)
    test('3. Rest-day workout is excluded from denominator so remaining 4 components total 100% without penalty', () {
      final log = TransformationDailyLog.calculate(
        planId: 'weight_loss_60',
        dayNumber: 7,
        dateString: '2026-11-02',
        workoutCompleted: false, // User didn't do a workout because it's a scheduled rest day
        isRestDay: true,
        actualCalories: 2000.0,
        targetCalories: 2000.0,
        actualProtein: 150.0,
        targetProtein: 150.0,
        actualWaterMl: 2500.0,
        targetWaterMl: 2500.0,
        recoveryLevel: 'good',
        isToday: true,
      );

      expect(log.workoutStatus, AccountabilityStatus.notApplicable);
      expect(log.isRestDay, isTrue);
      expect(log.totalAssessableComponents, 4);
      expect(log.calorieStatus, AccountabilityStatus.completed);
      expect(log.proteinStatus, AccountabilityStatus.completed);
      expect(log.waterStatus, AccountabilityStatus.completed);
      expect(log.recoveryStatus, AccountabilityStatus.completed);
      // 4 components x 20 pts = 80 earned out of 80 assessable = 100.0%
      expect(log.dailyAdherenceScore, 100.0);
    });

    // 4. Missing data handling ("Not enough data" when 0 items tracked)
    test('4. Missing data handling reports Not enough data and does not penalize with false 0%', () {
      final log = TransformationDailyLog.calculate(
        planId: 'weight_loss_60',
        dayNumber: 1,
        dateString: '2026-11-02',
        workoutCompleted: false,
        isRestDay: false,
        actualCalories: 0.0,
        targetCalories: 2000.0,
        actualProtein: 0.0,
        targetProtein: 150.0,
        actualWaterMl: 0.0,
        targetWaterMl: 2500.0,
        recoveryLevel: null,
        isToday: true,
      );

      expect(log.workoutStatus, AccountabilityStatus.pending);
      expect(log.calorieStatus, AccountabilityStatus.pending);
      expect(log.proteinStatus, AccountabilityStatus.pending);
      expect(log.waterStatus, AccountabilityStatus.pending);
      expect(log.recoveryStatus, AccountabilityStatus.pending);
      expect(log.trackedComponentsCount, 0);
      expect(log.hasEnoughData, isFalse);
      expect(log.coverageText, 'Not enough data');
    });

    // 5. Partial completion scoring
    test('5. Partial completion awards half points for calories, protein, water, and poor recovery', () {
      final log = TransformationDailyLog.calculate(
        planId: 'weight_loss_60',
        dayNumber: 1,
        dateString: '2026-11-02',
        workoutCompleted: false, // 0 pts
        isRestDay: false,
        actualCalories: 2350.0, // Target 2000 -> 17.5% diff -> partial (10 pts)
        targetCalories: 2000.0,
        actualProtein: 110.0,   // Target 150 -> 73.3% -> partial (10 pts)
        targetProtein: 150.0,
        actualWaterMl: 1500.0,  // Target 2500 -> 60% -> partial (10 pts)
        targetWaterMl: 2500.0,
        recoveryLevel: 'poor',  // poor -> partial (10 pts)
        isToday: true,
      );

      expect(log.calorieStatus, AccountabilityStatus.partiallyCompleted);
      expect(log.proteinStatus, AccountabilityStatus.partiallyCompleted);
      expect(log.waterStatus, AccountabilityStatus.partiallyCompleted);
      expect(log.recoveryStatus, AccountabilityStatus.partiallyCompleted);
      // 10 + 10 + 10 + 10 = 40.0 pts out of 100
      expect(log.dailyAdherenceScore, 40.0);
    });

    // 6. Calorie target comparison (±10% complete, ±20% partial, ±200 kcal absolute)
    test('6. Calorie target tolerances correctly evaluate completed, partial, and not completed', () {
      // Complete: within 10%
      final c1 = TransformationDailyLog.calculate(
        planId: 'p', dayNumber: 1, dateString: 'd', workoutCompleted: false, isRestDay: false,
        actualCalories: 2150.0, targetCalories: 2000.0, actualProtein: 0, targetProtein: 100, actualWaterMl: 0, targetWaterMl: 2000,
      );
      expect(c1.calorieStatus, AccountabilityStatus.completed);

      // Complete: within 200 absolute kcal (e.g. 1150 vs 1000)
      final c2 = TransformationDailyLog.calculate(
        planId: 'p', dayNumber: 1, dateString: 'd', workoutCompleted: false, isRestDay: false,
        actualCalories: 1180.0, targetCalories: 1000.0, actualProtein: 0, targetProtein: 100, actualWaterMl: 0, targetWaterMl: 2000,
      );
      expect(c2.calorieStatus, AccountabilityStatus.completed);

      // Partial: 16% diff (between 10% and 20%)
      final c3 = TransformationDailyLog.calculate(
        planId: 'p', dayNumber: 1, dateString: 'd', workoutCompleted: false, isRestDay: false,
        actualCalories: 2320.0, targetCalories: 2000.0, actualProtein: 0, targetProtein: 100, actualWaterMl: 0, targetWaterMl: 2000,
      );
      expect(c3.calorieStatus, AccountabilityStatus.partiallyCompleted);

      // Not completed: >20% diff
      final c4 = TransformationDailyLog.calculate(
        planId: 'p', dayNumber: 1, dateString: 'd', workoutCompleted: false, isRestDay: false,
        actualCalories: 2600.0, targetCalories: 2000.0, actualProtein: 0, targetProtein: 100, actualWaterMl: 0, targetWaterMl: 2000,
      );
      expect(c4.calorieStatus, AccountabilityStatus.notCompleted);
    });

    // 7. Protein target comparison (>=90% complete, >=70% partial)
    test('7. Protein target evaluation correctly evaluates thresholds', () {
      const target = 160.0;
      // >= 90% (144g)
      final p1 = TransformationDailyLog.calculate(
        planId: 'p', dayNumber: 1, dateString: 'd', workoutCompleted: false, isRestDay: false,
        actualCalories: 0, targetCalories: 2000, actualProtein: 145.0, targetProtein: target, actualWaterMl: 0, targetWaterMl: 2000,
      );
      expect(p1.proteinStatus, AccountabilityStatus.completed);

      // >= 70% (112g)
      final p2 = TransformationDailyLog.calculate(
        planId: 'p', dayNumber: 1, dateString: 'd', workoutCompleted: false, isRestDay: false,
        actualCalories: 0, targetCalories: 2000, actualProtein: 120.0, targetProtein: target, actualWaterMl: 0, targetWaterMl: 2000,
      );
      expect(p2.proteinStatus, AccountabilityStatus.partiallyCompleted);

      // < 70%
      final p3 = TransformationDailyLog.calculate(
        planId: 'p', dayNumber: 1, dateString: 'd', workoutCompleted: false, isRestDay: false,
        actualCalories: 0, targetCalories: 2000, actualProtein: 90.0, targetProtein: target, actualWaterMl: 0, targetWaterMl: 2000,
      );
      expect(p3.proteinStatus, AccountabilityStatus.notCompleted);
    });

    // 8. Water target comparison (>=80% complete, >=50% partial)
    test('8. Water target evaluation correctly evaluates thresholds', () {
      const target = 3000.0;
      // >= 80% (2400ml)
      final w1 = TransformationDailyLog.calculate(
        planId: 'p', dayNumber: 1, dateString: 'd', workoutCompleted: false, isRestDay: false,
        actualCalories: 0, targetCalories: 2000, actualProtein: 0, targetProtein: 100, actualWaterMl: 2500.0, targetWaterMl: target,
      );
      expect(w1.waterStatus, AccountabilityStatus.completed);

      // >= 50% (1500ml)
      final w2 = TransformationDailyLog.calculate(
        planId: 'p', dayNumber: 1, dateString: 'd', workoutCompleted: false, isRestDay: false,
        actualCalories: 0, targetCalories: 2000, actualProtein: 0, targetProtein: 100, actualWaterMl: 1800.0, targetWaterMl: target,
      );
      expect(w2.waterStatus, AccountabilityStatus.partiallyCompleted);

      // < 50%
      final w3 = TransformationDailyLog.calculate(
        planId: 'p', dayNumber: 1, dateString: 'd', workoutCompleted: false, isRestDay: false,
        actualCalories: 0, targetCalories: 2000, actualProtein: 0, targetProtein: 100, actualWaterMl: 1200.0, targetWaterMl: target,
      );
      expect(w3.waterStatus, AccountabilityStatus.notCompleted);
    });

    // 9. Recovery status updates (Good, Moderate, Poor)
    test('9. Recovery status updates correctly award graded points', () {
      // Good recovery: 20 points
      final rGood = TransformationDailyLog.calculate(
        planId: 'p', dayNumber: 1, dateString: 'd', workoutCompleted: false, isRestDay: false,
        actualCalories: 0, targetCalories: 2000, actualProtein: 0, targetProtein: 100, actualWaterMl: 0, targetWaterMl: 2000,
        recoveryLevel: 'good',
      );
      expect(rGood.recoveryStatus, AccountabilityStatus.completed);
      expect(rGood.dailyAdherenceScore, 20.0);

      // Moderate recovery: 15 points
      final rMod = TransformationDailyLog.calculate(
        planId: 'p', dayNumber: 1, dateString: 'd', workoutCompleted: false, isRestDay: false,
        actualCalories: 0, targetCalories: 2000, actualProtein: 0, targetProtein: 100, actualWaterMl: 0, targetWaterMl: 2000,
        recoveryLevel: 'moderate',
      );
      expect(rMod.recoveryStatus, AccountabilityStatus.completed);
      expect(rMod.dailyAdherenceScore, 15.0);

      // Poor recovery: 10 points
      final rPoor = TransformationDailyLog.calculate(
        planId: 'p', dayNumber: 1, dateString: 'd', workoutCompleted: false, isRestDay: false,
        actualCalories: 0, targetCalories: 2000, actualProtein: 0, targetProtein: 100, actualWaterMl: 0, targetWaterMl: 2000,
        recoveryLevel: 'poor',
      );
      expect(rPoor.recoveryStatus, AccountabilityStatus.partiallyCompleted);
      expect(rPoor.dailyAdherenceScore, 10.0);
    });

    // 10. Automatic workout completion synchronisation
    test('10. TransformationProvider.getDailyLogForDate syncs workout completion from completedDayIndices', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_p8';
      provider.activeDocFetcherForTesting = (_) => {
        'planId': 'weight_loss_60',
        'planTitle': '60-Day Weight Loss Challenge',
        'startDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'targetEndDate': DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 60))),
        'currentDay': 1,
        'totalDays': 60,
        'completedDayIndices': [1], // Day 1 completed!
        'targetCalories': 2000.0,
        'targetMacros': {'protein': 140.0, 'carbs': 180.0, 'fat': 60.0},
        'status': 'active',
      };
      await provider.loadTransformation();

      final today = DateTime.now();
      final log = provider.getDailyLogForDate(date: today);
      expect(log.workoutStatus, AccountabilityStatus.completed);
      expect(log.dailyAdherenceScore, 20.0); // 20 pts from workout
    });

    // 11. ConsumptionProvider integration (meals & water)
    test('11. TransformationProvider.getDailyLogForDate aggregates meals and water from ConsumptionProvider', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_p8';
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      provider.activeDocFetcherForTesting = (_) => {
        'planId': 'weight_loss_60',
        'planTitle': '60-Day Weight Loss Challenge',
        'startDate': todayStr,
        'targetEndDate': DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 60))),
        'currentDay': 1,
        'totalDays': 60,
        'completedDayIndices': <int>[],
        'targetCalories': 2000.0,
        'targetMacros': {'protein': 150.0, 'carbs': 180.0, 'fat': 60.0},
        'dailyWaterTargetMl': 2500.0,
        'status': 'active',
      };
      await provider.loadTransformation();

      final mockConsumption = MockConsumptionProvider();
      mockConsumption.setMockMeals([
        MealModel(
          id: 'm1',
          title: 'Breakfast Bowl',
          calories: 600.0,
          amount: 300.0,
          carbs: 60.0,
          fats: 20.0,
          proteins: 45.0,
          dateTime: DateTime.now(),
        ),
        MealModel(
          id: 'm2',
          title: 'Chicken Salad',
          calories: 1350.0,
          amount: 400.0,
          carbs: 80.0,
          fats: 35.0,
          proteins: 100.0,
          dateTime: DateTime.now(),
        ),
      ]);
      mockConsumption.waterADay = 2600.0;

      final log = provider.getDailyLogForDate(date: DateTime.now(), consumptionProvider: mockConsumption);
      // Total calories: 1950 (within 10% of 2000) -> completed
      expect(log.actualCalories, 1950.0);
      expect(log.calorieStatus, AccountabilityStatus.completed);

      // Total protein: 145 (>= 90% of 150 = 135) -> completed
      expect(log.actualProtein, 145.0);
      expect(log.proteinStatus, AccountabilityStatus.completed);

      // Total water: 2600 (>= 80% of 2500) -> completed
      expect(log.actualWaterMl, 2600.0);
      expect(log.waterStatus, AccountabilityStatus.completed);

      // Score: 3 completed x 20 = 60.0 pts
      expect(log.dailyAdherenceScore, 60.0);
    });

    // 12. Existing Home food logging integration (consumedCalories fallback)
    test('12. Uses consumedCalories from ConsumptionProvider when meal list is empty for today', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_p8';
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      provider.activeDocFetcherForTesting = (_) => {
        'planId': 'weight_loss_60',
        'startDate': todayStr,
        'currentDay': 1,
        'totalDays': 60,
        'targetCalories': 2000.0,
        'targetMacros': {'protein': 140.0},
        'status': 'active',
      };
      await provider.loadTransformation();

      final mockConsumption = MockConsumptionProvider();
      mockConsumption.consumedCalories = 1980; // from Home dashboard quick-tracker

      final log = provider.getDailyLogForDate(date: DateTime.now(), consumptionProvider: mockConsumption);
      expect(log.actualCalories, 1980.0);
      expect(log.calorieStatus, AccountabilityStatus.completed);
    });

    // 13. Existing water logging integration (waterADay)
    test('13. Reads waterADay from ConsumptionProvider directly for today', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_p8';
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      provider.activeDocFetcherForTesting = (_) => {
        'planId': 'muscle_building_90',
        'startDate': todayStr,
        'currentDay': 1,
        'totalDays': 90,
        'dailyWaterTargetMl': 3000.0,
        'status': 'active',
      };
      await provider.loadTransformation();

      final mockConsumption = MockConsumptionProvider();
      mockConsumption.waterADay = 3200.0;

      final log = provider.getDailyLogForDate(date: DateTime.now(), consumptionProvider: mockConsumption);
      expect(log.actualWaterMl, 3200.0);
      expect(log.waterStatus, AccountabilityStatus.completed);
    });

    // 14. Date-based record uniqueness (stable date string key)
    test('14. Saving daily logs uses dateString key to ensure idempotency and update stability', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_p8';
      Map<String, dynamic>? savedStateData;
      provider.activeDocSaverForTesting = (uid, data) async {
        savedStateData = data;
      };

      final todayStr = '2026-11-02';
      provider.activeDocFetcherForTesting = (_) => {
        'planId': 'weight_loss_60',
        'startDate': todayStr,
        'currentDay': 1,
        'totalDays': 60,
        'status': 'active',
      };
      await provider.loadTransformation();

      final log1 = TransformationDailyLog(
        planId: 'weight_loss_60',
        dayNumber: 1,
        dateString: todayStr,
        workoutStatus: AccountabilityStatus.pending,
        calorieStatus: AccountabilityStatus.pending,
        proteinStatus: AccountabilityStatus.pending,
        waterStatus: AccountabilityStatus.pending,
        recoveryStatus: AccountabilityStatus.pending,
        dailyAdherenceScore: 0.0,
        lastUpdated: DateTime.now(),
      );
      await provider.saveDailyLog(log1);

      expect(savedStateData?['dailyLogs']?[todayStr], isNotNull);
      expect(provider.activeTransformation?.dailyLogs.length, 1);

      // Save updated version on same date
      final log2 = log1.copyWith(dailyAdherenceScore: 80.0, recoveryLevel: 'good');
      await provider.saveDailyLog(log2);

      // Check that it overwrote rather than added duplicate
      expect(provider.activeTransformation?.dailyLogs.length, 1);
      expect(provider.activeTransformation?.dailyLogs[todayStr]?.dailyAdherenceScore, 80.0);
      expect(provider.activeTransformation?.dailyLogs[todayStr]?.recoveryLevel, 'good');
    });

    // 15. Persistence and restoration (dailyLogs in UserTransformationState)
    test('15. UserTransformationState serializes and deserializes dailyLogs map cleanly', () {
      final log1 = TransformationDailyLog(
        planId: 'weight_loss_60',
        dayNumber: 1,
        dateString: '2026-11-01',
        workoutStatus: AccountabilityStatus.completed,
        calorieStatus: AccountabilityStatus.completed,
        proteinStatus: AccountabilityStatus.completed,
        waterStatus: AccountabilityStatus.completed,
        recoveryStatus: AccountabilityStatus.completed,
        dailyAdherenceScore: 100.0,
        lastUpdated: DateTime(2026, 11, 1),
      );

      final state = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Weight Loss Challenge',
        startDate: DateTime(2026, 11, 1),
        targetEndDate: DateTime(2026, 12, 31),
        currentDay: 2,
        totalDays: 60,
        targetCalories: 2000.0,
        targetMacros: const {'protein': 140.0},
        dailyWaterTargetMl: 2800.0,
        dailyLogs: {'2026-11-01': log1},
      );

      final map = state.toMap();
      expect(map['dailyWaterTargetMl'], 2800.0);
      expect(map['dailyLogs'], isA<Map<String, dynamic>>());
      expect((map['dailyLogs'] as Map)['2026-11-01'], isNotNull);

      final restored = UserTransformationState.fromMap(map);
      expect(restored.dailyWaterTargetMl, 2800.0);
      expect(restored.dailyLogs.length, 1);
      expect(restored.dailyLogs['2026-11-01']?.dailyAdherenceScore, 100.0);
    });

    // 16. Historical daily records preserved across days
    test('16. Historical logs across multiple days are preserved independently', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_p8';
      provider.activeDocSaverForTesting = (uid, data) async {};

      provider.activeDocFetcherForTesting = (_) => {
        'planId': 'weight_loss_60',
        'startDate': '2026-11-01',
        'currentDay': 3,
        'totalDays': 60,
        'status': 'active',
      };
      await provider.loadTransformation();

      // Log Day 1
      await provider.saveDailyLog(TransformationDailyLog(
        planId: 'weight_loss_60',
        dayNumber: 1,
        dateString: '2026-11-01',
        workoutStatus: AccountabilityStatus.completed,
        calorieStatus: AccountabilityStatus.completed,
        proteinStatus: AccountabilityStatus.completed,
        waterStatus: AccountabilityStatus.completed,
        recoveryStatus: AccountabilityStatus.completed,
        dailyAdherenceScore: 100.0,
        lastUpdated: DateTime(2026, 11, 1),
      ));

      // Log Day 2
      await provider.saveDailyLog(TransformationDailyLog(
        planId: 'weight_loss_60',
        dayNumber: 2,
        dateString: '2026-11-02',
        workoutStatus: AccountabilityStatus.completed,
        calorieStatus: AccountabilityStatus.partiallyCompleted,
        proteinStatus: AccountabilityStatus.completed,
        waterStatus: AccountabilityStatus.completed,
        recoveryStatus: AccountabilityStatus.completed,
        dailyAdherenceScore: 90.0,
        lastUpdated: DateTime(2026, 11, 2),
      ));

      expect(provider.activeTransformation?.dailyLogs.length, 2);
      expect(provider.activeTransformation?.dailyLogs['2026-11-01']?.dailyAdherenceScore, 100.0);
      expect(provider.activeTransformation?.dailyLogs['2026-11-02']?.dailyAdherenceScore, 90.0);
    });

    // 17. Weekly adherence summary calculation from actual logs
    test('17. Weekly adherence summary computes accurate average adherence and habit counters', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_p8';
      provider.activeDocSaverForTesting = (uid, data) async {};

      final refDate = DateTime(2026, 11, 7);
      final logsMap = <String, TransformationDailyLog>{};

      // 4 assessable days with recorded logs
      for (int i = 0; i < 4; i++) {
        final d = refDate.subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(d);
        logsMap[dateStr] = TransformationDailyLog(
          planId: 'weight_loss_60',
          dayNumber: 10 - i,
          dateString: dateStr,
          workoutStatus: AccountabilityStatus.completed,
          calorieStatus: AccountabilityStatus.completed,
          proteinStatus: AccountabilityStatus.completed,
          waterStatus: AccountabilityStatus.completed,
          recoveryStatus: AccountabilityStatus.completed,
          dailyAdherenceScore: 100.0,
          lastUpdated: d,
          actualCalories: 2000.0,
          actualWaterMl: 2500.0,
          actualProtein: 150.0,
        );
      }

      provider.activeDocFetcherForTesting = (_) => {
        'planId': 'weight_loss_60',
        'startDate': '2026-10-25',
        'currentDay': 14,
        'totalDays': 60,
        'dailyLogs': logsMap.map((k, v) => MapEntry(k, v.toMap())),
        'status': 'active',
      };
      await provider.loadTransformation();

      final summary = provider.getWeeklyAdherenceSummary(
        referenceDate: refDate,
        daysCount: 7,
      );

      expect(summary.daysTracked, 4);
      expect(summary.hasEnoughData, isTrue);
      expect(summary.averageAdherenceScore, 100.0);
      expect(summary.workoutsCompletedCount, 4);
      expect(summary.calorieConsistencyCount, 4);
      expect(summary.proteinConsistencyCount, 4);
      expect(summary.waterGoalConsistencyCount, 4);
    });

    // 18. Backward compatibility with existing Firestore transformation records
    test('18. Deserialization of legacy records without Phase 8 fields gracefully sets defaults', () {
      final legacyMap = {
        'planId': 'beginner_fitness_30',
        'planTitle': '30-Day Complete Beginner Transformation',
        'startDate': '2026-10-01T00:00:00.000',
        'targetEndDate': '2026-10-31T00:00:00.000',
        'currentDay': 10,
        'totalDays': 30,
        'completedDayIndices': [1, 2, 3],
        'status': 'active',
        // Note: dailyWaterTargetMl and dailyLogs omitted deliberately
      };

      final state = UserTransformationState.fromMap(legacyMap);
      expect(state.dailyWaterTargetMl, 2500.0); // default
      expect(state.dailyLogs, isEmpty);
      expect(state.planId, 'beginner_fitness_30');
    });

    // 19. Dashboard checklist UI renders properly (compact: true)
    testWidgets('19. TransformationDailyChecklist renders compactly without overflow', (tester) async {
      _configureTestViewport(tester);

      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_p8';
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      provider.activeDocFetcherForTesting = (_) => {
        'planId': 'weight_loss_60',
        'planTitle': '60-Day Weight Loss Challenge',
        'startDate': todayStr,
        'targetEndDate': DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 60))),
        'currentDay': 1,
        'totalDays': 60,
        'targetCalories': 2000.0,
        'targetMacros': {'protein': 150.0},
        'dailyWaterTargetMl': 2500.0,
        'status': 'active',
      };
      await provider.loadTransformation();

      await tester.pumpWidget(
        _wrapWithTestProviders(
          transformationProvider: provider,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: TransformationDailyChecklist(compact: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Today's Accountability"), findsOneWidget);
      expect(find.text('Workout'), findsOneWidget);
      expect(find.text('Calories'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 20. Regression test for existing transformation roadmap & progress screens
    testWidgets('20. TransformationRoadmapScreen and TransformationProgressScreen display accountability components without error', (tester) async {
      _configureTestViewport(tester);

      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_p8';
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      provider.activeDocFetcherForTesting = (_) => {
        'planId': 'weight_loss_60',
        'planTitle': '60-Day Weight Loss Challenge',
        'startDate': todayStr,
        'targetEndDate': DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 60))),
        'currentDay': 1,
        'totalDays': 60,
        'targetCalories': 2000.0,
        'targetMacros': {'protein': 150.0, 'carbs': 180.0, 'fat': 60.0},
        'dailyWaterTargetMl': 2500.0,
        'completedDayIndices': [1],
        'status': 'active',
      };
      await provider.loadTransformation();

      // Test Roadmap Screen
      await tester.pumpWidget(
        _wrapWithTestProviders(
          transformationProvider: provider,
          child: const TransformationRoadmapScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Daily Accountability Checklist'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Daily Accountability Checklist'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Test Progress Screen
      await tester.pumpWidget(
        _wrapWithTestProviders(
          transformationProvider: provider,
          child: const TransformationProgressScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Weekly Habit Consistency'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
