import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/model/workout_model.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_home_box.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_slider_home_widget.dart';
import 'package:fitness_app/presentation/home/widgets/dashboard_ai_workout_generator_card.dart';
import 'package:fitness_app/presentation/home/widgets/home_ai_routine_card.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/dashboard_challenge_section.dart';
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
  double get waterADay => 1500.0;

  @override
  double get waterGoalLiters => 2.5;

  @override
  int get consumedCalories => 1200;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockStatisticsProvider extends ChangeNotifier
    implements StatisticsProvider {
  @override
  int get currentStreak => 5;

  @override
  bool get hasActiveSchedule => false;

  @override
  bool get hasWorkoutToday => false;

  @override
  List<DateTime> get completedWorkoutDates => [];

  @override
  List<String> get scheduledDayNames => [];

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

Widget _buildTestDashboard({
  required TransformationProvider transformationProvider,
  required WorkoutProvider workoutProvider,
  required SubscriptionProvider subscriptionProvider,
  required HomeProvider homeProvider,
  List<RouteBase>? routes,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: routes ??
        [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: ScreenUtilInit(
                designSize: const Size(390, 844),
                minTextAdapt: true,
                builder: (context, child) => SingleChildScrollView(
                  child: Column(
                    children: const [
                      HomeAiRoutineCard(),
                      SizedBox(height: 12),
                      DashboardAiWorkoutGeneratorCard(),
                      SizedBox(height: 16),
                      DashboardChallengeSection(),
                    ],
                  ),
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
            path: Routes.transformationProgressRoute,
            builder: (context, state) =>
                const Scaffold(body: Text('Transformation Progress Screen')),
          ),
          GoRoute(
            path: Routes.transformationCompletionRoute,
            builder: (context, state) =>
                const Scaffold(body: Text('Transformation Completion Screen')),
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
            path: Routes.transformationPlanDetailRoute,
            builder: (context, state) =>
                const Scaffold(body: Text('Plan Detail Screen')),
          ),
          GoRoute(
            path: Routes.premiumScreen,
            builder: (context, state) =>
                const Scaffold(body: Text('Premium Screen')),
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
      ChangeNotifierProvider<ConsumptionProvider?>.value(
          value: _MockConsumptionProvider()),
      ChangeNotifierProvider<StatisticsProvider?>.value(
          value: _MockStatisticsProvider()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Gym Buddy Dashboard Redesign Phase 3 — Duplicate Presentation Tests',
      () {
    // -------------------------------------------------------------------------
    // Scenario 1: New user with no active transformation
    // -------------------------------------------------------------------------
    testWidgets(
        '1. New user with no active transformation: Hero shows Priority 3, Challenge shows Featured card, zero duplicates',
        (tester) async {
      _configureTestViewport(tester);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'test_user_1';
      transProvider.activeDocFetcherForTesting = (_) => null;
      await transProvider.loadTransformation();

      final workoutProvider = WorkoutProvider()
        ..setAllWorkoutsForTesting([]); // No AI routine workouts
      final subProvider = _MockSubscriptionProvider()..setPremium(false);
      final homeProvider = _MockHomeProvider();

      await tester.pumpWidget(_buildTestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
      ));
      await tester.pumpAndSettle();

      // 1. Primary Workout Hero renders Priority 3 (AI Builder / Onboarding)
      expect(find.byType(HomeAiRoutineCard), findsOneWidget);
      expect(find.textContaining('Plan'), findsWidgets);
      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
      expect(find.textContaining('DAY 1 OF'), findsNothing);

      // 2. AI Workout Generator card collapses to avoid competing with Hero AI Builder
      expect(find.byType(DashboardAiWorkoutGeneratorCard), findsOneWidget);
      expect(find.text('AI WORKOUT GENERATOR'), findsNothing);

      // 3. Challenge section renders header with View All
      expect(find.text('Challenges'), findsOneWidget);
      expect(
          find.byKey(const Key('view_all_challenges_button')), findsOneWidget);

      // 4. Featured challenge card renders with PRO badge & Explore CTA
      expect(find.byKey(const Key('featured_challenge_card')), findsOneWidget);
      expect(find.text('FEATURED PROGRAMME'), findsOneWidget);
      expect(find.byKey(const Key('explore_challenge_cta')), findsOneWidget);

      // 5. Active challenge card is NOT present
      expect(find.byKey(const Key('active_challenge_card')), findsNothing);

      // 6. Mini Challenges & Technique carousel remains rendered
      expect(find.text('Mini Challenges & Technique'), findsOneWidget);
      expect(find.byType(CarouselSliderHomeWidget), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 2: User with an active transformation
    // -------------------------------------------------------------------------
    testWidgets(
        '2. User with an active transformation: Hero shows Priority 1, active card suppressed in challenges (rendered ONLY ONCE)',
        (tester) async {
      _configureTestViewport(tester);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'test_user_2';
      transProvider.activeDocSaverForTesting = (_, __) async {};

      await transProvider.enrollInPlan(
        blueprint: TransformationPlansData.weightLoss60,
        targetCalories: 2000,
        targetMacros: const {'protein': 160.0, 'carbs': 190.0, 'fat': 55.0},
      );

      final workoutProvider = WorkoutProvider()
        ..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();

      await tester.pumpWidget(_buildTestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
      ));
      await tester.pumpAndSettle();

      // 1. Primary Hero displays active transformation
      expect(find.byType(HomeAiRoutineCard), findsOneWidget);
      expect(find.text(TransformationPlansData.weightLoss60.title), findsOneWidget);
      expect(find.text('DAY 1 OF 60'), findsOneWidget);
      expect(find.text('START DAY 1 WORKOUT'), findsOneWidget);

      // 2. AI Workout Generator card remains visible alongside
      expect(find.byType(DashboardAiWorkoutGeneratorCard), findsOneWidget);

      // 3. Duplicate active challenge card is SUPPRESSED in DashboardChallengeSection
      expect(find.byKey(const Key('active_challenge_card')), findsNothing);

      // 4. Featured challenge card is NOT rendered either
      expect(find.byKey(const Key('featured_challenge_card')), findsNothing);

      // 5. Active transformation appears prominently EXACTLY ONCE on the dashboard
      expect(find.text(TransformationPlansData.weightLoss60.title), findsOneWidget);

      // 6. Challenges Header and Mini Challenges carousel remain visible and accessible
      expect(find.text('Challenges'), findsOneWidget);
      expect(
          find.byKey(const Key('view_all_challenges_button')), findsOneWidget);
      expect(find.text('Mini Challenges & Technique'), findsOneWidget);
      expect(find.byType(CarouselSliderHomeWidget), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 3: User on a transformation rest day
    // -------------------------------------------------------------------------
    testWidgets(
        '3. User on a transformation rest day: Hero shows Rest Day guidance, duplicate suppressed in challenges',
        (tester) async {
      _configureTestViewport(tester);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'test_user_3';
      transProvider.activeDocSaverForTesting = (_, __) async {};

      await transProvider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 140.0, 'carbs': 200.0, 'fat': 50.0},
      );

      // Advance currentDay to Day 7 (scheduled rest day in beginnerFitness30)
      await transProvider.setCurrentDay(7);

      final workoutProvider = WorkoutProvider()
        ..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();

      await tester.pumpWidget(_buildTestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
      ));
      await tester.pumpAndSettle();

      // 1. Primary Hero displays Rest Day state
      expect(find.byType(HomeAiRoutineCard), findsOneWidget);
      expect(find.text('DAY 7 • REST DAY'), findsOneWidget);
      expect(find.text('Rest & Muscle Repair'), findsOneWidget);
      expect(find.text('VIEW PROGRAMME ROADMAP'), findsOneWidget);
      expect(find.text('START DAY 7 WORKOUT'), findsNothing);

      // 2. Duplicate card in challenges section is SUPPRESSED
      expect(find.byKey(const Key('active_challenge_card')), findsNothing);

      // 3. Transformation plan title appears prominently ONLY ONCE
      expect(find.text(TransformationPlansData.beginnerFitness30.title), findsOneWidget);

      // 4. Mini challenges carousel is present
      expect(find.text('Mini Challenges & Technique'), findsOneWidget);
      expect(find.byType(CarouselSliderHomeWidget), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 4: User with an active AI routine but no transformation
    // -------------------------------------------------------------------------
    testWidgets(
        '4. User with an active AI routine but no transformation: Hero shows Priority 2 AI Split, challenges show discovery',
        (tester) async {
      _configureTestViewport(tester);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'test_user_4';
      transProvider.activeDocFetcherForTesting = (_) => null;
      await transProvider.loadTransformation();

      final monday = DateTime(2026, 3, 16, 10, 0); // Monday
      final workoutProvider = WorkoutProvider()
        ..setNowProviderForTesting(() => monday)
        ..setAllWorkoutsForTesting(_buildThreeDaySplitWorkouts(monday));

      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();

      await tester.pumpWidget(_buildTestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
      ));
      await tester.pumpAndSettle();

      // 1. Primary Hero shows Priority 2 AI routine scroller hub
      expect(find.byType(HomeAiRoutineCard), findsOneWidget);
      expect(find.text('AI Workout Schedule'), findsOneWidget);
      expect(find.text('Monday Routine'), findsOneWidget);
      expect(find.textContaining('3-Day Split'), findsOneWidget);

      // 2. AI Generator companion card is present
      expect(find.byType(DashboardAiWorkoutGeneratorCard), findsOneWidget);

      // 3. Challenge section shows discovery recommended card (no active transformation)
      expect(find.byKey(const Key('featured_challenge_card')), findsOneWidget);
      expect(find.byKey(const Key('active_challenge_card')), findsNothing);

      // 4. Mini challenges carousel is present
      expect(find.text('Mini Challenges & Technique'), findsOneWidget);
      expect(find.byType(CarouselSliderHomeWidget), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 5: User with a completed transformation
    // -------------------------------------------------------------------------
    testWidgets(
        '5. User with a completed transformation: History card in challenges with View Results, no duplicate hero',
        (tester) async {
      _configureTestViewport(tester);

      final completedState = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Weight Loss Challenge',
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        targetEndDate: DateTime.now(),
        currentDay: 60,
        totalDays: 60,
        status: 'completed',
        completedDayIndices: List.generate(60, (i) => i + 1),
        targetCalories: 2000,
        targetMacros: const {'protein': 160, 'carbs': 190, 'fat': 55},
        completedAt: DateTime.now(),
      );

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'test_user_5';
      transProvider.activeDocFetcherForTesting = (_) => null;
      transProvider.history.add(completedState);

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();

      await tester.pumpWidget(_buildTestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
      ));
      await tester.pumpAndSettle();

      // 1. Primary Hero does NOT show active transformation (user has none)
      expect(find.text('ACTIVE TRANSFORMATION'), findsNothing);
      expect(find.textContaining('DAY 1 OF'), findsNothing);

      // 2. Challenge section shows completed challenge card
      expect(find.byKey(const Key('completed_challenge_card')), findsOneWidget);
      expect(find.text('PROGRAMME COMPLETED 🏆'), findsOneWidget);
      expect(find.byKey(const Key('view_results_cta')), findsOneWidget);
      expect(find.byKey(const Key('explore_another_challenge_cta')),
          findsOneWidget);

      // 3. Completed transformation is NOT duplicated anywhere on the dashboard
      expect(find.text('60-Day Weight Loss Challenge'), findsOneWidget);

      // 4. Tapping View Results navigates to transformation completion screen
      await tester.tap(find.byKey(const Key('view_results_cta')));
      await tester.pumpAndSettle();

      expect(find.text('Transformation Completion Screen'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 6: User with an expired premium subscription and retained history
    // -------------------------------------------------------------------------
    testWidgets(
        '6. User with expired subscription and retained history: History remains accessible, paywall enforced on enrollment',
        (tester) async {
      _configureTestViewport(tester);

      final completedState = UserTransformationState(
        planId: 'strength_12_week',
        planTitle: '12-Week Strength Building Challenge',
        startDate: DateTime.now().subtract(const Duration(days: 84)),
        targetEndDate: DateTime.now(),
        currentDay: 84,
        totalDays: 84,
        status: 'completed',
        completedDayIndices: List.generate(84, (i) => i + 1),
        targetCalories: 2600,
        targetMacros: const {'protein': 180, 'carbs': 280, 'fat': 70},
        completedAt: DateTime.now(),
      );

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'test_user_6';
      transProvider.activeDocFetcherForTesting = (_) => null;
      transProvider.history.add(completedState);

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(false); // Free/expired
      final homeProvider = _MockHomeProvider();

      await tester.pumpWidget(_buildTestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
      ));
      await tester.pumpAndSettle();

      // 1. Completed history is retained and accessible via View Results
      expect(find.byKey(const Key('completed_challenge_card')), findsOneWidget);
      expect(find.text('12-Week Strength Building Challenge'), findsOneWidget);
      expect(find.byKey(const Key('view_results_cta')), findsOneWidget);

      // 2. Hero does not display active transformation
      expect(find.text('ACTIVE TRANSFORMATION'), findsNothing);

      // 3. Enrolling in a plan without premium is strictly rejected with error and zero writes
      await transProvider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 150, 'carbs': 200, 'fat': 60},
        subscriptionProvider: subProvider,
      );
      expect(transProvider.error,
          contains('Active Premium subscription required'));
      expect(transProvider.hasActiveTransformation, isFalse);
    });

    // -------------------------------------------------------------------------
    // Scenario 7: Free user without a transformation
    // -------------------------------------------------------------------------
    testWidgets(
        '7. Free user without a transformation: Featured card displays PRO badge, CTA routes to detail screen',
        (tester) async {
      _configureTestViewport(tester);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'test_user_7';
      transProvider.activeDocFetcherForTesting = (_) => null;
      await transProvider.loadTransformation();

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(false);
      final homeProvider = _MockHomeProvider();

      await tester.pumpWidget(_buildTestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
      ));
      await tester.pumpAndSettle();

      // 1. Featured card displays PRO badge
      expect(find.byKey(const Key('featured_challenge_card')), findsOneWidget);
      expect(find.text('PRO'), findsWidgets);

      // 2. Active challenge card is NOT present
      expect(find.byKey(const Key('active_challenge_card')), findsNothing);

      // 3. Tapping Explore Challenge navigates to plan detail
      await tester.tap(find.byKey(const Key('explore_challenge_cta')));
      await tester.pumpAndSettle();

      expect(find.text('Plan Detail Screen'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 8: User with legacy Six-Pack and Exercise of the Week challenges
    // -------------------------------------------------------------------------
    testWidgets(
        '8. User with legacy Six-Pack and Exercise of the Week: Carousel is fully accessible & navigates cleanly',
        (tester) async {
      _configureTestViewport(tester);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'test_user_8';
      transProvider.activeDocSaverForTesting = (_, __) async {};

      await transProvider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 1800,
        targetMacros: const {'protein': 120, 'carbs': 180, 'fat': 50},
      );

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();

      await tester.pumpWidget(_buildTestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
      ));
      await tester.pumpAndSettle();

      // Scroll down to make the Carousel fully visible and tappable
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // 1. Carousel widget is present and visible
      expect(find.byType(CarouselSliderHomeWidget), findsOneWidget);
      expect(find.text('Mini Challenges & Technique'), findsOneWidget);

      // 2. CarouselHomeBox card is present in carousel
      final carouselBoxes = find.byType(CarouselHomeBox);
      expect(carouselBoxes, findsWidgets);

      // 3. Six-Pack challenge card is accessible and tapping it navigates to SixPackChallengeRoute
      await tester.tap(carouselBoxes.first);
      await tester.pumpAndSettle();

      expect(find.text('Six Pack Challenge Screen'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 9: Active transformation with valid premium — hero shows play icon
    // -------------------------------------------------------------------------
    testWidgets(
        '9. Active transformation with valid premium: Hero shows play icon, workout button not locked',
        (tester) async {
      _configureTestViewport(tester);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'test_user_9';
      transProvider.activeDocSaverForTesting = (_, __) async {};

      await transProvider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 140, 'carbs': 200, 'fat': 50},
      );

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();

      await tester.pumpWidget(_buildTestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
      ));
      await tester.pumpAndSettle();

      // 1. Hero shows the active transformation badge
      expect(find.byType(HomeAiRoutineCard), findsOneWidget);
      expect(find.text('DAY 1 OF 30'), findsOneWidget);

      // 2. Start Workout button shows play icon, NOT lock icon
      expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);
      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);

      // 3. CTA label is shown (premium user gets full access)
      expect(find.text('START DAY 1 WORKOUT'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 10: Active transformation with expired premium — hero preserved
    // -------------------------------------------------------------------------
    testWidgets(
        '10. Expired premium with active transformation: Hero preserved, transformation NOT removed',
        (tester) async {
      _configureTestViewport(tester);

      // Step 1: Enrol while premium is true
      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'test_user_10';
      transProvider.activeDocSaverForTesting = (_, __) async {};
      transProvider.entitlementOverrideForTesting = true; // bypass entitlement for enrol

      await transProvider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 140, 'carbs': 200, 'fat': 50},
      );

      // Step 2: Revert entitlement override (simulate expiry)
      transProvider.entitlementOverrideForTesting = null;

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      // Subscription is now expired/free
      final subProvider = _MockSubscriptionProvider()..setPremium(false);
      final homeProvider = _MockHomeProvider();

      await tester.pumpWidget(_buildTestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
      ));
      await tester.pumpAndSettle();

      // 1. The active transformation is still present — expiry does NOT remove it
      expect(transProvider.hasActiveTransformation, isTrue);
      expect(find.byType(HomeAiRoutineCard), findsOneWidget);
      expect(find.text('DAY 1 OF 30'), findsOneWidget);
      expect(find.text(TransformationPlansData.beginnerFitness30.title),
          findsOneWidget);

      // 2. No automatic archiving — history remains empty
      expect(transProvider.history, isEmpty);

      // 3. Workout execution button now shows lock icon (paywall enforced)
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 11: Expired premium user — roadmap remains accessible
    // -------------------------------------------------------------------------
    testWidgets(
        '11. Expired premium user: Roadmap button is accessible despite expired subscription',
        (tester) async {
      _configureTestViewport(tester);

      // Enrol with entitlement override, then expire subscription
      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'test_user_11';
      transProvider.activeDocSaverForTesting = (_, __) async {};
      transProvider.entitlementOverrideForTesting = true;

      await transProvider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 140, 'carbs': 200, 'fat': 50},
      );
      transProvider.entitlementOverrideForTesting = null;

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(false);
      final homeProvider = _MockHomeProvider();

      await tester.pumpWidget(_buildTestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
      ));
      await tester.pumpAndSettle();

      // The 'Roadmap' InkWell is always rendered regardless of subscription
      expect(find.text('Roadmap'), findsOneWidget);

      // Tapping Roadmap navigates to the roadmap screen (no paywall)
      await tester.tap(find.text('Roadmap'));
      await tester.pumpAndSettle();

      expect(find.text('Transformation Roadmap Screen'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 12: Expired premium user — workout execution redirects to paywall
    // -------------------------------------------------------------------------
    testWidgets(
        '12. Expired premium user: Tapping workout CTA redirects to Premium Screen',
        (tester) async {
      _configureTestViewport(tester);

      // Enrol with entitlement override, then expire subscription
      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'test_user_12';
      transProvider.activeDocSaverForTesting = (_, __) async {};
      transProvider.entitlementOverrideForTesting = true;

      await transProvider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 140, 'carbs': 200, 'fat': 50},
      );
      transProvider.entitlementOverrideForTesting = null;

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(false);
      final homeProvider = _MockHomeProvider();

      await tester.pumpWidget(_buildTestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
      ));
      await tester.pumpAndSettle();

      // Verify the lock icon is shown on the CTA button (non-premium state)
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

      // Tap the CTA button (locked state routes to premium screen)
      await tester.tap(find.text('START DAY 1 WORKOUT'));
      await tester.pumpAndSettle();

      // No workout launched — user is on the premium paywall screen
      expect(find.text('Premium Screen'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 13: Expired/free user cannot enrol in a new premium plan
    // -------------------------------------------------------------------------
    testWidgets(
        '13. Free user cannot enrol in a new plan: enrollInPlan rejects with error, no transformation set',
        (tester) async {
      _configureTestViewport(tester);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'test_user_13';
      transProvider.activeDocSaverForTesting = (_, __) async {};
      // No entitlement override — real subscription check applies

      final subProvider = _MockSubscriptionProvider()..setPremium(false);

      await transProvider.enrollInPlan(
        blueprint: TransformationPlansData.muscleBuilding90,
        targetCalories: 2500,
        targetMacros: const {'protein': 180, 'carbs': 270, 'fat': 65},
        subscriptionProvider: subProvider,
      );

      // Enrolment must be rejected
      expect(transProvider.error, isNotNull);
      expect(transProvider.error,
          contains('Active Premium subscription required'));
      expect(transProvider.hasActiveTransformation, isFalse);
    });

    // -------------------------------------------------------------------------
    // Scenario 14: Completed transformation card shows View Results navigation
    // -------------------------------------------------------------------------
    testWidgets(
        '14. Completed transformation: View Results navigates to Transformation Completion Screen',
        (tester) async {
      _configureTestViewport(tester);

      final completedState = UserTransformationState(
        planId: 'beginner_fitness_30',
        planTitle: '30-Day Beginner Fitness Challenge',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        targetEndDate: DateTime.now(),
        currentDay: 30,
        totalDays: 30,
        status: 'completed',
        completedDayIndices: List.generate(30, (i) => i + 1),
        targetCalories: 1800,
        targetMacros: const {'protein': 120, 'carbs': 200, 'fat': 50},
        completedAt: DateTime.now(),
      );

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'test_user_14';
      transProvider.activeDocFetcherForTesting = (_) => null;
      transProvider.history.add(completedState);

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(true);
      final homeProvider = _MockHomeProvider();

      await tester.pumpWidget(_buildTestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
      ));
      await tester.pumpAndSettle();

      // Completed card is rendered
      expect(find.byKey(const Key('completed_challenge_card')), findsOneWidget);
      expect(find.text('30-Day Beginner Fitness Challenge'), findsOneWidget);
      expect(find.text('PROGRAMME COMPLETED 🏆'), findsOneWidget);

      // View Results CTA is tappable and navigates to completion screen
      expect(find.byKey(const Key('view_results_cta')), findsOneWidget);
      await tester.tap(find.byKey(const Key('view_results_cta')));
      await tester.pumpAndSettle();

      expect(find.text('Transformation Completion Screen'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 15: Six-Pack Challenge explicit navigation assertion
    // -------------------------------------------------------------------------
    testWidgets(
        '15. Six-Pack Challenge: Carousel card routes to Six Pack Challenge Screen',
        (tester) async {
      _configureTestViewport(tester);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'test_user_15';
      transProvider.activeDocFetcherForTesting = (_) => null;
      await transProvider.loadTransformation();

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(false);
      final homeProvider = _MockHomeProvider();

      await tester.pumpWidget(_buildTestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
      ));
      await tester.pumpAndSettle();

      // Scroll down so carousel is fully in viewport
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // Carousel widget is rendered
      expect(find.byType(CarouselSliderHomeWidget), findsOneWidget);

      // The Six-Pack card is the first (default visible) carousel card
      final carouselBoxes = find.byType(CarouselHomeBox);
      expect(carouselBoxes, findsWidgets);
      expect(find.text('30 day Six Pack Challenge'), findsOneWidget);

      // Tap the first visible carousel card
      await tester.tap(carouselBoxes.first);
      await tester.pumpAndSettle();

      expect(find.text('Six Pack Challenge Screen'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 16: Exercise of the Week explicit navigation assertion
    // -------------------------------------------------------------------------
    testWidgets(
        '16. Exercise of the Week: Swiping carousel to second card routes to Exercise Detail Screen',
        (tester) async {
      _configureTestViewport(tester);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'test_user_16';
      transProvider.activeDocFetcherForTesting = (_) => null;
      await transProvider.loadTransformation();

      final workoutProvider = WorkoutProvider()..setAllWorkoutsForTesting([]);
      final subProvider = _MockSubscriptionProvider()..setPremium(false);
      final homeProvider = _MockHomeProvider();

      await tester.pumpWidget(_buildTestDashboard(
        transformationProvider: transProvider,
        workoutProvider: workoutProvider,
        subscriptionProvider: subProvider,
        homeProvider: homeProvider,
      ));
      await tester.pumpAndSettle();

      // Scroll down so carousel is in viewport
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.byType(CarouselSliderHomeWidget), findsOneWidget);

      // Swipe the carousel left to reveal the Exercise of the Week card
      await tester.drag(
          find.byType(CarouselSliderHomeWidget), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Exercise of the Week card is now visible
      expect(find.text('Exercise of the week'), findsOneWidget);

      // Tap the now-visible CarouselHomeBox
      final carouselBoxes = find.byType(CarouselHomeBox);
      await tester.tap(carouselBoxes.first);
      await tester.pumpAndSettle();

      expect(find.text('Exercise Detail Screen'), findsOneWidget);
    });
  });
}
