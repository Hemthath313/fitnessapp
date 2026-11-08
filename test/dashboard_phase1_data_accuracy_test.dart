import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/fitness_data_widget.dart';
import 'package:fitness_app/presentation/home/widgets/quick_actions_widget.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/utils/tdee_calculator.dart';

class _MockTransformationProvider extends ChangeNotifier
    implements TransformationProvider {
  UserTransformationState? _activeTransformation;

  _MockTransformationProvider({UserTransformationState? activeState}) {
    _activeTransformation = activeState;
  }

  void setActiveTransformation(UserTransformationState? state) {
    _activeTransformation = state;
    notifyListeners();
  }

  @override
  UserTransformationState? get activeTransformation => _activeTransformation;

  @override
  bool get hasActiveTransformation =>
      _activeTransformation != null && _activeTransformation!.status == 'active';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHomeProvider extends ChangeNotifier implements HomeProvider {
  Map<String, dynamic> _userData = {};

  @override
  Map<String, dynamic> get userData => _userData;

  void setUserData(Map<String, dynamic> data) {
    _userData = data;
    notifyListeners();
  }

  @override
  Future<Map<String, dynamic>> fetchUserData() async => _userData;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestConsumptionProvider extends ChangeNotifier implements ConsumptionProvider {
  int _consumedCalories = 0;
  double _waterADay = 0.0;
  double _waterGoalLiters = 2.5;

  @override
  int get consumedCalories => _consumedCalories;

  void setConsumedCalories(int calories) {
    _consumedCalories = calories;
    notifyListeners();
  }

  @override
  double get waterADay => _waterADay;

  void setWaterADay(double water) {
    _waterADay = water;
    notifyListeners();
  }

  @override
  double get waterGoalLiters => _waterGoalLiters;

  @override
  void setWaterGoal(double liters) {
    if (liters > 0) {
      _waterGoalLiters = liters;
      notifyListeners();
    }
  }

  @override
  Future<void> getConsumedCalories() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockStatisticsProvider extends ChangeNotifier implements StatisticsProvider {
  @override
  int get currentStreak => 5;

  @override
  List<String> get scheduledDayNames => ['Monday', 'Wednesday', 'Friday'];

  @override
  bool get hasActiveSchedule => true;

  @override
  bool get hasWorkoutToday => false;

  @override
  bool isPendingScheduledDay([DateTime? date]) => false;

  @override
  bool isRestDay([DateTime? date]) => false;

  @override
  int get totalWorkouts => 3;

  @override
  List<String> get unlockedAchievements => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UserTransformationState _createMockTransformationState({
  required double targetCalories,
  double dailyWaterTargetMl = 2500.0,
}) {
  return UserTransformationState(
    planId: 'beginner_fitness_30',
    planTitle: '30-Day Beginner Fitness',
    startDate: DateTime.now().subtract(const Duration(days: 2)),
    targetEndDate: DateTime.now().add(const Duration(days: 28)),
    currentDay: 3,
    totalDays: 30,
    status: 'active',
    completedDayIndices: [1, 2],
    targetCalories: targetCalories,
    dailyWaterTargetMl: dailyWaterTargetMl,
    targetMacros: {'protein': 120, 'carbs': 200, 'fat': 60},
    milestones: [],
  );
}

Widget _buildTestHarness({
  required Widget child,
  TransformationProvider? transformationProvider,
  HomeProvider? homeProvider,
  ConsumptionProvider? consumptionProvider,
  List<RouteBase>? additionalRoutes,
}) {
  final tp = transformationProvider ?? _MockTransformationProvider();
  final hp = homeProvider ?? _MockHomeProvider();
  if (homeProvider == null && hp is _MockHomeProvider) {
    hp.setUserData({
      'bmr': 1800.0,
      'weight': 70.0,
      'height': 170.0,
      'age': 25,
      'gender': 'Male',
      'activity': 'MODERATE',
      'goal': 'MAINTAIN',
    });
  }
  final cp = consumptionProvider ?? _TestConsumptionProvider();
  final sp = _MockStatisticsProvider();
  final wp = WorkoutProvider();

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(body: child),
      ),
      GoRoute(
        path: Routes.dietRoute,
        builder: (context, state) => const Scaffold(body: Text('Legacy Diet Screen')),
      ),
      GoRoute(
        path: Routes.transformationNutritionRoute,
        builder: (context, state) => const Scaffold(body: Text('Transformation Nutrition Screen')),
      ),
      GoRoute(
        path: Routes.addWaterRoute,
        builder: (context, state) => const Scaffold(body: Text('Add Water Screen')),
      ),
      GoRoute(
        path: Routes.changeWeightRoute,
        builder: (context, state) => const Scaffold(body: Text('Profile Setup Screen')),
      ),
      GoRoute(
        path: Routes.workoutLogRoute,
        builder: (context, state) => const Scaffold(body: Text('Log Lift Screen')),
      ),
      GoRoute(
        path: Routes.workoutGeneratorRoute,
        builder: (context, state) => const Scaffold(body: Text('AI Generator Screen')),
      ),
      ...?additionalRoutes,
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TransformationProvider>.value(value: tp),
      ChangeNotifierProvider<HomeProvider>.value(value: hp),
      ChangeNotifierProvider<ConsumptionProvider>.value(value: cp),
      ChangeNotifierProvider<StatisticsProvider>.value(value: sp),
      ChangeNotifierProvider<WorkoutProvider>.value(value: wp),
    ],
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp.router(
        routerConfig: router,
      ),
    ),
  );
}

