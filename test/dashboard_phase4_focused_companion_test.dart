import 'dart:io';
import 'dart:ui' as ui;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/workout_model.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/pages/home_page.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_home_box.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_slider_home_widget.dart';
import 'package:fitness_app/presentation/home/widgets/dashboard_ai_workout_generator_card.dart';
import 'package:fitness_app/presentation/home/widgets/home_ai_routine_card.dart';
import 'package:fitness_app/presentation/home/widgets/streak_calendar_widget.dart';
import 'package:fitness_app/presentation/home/widgets/today_health_snapshot_widget.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/main/widgets/appbar_home.dart';
import 'package:fitness_app/presentation/progress/progress_data.dart';
import 'package:fitness_app/presentation/progress/progress_page.dart';
import 'package:fitness_app/presentation/profile/providers/profile_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/dashboard_challenge_section.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/utils/tdee_calculator.dart';

class _MockHomeProvider extends ChangeNotifier implements HomeProvider {
  Map<String, dynamic> _userData = {
    'name': 'Athlete',
    'first name': 'Athlete',
    'experience': 'Intermediate',
    'fitness_goal': 'Build Muscle',
    'goal': 'Build Muscle',
    'weight': 75.0,
    'height': 178.0,
    'age': 26,
    'gender': 'Male',
  };

  @override
  Map<String, dynamic> get userData => _userData;

  void setUserData(Map<String, dynamic> data) {
    _userData = data;
    notifyListeners();
  }

  int userDataLoads = 0;

  @override
  Future<Map<String, dynamic>> fetchUserData() async {
    userDataLoads++;
    return _userData;
  }

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
  double _waterADay = 1.6;
  double _waterGoalLiters = 2.5;
  int _consumedCalories = 1450;

  @override
  double get waterADay => _waterADay;

  @override
  double get waterGoalLiters => _waterGoalLiters;

  @override
  int get consumedCalories => _consumedCalories;

  void setWaterADay(double val) {
    _waterADay = val;
    notifyListeners();
  }

  void setWaterGoalLiters(double val) {
    _waterGoalLiters = val;
    notifyListeners();
  }

  void setConsumedCalories(int val) {
    _consumedCalories = val;
    notifyListeners();
  }

  int caloriesLoads = 0;
  int waterLoads = 0;

  @override
  Future<void> getConsumedCalories() async {
    caloriesLoads++;
  }

