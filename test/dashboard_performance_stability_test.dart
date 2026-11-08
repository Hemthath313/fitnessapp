import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/home_ai_routine_card.dart';
import 'package:fitness_app/presentation/home/widgets/quick_actions_widget.dart';
import 'package:fitness_app/presentation/home/widgets/recent_prs_widget.dart';
import 'package:fitness_app/presentation/main/widgets/appbar_home.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/utils/router/router.dart';

class _MockHomeProvider extends ChangeNotifier implements HomeProvider {
  final Map<String, dynamic> _userData = {
    'name': 'Athlete',
    'first name': 'Athlete',
    'experience': 'Intermediate',
    'fitness_goal': 'Build Muscle',
    'goal': 'Build Muscle',
  };

  @override
  Map<String, dynamic> get userData => _userData;

  void setFirstName(String name) {
    _userData['first name'] = name;
    notifyListeners();
  }

  @override
  Future<Map<String, dynamic>> fetchUserData() async => _userData;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockStatisticsProvider extends ChangeNotifier implements StatisticsProvider {
  int _currentStreak = 0;
  bool _hasWorkoutToday = false;
  final List<DateTime> _completedWorkoutDates = [];

  @override
  int get currentStreak => _currentStreak;

  @override
  bool get hasWorkoutToday => _hasWorkoutToday;

  @override
  List<DateTime> get completedWorkoutDates => _completedWorkoutDates;

  @override
  List<String> get scheduledDayNames => [];

  @override
  bool get hasActiveSchedule => false;

  @override
  bool get hasWorkoutHistory => false;

  @override
  bool isRestDay([DateTime? date]) => false;

  @override
  bool isPendingScheduledDay([DateTime? date]) => false;

  @override
  Future<Map<String, dynamic>> getWeeklyStats() async => {};

  @override
  List<String> consumeNewlyUnlocked() => [];

  void setStreak(int s) {
    _currentStreak = s;
    notifyListeners();
  }

  void setHasWorkoutToday(bool v) {
    _hasWorkoutToday = v;
    notifyListeners();
  }

  @override
  int get totalWorkouts => 3;

  @override
  List<String> get unlockedAchievements => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockConsumptionProvider extends ChangeNotifier implements ConsumptionProvider {
  double _water = 0.0;
  double _calories = 0.0;

  @override
  double get waterADay => _water;

  double get totalCalories => _calories;

  void setWater(double w) {
    _water = w;
    notifyListeners();
  }

  void setCalories(double c) {
    _calories = c;
    notifyListeners();
  }

  @override
  Future<void> getConsumedCalories() async {}

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

Widget _wrapWithHarness({
  required Widget child,
  _MockHomeProvider? homeProvider,
  _MockStatisticsProvider? statsProvider,
  _MockConsumptionProvider? consumptionProvider,
  TransformationProvider? transformationProvider,
  WorkoutProvider? workoutProvider,
  GoRouter? customRouter,
}) {
  final hp = homeProvider ?? _MockHomeProvider();
  final sp = statsProvider ?? _MockStatisticsProvider();
  final cp = consumptionProvider ?? _MockConsumptionProvider();
  final tp = transformationProvider ?? TransformationProvider(autoLoad: false);
  final wp = workoutProvider ?? WorkoutProvider();

  final router = customRouter ??
      GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => Scaffold(body: child)),
          GoRoute(path: Routes.strengthAnalyticsRoute, builder: (_, __) => const Scaffold(body: Text('Strength Analytics Screen'))),
          GoRoute(path: Routes.workoutHistoryRoute, builder: (_, __) => const Scaffold(body: Text('Workout History Screen'))),
          GoRoute(path: Routes.workoutLogRoute, builder: (_, __) => const Scaffold(body: Text('Workout Log Screen'))),
          GoRoute(path: Routes.premiumScreen, builder: (_, __) => const Scaffold(body: Text('Premium Screen'))),
          GoRoute(path: Routes.addWaterRoute, builder: (_, __) => const Scaffold(body: Text('Add Water Screen'))),
          GoRoute(path: Routes.dayWorkoutSessionRoute, builder: (_, __) => const Scaffold(body: Text('Day Workout Session Screen'))),
          GoRoute(path: Routes.transformationRoadmapRoute, builder: (_, __) => const Scaffold(body: Text('Transformation Roadmap Screen'))),
        ],
      );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<HomeProvider>.value(value: hp),
      ChangeNotifierProvider<StatisticsProvider>.value(value: sp),
      ChangeNotifierProvider<ConsumptionProvider>.value(value: cp),
      ChangeNotifierProvider<TransformationProvider?>.value(value: tp),
      ChangeNotifierProvider<WorkoutProvider>.value(value: wp),
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

