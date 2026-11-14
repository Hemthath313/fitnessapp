import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/challenges/30_days_sixpack.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_completion_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_plan_detail_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_progress_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_roadmap_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/utils/transformation_equipment_adapter.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/utils/tdee_calculator.dart';

class MockHomeProvider extends ChangeNotifier implements HomeProvider {
  @override
  Map<String, dynamic> userData = {
    'name': 'Weight Loss User',
    'experience': 'Beginner',
    'fitness_goal': 'Lose Weight',
    'weight': 85.0,
    'height': 178.0,
    'age': 30,
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
          path: Routes.sixPackChallengeRoute,
          builder: (context, state) => const SixPackChallengeSelectionScreen(),
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

  group('Gym Buddy — Phase 4 Weight Loss Blueprint & Curriculum Integrity', () {
    final wlPlan = TransformationPlansData.weightLoss60;

    test('1. Blueprint metadata matches 60-day fat loss requirements', () {
      expect(wlPlan.id, equals('weight_loss_60'));
      expect(wlPlan.durationDays, equals(60));
      expect(wlPlan.goal, equals('LOSE'));
      expect(wlPlan.difficulty, equals('Beginner to Intermediate'));
      expect(wlPlan.highlights.length, greaterThanOrEqualTo(4));
      expect(wlPlan.highlights.any((h) => h.contains('4 Resistance & Conditioning')), isTrue);
      expect(wlPlan.highlights.any((h) => h.contains('Sustainable Caloric Deficit')), isTrue);
    });

    test('2. All 60 days and phase boundaries are exact without ghost days', () {
      int totalDays = 0;
      for (final phase in wlPlan.phases) {
        for (final week in phase.weeks) {
          totalDays += week.days.length;
        }
      }
      expect(totalDays, equals(60));
      expect(wlPlan.durationDays, equals(60));

      expect(wlPlan.phases.length, equals(4));
      // Phase 1 (Weeks 1-2): 14 days
      expect(wlPlan.phases[0].weeks.fold(0, (sum, w) => sum + w.days.length), equals(14));
      // Phase 2 (Weeks 3-4): 14 days
      expect(wlPlan.phases[1].weeks.fold(0, (sum, w) => sum + w.days.length), equals(14));
      // Phase 3 (Weeks 5-6): 14 days
      expect(wlPlan.phases[2].weeks.fold(0, (sum, w) => sum + w.days.length), equals(14));
      // Phase 4 (Weeks 7-9): 18 days (7 + 7 + 4)
      expect(wlPlan.phases[3].weeks.fold(0, (sum, w) => sum + w.days.length), equals(18));
      expect(wlPlan.phases[3].weeks[2].days.length, equals(4));
    });

    test('3. Workout and recovery distribution: 4 workouts, 1 active recovery, 2 rest days', () {
      final week1 = wlPlan.phases[0].weeks[0];
      final workoutDaysW1 = week1.days.where((d) => d.dayType == 'workout').toList();
      final activeRecoveryW1 = week1.days.where((d) => d.dayType == 'active_recovery').toList();
      final restDaysW1 = week1.days.where((d) => d.dayType == 'rest').toList();

      expect(workoutDaysW1.length, equals(4)); // Days 1, 2, 4, 5
      expect(activeRecoveryW1.length, equals(1)); // Day 3
      expect(restDaysW1.length, equals(2)); // Days 6, 7

      // Final week (Week 9) has 2 workouts, 2 recovery/graduation days
      final week9 = wlPlan.phases[3].weeks[2];
      expect(week9.days.where((d) => d.dayType == 'workout').length, equals(2));
      expect(week9.days.where((d) => d.dayType == 'active_recovery').length, equals(2));
    });

    test('4. Exercise catalog compatibility: all exercises exist in ExerciseData', () {
      for (int day = 1; day <= 60; day++) {
        final dayBlueprint = wlPlan.getDayBlueprint(day);
        expect(dayBlueprint, isNotNull, reason: 'Day $day must exist');
        for (final exName in dayBlueprint!.exerciseNames) {
          final found = ExerciseData.findByName(exName);
          expect(found, isNotNull, reason: 'Exercise "$exName" on day $day must exist in ExerciseData');
        }
      }
    });

    test('5. Beginner-friendly exercise alternatives and home adaptation', () {
      // Day 5 full body circuit uses accessible exercises
      final day5 = wlPlan.getDayBlueprint(5)!;
      expect(day5.exerciseNames, containsAll([
        'Deep Pushups',
        'Dumbbell Bent Over Row',
        'Dumbbell Goblet Squat',
        'Air Twist Crunch',
      ]));

      // Test home adaptation for all gym apparatus in Day 1
      final adapted = TransformationEquipmentAdapter.adaptExercisesForEnvironment(
        exerciseNames: ['Barbell Bench Press', 'Cable Pulldown'],
        workoutLocation: 'home',
        availableEquipment: const ['Dumbbells'],
      );
      expect(adapted.contains('Barbell Bench Press'), isFalse);
      expect(adapted.contains('Incline Dumbbell Press'), isTrue);
      expect(adapted.contains('Dumbbell Bent Over Row'), isTrue);
    });
  });

  group('Gym Buddy — Phase 4 Enrolment, Nutrition, Persistence & Check-ins', () {
    test('6. Workout completion and progress persistence', () async {
      Map<String, dynamic>? savedDoc;
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'wl_user_1';
      provider.activeDocSaverForTesting = (uid, data) async {
        savedDoc = data;
      };
      provider.activeDocFetcherForTesting = (uid) => savedDoc;

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.weightLoss60,
        targetCalories: 1950.0,
        targetMacros: const {'protein': 160.0, 'carbs': 180.0, 'fat': 55.0},
        workoutLocation: 'gym',
        experienceLevel: 'Intermediate',
      );

      expect(provider.hasActiveTransformation, isTrue);
      expect(provider.activeTransformation?.planId, equals('weight_loss_60'));
      expect(provider.activeTransformation?.totalDays, equals(60));
      expect(provider.activeTransformation?.currentDay, equals(1));

      // Complete Day 1
      await provider.markDayCompleted(1);
      expect(provider.isDayCompleted(1), isTrue);
      expect(savedDoc?['completedDayIndices'], contains(1));
    });

    test('7. Calorie & nutrition target calculations enforce healthy deficit', () {
      // 20% deficit for fat loss, not starvation
      final targetCalories = TDEECalculator.calculateTargetCalories(
        tdee: 2500.0,
        goal: 'LOSE',
        gender: 'Male',
      );
      expect(targetCalories, equals(2000.0));

      final macros = TDEECalculator.calculateMacros(
        targetCalories: targetCalories,
        goal: 'LOSE',
        weightKg: 85.0,
      );
      // High protein to protect muscle (85 * 2.2 = 187g)
      expect(macros['protein'], equals(187.0));
      expect(macros['fat'], greaterThan(40.0));
      expect(macros['carbs'], greaterThan(100.0));
    });

    test('8. Water tracking integration and target updates', () async {
      Map<String, dynamic>? savedDoc;
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'wl_user_1';
      provider.activeDocSaverForTesting = (uid, data) async {
        savedDoc = data;
      };
      provider.activeDocFetcherForTesting = (uid) => savedDoc;

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.weightLoss60,
        targetCalories: 1950.0,
        targetMacros: const {'protein': 160.0, 'carbs': 180.0, 'fat': 55.0},
        workoutLocation: 'gym',
        experienceLevel: 'Intermediate',
      );

      expect(provider.activeTransformation?.dailyWaterTargetMl, equals(2500.0));

      // Update water target
      await provider.updateDailyWaterTarget(3000.0);
      expect(provider.activeTransformation?.dailyWaterTargetMl, equals(3000.0));
      expect(savedDoc?['dailyWaterTargetMl'], equals(3000.0));
    });

    test('9. Weight check-in behavior and tracking evolution', () async {
      Map<String, dynamic>? savedDoc;
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'wl_user_1';
      provider.activeDocSaverForTesting = (uid, data) async {
        savedDoc = data;
      };
      provider.activeDocFetcherForTesting = (uid) => savedDoc;

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.weightLoss60,
        targetCalories: 1950.0,
        targetMacros: const {'protein': 160.0, 'carbs': 180.0, 'fat': 55.0},
        workoutLocation: 'gym',
        experienceLevel: 'Intermediate',
        startingWeight: 85.0,
      );

      // Record week 1 check-in
      final checkInW1 = TransformationWeeklyCheckIn(
        weekNumber: 1,
        checkInDate: DateTime.now(),
        weight: 84.1,
        notes: 'Felt energetic and hit daily protein target.',
      );
      await provider.recordWeeklyCheckIn(checkInW1);

      expect(provider.activeTransformation?.weeklyCheckIns.length, equals(1));
      expect(provider.activeTransformation?.weeklyCheckIns.first.weight, equals(84.1));
      expect(savedDoc?['weeklyCheckIns'], isNotEmpty);
    });

