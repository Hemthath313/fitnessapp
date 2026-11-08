import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/workout_model.dart';
import 'package:fitness_app/presentation/ai_coach/workout_generator_screen.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/dashboard_ai_workout_generator_card.dart';
import 'package:fitness_app/presentation/home/widgets/home_ai_routine_card.dart';
import 'package:fitness_app/presentation/home/widgets/quick_actions_widget.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/utils/router/router.dart';

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

class _MockSubscriptionProvider extends ChangeNotifier
    implements SubscriptionProvider {
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

class _MockConsumptionProvider extends ChangeNotifier
    implements ConsumptionProvider {
  @override
  double get waterADay => 2000.0;

  @override
  Future<void> getConsumedCalories() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockStatisticsProvider extends ChangeNotifier
    implements StatisticsProvider {
  final int _streak = 5;
  final List<String> _scheduledDays = ['Monday', 'Wednesday', 'Friday'];

  @override
  int get currentStreak => _streak;

  @override
  List<String> get scheduledDayNames => _scheduledDays;

  @override
  bool get hasActiveSchedule => _scheduledDays.isNotEmpty;

  @override
  bool get hasWorkoutToday => false;

  @override
  Future<Map<String, dynamic>> getWeeklyStats() async => {};

  @override
  List<String> consumeNewlyUnlocked() => [];

  bool isScheduledDay(DateTime date) => true;

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

void _configureTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

List<WorkoutModel> _buildThreeDaySplit(DateTime date) {
  return [
    WorkoutModel(
      id: 'w1',
      name: '[Monday] Barbell Bench Press',
      repNumber: 10,
      setNumber: 3,
      dateTime: date,
    ),
    WorkoutModel(
      id: 'w2',
      name: '[Wednesday] Barbell Back Squat',
      repNumber: 10,
      setNumber: 3,
      dateTime: date,
    ),
    WorkoutModel(
      id: 'w3',
      name: '[Friday] Conventional Deadlift',
      repNumber: 8,
      setNumber: 3,
      dateTime: date,
    ),
  ];
}

Widget _buildDashboardHarness({
  required Widget child,
  TransformationProvider? transformationProvider,
  WorkoutProvider? workoutProvider,
  StatisticsProvider? statisticsProvider,
  HomeProvider? homeProvider,
  SubscriptionProvider? subscriptionProvider,
  ConsumptionProvider? consumptionProvider,
}) {
  final tp = transformationProvider ?? TransformationProvider(autoLoad: false);
  final wp = workoutProvider ?? WorkoutProvider();
  final sp = statisticsProvider ?? _MockStatisticsProvider();
  final hp = homeProvider ?? _MockHomeProvider();
  final subp = subscriptionProvider ?? _MockSubscriptionProvider();
  final cp = consumptionProvider ?? _MockConsumptionProvider();

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(body: child),
      ),
      GoRoute(
        path: Routes.workoutGeneratorRoute,
        builder: (context, state) => const Scaffold(
          body: Text('Workout Generator Screen Destination'),
        ),
      ),
      GoRoute(
        path: Routes.dayWorkoutSessionRoute,
        builder: (context, state) => const Scaffold(
          body: Text('Day Workout Session Screen Destination'),
        ),
      ),
      GoRoute(
        path: Routes.transformationRoadmapRoute,
        builder: (context, state) => const Scaffold(
          body: Text('Transformation Roadmap Screen Destination'),
        ),
      ),
      GoRoute(
        path: Routes.workoutLogRoute,
        builder: (context, state) => const Scaffold(
          body: Text('Workout Log Screen Destination'),
        ),
      ),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TransformationProvider>.value(value: tp),
      ChangeNotifierProvider<WorkoutProvider>.value(value: wp),
      ChangeNotifierProvider<StatisticsProvider>.value(value: sp),
      ChangeNotifierProvider<HomeProvider>.value(value: hp),
      ChangeNotifierProvider<SubscriptionProvider>.value(value: subp),
      ChangeNotifierProvider<ConsumptionProvider>.value(value: cp),
    ],
    child: ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (_, __) => MaterialApp.router(
        routerConfig: router,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF121212),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Gym Buddy Dashboard — Restore AI Workout Generator Suite', () {
    // -------------------------------------------------------------------------
    // Scenario 1: New user can access the AI Workout Generator
    // -------------------------------------------------------------------------
    testWidgets('Scenario 1: New user can access AI Workout Generator from hero and quick actions', (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      final workoutProvider = WorkoutProvider()
        ..setAllWorkoutsForTesting(const []);

      await tester.pumpWidget(_buildDashboardHarness(
        child: const SingleChildScrollView(
          child: Column(
            children: [
              HomeAiRoutineCard(),
              DashboardAiWorkoutGeneratorCard(),
              QuickActionsWidget(),
            ],
          ),
        ),
        transformationProvider: transformationProvider,
        workoutProvider: workoutProvider,
      ));
      await tester.pumpAndSettle();

      // Top hero displays AI onboarding builder
      expect(find.text('Build Your AI Workout Plan'), findsOneWidget);
      expect(find.text('Build My Plan with AI'), findsOneWidget);

      // Companion card is hidden because top card is already the AI builder
      expect(find.text('Build Your AI Workout Routine'), findsNothing);

      // Tapping "Build My Plan with AI" navigates to WorkoutGeneratorScreen
      await tester.tap(find.text('Build My Plan with AI'));
      await tester.pumpAndSettle();
      expect(find.text('Workout Generator Screen Destination'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 2: User with an active AI routine can access it
    // -------------------------------------------------------------------------
    testWidgets('Scenario 2: User with active AI routine can access it and re-plan', (tester) async {
      _configureTestViewport(tester);

      final monday = DateTime(2026, 3, 16, 9, 0);
      final transformationProvider = TransformationProvider(autoLoad: false);
      final workoutProvider = WorkoutProvider()
        ..setNowProviderForTesting(() => monday)
        ..setAllWorkoutsForTesting(_buildThreeDaySplit(monday));

      await tester.pumpWidget(_buildDashboardHarness(
        child: const SingleChildScrollView(
          child: Column(
            children: [
              HomeAiRoutineCard(),
              DashboardAiWorkoutGeneratorCard(),
              QuickActionsWidget(),
            ],
          ),
        ),
        transformationProvider: transformationProvider,
        workoutProvider: workoutProvider,
      ));
      await tester.pumpAndSettle();

      // Priority 2 AI routine scroller hub is active
      expect(find.text('AI Workout Schedule'), findsOneWidget);
      expect(find.text('Re-plan'), findsOneWidget);

      // Tapping Re-plan navigates to WorkoutGeneratorScreen
      await tester.tap(find.text('Re-plan'));
      await tester.pumpAndSettle();
      expect(find.text('Workout Generator Screen Destination'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 3: User with an active Beginner programme can access it
    // -------------------------------------------------------------------------
    testWidgets('Scenario 3: Active Beginner programme user sees Transformation Hero AND AI Generator card', (tester) async {
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
        ..setAllWorkoutsForTesting(const []);

      await tester.pumpWidget(_buildDashboardHarness(
        child: const SingleChildScrollView(
          child: Column(
            children: [
              HomeAiRoutineCard(),
              DashboardAiWorkoutGeneratorCard(),
              QuickActionsWidget(),
            ],
          ),
        ),
        transformationProvider: transformationProvider,
        workoutProvider: workoutProvider,
      ));
      await tester.pumpAndSettle();

      // 1. Transformation Hero is rendered at the top
      expect(find.text(TransformationPlansData.beginnerFitness30.title), findsOneWidget);
      expect(find.text('START DAY 1 WORKOUT'), findsOneWidget);

      // 2. Restored AI Workout Generator card is visible directly below
      expect(find.text('AI WORKOUT GENERATOR'), findsOneWidget);
      expect(find.text('Build Your AI Workout Routine'), findsOneWidget);
      expect(find.text('3–6 Day Custom Splits'), findsOneWidget);
      expect(find.text('Build My Routine with AI'), findsOneWidget);

      // 3. Tapping "Build My Routine with AI" navigates cleanly
      await tester.tap(find.text('Build My Routine with AI'));
      await tester.pumpAndSettle();
      expect(find.text('Workout Generator Screen Destination'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 4: User with an active Weight Loss programme can access it
    // -------------------------------------------------------------------------
    testWidgets('Scenario 4: Active Weight Loss programme user sees Weight Loss Hero AND AI Generator card', (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'weight_loss_user';
      transformationProvider.activeDocSaverForTesting = (_, __) async {};

      await transformationProvider.enrollInPlan(
        blueprint: TransformationPlansData.weightLoss60,
        targetCalories: 1800,
        targetMacros: const {'protein': 150.0, 'carbs': 150.0, 'fat': 40.0},
      );

      final workoutProvider = WorkoutProvider()
        ..setAllWorkoutsForTesting(const []);

      await tester.pumpWidget(_buildDashboardHarness(
        child: const SingleChildScrollView(
          child: Column(
            children: [
              HomeAiRoutineCard(),
              DashboardAiWorkoutGeneratorCard(),
              QuickActionsWidget(),
            ],
          ),
        ),
        transformationProvider: transformationProvider,
        workoutProvider: workoutProvider,
      ));
      await tester.pumpAndSettle();

      // 1. Transformation Hero is rendered
      expect(find.text(TransformationPlansData.weightLoss60.title), findsOneWidget);

      // 2. Restored AI Workout Generator card is visible
      expect(find.text('AI WORKOUT GENERATOR'), findsOneWidget);
      expect(find.text('Build Your AI Workout Routine'), findsOneWidget);

      // 3. Tapping AI Routine in QuickActions also routes to generator
      final aiRoutineQuickAction = find.text('AI Routine');
      expect(aiRoutineQuickAction, findsOneWidget);
      await tester.tap(aiRoutineQuickAction);
      await tester.pumpAndSettle();
      expect(find.text('Workout Generator Screen Destination'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 5: User with an active Muscle Building programme can access it
    // -------------------------------------------------------------------------
    testWidgets('Scenario 5: Active Muscle Building programme user sees Muscle Gain Hero AND AI Generator card', (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'muscle_gain_user';
      transformationProvider.activeDocSaverForTesting = (_, __) async {};

      await transformationProvider.enrollInPlan(
        blueprint: TransformationPlansData.muscleBuilding90,
        targetCalories: 2800,
        targetMacros: const {'protein': 180.0, 'carbs': 320.0, 'fat': 70.0},
      );

      final workoutProvider = WorkoutProvider()
        ..setAllWorkoutsForTesting(const []);

      await tester.pumpWidget(_buildDashboardHarness(
        child: const SingleChildScrollView(
          child: Column(
            children: [
              HomeAiRoutineCard(),
              DashboardAiWorkoutGeneratorCard(),
            ],
          ),
        ),
        transformationProvider: transformationProvider,
        workoutProvider: workoutProvider,
      ));
      await tester.pumpAndSettle();

      // 1. Transformation Hero is rendered
      expect(find.text(TransformationPlansData.muscleBuilding90.title), findsOneWidget);

      // 2. Restored AI Workout Generator card is visible
      expect(find.text('AI WORKOUT GENERATOR'), findsOneWidget);
      expect(find.text('Build Your AI Workout Routine'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 6: User with an active Strength Building programme can access it
    // -------------------------------------------------------------------------
    testWidgets('Scenario 6: Active Strength Building programme user sees 12-Week Strength Hero AND AI Generator card', (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'strength_user';
      transformationProvider.activeDocSaverForTesting = (_, __) async {};

      await transformationProvider.enrollInPlan(
        blueprint: TransformationPlansData.strength12Week,
        targetCalories: 2900,
        targetMacros: const {'protein': 190.0, 'carbs': 330.0, 'fat': 75.0},
      );

      final workoutProvider = WorkoutProvider()
        ..setAllWorkoutsForTesting(const []);

      await tester.pumpWidget(_buildDashboardHarness(
        child: const SingleChildScrollView(
          child: Column(
            children: [
              HomeAiRoutineCard(),
              DashboardAiWorkoutGeneratorCard(),
            ],
          ),
        ),
        transformationProvider: transformationProvider,
        workoutProvider: workoutProvider,
      ));
      await tester.pumpAndSettle();

      // 1. Transformation Hero is rendered
      expect(find.text(TransformationPlansData.strength12Week.title), findsOneWidget);

      // 2. Restored AI Workout Generator card is visible
      expect(find.text('AI WORKOUT GENERATOR'), findsOneWidget);
      expect(find.text('Build Your AI Workout Routine'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 7: User can select workout days and generate a custom AI routine
    // -------------------------------------------------------------------------
    testWidgets('Scenario 7: User can select workout days and generate a custom AI routine in WorkoutGeneratorScreen', (tester) async {
      _configureTestViewport(tester);

      final workoutProvider = WorkoutProvider()
        ..setAllWorkoutsForTesting(const []);
      final statsProvider = _MockStatisticsProvider();
      final homeProvider = _MockHomeProvider();
      final subscriptionProvider = _MockSubscriptionProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<WorkoutProvider>.value(value: workoutProvider),
            ChangeNotifierProvider<StatisticsProvider>.value(value: statsProvider),
            ChangeNotifierProvider<HomeProvider>.value(value: homeProvider),
            ChangeNotifierProvider<SubscriptionProvider>.value(value: subscriptionProvider),
          ],
          child: ScreenUtilInit(
            designSize: const Size(430, 932),
            builder: (_, __) => MaterialApp(
              theme: ThemeData.dark(),
              home: const Scaffold(body: WorkoutGeneratorScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify WorkoutGeneratorScreen day selection options
      expect(find.text('Days per Week'), findsOneWidget);
      expect(find.text('3 Days'), findsOneWidget);

      // Verify day selection chips (Mon, Wed, Fri selected initially)
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);

      // Toggle Tuesday to add a 4th day
      await tester.tap(find.text('Tue'));
      await tester.pumpAndSettle();

      // Verify active training days text updated to 4 selected
      expect(find.textContaining('4 selected'), findsOneWidget);

      // Tap generate button
      expect(find.text('GENERATE WEEKLY PLAN'), findsOneWidget);
      await tester.tap(find.text('GENERATE WEEKLY PLAN'));
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();

      // Routine generated with weekly split focus
      expect(find.text('Your Weekly Split'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 8: Generating an AI routine does not replace or abandon an active transformation
    // -------------------------------------------------------------------------
    testWidgets('Scenario 8: Generating an AI routine does not replace or abandon an active transformation', (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'coexistence_user';
      transformationProvider.activeDocSaverForTesting = (_, __) async {};

      // Enroll in Beginner Fitness 30
      await transformationProvider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 140.0, 'carbs': 200.0, 'fat': 50.0},
      );
      await transformationProvider.setCurrentDay(5);

      expect(transformationProvider.hasActiveTransformation, isTrue);
      expect(transformationProvider.activeTransformation!.planId, 'beginner_fitness_30');
      expect(transformationProvider.activeTransformation!.currentDay, 5);

      // Generate and save an AI routine via WorkoutProvider
      final now = DateTime(2026, 3, 16, 10, 0);
      final workoutProvider = WorkoutProvider()
        ..setNowProviderForTesting(() => now)
        ..setAllWorkoutsForTesting(const []);

      final generatedSplitWorkouts = _buildThreeDaySplit(now);
      await workoutProvider.replaceWeeklyPlan(generatedSplitWorkouts);

      // Critical Invariant: TransformationProvider remains 100% active and untouched
      expect(transformationProvider.hasActiveTransformation, isTrue);
      expect(transformationProvider.activeTransformation!.planId, 'beginner_fitness_30');
      expect(transformationProvider.activeTransformation!.currentDay, 5);
      expect(transformationProvider.history.isEmpty, isTrue); // Not abandoned!

      // WorkoutProvider now holds the AI routine
      expect(workoutProvider.allWorkouts.length, 3);
      expect(workoutProvider.allWorkouts.any((w) => w.name.contains('Barbell Bench Press')), isTrue);

      // Dashboard now displays BOTH: Transformation Hero AND Active AI Routine companion card
      await tester.pumpWidget(_buildDashboardHarness(
        child: const SingleChildScrollView(
          child: Column(
            children: [
              HomeAiRoutineCard(),
              DashboardAiWorkoutGeneratorCard(),
            ],
          ),
        ),
        transformationProvider: transformationProvider,
        workoutProvider: workoutProvider,
      ));
      await tester.pumpAndSettle();

      // Transformation Hero at top
      expect(find.text(TransformationPlansData.beginnerFitness30.title), findsOneWidget);
      expect(find.text('START DAY 5 WORKOUT'), findsOneWidget);

      // Active AI Routine companion card below
      expect(find.text('AI WORKOUT ROUTINE'), findsOneWidget);
      expect(find.text('Your Custom AI Routine'), findsOneWidget);
      expect(find.text('Re-plan Split'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Visual Evidence: Capture screenshot of Dashboard with Transformation Hero + Restored AI Generator
    // -------------------------------------------------------------------------
    testWidgets('Visual Verification: Capture Dashboard Screenshot showing Transformation Hero and Restored AI Generator', (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'screenshot_user';
      transformationProvider.activeDocSaverForTesting = (_, __) async {};

      await transformationProvider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2100,
        targetMacros: const {'protein': 145.0, 'carbs': 210.0, 'fat': 55.0},
      );

      final workoutProvider = WorkoutProvider()
        ..setAllWorkoutsForTesting(const []);

      final boundaryKey = GlobalKey();

      await tester.pumpWidget(
        _buildDashboardHarness(
          child: RepaintBoundary(
            key: boundaryKey,
            child: SingleChildScrollView(
              child: Column(
                children: const [
                  HomeAiRoutineCard(),
                  DashboardAiWorkoutGeneratorCard(),
                  QuickActionsWidget(),
                ],
              ),
            ),
          ),
          transformationProvider: transformationProvider,
          workoutProvider: workoutProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(TransformationPlansData.beginnerFitness30.title), findsOneWidget);
      expect(find.text('Build Your AI Workout Routine'), findsOneWidget);

      await tester.runAsync(() async {
        final boundary = boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 2.0);
          final byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final file = File(
              '/Users/hemthath/.gemini/antigravity/brain/0985b2e0-957d-4124-a5ef-faaac7edec5d/dashboard_transformation_and_ai_generator.png',
            );
            await file.writeAsBytes(byteData.buffer.asUint8List());
          }
        }
      });
    });
  });
}