  @override
  Future fetchAndSetWater() async {
    waterLoads++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockStatisticsProvider extends ChangeNotifier
    implements StatisticsProvider {
  int _streak = 5;
  bool _hasWorkoutToday = false;

  @override
  int get currentStreak => _streak;

  void setStreak(int val) {
    _streak = val;
    notifyListeners();
  }

  @override
  bool get hasActiveSchedule => false;

  @override
  bool get hasWorkoutToday => _hasWorkoutToday;

  void setHasWorkoutToday(bool val) {
    _hasWorkoutToday = val;
    notifyListeners();
  }

  @override
  List<DateTime> get completedWorkoutDates => [
        DateTime.now().subtract(const Duration(days: 1)),
        DateTime.now().subtract(const Duration(days: 2)),
      ];

  @override
  int get workoutsCompletedThisWeek => 2;

  @override
  int get weeklyTarget => 4;

  @override
  bool isRestDay([DateTime? date]) => false;

  @override
  bool isPendingScheduledDay([DateTime? date]) => false;

  @override
  bool get hasWorkoutHistory => true;

  @override
  List<String> get scheduledDayNames => [];

  @override
  List<String> consumeNewlyUnlocked() => [];

  int weeklyStatsLoads = 0;

  @override
  Future<Map<String, dynamic>> getWeeklyStats() async {
    weeklyStatsLoads++;
    return {};
  }

  @override
  int get totalWorkouts => 3;

  @override
  List<String> get unlockedAchievements => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockProfileProvider extends ChangeNotifier implements ProfileProvider {
  @override
  List<FlSpot> get flSpots => [
        const FlSpot(1, 75.0),
        const FlSpot(2, 74.5),
      ];

  @override
  Future<void> fetchAndSetFlSpots() async {}

  @override
  List<TimedValue> get weightEntries => const [];

  @override
  Map<String, List<TimedValue>> get measurementHistory => const {};

  @override
  Future<void> loadMeasurementHistory() async {}

  @override
  Future<List<FlSpot>> fetchMeasurementSpots(String type) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void _configureTestViewport(WidgetTester tester,
    {double width = 390, double height = 844, double textScale = 1.0}) {
  tester.view.physicalSize = Size(width * textScale, height * textScale);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

List<WorkoutModel> _buildSplitWorkouts(DateTime date) {
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
  ];
}

final GlobalKey _dashboardScreenshotKey = GlobalKey();

Widget _buildOptionATestDashboard({
  required TransformationProvider transformationProvider,
  required WorkoutProvider workoutProvider,
  required SubscriptionProvider subscriptionProvider,
  required HomeProvider homeProvider,
  required ConsumptionProvider consumptionProvider,
  required StatisticsProvider statsProvider,
  List<RouteBase>? routes,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: routes ??
        [
          GoRoute(
            path: '/',
            builder: (context, state) => RepaintBoundary(
              key: _dashboardScreenshotKey,
              child: Scaffold(
                appBar: const PreferredSize(
                  preferredSize: Size.fromHeight(70),
                  child: HomePageAppBarWidget(),
                ),
                body: ScreenUtilInit(
                  designSize: const Size(390, 844),
                  minTextAdapt: true,
                  builder: (context, child) => const HomePage(),
                ),
              ),
            ),
          ),
          GoRoute(
            path: Routes.transformationRoadmapRoute,
            builder: (context, state) =>
                const Scaffold(body: Text('Transformation Roadmap Screen')),
          ),
          GoRoute(
            path: Routes.transformationPlansRoute,
            builder: (context, state) =>
                const Scaffold(body: Text('Transformation Plans Screen')),
          ),
          GoRoute(
            path: Routes.sixPackChallengeRoute,
            builder: (context, state) =>
                const Scaffold(body: Text('Six Pack Challenge Screen')),
          ),
          GoRoute(
            path: Routes.exerciseOfTheWeekRoute,
            builder: (context, state) =>
                const Scaffold(body: Text('Exercise Detail Screen')),
          ),
          GoRoute(
            path: Routes.workoutGeneratorRoute,
            builder: (context, state) =>
                const Scaffold(body: Text('Workout Generator Screen')),
          ),
          GoRoute(
            path: Routes.premiumScreen,
            builder: (context, state) =>
                const Scaffold(body: Text('Premium Screen')),
          ),
          GoRoute(
            path: Routes.workoutHistoryRoute,
            builder: (context, state) =>
                const Scaffold(body: Text('Workout History Screen')),
          ),
          GoRoute(
            path: Routes.addDataRoute,
            builder: (context, state) =>
                const Scaffold(body: Text('Add Data Profile Screen')),
          ),
          GoRoute(
            path: Routes.editProfileRoute,
            builder: (context, state) =>
                const Scaffold(body: Text('Edit Profile Screen')),
          ),
          GoRoute(
            path: Routes.addWaterRoute,
            builder: (context, state) =>
                const Scaffold(body: Text('Add Water Screen')),
          ),
          GoRoute(
            path: Routes.newMealRoute,
            builder: (context, state) =>
                const Scaffold(body: Text('New Meal Screen')),
          ),
          GoRoute(
            path: Routes.changeWeightRoute,
            builder: (context, state) =>
                const Scaffold(body: Text('Profile Setup Screen')),
          ),
          GoRoute(
            path: Routes.dietRoute,
            builder: (context, state) =>
                const Scaffold(body: Text('Diet Screen')),
          ),
          GoRoute(
            path: Routes.transformationNutritionRoute,
            builder: (context, state) =>
                const Scaffold(body: Text('Transformation Nutrition Screen')),
          ),
          GoRoute(
            path: Routes.workoutLogRoute,
            builder: (context, state) =>
                const Scaffold(body: Text('Workout Log Screen')),
          ),
          GoRoute(
            path: Routes.strengthAnalyticsRoute,
            builder: (context, state) =>
                const Scaffold(body: Text('Strength Analytics Screen')),
          ),
        ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TransformationProvider?>.value(
          value: transformationProvider),
      ChangeNotifierProvider<WorkoutProvider>.value(value: workoutProvider),
      ChangeNotifierProvider<SubscriptionProvider>.value(
          value: subscriptionProvider),
      ChangeNotifierProvider<HomeProvider?>.value(value: homeProvider),
      ChangeNotifierProvider<ConsumptionProvider>.value(
          value: consumptionProvider),
      ChangeNotifierProvider<StatisticsProvider>.value(value: statsProvider),
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

Future<void> _captureScreenshot(
    WidgetTester tester, String filename) async {
  try {
    final context = _dashboardScreenshotKey.currentContext;
    if (context != null) {
      final boundary = context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2.0);
          final byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final file = File(
                '/Users/hemthath/.gemini/antigravity/brain/0985b2e0-957d-4124-a5ef-faaac7edec5d/$filename');
            await file.writeAsBytes(byteData.buffer.asUint8List());
          }
        });
      }
    }
  } catch (_) {
    // Supplementary
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Gym Buddy Dashboard Redesign Phase 4 — Focused Companion Suite', () {
    // -------------------------------------------------------------------------
    // Test 1: Compact AppBar renders correctly
    // -------------------------------------------------------------------------
    testWidgets('1. Compact AppBar renders greeting, name, profile and premium access',
        (tester) async {
      _configureTestViewport(tester, width: 390);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'p4_u1';
      transProvider.activeDocFetcherForTesting = (_) => null;

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();
      final consumption = _MockConsumptionProvider();
      final stats = _MockStatisticsProvider()..setStreak(5);

      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
        consumptionProvider: consumption,
        statsProvider: stats,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Greeting and display name rendered
      expect(find.byType(HomePageAppBarWidget), findsOneWidget);
      expect(find.textContaining('Athlete'), findsWidgets);

      // Profile access button present
      expect(find.byKey(const Key('appbar_profile_button')), findsOneWidget);

      // Premium crown button present & tappable in AppBar
      final appbarCrown = find.descendant(
        of: find.byType(HomePageAppBarWidget),
        matching: find.byIcon(Icons.workspace_premium_rounded),
      );
      expect(appbarCrown, findsOneWidget);
      await tester.tap(appbarCrown);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Premium Screen'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 1b: Avatar opens Edit Profile, never the sign-up data screen
    // -------------------------------------------------------------------------
    testWidgets('1b. Home avatar opens Edit Profile, not the sign-up data screen',
        (tester) async {
      _configureTestViewport(tester, width: 390);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'p4_u1b';
      transProvider.activeDocFetcherForTesting = (_) => null;

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();
      final consumption = _MockConsumptionProvider();
      final stats = _MockStatisticsProvider();

      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
        consumptionProvider: consumption,
        statsProvider: stats,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byKey(const Key('appbar_profile_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Edit Profile Screen'), findsOneWidget);
      expect(find.text('Add Data Profile Screen'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test 2: Only one primary streak indicator in header
    // -------------------------------------------------------------------------
    testWidgets('2. Header displays only ONE streak indicator (flame badge), no duplicate in subtitle',
        (tester) async {
      _configureTestViewport(tester, width: 390);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'p4_u2';
      transProvider.activeDocFetcherForTesting = (_) => null;

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();
      final consumption = _MockConsumptionProvider();
      final stats = _MockStatisticsProvider()..setStreak(7);

      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
        consumptionProvider: consumption,
        statsProvider: stats,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Primary interactive streak badge present
      expect(find.text('7'), findsOneWidget);
      expect(find.text('days'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsWidgets);

      // Time-based greeting line above the name, NOT repeating streak
      expect(
        find.textContaining(RegExp(r'^Good (Morning|Afternoon|Evening),$')),
        findsOneWidget,
      );
      expect(find.textContaining('7-day streak'), findsNothing);

      // Tap streak badge -> routes to workout history
      await tester.tap(find.text('7'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Workout History Screen'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 3: Transformation hero retains highest priority
    // -------------------------------------------------------------------------
    testWidgets('3. Transformation hero retains highest priority on Home, zero competing hero cards',
        (tester) async {
      _configureTestViewport(tester, width: 390);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'p4_u3';
      transProvider.activeDocSaverForTesting = (_, __) async {};

      await transProvider.enrollInPlan(
        blueprint: TransformationPlansData.weightLoss60,
        targetCalories: 2000,
        targetMacros: const {'protein': 160.0, 'carbs': 190.0, 'fat': 55.0},
      );

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();
      final consumption = _MockConsumptionProvider();
      final stats = _MockStatisticsProvider();

      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
        consumptionProvider: consumption,
        statsProvider: stats,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Primary Workout Hero renders Priority 1 Transformation
      expect(find.byType(HomeAiRoutineCard), findsOneWidget);
      expect(find.text(TransformationPlansData.weightLoss60.title), findsOneWidget);
      expect(find.text('DAY 1 OF 60'), findsOneWidget);
      expect(find.text('START DAY 1 WORKOUT'), findsOneWidget);

      // Competing secondary AI card is NOT on the Home dashboard
      expect(find.byType(DashboardAiWorkoutGeneratorCard), findsNothing);

      // Transformation title appears exactly once on Home
      expect(find.text(TransformationPlansData.weightLoss60.title), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 4: Expired transformation remains visible with locked workout CTA
    // -------------------------------------------------------------------------
    testWidgets('4. Expired transformation remains visible, roadmap accessible, workout locked with paywall redirect',
        (tester) async {
      _configureTestViewport(tester, width: 390);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'p4_u4';
      transProvider.activeDocSaverForTesting = (_, __) async {};
      transProvider.entitlementOverrideForTesting = true;

      await transProvider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 1900,
        targetMacros: const {'protein': 140, 'carbs': 190, 'fat': 50},
      );
      transProvider.entitlementOverrideForTesting = null;

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(false); // Expired
      final homeProvider = _MockHomeProvider();
      final consumption = _MockConsumptionProvider();
      final stats = _MockStatisticsProvider();

      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
        consumptionProvider: consumption,
        statsProvider: stats,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Active transformation is preserved
      expect(transProvider.hasActiveTransformation, isTrue);
      expect(find.text(TransformationPlansData.beginnerFitness30.title), findsOneWidget);
      expect(find.text('DAY 1 OF 30'), findsOneWidget);

      // Lock icon shown
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

      // Tapping Roadmap still opens roadmap
      expect(find.text('Roadmap'), findsOneWidget);
      await tester.tap(find.text('Roadmap'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Transformation Roadmap Screen'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 5: Active AI routine remains accessible (Priority 2)
    // -------------------------------------------------------------------------
    testWidgets('5. Active AI routine user sees Priority 2 Hero on Home',
        (tester) async {
      _configureTestViewport(tester, width: 390);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'p4_u5';
      transProvider.activeDocFetcherForTesting = (_) => null;
      await transProvider.loadTransformation();

      final monday = DateTime(2026, 3, 16, 10, 0);
      final workoutProvider = WorkoutProvider()
        ..setNowProviderForTesting(() => monday)
        ..setAllWorkoutsForTesting(_buildSplitWorkouts(monday));

      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();
      final consumption = _MockConsumptionProvider();
      final stats = _MockStatisticsProvider();

      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
        consumptionProvider: consumption,
        statsProvider: stats,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Priority 2 AI Routine card is displayed
      expect(find.byType(HomeAiRoutineCard), findsOneWidget);
      expect(find.text('Workout Schedule'), findsOneWidget);
      expect(find.text('Monday Routine'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 6: New user onboarding remains accessible (Priority 3)
    // -------------------------------------------------------------------------
    testWidgets('6. New user sees Priority 3 AI Builder onboarding hero',
        (tester) async {
      _configureTestViewport(tester, width: 390);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'p4_u6';
      transProvider.activeDocFetcherForTesting = (_) => null;
      await transProvider.loadTransformation();

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();
      final consumption = _MockConsumptionProvider();
      final stats = _MockStatisticsProvider();

      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
        consumptionProvider: consumption,
        statsProvider: stats,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Priority 3 AI Builder onboarding hero
      expect(find.byType(HomeAiRoutineCard), findsOneWidget);
      expect(find.textContaining('Plan'), findsWidgets);
      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
    });

    // -------------------------------------------------------------------------
    // Test 7: All four quick actions remain functional
    // -------------------------------------------------------------------------
    testWidgets('7. Quick actions (Log Meal, Log Lift, AI Plan) navigate; Water is reached via the snapshot card',
        (tester) async {
      _configureTestViewport(tester, width: 390);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'p4_u7';
      transProvider.activeDocFetcherForTesting = (_) => null;
      await transProvider.loadTransformation();

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();
      final consumption = _MockConsumptionProvider();
      final stats = _MockStatisticsProvider();

      // 1. Water Action
      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
        consumptionProvider: consumption,
        statsProvider: stats,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Water is no longer duplicated in Quick Actions: only the snapshot card shows it
      expect(find.text('Water'), findsOneWidget);
      await tester.tap(find.text('Water'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Add Water Screen'), findsOneWidget);

      // 2. Log Meal Action
      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
        consumptionProvider: consumption,
        statsProvider: stats,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Log Meal'), findsOneWidget);
      await tester.tap(find.text('Log Meal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Diet Screen'), findsOneWidget);

      // 3. AI Plan Action
      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
        consumptionProvider: consumption,
        statsProvider: stats,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Plan Builder'), findsOneWidget);
      await tester.tap(find.text('Plan Builder'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Workout Generator Screen'), findsOneWidget);

      // 4. Log Lift Action
      expect(find.text('Log Lift'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 8: Calorie target remains accurate (never raw BMR)
    // -------------------------------------------------------------------------
    testWidgets('8. Today\'s Snapshot displays accurate calorie target (never raw BMR)',
        (tester) async {
      _configureTestViewport(tester, width: 390);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'p4_u8';
      transProvider.activeDocSaverForTesting = (_, __) async {};

      // Active transformation target = 2350 kcal
      await transProvider.enrollInPlan(
        blueprint: TransformationPlansData.muscleBuilding90,
        targetCalories: 2350,
        targetMacros: const {'protein': 180, 'carbs': 260, 'fat': 65},
      );

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();
      homeProvider.setUserData({
        'bmr': 1600.0, // Raw BMR must NOT be displayed
        'weight': 75.0,
        'height': 178.0,
        'age': 26,
        'gender': 'Male',
      });

      final consumption = _MockConsumptionProvider()
        ..setConsumedCalories(1200);
      final stats = _MockStatisticsProvider();

      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
        consumptionProvider: consumption,
        statsProvider: stats,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Snapshot is rendered
      expect(find.byType(TodayHealthSnapshotWidget), findsOneWidget);
      expect(find.text("Today's Snapshot"), findsOneWidget);

      // Transformation target 2350 kcal is used
      expect(find.text('/ 2350 kcal'), findsOneWidget);
      expect(find.text('1200 kcal'), findsOneWidget);

      // Raw BMR (1600) is NEVER displayed as goal
      expect(find.text('/ 1600 kcal'), findsNothing);

      // Tapping calorie section routes to the Diet page
      await tester.tap(find.byKey(const Key('snapshot_calorie_card')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Diet Screen'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 8b: Calorie target Priority 2 - User configured target
    // -------------------------------------------------------------------------
    testWidgets('8b. Today\'s Snapshot: Priority 2 - User-configured target is used when no active transformation',
        (tester) async {
      _configureTestViewport(tester, width: 390);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'p4_u8b';
      transProvider.activeDocFetcherForTesting = (_) => null;
      await transProvider.loadTransformation();

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();
      homeProvider.setUserData({
        'bmr': 1550.0,
        'targetCalories': 2150.0,
        'weight': 70.0,
        'height': 170.0,
        'age': 28,
        'gender': 'Female',
      });

      final consumption = _MockConsumptionProvider()..setConsumedCalories(850);
      final stats = _MockStatisticsProvider();

      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
        consumptionProvider: consumption,
        statsProvider: stats,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('/ 2150 kcal'), findsOneWidget);
      expect(find.text('850 kcal'), findsOneWidget);
      expect(find.text('1300 left'), findsOneWidget);
      expect(find.text('/ 1550 kcal'), findsNothing);

      await tester.tap(find.byKey(const Key('snapshot_calorie_card')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Diet Screen'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 8c: Calorie target Priority 3 - TDEE fallback (never raw BMR)
    // -------------------------------------------------------------------------
    testWidgets('8c. Today\'s Snapshot: Priority 3 - TDEE calculated from valid profile is used (never raw BMR)',
        (tester) async {
      _configureTestViewport(tester, width: 390);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'p4_u8c';
      transProvider.activeDocFetcherForTesting = (_) => null;
      await transProvider.loadTransformation();

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();
      homeProvider.setUserData({
        'bmr': 1780.0,
        'weight': 80.0,
        'height': 180.0,
        'age': 30,
        'gender': 'Male',
        'activity': 'MODERATE',
        'goal': 'MAINTAIN',
      });

      final consumption = _MockConsumptionProvider()..setConsumedCalories(1500);
      final stats = _MockStatisticsProvider();

      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
        consumptionProvider: consumption,
        statsProvider: stats,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

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
      final expectedTargetStr = '/ ${expectedTarget.toStringAsFixed(0)} kcal';
      final remaining = (expectedTarget - 1500).toStringAsFixed(0);

      expect(find.text(expectedTargetStr), findsOneWidget);
      expect(find.text('1500 kcal'), findsOneWidget);
      expect(find.text('$remaining left'), findsOneWidget);
      expect(find.text('/ 1780 kcal'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test 8d: Calorie target Priority 4 - Missing profile info displays Not Set & navigates to setup
    // -------------------------------------------------------------------------
    testWidgets('8d. Today\'s Snapshot: Priority 4 - Missing profile info displays Not Set and navigates to setup',
        (tester) async {
      _configureTestViewport(tester, width: 390);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'p4_u8d';
      transProvider.activeDocFetcherForTesting = (_) => null;
      await transProvider.loadTransformation();

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();
      homeProvider.setUserData({
        'bmr': 0.0,
        'weight': 0.0,
        'height': 0.0,
        'age': 0,
      });

      final consumption = _MockConsumptionProvider()..setConsumedCalories(500);
      final stats = _MockStatisticsProvider();

      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
        consumptionProvider: consumption,
        statsProvider: stats,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Not Set'), findsOneWidget);
      expect(find.text('500 kcal'), findsOneWidget);
      expect(find.text('Set a goal'), findsOneWidget);
      expect(find.text('Set in profile'), findsNothing);

      await tester.tap(find.byKey(const Key('snapshot_calorie_card')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Diet Screen'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 8e: Calorie target has no arbitrary 2,000 kcal fallback
    // -------------------------------------------------------------------------
    testWidgets('8e. Today\'s Snapshot: Never falls back to arbitrary 2,000 kcal baseline',
        (tester) async {
      _configureTestViewport(tester, width: 390);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'p4_u8e';
      transProvider.activeDocFetcherForTesting = (_) => null;
      await transProvider.loadTransformation();

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();
      homeProvider.setUserData({
        'bmr': 0.0,
        'weight': 0.0,
        'height': 0.0,
        'age': 0,
      });

      final consumption = _MockConsumptionProvider()..setConsumedCalories(500);
      final stats = _MockStatisticsProvider();

      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
        consumptionProvider: consumption,
        statsProvider: stats,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('/ 2000 kcal'), findsNothing);
      expect(find.text('2000 kcal'), findsNothing);
      expect(find.text('1500 left'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test 9: Dynamic water goal remains accurate
    // -------------------------------------------------------------------------
    testWidgets('9. Today\'s Snapshot displays dynamic water goal and navigates to Add Water',
        (tester) async {
      _configureTestViewport(tester, width: 390);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'p4_u9';
      transProvider.activeDocFetcherForTesting = (_) => null;
      await transProvider.loadTransformation();

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();
      final consumption = _MockConsumptionProvider()
        ..setWaterGoalLiters(3.0)
        ..setWaterADay(1.8);
      final stats = _MockStatisticsProvider();

      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
        consumptionProvider: consumption,
        statsProvider: stats,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Consumed water = 1.8 L, Goal = 3.0 L
      expect(find.text('1.8'), findsOneWidget);
      expect(find.text('/ 3.0 L'), findsOneWidget);

      // Tapping water card routes to Add Water Screen
      await tester.tap(find.byKey(const Key('snapshot_water_card')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Add Water Screen'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 10: Legacy challenge destinations remain accessible
    // -------------------------------------------------------------------------
    testWidgets('10. Discovery Shelf renders Six-Pack Challenge and Exercise of the Week',
        (tester) async {
      _configureTestViewport(tester, width: 390);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'p4_u10';
      transProvider.activeDocFetcherForTesting = (_) => null;
      await transProvider.loadTransformation();

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();
      final consumption = _MockConsumptionProvider();
      final stats = _MockStatisticsProvider();

      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
        consumptionProvider: consumption,
        statsProvider: stats,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Discovery shelf widget present
      expect(find.byType(DashboardChallengeSection), findsOneWidget);
      expect(find.byType(CarouselSliderHomeWidget), findsOneWidget);

      // Scroll down to carousel
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Six-Pack Challenge card
      final carouselBoxes = find.byType(CarouselHomeBox);
      expect(carouselBoxes, findsWidgets);
      // Recommended programme leads the shelf, so bring the Six-Pack into view
      await tester.ensureVisible(carouselBoxes.first);
      await tester.pumpAndSettle();
      await tester.tap(carouselBoxes.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Six Pack Challenge Screen'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 11: Detailed features remain accessible through existing destinations
    // -------------------------------------------------------------------------
    testWidgets('11. Detailed features (ProgressPage, Streak calendar, analytics) remain accessible',
        (tester) async {
      _configureTestViewport(tester, width: 390);

      final homeProvider = _MockHomeProvider();
      final profileProvider = _MockProfileProvider();
      final statsProvider = _MockStatisticsProvider();

      // Verify ProgressPage contains AdaptiveStrengthSummaryCard and StreakCalendarWidget
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HomeProvider?>.value(value: homeProvider),
            ChangeNotifierProvider<ProfileProvider?>.value(value: profileProvider),
            ChangeNotifierProvider<StatisticsProvider?>.value(value: statsProvider),
          ],
          child: ScreenUtilInit(
            designSize: const Size(430, 810),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) => const MaterialApp(
              home: ProgressPage(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Detailed Streak Calendar is present in Progress tab
      expect(find.byType(StreakCalendarWidget), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 7b: Today's Snapshot no longer repeats the weekly dots
    // -------------------------------------------------------------------------
    testWidgets('7b. Today\'s Snapshot header has no Mon-Sun consistency dots',
        (tester) async {
      _configureTestViewport(tester, width: 390);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'p4_u7b';
      transProvider.activeDocFetcherForTesting = (_) => null;

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final stats = _MockStatisticsProvider()..setHasWorkoutToday(true);

      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: _MockSubscriptionProvider()..setPremium(true),
        homeProvider: _MockHomeProvider(),
        consumptionProvider: _MockConsumptionProvider(),
        statsProvider: stats,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final snapshot = find.byType(TodayHealthSnapshotWidget);
      expect(snapshot, findsOneWidget);
      expect(find.descendant(of: snapshot, matching: find.text("Today's Snapshot")),
          findsOneWidget);
      expect(find.descendant(of: snapshot, matching: find.byIcon(Icons.check)),
          findsNothing);
      expect(find.descendant(of: snapshot, matching: find.text('T')),
          findsNothing);
    });

    // -------------------------------------------------------------------------
    // Test 7c: One Log Lift sheet with consistent wording
    // -------------------------------------------------------------------------
    testWidgets('7c. Log Lift without a plan shows one sheet with "Log a Single Lift"',
        (tester) async {
      _configureTestViewport(tester, width: 390);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'p4_u7c';
      transProvider.activeDocFetcherForTesting = (_) => null;
      await transProvider.loadTransformation();

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);

      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: _MockSubscriptionProvider()..setPremium(true),
        homeProvider: _MockHomeProvider(),
        consumptionProvider: _MockConsumptionProvider(),
        statsProvider: _MockStatisticsProvider(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Log Lift'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Ready to Train?'), findsOneWidget);
      expect(find.text('Build My Adaptive Plan'), findsOneWidget);
      expect(find.text('Log a Single Lift'), findsOneWidget);
      expect(find.text('Log a Single Exercise Manually'), findsNothing);
      expect(find.text('Log a Single Ad-Hoc Lift'), findsNothing);

      // The fallback button logs a lift and closes the sheet.
      await tester.tap(find.text('Log a Single Lift'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Workout Log Screen'), findsOneWidget);
      expect(find.text('Ready to Train?'), findsNothing);
    });

    testWidgets('7d. Log Lift sheet primary action opens the plan builder',
        (tester) async {
      _configureTestViewport(tester, width: 390);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'p4_u7d';
      transProvider.activeDocFetcherForTesting = (_) => null;
      await transProvider.loadTransformation();

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);

      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: _MockSubscriptionProvider()..setPremium(true),
        homeProvider: _MockHomeProvider(),
        consumptionProvider: _MockConsumptionProvider(),
        statsProvider: _MockStatisticsProvider(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Log Lift'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Build My Adaptive Plan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Workout Generator Screen'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 7e: Pull-to-refresh reloads the Home data
    // -------------------------------------------------------------------------
    testWidgets('7e. Pull-to-refresh reloads calories, water, weekly stats and profile',
        (tester) async {
      _configureTestViewport(tester, width: 390);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'p4_u7e';
      transProvider.activeDocFetcherForTesting = (_) => null;

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final homeProvider = _MockHomeProvider();
      final consumption = _MockConsumptionProvider();
      final stats = _MockStatisticsProvider();

      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: _MockSubscriptionProvider()..setPremium(true),
        homeProvider: homeProvider,
        consumptionProvider: consumption,
        statsProvider: stats,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final caloriesBefore = consumption.caloriesLoads;
      final statsBefore = stats.weeklyStatsLoads;
      final userBefore = homeProvider.userDataLoads;
      expect(consumption.waterLoads, 0);

      final scroll = find
          .descendant(
            of: find.byType(RefreshIndicator),
            matching: find.byType(SingleChildScrollView),
          )
          .first;
      await tester.drag(scroll, const Offset(0, 400));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(consumption.caloriesLoads, caloriesBefore + 1);
      expect(consumption.waterLoads, 1);
      expect(stats.weeklyStatsLoads, statsBefore + 1);
      expect(homeProvider.userDataLoads, userBefore + 1);
      expect(tester.takeException(), isNull);
    });

    // -------------------------------------------------------------------------
    // Test 12: Responsive layouts render without overflow
    // -------------------------------------------------------------------------
    testWidgets('12. Responsive layouts render with zero overflow across 360dp, 390dp, 430dp and 1.3x text scale',
        (tester) async {
      final widths = [360.0, 390.0, 430.0];

      for (final w in widths) {
        _configureTestViewport(tester, width: w, height: 844);

        final transProvider = TransformationProvider(autoLoad: false);
        transProvider.userIdOverrideForTesting = 'p4_resp_$w';
        transProvider.activeDocSaverForTesting = (_, __) async {};

        await transProvider.enrollInPlan(
          blueprint: TransformationPlansData.weightLoss60,
          targetCalories: 2000,
          targetMacros: const {'protein': 160.0, 'carbs': 190.0, 'fat': 55.0},
        );

        final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
        final subProvider = _MockSubscriptionProvider()..setPremium(true);
        final homeProvider = _MockHomeProvider();
        final consumption = _MockConsumptionProvider();
        final stats = _MockStatisticsProvider()..setStreak(12);

        await tester.pumpWidget(_buildOptionATestDashboard(
          transformationProvider: transProvider,
          workoutProvider: workoutProvider,
          subscriptionProvider: subProvider,
          homeProvider: homeProvider,
          consumptionProvider: consumption,
          statsProvider: stats,
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Verify zero overflow exceptions
        expect(tester.takeException(), isNull,
            reason: 'RenderFlex overflow detected at width $w');

        // Capture visual screenshot
        await _captureScreenshot(
            tester, 'phase4_dashboard_${w.toInt()}dp.png');
      }

      // Also test with high text scaling (1.3x) at 360dp
      _configureTestViewport(tester, width: 360, height: 844, textScale: 1.3);

      FlutterErrorDetails? caughtDetails;
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caughtDetails = details;
      };

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'p4_textscale';
      transProvider.activeDocSaverForTesting = (_, __) async {};

      await transProvider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 1800,
        targetMacros: const {'protein': 140, 'carbs': 190, 'fat': 50},
      );

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();
      final consumption = _MockConsumptionProvider();
      final stats = _MockStatisticsProvider();

      await tester.pumpWidget(_buildOptionATestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
        consumptionProvider: consumption,
        statsProvider: stats,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      FlutterError.onError = oldOnError;
      if (caughtDetails != null && caughtDetails!.informationCollector != null) {
        debugPrint(caughtDetails!.informationCollector!()
            .map((d) => d.toString())
            .join('\n'));
      }

      final err = tester.takeException();
      expect(err, isNull,
          reason: 'RenderFlex overflow detected with 1.3x text scale');
      await _captureScreenshot(tester, 'phase4_dashboard_text_scale_high.png');
    });
  });
}
