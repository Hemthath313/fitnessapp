import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_completion_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_plan_detail_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_progress_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_roadmap_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/utils/transformation_equipment_adapter.dart';
import 'package:fitness_app/services/strength_service.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/router/router.dart';

class MockHomeProvider extends ChangeNotifier implements HomeProvider {
  @override
  Map<String, dynamic> userData = {
    'name': 'Power Lifter',
    'experience': 'Intermediate',
    'fitness_goal': 'Build Strength',
    'weight': 82.0,
    'height': 180.0,
    'age': 28,
    'gender': 'Male',
    'activity': 'MODERATE',
  };

  @override
  Future<Map<String, dynamic>> fetchUserData() async => userData;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSubscriptionProvider extends ChangeNotifier implements SubscriptionProvider {
  @override
  bool get isPremium => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Widget wrapWithScreenUtilAndRouter({
    required Widget child,
    TransformationProvider? transformationProvider,
    HomeProvider? homeProvider,
    SubscriptionProvider? subscriptionProvider,
  }) {
    final tp = transformationProvider ?? TransformationProvider(autoLoad: false);
    final hp = homeProvider ?? MockHomeProvider();
    final sp = subscriptionProvider ?? MockSubscriptionProvider();

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => child,
        ),
        GoRoute(
          path: Routes.transformationPlanDetailRoute,
          builder: (context, state) {
            final planId = state.uri.queryParameters['planId'];
            return TransformationPlanDetailScreen(planId: planId);
          },
        ),
        GoRoute(
          path: Routes.transformationRoadmapRoute,
          builder: (context, state) => const TransformationRoadmapScreen(),
        ),
        GoRoute(
          path: Routes.transformationProgressRoute,
          builder: (context, state) => const TransformationProgressScreen(),
        ),
        GoRoute(
          path: Routes.strengthAnalyticsRoute,
          builder: (context, state) => const Scaffold(body: Text('Strength Analytics Page')),
        ),
        GoRoute(
          path: Routes.workoutHistoryRoute,
          builder: (context, state) => const Scaffold(body: Text('Workout History Page')),
        ),
        GoRoute(
          path: Routes.dietRoute,
          builder: (context, state) => const Scaffold(body: Text('Diet Plans Page')),
        ),
        GoRoute(
          path: Routes.mainRoute,
          builder: (context, state) => const Scaffold(body: Text('Main Dashboard')),
        ),
        GoRoute(
          path: Routes.newMealRoute,
          builder: (context, state) => const Scaffold(body: Text('New Meal Page')),
        ),
        GoRoute(
          path: Routes.addWaterRoute,
          builder: (context, state) => const Scaffold(body: Text('Add Water Page')),
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TransformationProvider?>.value(value: tp),
        ChangeNotifierProvider<HomeProvider?>.value(value: hp),
        ChangeNotifierProvider<SubscriptionProvider>.value(value: sp),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
  }

  group('Gym Buddy — Phase 6 Strength Programme Blueprint & Curriculum Integrity', () {
    final sbPlan = TransformationPlansData.strength12Week;

    test('1. Strength programme metadata matches 12-week powerbuilding requirements', () {
      expect(sbPlan.id, equals('strength_12_week'));
      expect(sbPlan.durationDays, equals(84));
      expect(sbPlan.goal, equals('STRENGTH'));
      expect(sbPlan.difficulty, equals('Intermediate'));
      expect(sbPlan.highlights.length, greaterThanOrEqualTo(4));
      expect(sbPlan.highlights.any((h) => h.contains('4-Day Strength & Power Split')), isTrue);
      expect(sbPlan.highlights.any((h) => h.contains('Linear Periodization')), isTrue);
      expect(sbPlan.highlights.any((h) => h.contains('PR Vault Integration')), isTrue);
      expect(sbPlan.highlights.any((h) => h.contains('Scheduled Deload Weeks')), isTrue);
    });

    test('2. Exactly 12 weeks of programme content across 3 phases', () {
      expect(sbPlan.allWeeks.length, equals(12));
      expect(sbPlan.phases.length, equals(3));
      // Phase 1: Weeks 1-4
      expect(sbPlan.phases[0].weeks.length, equals(4));
      // Phase 2: Weeks 5-8
      expect(sbPlan.phases[1].weeks.length, equals(4));
      // Phase 3: Weeks 9-12
      expect(sbPlan.phases[2].weeks.length, equals(4));
    });

    test('3. Correct total day count: 84 days without ghost days', () {
      int totalDays = 0;
      for (final phase in sbPlan.phases) {
        for (final week in phase.weeks) {
          totalDays += week.days.length;
        }
      }
      expect(totalDays, equals(84));
      expect(sbPlan.durationDays, equals(84));
      expect(sbPlan.getDayBlueprint(84), isNotNull);
      expect(sbPlan.getDayBlueprint(85), isNull, reason: 'Day 85 must not exist');
    });

    test('4. Weekly workout distribution: 4 training days & 3 recovery/rest days', () {
      for (final week in sbPlan.allWeeks) {
        final workouts = week.days.where((d) => d.dayType == 'workout').length;
        final restDays = week.days.where((d) => d.dayType == 'rest' || d.dayType == 'active_recovery').length;
        expect(workouts, equals(4), reason: 'Week ${week.weekNumber} must have exactly 4 workouts');
        expect(restDays, equals(3), reason: 'Week ${week.weekNumber} must have exactly 3 rest/recovery days');
      }
    });

    test('5. Compound and accessory exercise balance across training days', () {
      final week1 = sbPlan.allWeeks[0];
      // Day 1: Bench Press & Accessories
      final day1 = week1.days[0];
      expect(day1.exerciseNames.contains('Barbell Bench Press'), isTrue);
      expect(day1.exerciseNames.contains('Barbell Close Grip Bench Press'), isTrue);

      // Day 2: Squat & Core
      final day2 = week1.days[1];
      expect(day2.exerciseNames.contains('Classic Barbell Squat'), isTrue);
      expect(day2.exerciseNames.contains('Twisting Crunch'), isTrue);

      // Day 4: Deadlift & Posterior Chain
      final day4 = week1.days[3];
      expect(day4.exerciseNames.contains('Smith Deadlift'), isTrue);
      expect(day4.exerciseNames.contains('Pull-ups Wide Back Grip'), isTrue);

      // Day 5: Military Press & Power
      final day5 = week1.days[4];
      expect(day5.exerciseNames.contains('Military Press'), isTrue);
      expect(day5.exerciseNames.contains('Chest Dips'), isTrue);
    });

    test('6. Progressive strength programming across phases (5x5 -> heavy wave -> peak)', () {
      // Phase 1 (Week 1): 5x5 compound foundation
      final week1Workout = sbPlan.allWeeks[0].days[0];
      expect(week1Workout.targetSets, equals(5));
      expect(week1Workout.targetReps, equals('5'));

      // Phase 2 (Week 5): Heavy 3-5 rep strength wave
      final week5Workout = sbPlan.allWeeks[4].days[0];
      expect(week5Workout.targetSets, equals(4));
      expect(week5Workout.targetReps, equals('3-5'));

      // Phase 3 (Week 9): Heavy Triples
      final week9Workout = sbPlan.allWeeks[8].days[0];
      expect(week9Workout.targetSets, equals(4));
      expect(week9Workout.targetReps, equals('3'));
    });

    test('7. Deload and recovery structure at Weeks 4, 8 & 11', () {
      for (final deloadWeekNum in [4, 8, 11]) {
        final deloadWeek = sbPlan.allWeeks[deloadWeekNum - 1];
        expect(deloadWeek.weekTip?.toLowerCase(), contains('deload'));

        for (final day in deloadWeek.days.where((d) => d.dayType == 'workout')) {
          expect(day.targetSets, equals(3), reason: 'Week $deloadWeekNum workouts must have reduced volume (3 sets)');
          expect(day.notes?.toLowerCase(), contains('deload'));
        }
      }
    });

    test('8. Canonical exercise catalogue matching for all 16 unique exercises', () {
      final allExercises = <String>{};
      for (final week in sbPlan.allWeeks) {
        for (final day in week.days) {
          allExercises.addAll(day.exerciseNames);
        }
      }

      expect(allExercises.length, equals(16));

      final catalogNames = ExerciseData.all.map((e) => e.name).toSet();
      for (final exName in allExercises) {
        expect(catalogNames.contains(exName), isTrue, reason: '$exName must exist in ExerciseData.all');
      }

      // Explicit verification of canonical names
      expect(allExercises.contains('Barbell Close Grip Bench Press'), isTrue);
      expect(allExercises.contains('Military Press'), isTrue);
      expect(allExercises.contains('Incline Dumbbell Press'), isTrue);
    });
  });

  group('Gym Buddy — Phase 6 Equipment Adaptation & Progressive Strength Intelligence', () {
    test('9. Home equipment alternatives convert heavy gym apparatus to dumbbells and bodyweight', () {
      const gymExercises = [
        'Barbell Bench Press',
        'Barbell Close Grip Bench Press',
        'Classic Barbell Squat',
        'Barbell Straight Leg Deadlift',
        'Leg Press',
        'Smith Deadlift',
        'Barbell Underhand Bent Over Row',
        'Military Press',
        'Chest Dips',
        'Barbell Curl',
      ];

      final homeAdapted = TransformationEquipmentAdapter.adaptExercisesForEnvironment(
        exerciseNames: gymExercises,
        workoutLocation: 'home',
        availableEquipment: ['dumbbells'],
      );

      expect(homeAdapted.contains('Barbell Bench Press'), isFalse);
      expect(homeAdapted.contains('Incline Dumbbell Press'), isTrue);
      expect(homeAdapted.contains('Dumbbell Close Grip Press'), isTrue);
      expect(homeAdapted.contains('Dumbbell Goblet Squat'), isTrue);
      expect(homeAdapted.contains('Dumbbell Sumo Squat'), isTrue);
      expect(homeAdapted.contains('Dumbbell Bent Over Row'), isTrue);
      expect(homeAdapted.contains('Dumbbell Bench Seated Press'), isTrue);
      expect(homeAdapted.contains('Deep Pushups'), isTrue);
      expect(homeAdapted.contains('Dumbbell Biceps Curl'), isTrue);
    });

    test('10. Commercial gym equipment preservation for gym lifters', () {
      const gymExercises = [
        'Barbell Bench Press',
        'Classic Barbell Squat',
        'Smith Deadlift',
        'Military Press',
      ];

      final gymAdapted = TransformationEquipmentAdapter.adaptExercisesForEnvironment(
        exerciseNames: gymExercises,
        workoutLocation: 'gym',
        availableEquipment: ['barbell', 'dumbbells', 'cables', 'machines'],
      );

      expect(gymAdapted, equals(gymExercises));
    });

    test('11. Previous weight and repetition memory via WorkoutLogService cache', () {
      WorkoutLogService.clearLastLogCache();

      // Seed previous bench press performance
      final prevBenchLog = WorkoutLog(
        id: 'bench_log_1',
        exerciseName: 'Barbell Bench Press',
        date: DateTime.now().subtract(const Duration(days: 3)),
        category: 'Chest',
        sets: [
          WorkoutSet(weight: 100.0, reps: 5, isCompleted: true),
        ],
      );
      WorkoutLogService.seedLastLogCache('Barbell Bench Press', prevBenchLog);

      final retrieved = WorkoutLogService.getCachedLastLog('Barbell Bench Press');
      expect(retrieved, isNotNull);
      expect(retrieved!.sets.first.weight, equals(100.0));
      expect(retrieved.sets.first.reps, equals(5));

      WorkoutLogService.clearLastLogCache();
    });

    test('12. Workout completion and progress persistence in TransformationProvider', () async {
      Map<String, dynamic>? savedDoc;
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'sb_tester_1';
      provider.activeDocSaverForTesting = (uid, data) async {
        savedDoc = data;
      };
      provider.activeDocFetcherForTesting = (uid) => savedDoc;

      final blueprint = TransformationPlansData.strength12Week;
      await provider.enrollInPlan(
        blueprint: blueprint,
        targetCalories: 2600.0,
        targetMacros: const {'protein': 175.0, 'carbs': 300.0, 'fat': 70.0},
        workoutLocation: 'gym',
        experienceLevel: 'Intermediate',
      );

      expect(provider.hasActiveTransformation, isTrue);
      expect(provider.activeTransformation?.planId, equals('strength_12_week'));
      expect(provider.activeTransformation?.totalDays, equals(84));
      expect(provider.activeTransformation?.currentDay, equals(1));

      // Mark Day 1 complete
      await provider.markDayCompleted(1);
      expect(provider.isDayCompleted(1), isTrue);
      expect(savedDoc?['completedDayIndices'], contains(1));
    });

    test('13. Estimated 1RM calculation guardrails and Epley formula accuracy', () {
      // 100kg for 5 reps -> 100 * (1 + 5/30) = 116.67 kg
      final est1RM = StrengthService.calculateEstimated1RMFromValues(
        weight: 100.0,
        reps: 5,
      );
      expect(est1RM, closeTo(116.67, 0.05));

      // 1 rep is exact weight
      expect(
        StrengthService.calculateEstimated1RMFromValues(weight: 120.0, reps: 1),
        equals(120.0),
      );

      // Warmup set returns 0
      expect(
        StrengthService.calculateEstimated1RMFromValues(weight: 100.0, reps: 5, isWarmup: true),
        equals(0.0),
      );

      // Non-positive weight returns 0
      expect(
        StrengthService.calculateEstimated1RMFromValues(weight: 0.0, reps: 5),
        equals(0.0),
      );
    });

    test('14. Existing PR detection and PR Vault integration', () {
      final strengthService = StrengthService();

      final session1 = WorkoutSession(
        id: 's1',
        userId: 'test_user',
        workoutName: 'Heavy Bench Day',
        dayName: 'Day 1',
        startedAt: DateTime.now().subtract(const Duration(days: 7)),
        completedAt: DateTime.now().subtract(const Duration(days: 7, hours: -1)),
        totalVolume: 500.0,
        exercises: [
          SessionExercise(
            exerciseName: 'Barbell Bench Press',
            order: 1,
            isCompleted: true,
            sets: [
              WorkoutSet(weight: 100.0, reps: 5, isCompleted: true),
            ],
          ),
        ],
      );

      final session2 = WorkoutSession(
        id: 's2',
        userId: 'test_user',
        workoutName: 'Heavy Bench PR Day',
        dayName: 'Day 1',
        startedAt: DateTime.now().subtract(const Duration(days: 1)),
        completedAt: DateTime.now().subtract(const Duration(days: 1, hours: -1)),
        totalVolume: 525.0,
        exercises: [
          SessionExercise(
            exerciseName: 'Barbell Bench Press',
            order: 1,
            isCompleted: true,
            sets: [
              WorkoutSet(weight: 105.0, reps: 5, isCompleted: true),
            ],
          ),
        ],
      );

      final prs = strengthService.getAllTimePRs(sessions: [session1, session2]);
      expect(prs.containsKey('barbell bench press'), isTrue);
      final benchPR = prs['barbell bench press']!;
      expect(benchPR.weight, equals(105.0));
      expect(benchPR.reps, equals(5));
      expect(benchPR.estimated1RM, closeTo(122.5, 0.1));
    });
  });

  group('Gym Buddy — Phase 6 Widget UX, Guidance & Graduation', () {
    testWidgets('15. Strength Guide Card renders with overload expectations & shortcuts on Detail Screen', (tester) async {
      await tester.pumpWidget(
        wrapWithScreenUtilAndRouter(
          child: const TransformationPlanDetailScreen(planId: 'strength_12_week'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('12-Week Strength Building Challenge'), findsOneWidget);
      expect(find.text('84 DAYS'), findsOneWidget);
      expect(find.text('Strength Guide: What to Expect'), findsOneWidget);

      // Verify Strength Guide Card exists
      final guideCardFinder = find.byKey(const Key('strength_onboarding_guide_card'));
      expect(guideCardFinder, findsOneWidget);

      // Verify guidance points
      expect(find.text('12-Week Strength: Science & Progressive Overload Guidelines'), findsOneWidget);
      expect(find.text('Strength vs. Hypertrophy'), findsOneWidget);
      expect(find.text('Core Compound Lifts'), findsOneWidget);
      expect(find.text('2–3 Minutes Rest Between Sets'), findsOneWidget);
      expect(find.text('Technique Before Load Overload'), findsOneWidget);
      expect(find.text('Scheduled CNS Deloads (Weeks 4, 8 & 11)'), findsOneWidget);
      expect(find.text('Estimated 1RM & PR Vault Integration'), findsOneWidget);

      // Verify companion action buttons
      expect(find.byKey(const Key('explore_strength_analytics_from_detail_btn')), findsOneWidget);
      expect(find.byKey(const Key('explore_workout_history_from_detail_btn')), findsOneWidget);
    });

    testWidgets('16. Roadmap Screen renders strength orientation banner & PR Vault advisory card', (tester) async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'sb_tester_1';
      provider.activeDocSaverForTesting = (uid, data) async {};

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.strength12Week,
        targetCalories: 2600.0,
        targetMacros: const {'protein': 175.0, 'carbs': 300.0, 'fat': 70.0},
        workoutLocation: 'gym',
        experienceLevel: 'Intermediate',
      );

      await tester.pumpWidget(
        wrapWithScreenUtilAndRouter(
          child: const TransformationRoadmapScreen(),
          transformationProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      // Verify orientation banner
      expect(find.byKey(const Key('strength_roadmap_orientation_banner')), findsOneWidget);
      expect(find.textContaining('Strength Rule: Compound Mastery'), findsOneWidget);

      // Scroll to Strength Intelligence Advisory Card
      final advisoryCard = find.byKey(const Key('strength_intelligence_advisory_card'));
      await tester.scrollUntilVisible(advisoryCard, 300);
      expect(advisoryCard, findsOneWidget);
      expect(find.byKey(const Key('roadmap_pr_vault_btn')), findsOneWidget);
      expect(find.byKey(const Key('roadmap_strength_history_btn')), findsOneWidget);

      // Verify nutrition bar actions
      expect(find.byKey(const Key('nutrition_bar_log_meal_btn')), findsOneWidget);
      expect(find.byKey(const Key('nutrition_bar_log_water_btn')), findsOneWidget);
      expect(find.text('Strength Fuel'), findsOneWidget);
    });

    testWidgets('17. Progress Screen renders strength progress card and fueling bridge', (tester) async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'sb_tester_1';
      provider.activeDocSaverForTesting = (uid, data) async {};

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.strength12Week,
        targetCalories: 2600.0,
        targetMacros: const {'protein': 175.0, 'carbs': 300.0, 'fat': 70.0},
        workoutLocation: 'gym',
        experienceLevel: 'Intermediate',
      );

      await tester.pumpWidget(
        wrapWithScreenUtilAndRouter(
          child: const TransformationProgressScreen(),
          transformationProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      // Verify strength card and nutrition targets
      expect(find.byKey(const Key('transformation_strength_progress_card')), findsOneWidget);
      expect(find.byKey(const Key('transformation_nutrition_hydration_card')), findsOneWidget);
      expect(find.textContaining('Personalized nutrition targets to fuel maximal neural output'), findsOneWidget);

      // Verify Strength Nutrition bridge
      expect(find.byKey(const Key('progress_strength_nutrition_btn')), findsOneWidget);
    });

    testWidgets('18. Graduation Screen renders all 4 Strength pathways without automatic enrolment', (tester) async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'sb_tester_1';

      final completedState = UserTransformationState(
        planId: 'strength_12_week',
        planTitle: '12-Week Strength Building Challenge',
        startDate: DateTime.now().subtract(const Duration(days: 84)),
        targetEndDate: DateTime.now(),
        currentDay: 84,
        totalDays: 84,
        status: 'completed',
        completedAt: DateTime.now(),
        completedDayIndices: List.generate(84, (i) => i + 1),
        startingWeight: 82.0,
        targetCalories: 2600.0,
        targetMacros: const {'protein': 175.0, 'carbs': 300.0, 'fat': 70.0},
      );

      await tester.pumpWidget(
        wrapWithScreenUtilAndRouter(
          child: TransformationCompletionScreen(completedState: completedState),
          transformationProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('12-Week Strength Building Challenge'), findsOneWidget);
      expect(find.text('Graduate to Your Next Chapter'), findsOneWidget);

      // Verify all 4 pathways for strength graduates
      expect(find.text('Repeat 12-Week Strength Challenge'), findsOneWidget);
      expect(find.byKey(const Key('graduate_sb_to_repeat_btn')), findsOneWidget);

      expect(find.text('90-Day Muscle Building Challenge'), findsOneWidget);
      expect(find.byKey(const Key('graduate_sb_to_muscle_btn')), findsOneWidget);

      expect(find.text('General Fitness & Strength Maintenance'), findsOneWidget);
      expect(find.byKey(const Key('graduate_sb_to_maintenance_btn')), findsOneWidget);

      expect(find.text('60-Day Fat Loss & Cutting Challenge'), findsOneWidget);
      expect(find.byKey(const Key('graduate_sb_to_cut_btn')), findsOneWidget);

      // Verify user is NOT auto-enrolled
      expect(provider.hasActiveTransformation, isFalse);
    });
  });
}
