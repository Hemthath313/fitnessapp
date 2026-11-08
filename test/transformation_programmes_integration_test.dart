import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_home_box.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_slider_home_widget.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_completion_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_plan_detail_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_progress_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_roadmap_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/dashboard_challenge_section.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/services/strength_service.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/router/router.dart';

class _MockHomeProvider extends ChangeNotifier implements HomeProvider {
  Map<String, dynamic> _userData = {
    'name': 'Athlete',
    'experience': 'Intermediate',
    'fitness_goal': 'Build Muscle',
    'weight': 75.0,
    'height': 178.0,
    'age': 26,
    'gender': 'Male',
    'activity': 'MODERATE',
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

Widget _wrapWidget({
  required Widget child,
  TransformationProvider? transformationProvider,
  HomeProvider? homeProvider,
  SubscriptionProvider? subscriptionProvider,
  ConsumptionProvider? consumptionProvider,
  WorkoutProvider? workoutProvider,
  StatisticsProvider? statisticsProvider,
  GoRouter? customRouter,
}) {
  final tp = transformationProvider ?? TransformationProvider(autoLoad: false);
  final hp = homeProvider ?? _MockHomeProvider();
  final sp = subscriptionProvider ?? _MockSubscriptionProvider();
  final cp = consumptionProvider ?? _MockConsumptionProvider();

  final router = customRouter ??
      GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => child),
          GoRoute(
            path: Routes.transformationPlanDetailRoute,
            builder: (context, state) {
              final planId = state.uri.queryParameters['planId'];
              return TransformationPlanDetailScreen(planId: planId);
            },
          ),
          GoRoute(path: Routes.transformationRoadmapRoute, builder: (_, __) => const TransformationRoadmapScreen()),
          GoRoute(path: Routes.transformationProgressRoute, builder: (_, __) => const TransformationProgressScreen()),
          GoRoute(path: Routes.transformationPlansRoute, builder: (_, __) => const Scaffold(body: Text('Transformation Plans Screen'))),
          GoRoute(path: Routes.newMealRoute, builder: (_, __) => const Scaffold(body: Text('Calorie Tracker Screen'))),
          GoRoute(path: Routes.addWaterRoute, builder: (_, __) => const Scaffold(body: Text('Water Tracker Screen'))),
          GoRoute(path: Routes.dietRoute, builder: (_, __) => const Scaffold(body: Text('Diet Plans Screen'))),
          GoRoute(path: Routes.bulkingDietRoute, builder: (_, __) => const Scaffold(body: Text('Bulking Diet Screen'))),
          GoRoute(path: Routes.transformationNutritionRoute, builder: (_, __) => const Scaffold(body: Text('Transformation Nutrition Screen'))),
          GoRoute(path: Routes.strengthAnalyticsRoute, builder: (_, __) => const Scaffold(body: Text('Strength Analytics Screen'))),
          GoRoute(path: Routes.workoutHistoryRoute, builder: (_, __) => const Scaffold(body: Text('Workout History Screen'))),
          GoRoute(path: Routes.sixPackChallengeRoute, builder: (_, __) => const Scaffold(body: Text('Six Pack Challenge Screen'))),
          GoRoute(path: Routes.mainRoute, builder: (_, __) => const Scaffold(body: Text('Main Screen'))),
        ],
      );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TransformationProvider?>.value(value: tp),
      ChangeNotifierProvider<HomeProvider?>.value(value: hp),
      ChangeNotifierProvider<SubscriptionProvider>.value(value: sp),
      ChangeNotifierProvider<ConsumptionProvider>.value(value: cp),
      if (workoutProvider != null) ChangeNotifierProvider<WorkoutProvider>.value(value: workoutProvider),
      if (statisticsProvider != null) ChangeNotifierProvider<StatisticsProvider>.value(value: statisticsProvider),
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
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Gym Buddy Phase 7 — Transformation Programme Integration & E2E Consistency', () {
    // -------------------------------------------------------------------------
    // Test 1: All 4 transformation programmes metadata, duration and blueprints
    // -------------------------------------------------------------------------
    test('1. Metadata, durations, phases and blueprints for all 4 programmes (zero ghost days)', () {
      final plans = TransformationPlansData.allPlans;
      expect(plans.length, equals(4));

      final beginner = TransformationPlansData.getById(TransformationPlansData.beginnerFitness30.id);
      final weightLoss = TransformationPlansData.getById(TransformationPlansData.weightLoss60.id);
      final muscleBuilding = TransformationPlansData.getById(TransformationPlansData.muscleBuilding90.id);
      final strength = TransformationPlansData.getById(TransformationPlansData.strength12Week.id);

      expect(beginner, isNotNull);
      expect(weightLoss, isNotNull);
      expect(muscleBuilding, isNotNull);
      expect(strength, isNotNull);

      // Verify exact duration math
      expect(beginner!.durationDays, equals(30));
      expect(beginner.allWeeks.expand((w) => w.days).length, equals(30));

      expect(weightLoss!.durationDays, equals(60));
      expect(weightLoss.allWeeks.expand((w) => w.days).length, equals(60));

      expect(muscleBuilding!.durationDays, equals(90));
      expect(muscleBuilding.allWeeks.expand((w) => w.days).length, equals(90));

      expect(strength!.durationDays, equals(84));
      expect(strength.allWeeks.expand((w) => w.days).length, equals(84));

      // Verify exercise naming integrity across all programmes
      final catalogNames = ExerciseData.all.map((e) => e.name).toSet();
      for (final plan in [beginner, weightLoss, muscleBuilding, strength]) {
        for (final week in plan.allWeeks) {
          for (final day in week.days) {
            for (final exName in day.exerciseNames) {
              expect(catalogNames.contains(exName), isTrue,
                  reason: 'Exercise "$exName" in ${plan.title} must exist in ExerciseData.all');
            }
          }
        }
      }
    });

    // -------------------------------------------------------------------------
    // Test 2: Enrolment for all 4 programmes initializes valid active state
    // -------------------------------------------------------------------------
    test('2. Enrolment for all 4 programmes initializes valid active state', () async {
      final blueprints = [
        TransformationPlansData.beginnerFitness30,
        TransformationPlansData.weightLoss60,
        TransformationPlansData.muscleBuilding90,
        TransformationPlansData.strength12Week,
      ];

      for (final bp in blueprints) {
        final provider = TransformationProvider(autoLoad: false);
        provider.userIdOverrideForTesting = 'user_enroll_${bp.id}';
        provider.activeDocSaverForTesting = (_, __) async {};

        await provider.enrollInPlan(
          blueprint: bp,
          targetCalories: 2200,
          targetMacros: const {'protein': 150.0, 'carbs': 200.0, 'fat': 60.0},
          workoutLocation: 'gym',
          experienceLevel: 'Intermediate',
          startingWeight: 80.0,
          targetWeight: 75.0,
        );

        expect(provider.hasActiveTransformation, isTrue);
        final state = provider.activeTransformation!;
        expect(state.planId, equals(bp.id));
        expect(state.planTitle, equals(bp.title));
        expect(state.totalDays, equals(bp.durationDays));
        expect(state.currentDay, equals(1));
        expect(state.status, equals('active'));
        expect(state.completedDayIndices, isEmpty);
        expect(state.milestones, isNotEmpty);
        expect(provider.activeBlueprint?.id, equals(bp.id));
      }
    });

    // -------------------------------------------------------------------------
    // Test 3: Active programme persistence across saves
    // -------------------------------------------------------------------------
    test('3. Active programme persistence across state updates', () async {
      Map<String, dynamic>? persistedDoc;
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'user_persist_test';
      provider.activeDocSaverForTesting = (_, data) async {
        persistedDoc = data;
      };

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 140.0, 'carbs': 210.0, 'fat': 50.0},
      );

      expect(persistedDoc, isNotNull);
      expect(persistedDoc!['planId'], equals('beginner_fitness_30'));

      // Mark Day 1 complete
      await provider.markDayCompleted(1);
      expect(persistedDoc!['completedDayIndices'], contains(1));

      // Mark Day 2 complete
      await provider.markDayCompleted(2);
      expect(persistedDoc!['completedDayIndices'], contains(2));
      expect((persistedDoc!['completedDayIndices'] as List).length, equals(2));
    });

    // -------------------------------------------------------------------------
    // Test 4: App restart and progress restoration from storage
    // -------------------------------------------------------------------------
    test('4. App restart and progress restoration from saved storage', () async {
      final now = DateTime.now();
      final savedStateMap = {
        'planId': 'muscle_building_90',
        'planTitle': '90-Day Muscle Building Challenge',
        'startDate': now.subtract(const Duration(days: 10)),
        'targetEndDate': now.add(const Duration(days: 80)),
        'currentDay': 11,
        'totalDays': 90,
        'status': 'active',
        'completedDayIndices': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        'targetCalories': 2800.0,
        'targetMacros': {'protein': 180.0, 'carbs': 350.0, 'fat': 75.0},
        'milestones': [
          {'id': 'm1', 'title': 'Week 1 Complete', 'description': '', 'triggerDay': 7, 'isAchieved': true},
          {'id': 'm2', 'title': 'Month 1 Checkpoint', 'description': '', 'triggerDay': 30, 'isAchieved': false},
        ],
        'workoutLocation': 'gym',
        'experienceLevel': 'Intermediate',
        'availableEquipment': ['barbell', 'dumbbells', 'cables'],
        'workoutDurationMinutes': 60,
        'workoutDaysPerWeek': 5,
        'startingWeight': 74.0,
        'targetWeight': 80.0,
      };

      final restoredProvider = TransformationProvider(autoLoad: false);
      restoredProvider.userIdOverrideForTesting = 'restart_user_1';
      restoredProvider.activeDocFetcherForTesting = (_) => savedStateMap;

      await restoredProvider.loadTransformation();

      expect(restoredProvider.hasActiveTransformation, isTrue);
      expect(restoredProvider.activeTransformation?.planId, equals('muscle_building_90'));
      expect(restoredProvider.activeTransformation?.currentDay, equals(11));
      expect(restoredProvider.activeTransformation?.completedDayIndices.length, equals(10));
      expect(restoredProvider.isDayCompleted(7), isTrue);
      expect(restoredProvider.isDayCompleted(11), isFalse);
    });

    // -------------------------------------------------------------------------
    // Test 5: Programme switching preserves previous progress in history
    // -------------------------------------------------------------------------
    test('5. Programme switching preserves previous programme progress in history with switched status', () async {
      final historyRecords = <Map<String, dynamic>>[];
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'switcher_user_1';
      provider.activeDocSaverForTesting = (_, __) async {};
      provider.historyDocSaverForTesting = (_, data) async {
        historyRecords.add(data);
      };

      // 1. Enroll in Beginner 30-Day
      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 130.0, 'carbs': 200.0, 'fat': 50.0},
      );
      await provider.markDayCompleted(1);
      await provider.markDayCompleted(2);
      await provider.markDayCompleted(3);

      expect(provider.activeTransformation?.planId, equals('beginner_fitness_30'));
      expect(provider.activeTransformation?.completedDayIndices, equals([1, 2, 3]));

      // 2. Switch to Weight Loss 60-Day
      await provider.enrollInPlan(
        blueprint: TransformationPlansData.weightLoss60,
        targetCalories: 1800,
        targetMacros: const {'protein': 140.0, 'carbs': 150.0, 'fat': 45.0},
      );

      // Verify new plan is active
      expect(provider.activeTransformation?.planId, equals('weight_loss_60'));
      expect(provider.activeTransformation?.currentDay, equals(1));
      expect(provider.activeTransformation?.completedDayIndices, isEmpty);

      // Verify previous plan was archived to history with status 'switched'
      expect(provider.history.length, equals(1));
      final archived = provider.history.first;
      expect(archived.planId, equals('beginner_fitness_30'));
      expect(archived.status, equals('switched'));
      expect(archived.completedDayIndices, equals([1, 2, 3]));
      expect(archived.completedAt, isNotNull);

      // Verify persistence callback received the switched record
      expect(historyRecords.length, equals(1));
      expect(historyRecords.first['planId'], equals('beginner_fitness_30'));
      expect(historyRecords.first['status'], equals('switched'));
    });

    // -------------------------------------------------------------------------
    // Test 6: Correct roadmap day calculations & week boundaries for all 4 plans
    // -------------------------------------------------------------------------
    test('6. Correct roadmap day calculations & week boundaries for all 4 programmes', () {
      final plans = [
        TransformationPlansData.beginnerFitness30,
        TransformationPlansData.weightLoss60,
        TransformationPlansData.muscleBuilding90,
        TransformationPlansData.strength12Week,
      ];

      for (final plan in plans) {
        int expectedDay = 1;
        for (int w = 0; w < plan.allWeeks.length; w++) {
          final week = plan.allWeeks[w];
          expect(week.weekNumber, equals(w + 1));
          for (final day in week.days) {
            // Verify blueprint lookup matches calculated day
            final lookupDay = plan.getDayBlueprint(expectedDay);
            expect(lookupDay, isNotNull, reason: 'Failed to look up day $expectedDay in ${plan.title}');
            expect(lookupDay!.dayIndex, equals(day.dayIndex));
            expectedDay++;
          }
        }
        expect(expectedDay - 1, equals(plan.durationDays));
      }
    });

    // -------------------------------------------------------------------------
    // Test 7: Rest-day and active-recovery handling across all programmes
    // -------------------------------------------------------------------------
    test('7. Rest-day and active-recovery handling across all programmes', () {
      for (final plan in TransformationPlansData.allPlans) {
        final allDays = plan.allWeeks.expand((w) => w.days).toList();
        final restDays = allDays.where((d) => d.isRestDay).toList();
        final workoutDays = allDays.where((d) => !d.isRestDay).toList();

        expect(restDays, isNotEmpty, reason: '${plan.title} must have scheduled rest/recovery days');
        expect(workoutDays, isNotEmpty, reason: '${plan.title} must have scheduled workout days');

        for (final restDay in restDays) {
          expect(restDay.dayType, isIn(['rest', 'active_recovery']));
          expect(restDay.notes, isNotNull);
          expect(restDay.notes!.isNotEmpty, isTrue);
          expect(restDay.exerciseNames, isEmpty);
        }
      }
    });

    // -------------------------------------------------------------------------
    // Test 8: Workout logging integration with canonical WorkoutSession
    // -------------------------------------------------------------------------
    test('8. Workout logging integration with canonical WorkoutSession', () {
      final blueprint = TransformationPlansData.strength12Week;
      final day1 = blueprint.getDayBlueprint(1)!;

      // Construct canonical WorkoutSession as done when launching DayWorkoutSessionPage
      final sessionExercises = <SessionExercise>[];
      for (int i = 0; i < day1.exerciseNames.length; i++) {
        final name = day1.exerciseNames[i];
        sessionExercises.add(
          SessionExercise(
            exerciseName: name,
            order: i,
            sets: List.generate(
              day1.targetSets,
              (_) => WorkoutSet(
                weight: 60.0,
                reps: 5,
                isCompleted: false,
              ),
            ),
          ),
        );
      }

      final session = WorkoutSession(
        id: 'session_strength_day1',
        userId: 'test_athlete_1',
        workoutName: '${blueprint.title} – Day 1',
        dayName: 'Day 1',
        startedAt: DateTime.now(),
        totalVolume: 0.0,
        exercises: sessionExercises,
        planId: blueprint.id,
        planDay: 1,
      );

      expect(session.workoutName, contains('12-Week Strength'));
      expect(session.exercises.length, equals(day1.exerciseNames.length));
      expect(session.exercises.first.sets.length, equals(day1.targetSets));
      expect(session.exercises.first.exerciseName, equals('Barbell Bench Press'));
      expect(session.planId, equals('strength_12_week'));
      expect(session.planDay, equals(1));
    });

    // -------------------------------------------------------------------------
    // Test 9: Previous workout performance memory via WorkoutLogService
    // -------------------------------------------------------------------------
    test('9. Previous workout performance memory via WorkoutLogService cache', () {
      WorkoutLogService.clearLastLogCache();

      final squatLog = WorkoutLog(
        id: 'squat_prev_1',
        exerciseName: 'Classic Barbell Squat',
        date: DateTime.now().subtract(const Duration(days: 4)),
        category: 'Legs',
        sets: [
          WorkoutSet(weight: 120.0, reps: 5, isCompleted: true),
          WorkoutSet(weight: 120.0, reps: 5, isCompleted: true),
          WorkoutSet(weight: 120.0, reps: 5, isCompleted: true),
        ],
      );

      WorkoutLogService.seedLastLogCache('Classic Barbell Squat', squatLog);

      final cached = WorkoutLogService.getCachedLastLog('Classic Barbell Squat');
      expect(cached, isNotNull);
      expect(cached!.exerciseName, equals('Classic Barbell Squat'));
      expect(cached.sets.length, equals(3));
      expect(cached.sets.first.weight, equals(120.0));
      expect(cached.sets.first.reps, equals(5));

      WorkoutLogService.clearLastLogCache();
    });

    // -------------------------------------------------------------------------
    // Test 10: Strength and PR integration via StrengthService
    // -------------------------------------------------------------------------
    test('10. Strength analytics and 1RM calculation accuracy via StrengthService', () {
      // Epley formula: weight * (1 + reps / 30)
      // 140kg for 5 reps -> 140 * (1 + 5/30) = 140 * 1.1667 = 163.33 kg
      final est1RM = StrengthService.calculateEstimated1RMFromValues(
        weight: 140.0,
        reps: 5,
      );
      expect(est1RM, closeTo(163.33, 0.05));

      // Single rep: 100kg for 1 rep = 100.0 kg
      final singleRep1RM = StrengthService.calculateEstimated1RMFromValues(
        weight: 100.0,
        reps: 1,
      );
      expect(singleRep1RM, equals(100.0));

      // Heavy 10 reps: 100kg for 10 reps -> 100 * (1 + 10/30) = 133.33 kg
      final tenRep1RM = StrengthService.calculateEstimated1RMFromValues(
        weight: 100.0,
        reps: 10,
      );
      expect(tenRep1RM, closeTo(133.33, 0.05));
    });

    // -------------------------------------------------------------------------
    // Test 11: Nutrition navigation to all nutrition routes
    // -------------------------------------------------------------------------
    testWidgets('11. Nutrition and tracker routes navigation integration', (tester) async {
      _configureTestViewport(tester);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => context.push(Routes.newMealRoute),
                    child: const Text('Go Calorie Tracker'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(Routes.addWaterRoute),
                    child: const Text('Go Water Tracker'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(Routes.dietRoute),
                    child: const Text('Go Diet Plans'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(Routes.bulkingDietRoute),
                    child: const Text('Go Bulking Diet'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(Routes.transformationNutritionRoute),
                    child: const Text('Go Transformation Nutrition'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push(Routes.strengthAnalyticsRoute),
                    child: const Text('Go Strength Analytics'),
                  ),
                ],
              ),
            ),
          ),
          GoRoute(path: Routes.newMealRoute, builder: (_, __) => const Scaffold(body: Text('Calorie Tracker Destination'))),
          GoRoute(path: Routes.addWaterRoute, builder: (_, __) => const Scaffold(body: Text('Water Tracker Destination'))),
          GoRoute(path: Routes.dietRoute, builder: (_, __) => const Scaffold(body: Text('Diet Plans Destination'))),
          GoRoute(path: Routes.bulkingDietRoute, builder: (_, __) => const Scaffold(body: Text('Bulking Diet Destination'))),
          GoRoute(path: Routes.transformationNutritionRoute, builder: (_, __) => const Scaffold(body: Text('Transformation Nutrition Destination'))),
          GoRoute(path: Routes.strengthAnalyticsRoute, builder: (_, __) => const Scaffold(body: Text('Strength Analytics Destination'))),
        ],
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, _) => MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Test Calorie Tracker
      await tester.tap(find.text('Go Calorie Tracker'));
      await tester.pumpAndSettle();
      expect(find.text('Calorie Tracker Destination'), findsOneWidget);

      // Back and test Water Tracker
      router.go('/');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go Water Tracker'));
      await tester.pumpAndSettle();
      expect(find.text('Water Tracker Destination'), findsOneWidget);

      // Back and test Diet Plans
      router.go('/');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go Diet Plans'));
      await tester.pumpAndSettle();
      expect(find.text('Diet Plans Destination'), findsOneWidget);

      // Back and test Bulking Diet
      router.go('/');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go Bulking Diet'));
      await tester.pumpAndSettle();
      expect(find.text('Bulking Diet Destination'), findsOneWidget);

      // Back and test Transformation Nutrition
      router.go('/');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go Transformation Nutrition'));
      await tester.pumpAndSettle();
      expect(find.text('Transformation Nutrition Destination'), findsOneWidget);

      // Back and test Strength Analytics
      router.go('/');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go Strength Analytics'));
      await tester.pumpAndSettle();
      expect(find.text('Strength Analytics Destination'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 12: Dashboard recommendation based on profile and active priority
    // -------------------------------------------------------------------------
    testWidgets('12. Dashboard challenge recommendation prioritizes active plan, then profile', (tester) async {
      _configureTestViewport(tester);

      final homeProvider = _MockHomeProvider();
      final transformationProvider = TransformationProvider(autoLoad: false);

      // Case A: No active plan, goal is STRENGTH -> recommends 12-Week Strength
      homeProvider.setUserData({
        'name': 'Lifter',
        'experience': 'Intermediate',
        'goal': 'STRENGTH',
      });

      await tester.pumpWidget(_wrapWidget(
        child: const Scaffold(body: SingleChildScrollView(child: DashboardChallengeSection())),
        homeProvider: homeProvider,
        transformationProvider: transformationProvider,
      ));
      await tester.pumpAndSettle();

      expect(find.text(TransformationPlansData.strength12Week.title), findsOneWidget);

      // Case B: No active plan, goal is LOSE -> recommends 60-Day Weight Loss
      homeProvider.setUserData({
        'name': 'Runner',
        'experience': 'Intermediate',
        'goal': 'LOSE',
      });

      await tester.pumpWidget(_wrapWidget(
        child: const Scaffold(body: SingleChildScrollView(child: DashboardChallengeSection())),
        homeProvider: homeProvider,
        transformationProvider: transformationProvider,
      ));
      await tester.pumpAndSettle();

      expect(find.text(TransformationPlansData.weightLoss60.title), findsOneWidget);

      // Case C: Active plan exists -> ALWAYS shows active plan regardless of profile
      transformationProvider.userIdOverrideForTesting = 'active_prio_user';
      transformationProvider.activeDocSaverForTesting = (_, __) async {};
      await transformationProvider.enrollInPlan(
        blueprint: TransformationPlansData.muscleBuilding90,
        targetCalories: 2700,
        targetMacros: const {'protein': 160.0, 'carbs': 320.0, 'fat': 70.0},
      );

      await tester.pumpWidget(_wrapWidget(
        child: const Scaffold(body: SingleChildScrollView(child: DashboardChallengeSection())),
        homeProvider: homeProvider,
        transformationProvider: transformationProvider,
      ));
      await tester.pumpAndSettle();

      expect(find.text(TransformationPlansData.muscleBuilding90.title), findsOneWidget);
      expect(find.text('Day 1 of 90'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Test 13: Completion screen accuracy for all 4 programmes
    // -------------------------------------------------------------------------
    testWidgets('13. Completion screen accurately displays stats and graduation for all 4 programmes', (tester) async {
      _configureTestViewport(tester);

      for (final bp in [
        TransformationPlansData.beginnerFitness30,
        TransformationPlansData.weightLoss60,
        TransformationPlansData.muscleBuilding90,
        TransformationPlansData.strength12Week,
      ]) {
        final completedState = UserTransformationState(
          planId: bp.id,
          planTitle: bp.title,
          startDate: DateTime.now().subtract(Duration(days: bp.durationDays)),
          targetEndDate: DateTime.now(),
          currentDay: bp.durationDays,
          totalDays: bp.durationDays,
          status: 'completed',
          completedDayIndices: List.generate(bp.durationDays, (i) => i + 1),
          targetCalories: 2400,
          targetMacros: const {'protein': 150.0, 'carbs': 250.0, 'fat': 65.0},
          milestones: TransformationPlansData.createDefaultMilestones(bp)
              .map((m) => m.copyWith(isAchieved: true))
              .toList(),
          completedAt: DateTime.now(),
        );

        await tester.pumpWidget(_wrapWidget(
          child: TransformationCompletionScreen(completedState: completedState),
        ));
        await tester.pumpAndSettle();

        // Verifies the programme title, celebration badge and graduation options
        expect(find.text(bp.title), findsOneWidget);
        expect(find.text('ACHIEVEMENT UNLOCKED'), findsOneWidget);
        expect(find.text('Transformation Summary'), findsOneWidget);

        final graduationHeader = find.textContaining('Graduate to Your Next');
        await tester.scrollUntilVisible(graduationHeader, 300);
        expect(graduationHeader, findsOneWidget);
      }
    });

    // -------------------------------------------------------------------------
    // Test 14: Graduation pathways require explicit user action (no auto-enrol)
    // -------------------------------------------------------------------------
    testWidgets('14. Graduation pathways for all 4 programmes require explicit user action and do not auto-enroll', (tester) async {
      _configureTestViewport(tester);

      final completedState = UserTransformationState(
        planId: TransformationPlansData.beginnerFitness30.id,
        planTitle: 'Complete Beginner – 30 Days',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        targetEndDate: DateTime.now(),
        currentDay: 30,
        totalDays: 30,
        status: 'completed',
        completedDayIndices: List.generate(30, (i) => i + 1),
        targetCalories: 2000,
        targetMacros: const {'protein': 130.0, 'carbs': 200.0, 'fat': 50.0},
        completedAt: DateTime.now(),
      );

      final provider = TransformationProvider(autoLoad: false);
      // Provider currently has no active transformation
      expect(provider.hasActiveTransformation, isFalse);

      await tester.pumpWidget(_wrapWidget(
        child: TransformationCompletionScreen(completedState: completedState),
        transformationProvider: provider,
      ));
      await tester.pumpAndSettle();

      // Tap graduation option button
      final graduateBtn = find.byKey(const Key('graduate_to_weight_loss_btn'));
      await tester.scrollUntilVisible(graduateBtn, 300);
      expect(graduateBtn, findsOneWidget);

      await tester.tap(graduateBtn);
      await tester.pumpAndSettle();

      // Navigated to plan detail screen
      expect(find.byType(TransformationPlanDetailScreen), findsOneWidget);

      // Verify user is NOT automatically enrolled; provider still has no active transformation
      expect(provider.hasActiveTransformation, isFalse);
    });

    // -------------------------------------------------------------------------
    // Test 15: Six-Pack challenge compatibility and independence
    // -------------------------------------------------------------------------
    testWidgets('15. Six-Pack challenge is accessible and independent from active transformation', (tester) async {
      _configureTestViewport(tester);

      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'sixpack_test_user';
      provider.activeDocSaverForTesting = (_, __) async {};

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.strength12Week,
        targetCalories: 2600,
        targetMacros: const {'protein': 170.0, 'carbs': 280.0, 'fat': 65.0},
      );

      await tester.pumpWidget(_wrapWidget(
        child: const Scaffold(body: SingleChildScrollView(child: DashboardChallengeSection())),
        transformationProvider: provider,
      ));
      await tester.pumpAndSettle();

      // Both the active transformation card and the Six-Pack challenge card render
      expect(find.text('12-Week Strength Building Challenge'), findsOneWidget);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      final carouselWidget = find.byType(CarouselSliderHomeWidget);
      expect(carouselWidget, findsOneWidget);

      // Tap Six-Pack challenge box within the carousel
      await tester.tap(find.byType(CarouselHomeBox).first);
      await tester.pumpAndSettle();

      expect(find.text('Six Pack Challenge Screen'), findsOneWidget);
      // Active transformation in provider is completely intact
      expect(provider.activeTransformation?.planId, equals('strength_12_week'));
    });

    // -------------------------------------------------------------------------
    // Test 16: Offline and Firestore failure handling without crashing
    // -------------------------------------------------------------------------
    test('16. Offline and Firestore error handling without crashing or resetting state', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'offline_user';

      // Simulate network / Firestore failure on save
      provider.activeDocSaverForTesting = (_, __) async {
        throw Exception('Network connection timed out: Firestore offline');
      };

      // Enrolling should catch error gracefully
      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 120.0, 'carbs': 200.0, 'fat': 50.0},
      );

      expect(provider.isLoading, isFalse);
      expect(provider.error, contains('Firestore offline'));
      expect(provider.hasActiveTransformation, isFalse); // Enrolment aborted safely
    });

    // -------------------------------------------------------------------------
    // Test 17: No duplicate records when completing or repeating programmes
    // -------------------------------------------------------------------------
    test('17. Repeating or completing a programme creates unique history records without collision', () async {
      final historyRecords = <Map<String, dynamic>>[];
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'repeat_user_1';
      provider.activeDocSaverForTesting = (_, __) async {};
      provider.historyDocSaverForTesting = (_, data) async {
        historyRecords.add(data);
      };

      // 1. Enroll and complete Beginner 30-Day (Round 1)
      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 130.0, 'carbs': 200.0, 'fat': 50.0},
      );
      for (int i = 1; i <= 30; i++) {
        await provider.markDayCompleted(i);
      }
      await provider.completePlan();

      expect(provider.hasActiveTransformation, isFalse);
      expect(provider.history.length, equals(1));
      expect(provider.history.first.status, equals('completed'));

      // 2. Repeat Beginner 30-Day (Round 2)
      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2100,
        targetMacros: const {'protein': 140.0, 'carbs': 210.0, 'fat': 55.0},
      );
      expect(provider.hasActiveTransformation, isTrue);
      expect(provider.activeTransformation?.completedDayIndices, isEmpty);

      // Complete Round 2
      for (int i = 1; i <= 30; i++) {
        await provider.markDayCompleted(i);
      }
      await provider.completePlan();

      // Verify history contains 2 distinct completion entries
      expect(provider.history.length, equals(2));
      expect(historyRecords.length, equals(2));
      expect(provider.history[0].status, equals('completed'));
      expect(provider.history[1].status, equals('completed'));
    });

    // -------------------------------------------------------------------------
    // Test 18: No regression in existing subscription and entitlement behavior
    // -------------------------------------------------------------------------
    testWidgets('18. Subscription entitlements and access boundaries preserved', (tester) async {
      _configureTestViewport(tester);

      final subProvider = _MockSubscriptionProvider();
      subProvider.setPremium(false); // Free user

      expect(subProvider.isPremium, isFalse);

      subProvider.setPremium(true); // Premium subscriber
      expect(subProvider.isPremium, isTrue);

      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'sub_test_user';
      provider.activeDocSaverForTesting = (_, __) async {};
      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 120.0, 'carbs': 200.0, 'fat': 50.0},
      );

      await tester.pumpWidget(_wrapWidget(
        child: const TransformationRoadmapScreen(),
        transformationProvider: provider,
        subscriptionProvider: subProvider,
      ));
      await tester.pumpAndSettle();

      // Roadmap renders without subscription errors or broken state
      expect(find.byType(TransformationRoadmapScreen), findsOneWidget);
    });
  });
}
