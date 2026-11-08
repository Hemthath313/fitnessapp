import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/custom_workouts/workout_session_launcher_page.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/home_ai_routine_card.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_hub_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_onboarding_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_plan_detail_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_roadmap_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/dashboard_challenge_section.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/utils/router/router.dart';

class _MockSubscriptionProvider extends ChangeNotifier
    implements SubscriptionProvider {
  bool _isPremium;
  bool _isLifetime;

  _MockSubscriptionProvider({
    bool isPremium = false,
    bool isLifetime = false,
  })  : _isPremium = isPremium,
        _isLifetime = isLifetime;

  @override
  bool get isPremium => _isPremium;

  @override
  bool get isLifetime => _isLifetime;

  void setPremium(bool val, {bool isLifetime = false}) {
    _isPremium = val;
    _isLifetime = isLifetime;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHomeProvider extends ChangeNotifier implements HomeProvider {
  final Map<String, dynamic> _userData = {
    'name': 'Athlete',
    'age': 28,
    'weight': 80.0,
    'height': 180.0,
    'gender': 'Male',
    'activity_level': 'MODERATE',
  };

  @override
  Map<String, dynamic> get userData => _userData;

  @override
  Future<Map<String, dynamic>> fetchUserData() async => _userData;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockStatisticsProvider extends ChangeNotifier
    implements StatisticsProvider {
  @override
  int get currentStreak => 7;

  @override
  List<String> get scheduledDayNames => const ['Monday', 'Wednesday', 'Friday'];

  @override
  bool get hasActiveSchedule => true;

  @override
  bool get hasWorkoutToday => false;

  @override
  Future<Map<String, dynamic>> getWeeklyStats() async => {};

  @override
  List<String> consumeNewlyUnlocked() => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockConsumptionProvider extends ChangeNotifier
    implements ConsumptionProvider {
  @override
  double get waterADay => 2500.0;

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

Widget _buildTestHarness({
  required Widget child,
  required SubscriptionProvider subscriptionProvider,
  TransformationProvider? transformationProvider,
  WorkoutProvider? workoutProvider,
}) {
  final tp = transformationProvider ?? TransformationProvider(autoLoad: false);
  final wp = workoutProvider ?? WorkoutProvider();

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Material(child: child),
      ),
      GoRoute(
        path: Routes.premiumScreen,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('PREMIUM_SCREEN_DESTINATION')),
        ),
      ),
      GoRoute(
        path: Routes.transformationOnboardingRoute,
        builder: (context, state) {
          final planId = state.uri.queryParameters['planId'];
          return TransformationOnboardingScreen(planId: planId);
        },
      ),
      GoRoute(
        path: Routes.transformationRoadmapRoute,
        builder: (context, state) => const TransformationRoadmapScreen(),
      ),
      GoRoute(
        path: Routes.transformationPlansRoute,
        builder: (context, state) => const TransformationHubScreen(),
      ),
      GoRoute(
        path: Routes.transformationPlanDetailRoute,
        builder: (context, state) {
          final planId = state.uri.queryParameters['planId'];
          return TransformationPlanDetailScreen(planId: planId);
        },
      ),
      GoRoute(
        path: Routes.dayWorkoutSessionRoute,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('DAY_WORKOUT_SESSION_DESTINATION')),
        ),
      ),
      GoRoute(
        path: '/sessionLauncher',
        builder: (context, state) {
          final planId = state.uri.queryParameters['planId'];
          return WorkoutSessionLauncherPage(
            dayName: 'Day 1',
            planId: planId,
            planDay: 1,
            initialWorkouts: const [],
          );
        },
      ),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SubscriptionProvider>.value(value: subscriptionProvider),
      ChangeNotifierProvider<TransformationProvider>.value(value: tp),
      ChangeNotifierProvider<WorkoutProvider>.value(value: wp),
      ChangeNotifierProvider<HomeProvider>(create: (_) => _MockHomeProvider()),
      ChangeNotifierProvider<StatisticsProvider>(create: (_) => _MockStatisticsProvider()),
      ChangeNotifierProvider<ConsumptionProvider>(create: (_) => _MockConsumptionProvider()),
    ],
    child: ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (_, __) => MaterialApp.router(
        routerConfig: router,
        theme: ThemeData.dark(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TransformationProvider.defaultEntitlementForTesting = false;
  });

  tearDown(() {
    TransformationProvider.defaultEntitlementForTesting = true;
  });

  group('Transformation Premium Subscription Gating Suite', () {
    // -------------------------------------------------------------------------
    // Scenario 1: Free user cannot start Beginner Fitness
    // -------------------------------------------------------------------------
    testWidgets('Scenario 1: Free user cannot start Beginner Fitness (redirects to PremiumScreen)', (tester) async {
      _configureTestViewport(tester);

      final subProvider = _MockSubscriptionProvider(isPremium: false);
      final transProvider = TransformationProvider(autoLoad: false);

      await tester.pumpWidget(_buildTestHarness(
        child: const TransformationPlanDetailScreen(planId: 'beginner_fitness_30'),
        subscriptionProvider: subProvider,
        transformationProvider: transProvider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Complete Beginner – 30 Days'), findsOneWidget);
      final cta = find.byKey(const Key('plan_detail_bottom_cta'));
      expect(cta, findsOneWidget);

      await tester.tap(cta);
      await tester.pumpAndSettle();

      expect(find.text('PREMIUM_SCREEN_DESTINATION'), findsOneWidget);
      expect(transProvider.hasActiveTransformation, isFalse);
    });

    // -------------------------------------------------------------------------
    // Scenario 2: Free user cannot start Weight Loss
    // -------------------------------------------------------------------------
    testWidgets('Scenario 2: Free user cannot start Weight Loss (redirects to PremiumScreen)', (tester) async {
      _configureTestViewport(tester);

      final subProvider = _MockSubscriptionProvider(isPremium: false);
      final transProvider = TransformationProvider(autoLoad: false);

      await tester.pumpWidget(_buildTestHarness(
        child: const TransformationPlanDetailScreen(planId: 'weight_loss_60'),
        subscriptionProvider: subProvider,
        transformationProvider: transProvider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('60-Day Weight Loss Challenge'), findsOneWidget);
      final cta = find.byKey(const Key('plan_detail_bottom_cta'));
      expect(cta, findsOneWidget);

      await tester.tap(cta);
      await tester.pumpAndSettle();

      expect(find.text('PREMIUM_SCREEN_DESTINATION'), findsOneWidget);
      expect(transProvider.hasActiveTransformation, isFalse);
    });

    // -------------------------------------------------------------------------
    // Scenario 3: Free user cannot start Muscle Building
    // -------------------------------------------------------------------------
    testWidgets('Scenario 3: Free user cannot start Muscle Building (redirects to PremiumScreen)', (tester) async {
      _configureTestViewport(tester);

      final subProvider = _MockSubscriptionProvider(isPremium: false);
      final transProvider = TransformationProvider(autoLoad: false);

      await tester.pumpWidget(_buildTestHarness(
        child: const TransformationPlanDetailScreen(planId: 'muscle_building_90'),
        subscriptionProvider: subProvider,
        transformationProvider: transProvider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('90-Day Muscle Building Challenge'), findsOneWidget);
      final cta = find.byKey(const Key('plan_detail_bottom_cta'));
      expect(cta, findsOneWidget);

      await tester.tap(cta);
      await tester.pumpAndSettle();

      expect(find.text('PREMIUM_SCREEN_DESTINATION'), findsOneWidget);
      expect(transProvider.hasActiveTransformation, isFalse);
    });

    // -------------------------------------------------------------------------
    // Scenario 4: Free user cannot start Strength Building
    // -------------------------------------------------------------------------
    testWidgets('Scenario 4: Free user cannot start Strength Building (redirects to PremiumScreen)', (tester) async {
      _configureTestViewport(tester);

      final subProvider = _MockSubscriptionProvider(isPremium: false);
      final transProvider = TransformationProvider(autoLoad: false);

      await tester.pumpWidget(_buildTestHarness(
        child: const TransformationPlanDetailScreen(planId: 'strength_12_week'),
        subscriptionProvider: subProvider,
        transformationProvider: transProvider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('12-Week Strength Building Challenge'), findsOneWidget);
      final cta = find.byKey(const Key('plan_detail_bottom_cta'));
      expect(cta, findsOneWidget);

      await tester.tap(cta);
      await tester.pumpAndSettle();

      expect(find.text('PREMIUM_SCREEN_DESTINATION'), findsOneWidget);
      expect(transProvider.hasActiveTransformation, isFalse);
    });

    // -------------------------------------------------------------------------
    // Scenario 5: Direct navigation to onboarding is intercepted for free user
    // -------------------------------------------------------------------------
    testWidgets('Scenario 5: Free user cannot bypass paywall via direct route to onboarding', (tester) async {
      _configureTestViewport(tester);

      final subProvider = _MockSubscriptionProvider(isPremium: false);
      final transProvider = TransformationProvider(autoLoad: false);

      await tester.pumpWidget(_buildTestHarness(
        child: const TransformationOnboardingScreen(planId: 'strength_12_week'),
        subscriptionProvider: subProvider,
        transformationProvider: transProvider,
      ));
      await tester.pumpAndSettle();

      // Post-frame callback immediately redirects free user away from onboarding
      expect(find.text('PREMIUM_SCREEN_DESTINATION'), findsOneWidget);
      expect(transProvider.hasActiveTransformation, isFalse);
    });

    // -------------------------------------------------------------------------
    // Scenario 6A: Provider enrollment when entitlement argument is omitted
    // -------------------------------------------------------------------------
    testWidgets('Scenario 6A: Provider enrollment when entitlement argument is omitted fails for free user with zero writes', (tester) async {
      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'free_user_omitted_arg';
      bool batchExecuted = false;
      transProvider.batchCommitForTesting = (uid,
          {activeData,
          bool deleteActive = false,
          historyData,
          historyDocId}) async {
        batchExecuted = true;
      };

      // Call enrollInPlan with subscriptionProvider omitted!
      await transProvider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 140.0, 'carbs': 200.0, 'fat': 50.0},
      );

      expect(batchExecuted, isFalse);
      expect(transProvider.hasActiveTransformation, isFalse);
      expect(transProvider.error, contains('Active Premium subscription required'));
    });

    // -------------------------------------------------------------------------
    // Scenario 6B: Free user attempts to enroll through provider with free SubscriptionProvider
    // -------------------------------------------------------------------------
    testWidgets('Scenario 6B: Provider rejects enrollment with free SubscriptionProvider instance with zero writes', (tester) async {
      final freeSub = _MockSubscriptionProvider(isPremium: false);
      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'free_user_with_free_sub';
      bool batchExecuted = false;
      transProvider.batchCommitForTesting = (uid,
          {activeData,
          bool deleteActive = false,
          historyData,
          historyDocId}) async {
        batchExecuted = true;
      };

      await transProvider.enrollInPlan(
        blueprint: TransformationPlansData.weightLoss60,
        targetCalories: 1800,
        targetMacros: const {'protein': 150.0, 'carbs': 180.0, 'fat': 45.0},
        subscriptionProvider: freeSub,
      );

      expect(batchExecuted, isFalse);
      expect(transProvider.hasActiveTransformation, isFalse);
      expect(transProvider.error, contains('Active Premium subscription required'));
    });

    // -------------------------------------------------------------------------
    // Scenario 6C: Free user direct navigation to transformation workout session launcher
    // -------------------------------------------------------------------------
    testWidgets('Scenario 6C: Free user direct navigation to transformation workout intercepts to paywall', (tester) async {
      _configureTestViewport(tester);

      final freeSub = _MockSubscriptionProvider(isPremium: false);
      final transProvider = TransformationProvider(autoLoad: false);

      await tester.pumpWidget(_buildTestHarness(
        child: const WorkoutSessionLauncherPage(
          dayName: 'Day 1',
          planId: 'beginner_fitness_30',
          planDay: 1,
          initialWorkouts: [],
        ),
        subscriptionProvider: freeSub,
        transformationProvider: transProvider,
      ));
      await tester.pumpAndSettle();

      // Intercepted and replaced route with PremiumScreen!
      expect(find.text('PREMIUM_SCREEN_DESTINATION'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Scenario 7: Active premium user can access all four programmes
    // -------------------------------------------------------------------------
    testWidgets('Scenario 7: Active premium user can access and start all four programmes', (tester) async {
      _configureTestViewport(tester);

      final subProvider = _MockSubscriptionProvider(isPremium: true);

      for (final plan in TransformationPlansData.allPlans) {
        final transProvider = TransformationProvider(autoLoad: false);

        await tester.pumpWidget(_buildTestHarness(
          child: TransformationPlanDetailScreen(planId: plan.id),
          subscriptionProvider: subProvider,
          transformationProvider: transProvider,
        ));
        await tester.pumpAndSettle();

        expect(find.text(plan.title), findsOneWidget);
        final cta = find.byKey(const Key('plan_detail_bottom_cta'));
        expect(cta, findsOneWidget);

        // Premium user tapping Start navigates to Onboarding without hitting paywall
        await tester.tap(cta);
        await tester.pumpAndSettle();

        expect(find.text('PREMIUM_SCREEN_DESTINATION'), findsNothing);
        expect(find.text('Profile'), findsOneWidget);
        expect(find.text('Training'), findsOneWidget);
      }
    });

    // -------------------------------------------------------------------------
    // Scenario 8: Lifetime purchase users receive correct existing entitlement
    // -------------------------------------------------------------------------
    testWidgets('Scenario 8: Lifetime purchase users receive full premium entitlement across programmes', (tester) async {
      _configureTestViewport(tester);

      final subProvider = _MockSubscriptionProvider(isPremium: true, isLifetime: true);
      expect(subProvider.isLifetime, isTrue);
      expect(subProvider.isPremium, isTrue);

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'lifetime_user';
      transProvider.activeDocSaverForTesting = (_, __) async {};

      await tester.pumpWidget(_buildTestHarness(
        child: const TransformationPlanDetailScreen(planId: 'muscle_building_90'),
        subscriptionProvider: subProvider,
        transformationProvider: transProvider,
      ));
      await tester.pumpAndSettle();

      final cta = find.byKey(const Key('plan_detail_bottom_cta'));
      await tester.tap(cta);
      await tester.pumpAndSettle();

      // Navigated to Onboarding successfully
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Training'), findsOneWidget);
      expect(find.text('PREMIUM_SCREEN_DESTINATION'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Scenario 9: Expired subscription users cannot start new programmes
    // -------------------------------------------------------------------------
    testWidgets('Scenario 9: Expired subscription users cannot start new programmes', (tester) async {
      _configureTestViewport(tester);

      // User whose subscription expired
      final subProvider = _MockSubscriptionProvider(isPremium: false, isLifetime: false);
      final transProvider = TransformationProvider(autoLoad: false);

      await tester.pumpWidget(_buildTestHarness(
        child: const TransformationPlanDetailScreen(planId: 'weight_loss_60'),
        subscriptionProvider: subProvider,
        transformationProvider: transProvider,
      ));
      await tester.pumpAndSettle();

      final cta = find.byKey(const Key('plan_detail_bottom_cta'));
      await tester.tap(cta);
      await tester.pumpAndSettle();

      // Blocked and sent to paywall
      expect(find.text('PREMIUM_SCREEN_DESTINATION'), findsOneWidget);
      expect(transProvider.hasActiveTransformation, isFalse);
    });

    // -------------------------------------------------------------------------
    // Scenario 10: Existing active programme after subscription expiry
    // -------------------------------------------------------------------------
    testWidgets('Scenario 10: Expired user with active programme: data preserved, but workout execution prompts paywall', (tester) async {
      _configureTestViewport(tester);

      final subProvider = _MockSubscriptionProvider(isPremium: false); // Expired
      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'expired_user_with_plan';
      transProvider.activeDocSaverForTesting = (_, __) async {};

      // Seed an active transformation enrolled previously while premium
      await transProvider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 140.0, 'carbs': 200.0, 'fat': 50.0},
        subscriptionProvider: _MockSubscriptionProvider(isPremium: true),
      );

      // Data is preserved
      expect(transProvider.hasActiveTransformation, isTrue);
      expect(transProvider.activeTransformation!.currentDay, 1);

      // 10A: On Home Card, expired user sees Day 1, but tapping START WORKOUT routes to paywall
      await tester.pumpWidget(_buildTestHarness(
        child: const HomeAiRoutineCard(),
        subscriptionProvider: subProvider,
        transformationProvider: transProvider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('START DAY 1 WORKOUT'), findsOneWidget);
      await tester.tap(find.text('START DAY 1 WORKOUT'));
      await tester.pumpAndSettle();

      // Redirected to paywall!
      expect(find.text('PREMIUM_SCREEN_DESTINATION'), findsOneWidget);
      expect(find.text('DAY_WORKOUT_SESSION_DESTINATION'), findsNothing);

      // 10B: On Roadmap Screen, expired user can view progress, but tapping workout day routes to paywall
      await tester.pumpWidget(_buildTestHarness(
        child: const TransformationRoadmapScreen(),
        subscriptionProvider: subProvider,
        transformationProvider: transProvider,
      ));
      await tester.pumpAndSettle();

      // Roadmap renders cleanly (data preserved)
      expect(find.text('Complete Beginner – 30 Days'), findsOneWidget);
      expect(find.text('Day 1 of 30'), findsOneWidget);

      // Tap Day 1 workout card in roadmap
      final day1Button = find.byKey(const Key('start_workout_day_1'));
      await tester.scrollUntilVisible(day1Button, 100, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(day1Button);
      await tester.pumpAndSettle();
      expect(day1Button, findsOneWidget);
      await tester.tap(day1Button);
      await tester.pumpAndSettle();

      // Intercepted and routed to paywall!
      expect(find.text('PREMIUM_SCREEN_DESTINATION'), findsOneWidget);
      expect(find.text('DAY_WORKOUT_SESSION_DESTINATION'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Visual Affordances: PRO badges render on Hub and Dashboard
    // -------------------------------------------------------------------------
    testWidgets('Visual Affordances: PRO badges render on Hub and Dashboard challenge cards', (tester) async {
      _configureTestViewport(tester);

      final subProvider = _MockSubscriptionProvider(isPremium: false);
      final transProvider = TransformationProvider(autoLoad: false);

      // Hub screen shows PRO badges
      await tester.pumpWidget(_buildTestHarness(
        child: const TransformationHubScreen(),
        subscriptionProvider: subProvider,
        transformationProvider: transProvider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('PRO'), findsWidgets);

      // Dashboard card shows PRO badge
      await tester.pumpWidget(_buildTestHarness(
        child: const SingleChildScrollView(child: DashboardChallengeSection()),
        subscriptionProvider: subProvider,
        transformationProvider: transProvider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('PRO'), findsWidgets);
    });
  });
}