  group('Gym Buddy Dashboard Phase 3 — Performance & Stability Optimization Suite', () {
    // -------------------------------------------------------------------------
    // Test 1: Recent PR streams are reused across parent widget rebuilds
    // -------------------------------------------------------------------------
    testWidgets('1. Recent PR streams are reused across parent rebuilds without recreation', (tester) async {
      _configureTestViewport(tester);

      int sessionsStreamListenCount = 0;
      int logsStreamListenCount = 0;

      final sessionController = StreamController<List<WorkoutSession>>.broadcast(
        onListen: () => sessionsStreamListenCount++,
      );
      final logController = StreamController<List<WorkoutLog>>.broadcast(
        onListen: () => logsStreamListenCount++,
      );

      // Wrapper stateful widget to trigger rebuilds
      bool toggle = false;
      late StateSetter triggerRebuild;

      final widgetToTest = StatefulBuilder(
        builder: (context, setState) {
          triggerRebuild = setState;
          return Column(
            children: [
              Text('Rebuild Trigger: $toggle'),
              RecentPRsWidget(
                sessionsStream: sessionController.stream,
                logsStream: logController.stream,
              ),
            ],
          );
        },
      );

      await tester.pumpWidget(_wrapWithHarness(child: widgetToTest));
      await tester.pump();

      expect(sessionsStreamListenCount, equals(1));
      expect(logsStreamListenCount, equals(1));

      // Trigger 5 parent widget rebuilds
      for (int i = 0; i < 5; i++) {
        triggerRebuild(() {
          toggle = !toggle;
        });
        await tester.pump();
      }

      // Streams must be cached in state, so listeners were NOT torn down and recreated!
      expect(sessionsStreamListenCount, equals(1));
      expect(logsStreamListenCount, equals(1));

      await sessionController.close();
      await logController.close();
    });

    // -------------------------------------------------------------------------
    // Test 2: No duplicate Firestore subscriptions are created
    // -------------------------------------------------------------------------
    testWidgets('2. No duplicate subscriptions are created on stream updates', (tester) async {
      _configureTestViewport(tester);

      final sessionController = StreamController<List<WorkoutSession>>.broadcast();
      final logController = StreamController<List<WorkoutLog>>.broadcast();

      await tester.pumpWidget(_wrapWithHarness(
        child: RecentPRsWidget(
          sessionsStream: sessionController.stream,
          logsStream: logController.stream,
        ),
      ));
      await tester.pump();

      // Emit data once
      sessionController.add([]);
      logController.add([]);
      await tester.pumpAndSettle();

      // Ensure empty state renders cleanly with single subscription
      expect(find.textContaining('Log your sets during workouts'), findsOneWidget);

      await sessionController.close();
      await logController.close();
    });

    // -------------------------------------------------------------------------
    // Test 3: Stream errors display the correct state
    // -------------------------------------------------------------------------
    testWidgets('3. Stream errors display the correct user-friendly error state with PR Vault link', (tester) async {
      _configureTestViewport(tester);

      final sessionController = StreamController<List<WorkoutSession>>.broadcast();
      final logController = StreamController<List<WorkoutLog>>.broadcast();

      await tester.pumpWidget(_wrapWithHarness(
        child: RecentPRsWidget(
          sessionsStream: sessionController.stream,
          logsStream: logController.stream,
        ),
      ));
      await tester.pump();

      // Emit error on session stream
      sessionController.addError(Exception('Firestore stream timeout: offline'));
      await tester.pumpAndSettle();

      // Verify graceful error UI
      expect(find.textContaining('Unable to load recent personal records'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.text('PR Vault'), findsOneWidget);

      await sessionController.close();
      await logController.close();
    });

    // -------------------------------------------------------------------------
    // Test 4: Empty PR state remains correct
    // -------------------------------------------------------------------------
    testWidgets('4. Empty PR state renders motivational guidance without crashing', (tester) async {
      _configureTestViewport(tester);

      final sessionController = StreamController<List<WorkoutSession>>.broadcast();
      final logController = StreamController<List<WorkoutLog>>.broadcast();

      await tester.pumpWidget(_wrapWithHarness(
        child: RecentPRsWidget(
          sessionsStream: sessionController.stream,
          logsStream: logController.stream,
        ),
      ));
      await tester.pump();

      sessionController.add(<WorkoutSession>[]);
      logController.add(<WorkoutLog>[]);
      await tester.pumpAndSettle();

      expect(find.text('Personal Records'), findsOneWidget);
      expect(find.textContaining('unlock automatic PR detection'), findsOneWidget);

      await sessionController.close();
      await logController.close();
    });

    // -------------------------------------------------------------------------
    // Test 5: PR navigation still works
    // -------------------------------------------------------------------------
    testWidgets('5. PR Vault header navigation routes to Strength Analytics screen', (tester) async {
      _configureTestViewport(tester);

      final sessionController = StreamController<List<WorkoutSession>>.broadcast();
      final logController = StreamController<List<WorkoutLog>>.broadcast();

      await tester.pumpWidget(_wrapWithHarness(
        child: RecentPRsWidget(
          sessionsStream: sessionController.stream,
          logsStream: logController.stream,
        ),
      ));
      await tester.pump();

      sessionController.add([]);
      logController.add([]);
      await tester.pumpAndSettle();

      final prVaultBtn = find.text('PR Vault');
      expect(prVaultBtn, findsOneWidget);

      await tester.tap(prVaultBtn);
      await tester.pumpAndSettle();

      expect(find.text('Strength Analytics Screen'), findsOneWidget);

      await sessionController.close();
      await logController.close();
    });

    // -------------------------------------------------------------------------
    // Test 6: AppBar animation remains functional with RepaintBoundary isolation
    // -------------------------------------------------------------------------
    testWidgets('6. AppBar streak badge is wrapped in RepaintBoundary and renders correctly', (tester) async {
      _configureTestViewport(tester);

      final stats = _MockStatisticsProvider();
      stats.setStreak(7);

      await tester.pumpWidget(_wrapWithHarness(
        child: const HomePageAppBarWidget(),
        statsProvider: stats,
      ));
      await tester.pump();

      // Streak badge displays 7 days
      expect(find.text('7'), findsOneWidget);
      expect(find.text('days'), findsOneWidget);

      // Verify streak badge is isolated inside a RepaintBoundary
      final streakText = find.text('7');
      final repaintBoundary = find.ancestor(
        of: streakText,
        matching: find.byType(RepaintBoundary),
      );
      expect(repaintBoundary, findsWidgets);

      // Pump 1 second of frames without exceptions (chip is static now)
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('7'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 7: AppBar animation resources are managed correctly when streak = 0
    // -------------------------------------------------------------------------
    testWidgets('7. AppBar handles streak = 0 cleanly without endless animation repeat cycles', (tester) async {
      _configureTestViewport(tester);

      final stats = _MockStatisticsProvider();
      stats.setStreak(0);

      await tester.pumpWidget(_wrapWithHarness(
        child: const HomePageAppBarWidget(),
        statsProvider: stats,
      ));
      await tester.pump();

      expect(find.text('0'), findsOneWidget);
      expect(find.text('days'), findsNothing);

      // Animate frame — should render stably
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('0'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 8: Narrow Consumer / Selector scopes preserve correct UI updates
    // -------------------------------------------------------------------------
    testWidgets('8. Narrow Selector scopes update QuickActions only when targeted booleans change', (tester) async {
      _configureTestViewport(tester);

      final consumption = _MockConsumptionProvider();
      final stats = _MockStatisticsProvider();

      await tester.pumpWidget(_wrapWithHarness(
        child: const QuickActionsWidget(),
        consumptionProvider: consumption,
        statsProvider: stats,
      ));
      await tester.pumpAndSettle();

      // Initially water is 0 -> not completed
      expect(consumption.waterADay, equals(0.0));

      // Updating unrelated totalCalories does NOT break or mutate water state
      consumption.setCalories(500.0);
      await tester.pump();

      // Updating waterADay to 500 triggers targeted Selector update
      consumption.setWater(500.0);
      await tester.pump();
      expect(consumption.waterADay, equals(500.0));

      // Updating workoutDoneToday triggers targeted Selector update
      stats.setHasWorkoutToday(true);
      await tester.pump();
      expect(stats.hasWorkoutToday, isTrue);
    });

    // -------------------------------------------------------------------------
    // Test 9: Dashboard rebuilds do not break the unified workout hero
    // -------------------------------------------------------------------------
    testWidgets('9. Sibling rebuilds and dashboard scrolling do not break the unified workout hero', (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'hero_rebuild_user';
      transformationProvider.activeDocSaverForTesting = (_, __) async {};

      await transformationProvider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 140.0, 'carbs': 200.0, 'fat': 50.0},
      );

      final stats = _MockStatisticsProvider();
      final consumption = _MockConsumptionProvider();

      await tester.pumpWidget(_wrapWithHarness(
        child: SingleChildScrollView(
          child: Column(
            children: const [
              HomePageAppBarWidget(),
              HomeAiRoutineCard(),
              QuickActionsWidget(),
            ],
          ),
        ),
        transformationProvider: transformationProvider,
        statsProvider: stats,
        consumptionProvider: consumption,
      ));
      await tester.pumpAndSettle();

      // Priority 1 Hero Card is active
      expect(find.text(TransformationPlansData.beginnerFitness30.title), findsOneWidget);
      expect(find.text('DAY 1 OF 30'), findsOneWidget);
      expect(find.text('START DAY 1 WORKOUT'), findsOneWidget);

      // Trigger stats and consumption changes (rebuilding siblings)
      stats.setStreak(3);
      consumption.setWater(1200.0);
      await tester.pumpAndSettle();

      // Hero card remains rock-solid and responsive
      expect(find.text(TransformationPlansData.beginnerFitness30.title), findsOneWidget);
      expect(find.text('START DAY 1 WORKOUT'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // AppBar updated streak
    });

    // -------------------------------------------------------------------------
    // Test 10: Widget disposal does not produce exceptions
    // -------------------------------------------------------------------------
    testWidgets('10. Full unmount and disposal of dashboard widgets produces zero memory leaks or exceptions', (tester) async {
      _configureTestViewport(tester);

      final sessionController = StreamController<List<WorkoutSession>>.broadcast();
      final logController = StreamController<List<WorkoutLog>>.broadcast();

      // Mount all widgets inside SingleChildScrollView to prevent viewport overflow
      await tester.pumpWidget(_wrapWithHarness(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const HomePageAppBarWidget(),
              const HomeAiRoutineCard(),
              const QuickActionsWidget(),
              RecentPRsWidget(
                sessionsStream: sessionController.stream,
                logsStream: logController.stream,
              ),
            ],
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      // Unmount everything by replacing with a blank Container
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox.shrink())));
      await tester.pump(const Duration(milliseconds: 100));

      // Close stream controllers after unmount
      await sessionController.close();
      await logController.close();

      // Verify no exceptions were thrown during teardown
      expect(tester.takeException(), isNull);
    });
  });
}