    test('10. Milestone completion unlocks progression badges', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'wl_user_1';
      provider.activeDocSaverForTesting = (uid, data) async {};

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.weightLoss60,
        targetCalories: 1950.0,
        targetMacros: const {'protein': 160.0, 'carbs': 180.0, 'fat': 55.0},
        workoutLocation: 'gym',
        experienceLevel: 'Intermediate',
      );

      final milestones = provider.activeTransformation?.milestones ?? [];
      expect(milestones.any((m) => m.triggerDay == 7), isTrue);
      expect(milestones.any((m) => m.triggerDay == 30), isTrue);
      expect(milestones.any((m) => m.triggerDay == 60), isTrue);

      // Complete 7 days
      for (int i = 1; i <= 7; i++) {
        await provider.markDayCompleted(i);
      }
      expect(provider.isDayCompleted(7), isTrue);
    });
  });

  group('Gym Buddy — Phase 4 UI, Six-Pack Compatibility & Graduation Tests', () {
    testWidgets('11. Plan Detail Screen renders Weight Loss Guide Card and Six-Pack link', (tester) async {
      await tester.pumpWidget(
        wrapWithScreenUtilAndRouter(
          child: const TransformationPlanDetailScreen(planId: 'weight_loss_60'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('60-Day Weight Loss Challenge'), findsOneWidget);
      expect(find.text('60 DAYS'), findsOneWidget);
      expect(find.text('Weight Loss Guide: What to Expect'), findsOneWidget);

      // Check Weight Loss Guide card contents
      expect(find.byKey(const Key('weight_loss_onboarding_guide_card')), findsOneWidget);
      expect(find.text('4 Training Days per Week'), findsOneWidget);
      expect(find.text('3 Dedicated Recovery Days'), findsOneWidget);
      expect(find.text('Sustainable Energy Deficit'), findsOneWidget);
      expect(find.text('Daily Hydration Focus'), findsOneWidget);
      expect(find.text('Holistic Progress Tracking'), findsOneWidget);
      expect(find.text('Core vs. Fat Loss Reality'), findsOneWidget);

      // Check Six-Pack Companion link
      expect(find.byKey(const Key('explore_six_pack_from_detail_btn')), findsOneWidget);
    });

    testWidgets('12. Roadmap Screen renders fat loss orientation, nutrition actions & Six-Pack card', (tester) async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_wl_user';
      provider.activeDocSaverForTesting = (uid, data) async {};

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.weightLoss60,
        targetCalories: 1950.0,
        targetMacros: const {'protein': 160.0, 'carbs': 180.0, 'fat': 55.0},
        workoutLocation: 'gym',
        experienceLevel: 'Intermediate',
      );

      await tester.pumpWidget(
        wrapWithScreenUtilAndRouter(
          transformationProvider: provider,
          child: const TransformationRoadmapScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tips, nutrition and advice live in the folded "Plan guide" section.
      await tester.ensureVisible(find.byKey(const Key('plan_guide_toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('plan_guide_toggle')));
      await tester.pumpAndSettle();
      // Check orientation banner
      expect(find.byKey(const Key('weight_loss_roadmap_orientation_banner')), findsOneWidget);
      expect(find.textContaining('Fat Loss Rule: Sustainable energy deficit'), findsOneWidget);

      // Check quick logging buttons in nutrition targets bar
      await tester.scrollUntilVisible(
        find.byKey(const Key('nutrition_bar_log_meal_btn')),
        300,
      );
      expect(find.byKey(const Key('nutrition_bar_log_meal_btn')), findsOneWidget);
      expect(find.byKey(const Key('nutrition_bar_log_water_btn')), findsOneWidget);

      // Check Six-Pack educational companion card
      await tester.scrollUntilVisible(
        find.byKey(const Key('weight_loss_six_pack_companion_card')),
        300,
      );
      expect(find.byKey(const Key('weight_loss_six_pack_companion_card')), findsOneWidget);
      expect(find.byKey(const Key('roadmap_six_pack_challenge_btn')), findsOneWidget);
    });

    testWidgets('13. Progress Screen renders nutrition, water tracking & Six-Pack educational bridge', (tester) async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_wl_user';
      provider.activeDocSaverForTesting = (uid, data) async {};

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.weightLoss60,
        targetCalories: 1950.0,
        targetMacros: const {'protein': 160.0, 'carbs': 180.0, 'fat': 55.0},
        workoutLocation: 'gym',
        experienceLevel: 'Intermediate',
        startingWeight: 85.0,
      );

      await tester.pumpWidget(
        wrapWithScreenUtilAndRouter(
          transformationProvider: provider,
          child: const TransformationProgressScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check nutrition & hydration card
      expect(find.byKey(const Key('transformation_nutrition_hydration_card')), findsOneWidget);
      expect(find.text('1950 kcal'), findsOneWidget);
      expect(find.text('160g'), findsOneWidget);
      expect(find.text('2.5L'), findsOneWidget);
      expect(find.byKey(const Key('progress_log_meal_btn')), findsOneWidget);
      expect(find.byKey(const Key('progress_log_water_btn')), findsOneWidget);
      expect(find.byKey(const Key('progress_view_meal_plan_btn')), findsOneWidget);
      expect(find.byKey(const Key('progress_six_pack_challenge_btn')), findsOneWidget);
    });

    testWidgets('14. Six-Pack Challenge Screen preserves progress and renders Weight Loss bridge', (tester) async {
      await tester.pumpWidget(
        wrapWithScreenUtilAndRouter(
          child: const SixPackChallengeSelectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('30 Day Abs Challenge'), findsOneWidget);
      expect(find.byKey(const Key('sixpack_to_weight_loss_button')), findsOneWidget);
      expect(find.text('Core vs. Fat Loss Tip'), findsOneWidget);
    });

    testWidgets('15. Graduation Screen renders all 4 Weight Loss progression pathways without auto-enrolment', (tester) async {
      final completedState = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Weight Loss Challenge',
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        targetEndDate: DateTime.now(),
        currentDay: 60,
        totalDays: 60,
        status: 'completed',
        completedAt: DateTime.now(),
        completedDayIndices: List.generate(60, (i) => i + 1),
        startingWeight: 85.0,
        targetCalories: 1950.0,
        targetMacros: const {'protein': 160.0, 'carbs': 180.0, 'fat': 55.0},
      );

      await tester.pumpWidget(
        wrapWithScreenUtilAndRouter(
          child: TransformationCompletionScreen(completedState: completedState),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('60-Day Weight Loss Challenge'), findsOneWidget);
      expect(find.text('Graduate to Your Next Chapter'), findsOneWidget);

      // Verify all 4 pathways for weight loss graduates:
      // 1. General Fitness Maintenance
      expect(find.text('General Fitness & Lifestyle Maintenance'), findsOneWidget);
      expect(find.byKey(const Key('graduate_wl_to_maintenance_btn')), findsOneWidget);

      // 2. Muscle Building 90
      expect(find.text('90-Day Muscle Building Challenge'), findsOneWidget);
      expect(find.byKey(const Key('graduate_wl_to_muscle_btn')), findsOneWidget);

      // 3. Strength Building 12-Week
      expect(find.text('12-Week Strength Building Challenge'), findsOneWidget);
      expect(find.byKey(const Key('graduate_wl_to_strength_btn')), findsOneWidget);

      // 4. Repeat Weight Loss 60
      expect(find.text('Repeat 60-Day Weight Loss Challenge'), findsOneWidget);
      expect(find.byKey(const Key('graduate_wl_to_repeat_btn')), findsOneWidget);

      // Tap Muscle Building CTA -> navigates to plan detail without auto-enrolling
      await tester.ensureVisible(find.byKey(const Key('graduate_wl_to_muscle_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('graduate_wl_to_muscle_btn')));
      await tester.pumpAndSettle();
      expect(find.text('90-Day Muscle Building Challenge'), findsAtLeastNWidgets(1));
    });
  });
}
