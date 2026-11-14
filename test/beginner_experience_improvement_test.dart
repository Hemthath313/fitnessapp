import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_completion_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_plan_detail_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_roadmap_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/utils/transformation_equipment_adapter.dart';
import 'package:fitness_app/utils/router/router.dart';

class MockHomeProvider extends ChangeNotifier implements HomeProvider {
  @override
  Map<String, dynamic> userData = {
    'name': 'Test Novice',
    'experience': 'Beginner',
    'fitness_goal': 'Maintain',
    'weight': 70.0,
    'height': 175.0,
    'age': 28,
    'gender': 'Male',
    'activity': 'LIGHT',
  };

  @override
  Future<Map<String, dynamic>> fetchUserData() async => userData;

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
  }) {
    final tp = transformationProvider ?? TransformationProvider(autoLoad: false);
    final hp = homeProvider ?? MockHomeProvider();

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
          path: Routes.mainRoute,
          builder: (context, state) => const Scaffold(body: Text('Main Dashboard')),
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TransformationProvider?>.value(value: tp),
        ChangeNotifierProvider<HomeProvider?>.value(value: hp),
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

  group('Gym Buddy – Phase 3 Complete Beginner Blueprint & Curriculum Tests', () {
    final beginnerPlan = TransformationPlansData.beginnerFitness30;

    test('1. Blueprint metadata matches 30-day novice requirements', () {
      expect(beginnerPlan.id, equals('beginner_fitness_30'));
      expect(beginnerPlan.durationDays, equals(30));
      expect(beginnerPlan.difficulty, equals('Beginner'));
      expect(beginnerPlan.goal, equals('MAINTAIN'));
      expect(beginnerPlan.highlights.length, greaterThanOrEqualTo(4));
      expect(beginnerPlan.highlights.any((h) => h.contains('3 Manageable 25–35 Min')), isTrue);
      expect(beginnerPlan.highlights.any((h) => h.contains('4 Scheduled Active Recovery & Rest Days')), isTrue);
    });

    test('2. Total days across all 5 weeks equals exactly 30 days without ghost days', () {
      int totalDays = 0;
      for (final phase in beginnerPlan.phases) {
        for (final week in phase.weeks) {
          totalDays += week.days.length;
        }
      }
      expect(totalDays, equals(30));
      expect(beginnerPlan.durationDays, equals(30));

      // Week breakdown: 7 + 7 + 7 + 7 + 2 = 30
      final allWeeks = beginnerPlan.phases.expand((p) => p.weeks).toList();
      expect(allWeeks.length, equals(5));
      expect(allWeeks[0].days.length, equals(7));
      expect(allWeeks[1].days.length, equals(7));
      expect(allWeeks[2].days.length, equals(7));
      expect(allWeeks[3].days.length, equals(7));
      expect(allWeeks[4].days.length, equals(2));
    });

    test('3. Recovery days properly distributed: 3 workout days & 4 recovery/rest days per week', () {
      final week1 = beginnerPlan.phases[0].weeks[0];
      final workoutDaysW1 = week1.days.where((d) => d.dayType == 'workout').toList();
      final restDaysW1 = week1.days.where((d) => d.dayType == 'rest' || d.dayType == 'active_recovery').toList();

      expect(workoutDaysW1.length, equals(3)); // Days 1, 3, 5
      expect(restDaysW1.length, equals(4)); // Days 2, 4, 6, 7

      final week2 = beginnerPlan.phases[1].weeks[0];
      final workoutDaysW2 = week2.days.where((d) => d.dayType == 'workout').toList();
      final restDaysW2 = week2.days.where((d) => d.dayType == 'rest' || d.dayType == 'active_recovery').toList();

      expect(workoutDaysW2.length, equals(3));
      expect(restDaysW2.length, equals(4));
    });

    test('4. Day 1 exercise suitability and starting targets', () {
      final day1 = beginnerPlan.getDayBlueprint(1);
      expect(day1, isNotNull);
      expect(day1!.dayType, equals('workout'));
      expect(day1.targetSets, equals(3));
      expect(day1.targetReps, equals('8-10'));
      expect(day1.exerciseNames, containsAll(['Deep Pushups', 'Dumbbell Goblet Squat', 'Twisting Crunch']));
      expect(day1.notes, contains('Rest 60-90s'));

      // Check warm-up & cool-down routines are generated
      expect(day1.warmupExercises.isNotEmpty, isTrue);
      expect(day1.cooldownExercises.isNotEmpty, isTrue);
    });

    test('5. Day 29 benchmark assessment mirrors Day 1 baseline exercises for comparison', () {
      final day1 = beginnerPlan.getDayBlueprint(1)!;
      final day29 = beginnerPlan.getDayBlueprint(29)!;

      expect(day29.dayType, equals('workout'));
      expect(day29.exerciseNames, equals(day1.exerciseNames));
      expect(day29.muscleGroup, contains('Benchmark Assessment'));
      expect(day29.notes, contains('Day 1'));
    });

    test('6. Day 30 graduation active recovery day', () {
      final day30 = beginnerPlan.getDayBlueprint(30)!;
      expect(day30.dayType, equals('active_recovery'));
      expect(day30.muscleGroup, contains('Graduation'));
    });

    test('7. Canonical exercise catalog compatibility and home adaptations', () {
      final day1Exercises = beginnerPlan.getDayBlueprint(1)!.exerciseNames;
      for (final exName in day1Exercises) {
        final found = ExerciseData.findByName(exName);
        expect(found, isNotNull, reason: 'Exercise $exName must exist in canonical ExerciseData');
      }

      // Home adaptation test
      final adapted = TransformationEquipmentAdapter.adaptExercisesForEnvironment(
        exerciseNames: ['Cable Seated Row', 'Leg Press'],
        workoutLocation: 'home',
        availableEquipment: const ['Dumbbells'],
      );
      expect(adapted.contains('Cable Seated Row'), isFalse);
      expect(adapted.contains('Dumbbell Bent Over Row'), isTrue);
    });
  });

  group('Gym Buddy – Phase 3 Enrolment, Persistence & Cancellation Tests', () {
    test('8. Enrolment in beginner programme initializes 30-day active state', () async {
      Map<String, dynamic>? savedDoc;
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'novice_user_1';
      provider.activeDocSaverForTesting = (uid, data) async {
        savedDoc = data;
      };
      provider.activeDocFetcherForTesting = (uid) => savedDoc;

      expect(provider.hasActiveTransformation, isFalse);

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2100.0,
        targetMacros: const {'protein': 140.0, 'carbs': 240.0, 'fat': 60.0},
        workoutLocation: 'home',
        experienceLevel: 'Beginner',
      );

      expect(provider.hasActiveTransformation, isTrue);
      expect(provider.activeTransformation?.planId, equals('beginner_fitness_30'));
      expect(provider.activeTransformation?.totalDays, equals(30));
      expect(provider.activeTransformation?.currentDay, equals(1));
      expect(provider.activeTransformation?.completedDayIndices, isEmpty);
      expect(savedDoc, isNotNull);
      expect(savedDoc!['planId'], equals('beginner_fitness_30'));
    });

    test('9. Workout completion updates progress and persists', () async {
      Map<String, dynamic>? savedDoc;
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'novice_user_1';
      provider.activeDocSaverForTesting = (uid, data) async {
        savedDoc = data;
      };
      provider.activeDocFetcherForTesting = (uid) => savedDoc;

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2100.0,
        targetMacros: const {'protein': 140.0, 'carbs': 240.0, 'fat': 60.0},
        workoutLocation: 'gym',
        experienceLevel: 'Beginner',
      );

      expect(provider.isDayCompleted(1), isFalse);

      // Complete Day 1 workout (canonical session completion callback)
      await provider.markDayCompleted(1);
      expect(provider.isDayCompleted(1), isTrue);
      expect(provider.activeTransformation?.completedDayIndices, contains(1));
      expect(savedDoc!['completedDayIndices'], contains(1));

      // Toggle off / on
      await provider.toggleDayCompletion(1);
      expect(provider.isDayCompleted(1), isFalse);
      await provider.toggleDayCompletion(1);
      expect(provider.isDayCompleted(1), isTrue);
    });

    test('10. Programme cancellation and restart safety', () async {
      Map<String, dynamic>? savedDoc;
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'novice_user_1';
      provider.activeDocSaverForTesting = (uid, data) async {
        savedDoc = data;
      };
      provider.activeDocFetcherForTesting = (uid) => savedDoc;

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2100.0,
        targetMacros: const {'protein': 140.0, 'carbs': 240.0, 'fat': 60.0},
        workoutLocation: 'home',
        experienceLevel: 'Beginner',
      );

      expect(provider.hasActiveTransformation, isTrue);

      // Cancel programme
      await provider.abandonPlan();
      expect(provider.hasActiveTransformation, isFalse);
      expect(savedDoc?.isEmpty ?? false, isTrue);

      // Re-enrol restart
      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2100.0,
        targetMacros: const {'protein': 140.0, 'carbs': 240.0, 'fat': 60.0},
        workoutLocation: 'gym',
        experienceLevel: 'Beginner',
      );
      expect(provider.hasActiveTransformation, isTrue);
      expect(provider.activeTransformation?.currentDay, equals(1));
      expect(provider.activeTransformation?.completedDayIndices, isEmpty);
    });

    test('11. Reaching Day 30 and completePlan moves state to history', () async {
      Map<String, dynamic>? savedDoc;
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'novice_user_1';
      provider.activeDocSaverForTesting = (uid, data) async {
        savedDoc = data;
      };
      provider.activeDocFetcherForTesting = (uid) => savedDoc;

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2100.0,
        targetMacros: const {'protein': 140.0, 'carbs': 240.0, 'fat': 60.0},
        workoutLocation: 'gym',
        experienceLevel: 'Beginner',
      );

      // Complete all 30 days
      for (int i = 1; i <= 30; i++) {
        await provider.markDayCompleted(i);
      }
      expect(provider.activeTransformation?.completionPercentage, equals(1.0));
      expect(provider.activeTransformation?.completedDayIndices.length, equals(30));

      // Complete plan
      await provider.completePlan();
      expect(provider.hasActiveTransformation, isFalse);
      expect(provider.history.length, equals(1));
      expect(provider.history.first.planId, equals('beginner_fitness_30'));
      expect(provider.history.first.isCompleted, isTrue);
    });
  });

  group('Gym Buddy – Phase 3 UI & Widget Tests', () {
    testWidgets('12. Beginner Plan Detail Screen renders Beginner Guide Card with all expectations', (tester) async {
      await tester.pumpWidget(
        wrapWithScreenUtilAndRouter(
          child: const TransformationPlanDetailScreen(planId: 'beginner_fitness_30'),
        ),
      );
      await tester.pumpAndSettle();

      // Check title and highlights
      expect(find.text('Complete Beginner – 30 Days'), findsOneWidget);
      expect(find.text('30 DAYS'), findsOneWidget);
      expect(find.text('Beginner Guide: What to Expect'), findsOneWidget);

      // Check Beginner Onboarding Card contents
      expect(find.byKey(const Key('beginner_onboarding_guide_card')), findsOneWidget);
      expect(find.text('3 Workouts per Week'), findsOneWidget);
      expect(find.text('4 Recovery & Rest Days'), findsOneWidget);
      expect(find.text('Home or Gym Flexibility'), findsOneWidget);
      expect(find.text('Guided Workout Tracking'), findsOneWidget);
      expect(find.text('Lifelong Habit & Graduation'), findsOneWidget);

      // Check CTA
      expect(find.byKey(const Key('plan_detail_bottom_cta')), findsOneWidget);
    });

    testWidgets('13. Roadmap Screen renders active progress and orientation banner for beginner', (tester) async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_novice';
      provider.activeDocSaverForTesting = (uid, data) async {};

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000.0,
        targetMacros: const {'protein': 140.0, 'carbs': 220.0, 'fat': 60.0},
        workoutLocation: 'gym',
        experienceLevel: 'Beginner',
      );

      await tester.pumpWidget(
        wrapWithScreenUtilAndRouter(
          transformationProvider: provider,
          child: const TransformationRoadmapScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Complete Beginner – 30 Days'), findsOneWidget);
      expect(find.text('Day 1 of 30'), findsOneWidget);
      // Tips, nutrition and advice live in the folded "Plan guide" section.
      await tester.ensureVisible(find.byKey(const Key('plan_guide_toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('plan_guide_toggle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('beginner_roadmap_orientation_banner')), findsOneWidget);
      expect(find.textContaining('Beginner Rule: Form beats weight'), findsOneWidget);
    });

    testWidgets('14. Graduation Screen renders all 4 progression pathways without auto-enrolment', (tester) async {
      final completedState = UserTransformationState(
        planId: 'beginner_fitness_30',
        planTitle: 'Complete Beginner – 30 Days',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        targetEndDate: DateTime.now(),
        currentDay: 30,
        totalDays: 30,
        status: 'completed',
        completedAt: DateTime.now(),
        completedDayIndices: List.generate(30, (i) => i + 1),
        startingWeight: 75.0,
        targetCalories: 2000.0,
        targetMacros: const {'protein': 140.0, 'carbs': 220.0, 'fat': 60.0},
      );

      await tester.pumpWidget(
        wrapWithScreenUtilAndRouter(
          child: TransformationCompletionScreen(completedState: completedState),
        ),
      );
      await tester.pumpAndSettle();

      // Check trophy and completion title
      expect(find.text('Complete Beginner – 30 Days'), findsOneWidget);
      expect(find.text('Graduate to Your Next Programme'), findsOneWidget);

      // Verify all 4 progression options are present:
      // 1. Muscle Building
      expect(find.text('90-Day Muscle Building Challenge'), findsOneWidget);
      expect(find.byKey(const Key('graduate_to_muscle_building_btn')), findsOneWidget);

      // 2. Weight Loss
      expect(find.text('60-Day Weight Loss Challenge'), findsOneWidget);
      expect(find.byKey(const Key('graduate_to_weight_loss_btn')), findsOneWidget);

      // 3. Strength Building
      expect(find.text('12-Week Strength Building Challenge'), findsOneWidget);
      expect(find.byKey(const Key('graduate_to_strength_btn')), findsOneWidget);

      // 4. Continued General Fitness
      expect(find.text('Continued General Fitness'), findsOneWidget);
      expect(find.byKey(const Key('graduate_to_maintenance_btn')), findsOneWidget);

      // Tap Muscle Building CTA -> navigates to plan detail without auto-enrolling
      await tester.ensureVisible(find.byKey(const Key('graduate_to_muscle_building_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('graduate_to_muscle_building_btn')));
      await tester.pumpAndSettle();
      expect(find.text('90-Day Muscle Building Challenge'), findsAtLeastNWidgets(1));
    });
  });
}
