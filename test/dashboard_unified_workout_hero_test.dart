import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/workout_model.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/home_ai_routine_card.dart';
import 'package:fitness_app/presentation/home/widgets/quick_actions_widget.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/utils/router/router.dart';

class _MockHomeProvider extends ChangeNotifier implements HomeProvider {
  Map<String, dynamic> _userData = {
    'name': 'Athlete',
    'experience': 'Intermediate',
    'fitness_goal': 'Build Muscle',
    'goal': 'Build Muscle',
  };

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

class _MockSubscriptionProvider extends ChangeNotifier implements SubscriptionProvider {
  bool _isPremium = true;

  @override
  bool get isPremium => _isPremium;

  void setPremium(bool val) {
    _isPremium = val;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockConsumptionProvider extends ChangeNotifier implements ConsumptionProvider {
  @override
  double get waterADay => 1500.0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void _configureTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

List<WorkoutModel> _buildThreeDaySplitWorkouts(DateTime date) {
  return [
    WorkoutModel(
      id: 'w_mon_1',
      name: '[Monday] Barbell Bench Press',
      repNumber: 10,
      setNumber: 3,
      dateTime: date,
    ),
    WorkoutModel(
      id: 'w_wed_1',
      name: '[Wednesday] Barbell Squat',
      repNumber: 10,
      setNumber: 3,
      dateTime: date,
    ),
    WorkoutModel(
      id: 'w_fri_1',
      name: '[Friday] Barbell Deadlift',
      repNumber: 8,
      setNumber: 3,
      dateTime: date,
    ),
  ];
}

Widget _buildTestHarness({
  required Widget child,
  TransformationProvider? transformationProvider,
  WorkoutProvider? workoutProvider,
  StatisticsProvider? statisticsProvider,
  HomeProvider? homeProvider,
  SubscriptionProvider? subscriptionProvider,
  ConsumptionProvider? consumptionProvider,
  GoRouter? customRouter,
}) {
  final tp = transformationProvider ?? TransformationProvider(autoLoad: false);
  final wp = workoutProvider ?? WorkoutProvider();
  final sp = statisticsProvider ?? StatisticsProvider();
  final hp = homeProvider ?? _MockHomeProvider();
  final subp = subscriptionProvider ?? _MockSubscriptionProvider();
  final cp = consumptionProvider ?? _MockConsumptionProvider();

  final router = customRouter ??
      GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => Scaffold(body: SingleChildScrollView(child: child))),
          GoRoute(path: Routes.dayWorkoutSessionRoute, builder: (_, __) => const Scaffold(body: Text('Day Workout Session Screen'))),
          GoRoute(path: Routes.transformationRoadmapRoute, builder: (_, __) => const Scaffold(body: Text('Transformation Roadmap Screen'))),
          GoRoute(path: Routes.transformationCompletionRoute, builder: (_, __) => const Scaffold(body: Text('Transformation Completion Screen'))),
          GoRoute(path: Routes.workoutLogRoute, builder: (_, __) => const Scaffold(body: Text('Workout Log Screen'))),
          GoRoute(path: Routes.workoutGeneratorRoute, builder: (_, __) => const Scaffold(body: Text('Workout Generator Screen'))),
        ],
      );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TransformationProvider?>.value(value: tp),
      ChangeNotifierProvider<WorkoutProvider>.value(value: wp),
      ChangeNotifierProvider<StatisticsProvider>.value(value: sp),
      ChangeNotifierProvider<HomeProvider?>.value(value: hp),
      ChangeNotifierProvider<SubscriptionProvider>.value(value: subp),
      ChangeNotifierProvider<ConsumptionProvider>.value(value: cp),
    ],
    child: ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp.router(
        routerConfig: router,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Gym Buddy Dashboard Phase 2 — Unified Workout Hero & Transformation-Aware Dashboard', () {
    // -------------------------------------------------------------------------
    // Scenario 1: New user without a workout plan (Priority 3)
    // -------------------------------------------------------------------------
    testWidgets('Scenario 1: New user without any workout plan renders AI onboarding hero (Priority 3)', (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'new_user_1';
      final workoutProvider = WorkoutProvider()
        ..setAllWorkoutsForTesting([]); // No AI routine workouts

      await tester.pumpWidget(_buildTestHarness(
        child: const HomeAiRoutineCard(),
        transformationProvider: transformationProvider,
        workoutProvider: workoutProvider,
      ));
      await tester.pumpAndSettle();

      // Priority 3: Shows AI plan builder/activation card
      expect(find.textContaining('Plan'), findsWidgets);
      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
      // Must NOT display transformation hero
      expect(find.textContaining('DAY 1 OF'), findsNothing);
      expect(find.text('START DAY 1 WORKOUT'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Scenario 2: User with an active AI workout routine (Priority 2)
    // -------------------------------------------------------------------------
    testWidgets('Scenario 2: User with active AI routine renders AI Workout Schedule hub (Priority 2)', (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'ai_routine_user';
      final monday = DateTime(2026, 3, 16, 10, 0); // Monday
      final workoutProvider = WorkoutProvider()
        ..setNowProviderForTesting(() => monday)
        ..setAllWorkoutsForTesting(_buildThreeDaySplitWorkouts(monday));

      await tester.pumpWidget(_buildTestHarness(
        child: const HomeAiRoutineCard(),
        transformationProvider: transformationProvider,
        workoutProvider: workoutProvider,
      ));
      await tester.pumpAndSettle();

      // Priority 2: AI Workout Schedule is prominently rendered
      expect(find.text('Workout Schedule'), findsOneWidget);
      expect(find.textContaining('3-Day Split'), findsOneWidget);
      expect(find.text('Monday Routine'), findsOneWidget);
      // Must NOT display empty onboarding or transformation hero
      expect(find.text('Build Your Workout Plan'), findsNothing);
      expect(find.textContaining('DAY 1 OF'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Scenario 3: Beginner transformation user (Priority 1)
    // -------------------------------------------------------------------------
    testWidgets('Scenario 3: Beginner transformation user displays Beginner 30-Day hero (Priority 1)', (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'beginner_user';
      transformationProvider.activeDocSaverForTesting = (_, __) async {};

      await transformationProvider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 140.0, 'carbs': 200.0, 'fat': 50.0},
      );

      final workoutProvider = WorkoutProvider()
        ..setAllWorkoutsForTesting(_buildThreeDaySplitWorkouts(DateTime.now()));

      await tester.pumpWidget(_buildTestHarness(
        child: const HomeAiRoutineCard(),
        transformationProvider: transformationProvider,
        workoutProvider: workoutProvider,
      ));
      await tester.pumpAndSettle();

      // Priority 1 Verification
      expect(find.text(TransformationPlansData.beginnerFitness30.title), findsOneWidget);
      expect(find.text('DAY 1 OF 30'), findsOneWidget);
      expect(find.textContaining('Week 1'), findsOneWidget);
      expect(find.text('START DAY 1 WORKOUT'), findsOneWidget);
      // AI Schedule must NOT be shown
      expect(find.text('Workout Schedule'), findsNothing);
      expect(find.text('Build Your Workout Plan'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Scenario 4: Weight Loss transformation user (Priority 1)
    // -------------------------------------------------------------------------
    testWidgets('Scenario 4: Weight Loss transformation user displays 60-Day Weight Loss hero', (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'weight_loss_user';
      transformationProvider.activeDocSaverForTesting = (_, __) async {};

      await transformationProvider.enrollInPlan(
        blueprint: TransformationPlansData.weightLoss60,
        targetCalories: 1800,
        targetMacros: const {'protein': 130.0, 'carbs': 180.0, 'fat': 45.0},
      );

      await tester.pumpWidget(_buildTestHarness(
        child: const HomeAiRoutineCard(),
        transformationProvider: transformationProvider,
      ));
      await tester.pumpAndSettle();

      expect(find.text(TransformationPlansData.weightLoss60.title), findsOneWidget);
      expect(find.text('DAY 1 OF 60'), findsOneWidget);
      expect(find.text('START DAY 1 WORKOUT'), findsOneWidget);
      expect(find.textContaining('0% Complete'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 5: Muscle Building transformation user (Priority 1)
    // -------------------------------------------------------------------------
    testWidgets('Scenario 5: Muscle Building transformation user displays 90-Day Muscle Building hero', (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'muscle_gain_user';
      transformationProvider.activeDocSaverForTesting = (_, __) async {};

      await transformationProvider.enrollInPlan(
        blueprint: TransformationPlansData.muscleBuilding90,
        targetCalories: 2600,
        targetMacros: const {'protein': 180.0, 'carbs': 280.0, 'fat': 70.0},
      );

      await tester.pumpWidget(_buildTestHarness(
        child: const HomeAiRoutineCard(),
        transformationProvider: transformationProvider,
      ));
      await tester.pumpAndSettle();

      expect(find.text(TransformationPlansData.muscleBuilding90.title), findsOneWidget);
      expect(find.text('DAY 1 OF 90'), findsOneWidget);
      expect(find.text('START DAY 1 WORKOUT'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 6: Strength Building transformation user (Priority 1)
    // -------------------------------------------------------------------------
    testWidgets('Scenario 6: Strength Building transformation user displays 12-Week Strength hero', (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'strength_user';
      transformationProvider.activeDocSaverForTesting = (_, __) async {};

      await transformationProvider.enrollInPlan(
        blueprint: TransformationPlansData.strength12Week,
        targetCalories: 2700,
        targetMacros: const {'protein': 190.0, 'carbs': 290.0, 'fat': 65.0},
      );

      await tester.pumpWidget(_buildTestHarness(
        child: const HomeAiRoutineCard(),
        transformationProvider: transformationProvider,
      ));
      await tester.pumpAndSettle();

      expect(find.text(TransformationPlansData.strength12Week.title), findsOneWidget);
      expect(find.text('DAY 1 OF 84'), findsOneWidget);
      expect(find.text('START DAY 1 WORKOUT'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 7: Transformation rest day (no misleading Start Workout button)
    // -------------------------------------------------------------------------
    testWidgets('Scenario 7: Transformation rest day displays rest recovery guidance and no Start Workout button', (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'rest_day_user';
      transformationProvider.activeDocSaverForTesting = (_, __) async {};

      await transformationProvider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 140.0, 'carbs': 200.0, 'fat': 50.0},
      );

      // Advance currentDay to Day 7 (which is a scheduled rest day in beginnerFitness30)
      await transformationProvider.setCurrentDay(7);

      await tester.pumpWidget(_buildTestHarness(
        child: const HomeAiRoutineCard(),
        transformationProvider: transformationProvider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('DAY 7 • REST DAY'), findsOneWidget);
      expect(find.text('Rest & Muscle Repair'), findsOneWidget);
      // NO misleading Start Workout button on rest days!
      expect(find.text('START DAY 7 WORKOUT'), findsNothing);
      expect(find.text('VIEW PROGRAMME ROADMAP'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 8: Transformation active recovery day
    // -------------------------------------------------------------------------
    testWidgets('Scenario 8: Transformation active recovery day displays mobility and active recovery guidance', (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'active_recovery_user';
      transformationProvider.activeDocSaverForTesting = (_, __) async {};

      // In beginnerFitness30, Day 2 is an active recovery day
      await transformationProvider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 140.0, 'carbs': 200.0, 'fat': 50.0},
      );
      await transformationProvider.setCurrentDay(2);

      await tester.pumpWidget(_buildTestHarness(
        child: const HomeAiRoutineCard(),
        transformationProvider: transformationProvider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('DAY 2 • ACTIVE RECOVERY'), findsOneWidget);
      expect(find.text('Active Recovery & Mobility'), findsOneWidget);
      expect(find.text('START ACTIVE RECOVERY'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 9: Completed transformation user
    // -------------------------------------------------------------------------
    testWidgets('Scenario 9: Completed transformation user displays graduation card', (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'completed_user';
      transformationProvider.activeDocSaverForTesting = (_, __) async {};

      await transformationProvider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 140.0, 'carbs': 200.0, 'fat': 50.0},
      );

      // Fast forward to Day 30 and complete it
      await transformationProvider.setCurrentDay(30);
      await transformationProvider.markDayCompleted(30);

      await tester.pumpWidget(_buildTestHarness(
        child: const HomeAiRoutineCard(),
        transformationProvider: transformationProvider,
      ));
      await tester.pumpAndSettle();

      // Final day complete shows graduation button
      expect(find.text('DAY 30 COMPLETED ✓'), findsOneWidget);
      expect(find.text('VIEW PROGRAMME GRADUATION'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 10: User with both an AI routine and transformation history
    // -------------------------------------------------------------------------
    testWidgets('Scenario 10: User with AI routine and transformation history displays AI routine (Priority 2)', (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'history_and_ai_user';
      transformationProvider.activeDocSaverForTesting = (_, __) async {};
      transformationProvider.historyDocSaverForTesting = (_, __) async {};

      // Complete a past transformation to put it in history
      await transformationProvider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 140.0, 'carbs': 200.0, 'fat': 50.0},
      );
      for (int i = 1; i <= 30; i++) {
        await transformationProvider.markDayCompleted(i);
      }
      await transformationProvider.completePlan();

      expect(transformationProvider.hasActiveTransformation, isFalse);
      expect(transformationProvider.history.isNotEmpty, isTrue);

      // Inject active AI routine
      final monday = DateTime(2026, 3, 16, 10, 0);
      final workoutProvider = WorkoutProvider()
        ..setNowProviderForTesting(() => monday)
        ..setAllWorkoutsForTesting(_buildThreeDaySplitWorkouts(monday));

      await tester.pumpWidget(_buildTestHarness(
        child: const HomeAiRoutineCard(),
        transformationProvider: transformationProvider,
        workoutProvider: workoutProvider,
      ));
      await tester.pumpAndSettle();

      // Priority 2 wins: AI Workout Schedule is rendered, not onboarding or active transformation
      expect(find.text('Workout Schedule'), findsOneWidget);
      expect(find.text('Monday Routine'), findsOneWidget);
      expect(find.text('Build Your Workout Plan'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test 11: Navigation and Quick Actions Integration
    // -------------------------------------------------------------------------
    testWidgets('Test 11: Workout day launch navigates to DayWorkoutSessionPage and QuickActions preserves /workoutLog', (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'nav_test_user';
      transformationProvider.activeDocSaverForTesting = (_, __) async {};

      await transformationProvider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 140.0, 'carbs': 200.0, 'fat': 50.0},
      );

      await tester.pumpWidget(_buildTestHarness(
        child: Column(
          children: const [
            HomeAiRoutineCard(),
            QuickActionsWidget(),
          ],
        ),
        transformationProvider: transformationProvider,
      ));
      await tester.pumpAndSettle();

      // 1. Tapping START DAY 1 WORKOUT launches DayWorkoutSessionPage
      final startButton = find.text('START DAY 1 WORKOUT');
      expect(startButton, findsOneWidget);
      await tester.tap(startButton);
      await tester.pumpAndSettle();
      expect(find.text('Day Workout Session Screen'), findsOneWidget);

      // Return to dashboard
      final router = GoRouter.of(tester.element(find.text('Day Workout Session Screen')));
      router.go('/');
      await tester.pumpAndSettle();

      // 2. Tapping "Log Lift" in QuickActions when transformation workout is active routes to workoutLogRoute
      final logLiftButton = find.text('Log Lift');
      expect(logLiftButton, findsOneWidget);
      await tester.tap(logLiftButton);
      await tester.pumpAndSettle();

      // Navigated to Workout Log Screen for ad-hoc manual logging without AI prompt
      expect(find.text('Workout Log Screen'), findsOneWidget);
    });
  });
}