void _configureTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1 — Data Accuracy: Calorie Goal Priority System', () {
    testWidgets('Priority 1: Active transformation target calories is used over user data',
        (tester) async {
      _configureTestViewport(tester);
      final tp = _MockTransformationProvider();
      tp.setActiveTransformation(
        _createMockTransformationState(targetCalories: 2450.0),
      );

      final hp = _MockHomeProvider();
      hp.setUserData({
        'bmr': 1600.0,
        'targetCalories': 2100.0,
        'weight': 75.0,
        'height': 175.0,
        'age': 25,
        'gender': 'Male',
      });

      final cp = _TestConsumptionProvider();
      cp.setConsumedCalories(1450);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const FitnessDataWidget(),
          transformationProvider: tp,
          homeProvider: hp,
          consumptionProvider: cp,
        ),
      );
      await tester.pump();

      // Goal should display 2450 kcal (from transformation)
      expect(find.text('2450 kcal'), findsOneWidget);
      expect(find.text('/ 2450 kcal'), findsOneWidget);

      // Consumed: 1450 kcal
      expect(find.text('1450 kcal'), findsOneWidget);

      // Remaining: 2450 - 1450 = 1000 kcal
      expect(find.text('1000 kcal'), findsOneWidget);

      // Verify circular indicator percent = 1450 / 2450
      final indicator = tester.widget<CircularPercentIndicator>(
        find.byType(CircularPercentIndicator),
      );
      expect(indicator.percent, closeTo(1450.0 / 2450.0, 0.001));
    });

    testWidgets('Priority 2: User configured targetCalories is used when no active transformation',
        (tester) async {
      _configureTestViewport(tester);
      final tp = _MockTransformationProvider();
      // No active transformation

      final hp = _MockHomeProvider();
      hp.setUserData({
        'bmr': 1550.0,
        'targetCalories': 2150.0,
        'weight': 70.0,
        'height': 170.0,
        'age': 28,
        'gender': 'Female',
      });

      final cp = _TestConsumptionProvider();
      cp.setConsumedCalories(850);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const FitnessDataWidget(),
          transformationProvider: tp,
          homeProvider: hp,
          consumptionProvider: cp,
        ),
      );
      await tester.pump();

      // Goal should display 2150 kcal
      expect(find.text('2150 kcal'), findsOneWidget);
      expect(find.text('/ 2150 kcal'), findsOneWidget);

      // Consumed: 850 kcal
      expect(find.text('850 kcal'), findsOneWidget);

      // Remaining: 2150 - 850 = 1300 kcal
      expect(find.text('1300 kcal'), findsOneWidget);

      final indicator = tester.widget<CircularPercentIndicator>(
        find.byType(CircularPercentIndicator),
      );
      expect(indicator.percent, closeTo(850.0 / 2150.0, 0.001));
    });

    testWidgets('Priority 3: TDEE calculation is used when no target is set; raw BMR is NOT used',
        (tester) async {
      _configureTestViewport(tester);
      final tp = _MockTransformationProvider();
      final hp = _MockHomeProvider();
      // Male, 80kg, 180cm, 30yo, Moderate activity, Maintain goal
      // BMR = 10*80 + 6.25*180 - 5*30 + 5 = 800 + 1125 - 150 + 5 = 1780
      // TDEE = 1780 * 1.55 = 2759.0
      // Target = 2759 kcal
      hp.setUserData({
        'bmr': 1780.0, // raw BMR must NOT be displayed as the daily target
        'weight': 80.0,
        'height': 180.0,
        'age': 30,
        'gender': 'Male',
        'activity': 'MODERATE',
        'goal': 'MAINTAIN',
      });

      final cp = _TestConsumptionProvider();
      cp.setConsumedCalories(1500);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const FitnessDataWidget(),
          transformationProvider: tp,
          homeProvider: hp,
          consumptionProvider: cp,
        ),
      );
      await tester.pump();

      final expectedTdee = TDEECalculator.calculateTDEE(
        gender: 'Male',
        weightKg: 80.0,
        heightCm: 180.0,
        age: 30,
        activityLevel: 'MODERATE',
      );
      final expectedTarget = TDEECalculator.calculateTargetCalories(
        tdee: expectedTdee,
        goal: 'MAINTAIN',
        gender: 'Male',
      );
      final expectedTargetStr = '${expectedTarget.toStringAsFixed(0)} kcal';

      // Expect calculated TDEE target, NOT raw BMR (1780 kcal)
      expect(find.text(expectedTargetStr), findsOneWidget);
      expect(find.text('1780 kcal'), findsNothing);

      final remaining = (expectedTarget - 1500).toStringAsFixed(0);
      expect(find.text('$remaining kcal'), findsOneWidget);
    });

    testWidgets('Priority 4: Missing target shows honest setup state and avoids fake remaining kcal',
        (tester) async {
      _configureTestViewport(tester);
      final tp = _MockTransformationProvider();
      final hp = _MockHomeProvider();
      hp.setUserData({
        // Incomplete profile: no height, no age, no targetCalories
        'bmr': 0.0,
        'weight': 0.0,
        'height': 0.0,
        'age': 0,
      });

      final cp = _TestConsumptionProvider();
      cp.setConsumedCalories(500);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const FitnessDataWidget(),
          transformationProvider: tp,
          homeProvider: hp,
          consumptionProvider: cp,
        ),
      );
      await tester.pump();

      // Goal should show 'Not Set' instead of fake BMR
      expect(find.text('Not Set'), findsOneWidget);
      // Center circle should show '/ -- kcal'
      expect(find.text('/ -- kcal'), findsOneWidget);
      // Remaining should show '--'
      expect(find.text('--'), findsOneWidget);
      // Gauge percent should be 0.0
      final indicator = tester.widget<CircularPercentIndicator>(
        find.byType(CircularPercentIndicator),
      );
      expect(indicator.percent, 0.0);

      // Honest setup state banner / prompt should be visible
      expect(find.text('Set daily calorie target in Profile'), findsOneWidget);

      // Tapping prompt navigates to profile setup
      await tester.tap(find.text('Set daily calorie target in Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile Setup Screen'), findsOneWidget);
    });

    testWidgets('Progress calculations clamp correctly when consumed exceeds target',
        (tester) async {
      _configureTestViewport(tester);
      final tp = _MockTransformationProvider();
      tp.setActiveTransformation(
        _createMockTransformationState(targetCalories: 2000.0),
      );

      final cp = _TestConsumptionProvider();
      // Consumed 2500 kcal when target is 2000 kcal
      cp.setConsumedCalories(2500);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const FitnessDataWidget(),
          transformationProvider: tp,
          consumptionProvider: cp,
        ),
      );
      await tester.pump();

      // Consumed: 2500 kcal
      expect(find.text('2500 kcal'), findsOneWidget);
      // Goal: 2000 kcal
      expect(find.text('2000 kcal'), findsOneWidget);
      // Remaining: clamped to 0 kcal
      expect(find.text('0 kcal'), findsOneWidget);

      // Percent: clamped to 1.0 (not 1.25)
      final indicator = tester.widget<CircularPercentIndicator>(
        find.byType(CircularPercentIndicator),
      );
      expect(indicator.percent, 1.0);
    });
  });

  group('Phase 1 — Data Accuracy: Dynamic Water Goal', () {
    testWidgets('Uses active transformation dailyWaterTargetMl dynamically', (tester) async {
      _configureTestViewport(tester);
      final tp = _MockTransformationProvider();
      // 3200 ml = 3.2 L
      tp.setActiveTransformation(
        _createMockTransformationState(
          targetCalories: 2200.0,
          dailyWaterTargetMl: 3200.0,
        ),
      );

      final cp = _TestConsumptionProvider();
      cp.setWaterADay(1.6);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const FitnessDataWidget(),
          transformationProvider: tp,
          consumptionProvider: cp,
        ),
      );
      await tester.pump();

      // Displays consumed: 1.6 L
      expect(find.text('1.6'), findsOneWidget);
      // Displays dynamic goal: / 3.2 L
      expect(find.text('/ 3.2 L'), findsOneWidget);

      // LinearProgressIndicator value is 1.6 / 3.2 = 0.5
      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, closeTo(0.5, 0.01));
    });

    testWidgets('Uses ConsumptionProvider configured custom water goal', (tester) async {
      _configureTestViewport(tester);
      final tp = _MockTransformationProvider();
      final cp = _TestConsumptionProvider();
      cp.setWaterGoal(3.0);
      cp.setWaterADay(1.5);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const FitnessDataWidget(),
          transformationProvider: tp,
          consumptionProvider: cp,
        ),
      );
      await tester.pump();

      expect(find.text('1.5'), findsOneWidget);
      expect(find.text('/ 3.0 L'), findsOneWidget);

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, closeTo(0.5, 0.01));
    });

    testWidgets('Preserves default 2.5L water goal when no custom goal is configured',
        (tester) async {
      _configureTestViewport(tester);
      final tp = _MockTransformationProvider();
      final cp = _TestConsumptionProvider();
      cp.setWaterADay(1.2);

      await tester.pumpWidget(
        _buildTestHarness(
          child: const FitnessDataWidget(),
          transformationProvider: tp,
          consumptionProvider: cp,
        ),
      );
      await tester.pump();

      expect(find.text('1.2'), findsOneWidget);
      expect(find.text('/ 2.5 L'), findsOneWidget);

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, closeTo(1.2 / 2.5, 0.01));
    });
  });

  group('Phase 1 — Data Accuracy: Context-Aware Diet Plans Navigation', () {
    testWidgets('Routes active transformation user to Routes.transformationNutritionRoute',
        (tester) async {
      _configureTestViewport(tester);
      final tp = _MockTransformationProvider();
      tp.setActiveTransformation(
        _createMockTransformationState(targetCalories: 2000.0),
      );

      await tester.pumpWidget(
        _buildTestHarness(
          child: const QuickActionsWidget(),
          transformationProvider: tp,
        ),
      );
      await tester.pump();

      // Find Diet Plans action and tap it
      expect(find.text('Diet Plans'), findsOneWidget);
      await tester.tap(find.text('Diet Plans'));
      await tester.pumpAndSettle();

      // Active transformation user navigates to Transformation Nutrition Screen
      expect(find.text('Transformation Nutrition Screen'), findsOneWidget);
      expect(find.text('Legacy Diet Screen'), findsNothing);
    });

    testWidgets('Routes user without transformation to legacy Routes.dietRoute', (tester) async {
      _configureTestViewport(tester);
      final tp = _MockTransformationProvider();
      // No active transformation

      await tester.pumpWidget(
        _buildTestHarness(
          child: const QuickActionsWidget(),
          transformationProvider: tp,
        ),
      );
      await tester.pump();

      expect(find.text('Diet Plans'), findsOneWidget);
      await tester.tap(find.text('Diet Plans'));
      await tester.pumpAndSettle();

      // Standard user navigates to Legacy Diet Screen
      expect(find.text('Legacy Diet Screen'), findsOneWidget);
      expect(find.text('Transformation Nutrition Screen'), findsNothing);
    });
  });
}
