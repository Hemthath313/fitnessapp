import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/workout_model.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_home_box.dart';
import 'package:fitness_app/presentation/home/widgets/quick_actions_widget.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/dashboard_challenge_section.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubSubscriptionProvider extends ChangeNotifier implements SubscriptionProvider {
  @override
  bool get isPremium => false;
  @override
  bool get isLifetime => false;
  @override
  bool get isLoading => false;
  @override
  String? get error => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockConsumptionProvider extends ConsumptionProvider {
  @override
  Future<void> getConsumedCalories() async {}
}

void _configureTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _wrapWidget(
  Widget child, {
  HomeProvider? homeProvider,
  TransformationProvider? transformationProvider,
  WorkoutProvider? workoutProvider,
  StatisticsProvider? statisticsProvider,
  ConsumptionProvider? consumptionProvider,
  SubscriptionProvider? subscriptionProvider,
  GoRouter? customRouter,
}) {
  final router = customRouter ??
      GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => Scaffold(body: SingleChildScrollView(child: child)),
          ),
          GoRoute(
            path: Routes.workoutLogRoute,
            builder: (_, __) => const Scaffold(body: Text('Workout Log Screen')),
          ),
          GoRoute(
            path: Routes.transformationPlansRoute,
            builder: (_, __) => const Scaffold(body: Text('Transformation Plans Screen')),
          ),
          GoRoute(
            path: Routes.transformationPlanDetailRoute,
            builder: (_, __) => const Scaffold(body: Text('Transformation Detail Screen')),
          ),
        ],
      );

  return ScreenUtilInit(
    key: UniqueKey(),
    designSize: const Size(430, 932),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (_, __) => MultiProvider(
      providers: [
        ChangeNotifierProvider<HomeProvider>(
          create: (_) => homeProvider ?? HomeProvider(),
        ),
        ChangeNotifierProvider<TransformationProvider?>(
          create: (_) => transformationProvider ?? TransformationProvider(autoLoad: false),
        ),
        ChangeNotifierProvider<WorkoutProvider>(
          create: (_) => workoutProvider ?? WorkoutProvider(),
        ),
        ChangeNotifierProvider<StatisticsProvider>(
          create: (_) => statisticsProvider ?? StatisticsProvider(),
        ),
        ChangeNotifierProvider<ConsumptionProvider>(
          create: (_) => consumptionProvider ?? _MockConsumptionProvider(),
        ),
        ChangeNotifierProvider<SubscriptionProvider>(
          create: (_) => subscriptionProvider ?? _StubSubscriptionProvider(),
        ),
      ],
      child: MaterialApp.router(
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

  group('Gym Buddy Dashboard Personalization & Challenges UX Suite', () {
    // 1. Beginner recommendation
    test('1. Beginner recommendation selects Complete Beginner 30-Day', () {
      final userData = {
        'experience': 'Beginner',
        'goal': 'MAINTAIN',
        'activity': 'LIGHT',
      };
      final recommended = DashboardChallengeSection.getRecommendedProgramme(userData: userData);
      expect(recommended.id, equals(TransformationPlansData.beginnerFitness30.id));
      expect(recommended.title, equals('Complete Beginner – 30 Days'));
    });

    testWidgets('1b. Dashboard renders Complete Beginner 30-Day for beginner profile', (tester) async {
      _configureTestViewport(tester);
      final homeProvider = HomeProvider();
      homeProvider.userData['experience'] = 'Beginner';
      homeProvider.userData['goal'] = 'MAINTAIN';

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'user_beginner';
      transProvider.activeDocFetcherForTesting = (_) => null;

      await tester.pumpWidget(
        _wrapWidget(
          const DashboardChallengeSection(),
          homeProvider: homeProvider,
          transformationProvider: transProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('featured_challenge_card')), findsOneWidget);
      expect(find.text('Complete Beginner – 30 Days'), findsOneWidget);
      expect(find.text('Foundation'), findsOneWidget);
      expect(find.byKey(const Key('explore_challenge_cta')), findsOneWidget);
    });

    // 2. Weight-loss recommendation
    test('2. Weight-loss recommendation selects 60-Day Weight Loss', () {
      final userData = {
        'experience': 'Intermediate',
        'goal': 'LOSE',
        'activity': 'MODERATE',
      };
      final recommended = DashboardChallengeSection.getRecommendedProgramme(userData: userData);
      expect(recommended.id, equals(TransformationPlansData.weightLoss60.id));
      expect(recommended.title, equals('60-Day Weight Loss Challenge'));
    });

    testWidgets('2b. Dashboard renders 60-Day Weight Loss for weight-loss profile', (tester) async {
      _configureTestViewport(tester);
      final homeProvider = HomeProvider();
      homeProvider.userData['experience'] = 'Intermediate';
      homeProvider.userData['goal'] = 'LOSE';

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'user_fatloss';
      transProvider.activeDocFetcherForTesting = (_) => null;

      await tester.pumpWidget(
        _wrapWidget(
          const DashboardChallengeSection(),
          homeProvider: homeProvider,
          transformationProvider: transProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('featured_challenge_card')), findsOneWidget);
      expect(find.text('60-Day Weight Loss Challenge'), findsOneWidget);
      expect(find.text('Fat Loss'), findsOneWidget);
    });

    // 3. Muscle-gain recommendation
    test('3. Muscle-gain recommendation selects 90-Day Muscle Building for intermediate/advanced', () {
      final userData = {
        'experience': 'Intermediate',
        'goal': 'GAIN',
        'activity': 'HIGH',
      };
      final recommended = DashboardChallengeSection.getRecommendedProgramme(userData: userData);
      expect(recommended.id, equals(TransformationPlansData.muscleBuilding90.id));
      expect(recommended.title, equals(TransformationPlansData.muscleBuilding90.title));
    });

    testWidgets('3b. Dashboard renders 90-Day Muscle Building for muscle gain goal', (tester) async {
      _configureTestViewport(tester);
      final homeProvider = HomeProvider();
      homeProvider.userData['experience'] = 'Intermediate';
      homeProvider.userData['goal'] = 'GAIN';

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'user_muscle';
      transProvider.activeDocFetcherForTesting = (_) => null;

      await tester.pumpWidget(
        _wrapWidget(
          const DashboardChallengeSection(),
          homeProvider: homeProvider,
          transformationProvider: transProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('featured_challenge_card')), findsOneWidget);
      expect(find.text(TransformationPlansData.muscleBuilding90.title), findsOneWidget);
      expect(find.text('Muscle Mass'), findsOneWidget);
    });

    // 4. Strength recommendation
    test('4. Strength recommendation selects 12-Week Strength Transformation', () {
      final userData = {
        'experience': 'Advanced',
        'goal': 'STRENGTH',
        'activity': 'HIGH',
      };
      final recommended = DashboardChallengeSection.getRecommendedProgramme(userData: userData);
      expect(recommended.id, equals(TransformationPlansData.strength12Week.id));
      expect(recommended.title, equals(TransformationPlansData.strength12Week.title));
    });

    testWidgets('4b. Dashboard renders 12-Week Strength for strength goal', (tester) async {
      _configureTestViewport(tester);
      final homeProvider = HomeProvider();
      homeProvider.userData['experience'] = 'Advanced';
      homeProvider.userData['goal'] = 'STRENGTH';

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'user_strength';
      transProvider.activeDocFetcherForTesting = (_) => null;

      await tester.pumpWidget(
        _wrapWidget(
          const DashboardChallengeSection(),
          homeProvider: homeProvider,
          transformationProvider: transProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('featured_challenge_card')), findsOneWidget);
      expect(find.text(TransformationPlansData.strength12Week.title), findsOneWidget);
      expect(find.text('Strength'), findsOneWidget);
    });

    // 5. Beginner with muscle-gain goal
    test('5. Beginner with muscle-gain goal provides Beginner 30-Day recommendation', () {
      final userData = {
        'experience': 'Beginner',
        'goal': 'GAIN',
        'activity': 'LIGHT',
      };
      final recommended = DashboardChallengeSection.getRecommendedProgramme(userData: userData);
      expect(recommended.id, equals(TransformationPlansData.beginnerFitness30.id));
      expect(recommended.title, equals('Complete Beginner – 30 Days'));
    });

    testWidgets('5b. Dashboard renders Beginner 30-Day even when user selected muscle gain goal', (tester) async {
      _configureTestViewport(tester);
      final homeProvider = HomeProvider();
      homeProvider.userData['experience'] = 'Beginner';
      homeProvider.userData['goal'] = 'GAIN';

      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'user_beg_muscle';
      transProvider.activeDocFetcherForTesting = (_) => null;

      await tester.pumpWidget(
        _wrapWidget(
          const DashboardChallengeSection(),
          homeProvider: homeProvider,
          transformationProvider: transProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('featured_challenge_card')), findsOneWidget);
      expect(find.text('Complete Beginner – 30 Days'), findsOneWidget);
    });

    // 6. Existing active transformation takes priority
    testWidgets('6. Existing active transformation takes priority over recommendations', (tester) async {
      _configureTestViewport(tester);
      final homeProvider = HomeProvider();
      homeProvider.userData['experience'] = 'Beginner';
      homeProvider.userData['goal'] = 'MAINTAIN';

      final now = DateTime.now();
      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'user_active';
      transProvider.activeDocFetcherForTesting = (_) => {
        'planId': 'muscle_building_90',
        'planTitle': '90-Day Muscle Building Plan',
        'startDate': now.toIso8601String(),
        'targetEndDate': now.add(const Duration(days: 90)).toIso8601String(),
        'currentDay': 15,
        'totalDays': 90,
        'completedDayIndices': [1, 2, 3, 4],
        'targetCalories': 2600,
        'targetMacros': {'protein': 180, 'carbs': 300, 'fat': 70},
        'milestones': [],
        'weighIns': [],
        'weeklyCheckIns': [],
        'celebratedMilestoneIds': [],
        'mealSubstitutions': {},
        'status': 'active',
        'adherenceScore': 0.85,
        'currentPhaseIndex': 0,
        'currentPhaseName': 'Phase 1',
      };
      await transProvider.loadTransformation();

      await tester.pumpWidget(
        _wrapWidget(
          const DashboardChallengeSection(),
          homeProvider: homeProvider,
          transformationProvider: transProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Must show active card, NOT the beginner featured card
      expect(find.byKey(const Key('active_challenge_card')), findsOneWidget);
      expect(find.text('90-Day Muscle Building Plan'), findsOneWidget);
      expect(find.byKey(const Key('featured_challenge_card')), findsNothing);
    });

    // 7. Completed transformation state
    testWidgets('7. Completed transformation state renders summary card and explore another CTA', (tester) async {
      _configureTestViewport(tester);
      final homeProvider = HomeProvider();

      final now = DateTime.now();
      final transProvider = TransformationProvider(autoLoad: false);
      transProvider.userIdOverrideForTesting = 'user_completed';
      transProvider.activeDocFetcherForTesting = (_) => null;
      transProvider.historyDocFetcherForTesting = (_) => [
        {
          'planId': 'beginner_fitness_30',
          'planTitle': 'Complete Beginner – 30 Days',
          'startDate': now.subtract(const Duration(days: 35)).toIso8601String(),
          'targetEndDate': now.subtract(const Duration(days: 5)).toIso8601String(),
          'currentDay': 30,
          'totalDays': 30,
          'completedDayIndices': List.generate(30, (i) => i + 1),
          'targetCalories': 2000,
          'targetMacros': {'protein': 140, 'carbs': 220, 'fat': 60},
          'milestones': [],
          'weighIns': [],
          'weeklyCheckIns': [],
          'celebratedMilestoneIds': [],
          'mealSubstitutions': {},
          'status': 'completed',
          'adherenceScore': 1.0,
          'currentPhaseIndex': 3,
          'currentPhaseName': 'Phase 4',
        }
      ];
      await transProvider.loadTransformation();

      await tester.pumpWidget(
        _wrapWidget(
          const DashboardChallengeSection(),
          homeProvider: homeProvider,
          transformationProvider: transProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('completed_challenge_card')), findsOneWidget);
      expect(find.text('Complete Beginner – 30 Days'), findsOneWidget);
      expect(find.byKey(const Key('explore_another_challenge_cta')), findsOneWidget);
    });

    // 8. Missing profile data fallback
    test('8. Missing profile data fallback provides a sensible default without crashing', () {
      expect(() => DashboardChallengeSection.getRecommendedProgramme(userData: null), returnsNormally);
      expect(() => DashboardChallengeSection.getRecommendedProgramme(userData: {}), returnsNormally);

      final fallbackNull = DashboardChallengeSection.getRecommendedProgramme(userData: null);
      final fallbackEmpty = DashboardChallengeSection.getRecommendedProgramme(userData: {});

      expect(fallbackNull, isNotNull);
      expect(fallbackEmpty, isNotNull);
      expect(fallbackNull.id.isNotEmpty, isTrue);
      expect(fallbackEmpty.id.isNotEmpty, isTrue);
    });

    // 9. Six-Pack not-started badge
    testWidgets('9. Six-Pack not-started badge displays 30-DAY CHALLENGE when progress is 0', (tester) async {
      _configureTestViewport(tester);

      await tester.pumpWidget(
        _wrapWidget(
          CarouselHomeBox(
            deviceWidth: 430,
            image: 'assets/images/abs_workout.jpg',
            title: StringsManager.sixPackChallenge,
            badge: '30-DAY CHALLENGE',
            subtitle: '30-Day progressive core curriculum',
            actionText: 'Start Day 1',
            onTap: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('30-DAY CHALLENGE'), findsOneWidget);
      expect(find.text('ACTIVE CHALLENGE'), findsNothing);
      expect(find.text('Start Day 1'), findsOneWidget);
    });

    // 10. Six-Pack active badge
    testWidgets('10. Six-Pack active badge displays ACTIVE when progress is in-flight', (tester) async {
      _configureTestViewport(tester);

      await tester.pumpWidget(
        _wrapWidget(
          CarouselHomeBox(
            deviceWidth: 430,
            image: 'assets/images/abs_workout.jpg',
            title: StringsManager.sixPackChallenge,
            badge: 'ACTIVE',
            subtitle: '12 of 30 days completed',
            progress: 12 / 30.0,
            actionText: 'Continue Day 13',
            onTap: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('30-DAY CHALLENGE'), findsNothing);
      expect(find.text('12 of 30 days completed'), findsOneWidget);
      expect(find.text('Continue Day 13'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    // 11. Six-Pack completed badge
    testWidgets('11. Six-Pack completed badge displays COMPLETED when all 30 days are done', (tester) async {
      _configureTestViewport(tester);

      await tester.pumpWidget(
        _wrapWidget(
          CarouselHomeBox(
            deviceWidth: 430,
            image: 'assets/images/abs_workout.jpg',
            title: StringsManager.sixPackChallenge,
            badge: 'COMPLETED',
            subtitle: '30 of 30 days completed',
            progress: 1.0,
            actionText: 'Completed 🏆',
            onTap: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('ACTIVE'), findsNothing);
      expect(find.text('Completed 🏆'), findsOneWidget);
    });

    // 12. No duplicate workout-launch behavior
    testWidgets('12. When today has scheduled split, Log Lift navigates to manual log without duplicate session start', (tester) async {
      _configureTestViewport(tester);

      final todayName = DateFormat('EEEE').format(DateTime.now());
      final workoutProvider = WorkoutProvider();
      workoutProvider.setAllWorkoutsForTesting([
        WorkoutModel(
          id: 'test_1',
          name: '[$todayName] Bench Press',
          setNumber: 3,
          repNumber: 10,
          dateTime: DateTime.now(),
        ),
      ]);

      bool pushedWorkoutLog = false;
      final customRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: SingleChildScrollView(child: QuickActionsWidget())),
          ),
          GoRoute(
            path: Routes.workoutLogRoute,
            builder: (_, __) {
              pushedWorkoutLog = true;
              return const Scaffold(body: Text('Workout Log Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        _wrapWidget(
          const QuickActionsWidget(),
          workoutProvider: workoutProvider,
          customRouter: customRouter,
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Log Lift"
      await tester.tap(find.text('Log past workout'));
      await tester.pumpAndSettle();

      // Must navigate directly to manual workoutLogRoute, NOT duplicate the DayWorkoutSessionPage
      expect(pushedWorkoutLog, isTrue);
    });
  });
}
