import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_completion_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_plan_detail_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_progress_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_roadmap_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/utils/transformation_equipment_adapter.dart';
import 'package:fitness_app/utils/router/router.dart';

class MockHomeProvider extends ChangeNotifier implements HomeProvider {
  @override
  Map<String, dynamic> userData = {
    'name': 'Hypertrophy Athlete',
    'experience': 'Intermediate',
    'fitness_goal': 'Build Muscle',
    'weight': 75.0,
    'height': 178.0,
    'age': 25,
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
          path: Routes.bulkingDietRoute,
          builder: (context, state) => const Scaffold(body: Text('Bulking Diet Page')),
        ),
        GoRoute(
          path: Routes.strengthAnalyticsRoute,
          builder: (context, state) => const Scaffold(body: Text('Strength Analytics Page')),
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

  group('Gym Buddy — Phase 5 Muscle Gain Blueprint & Curriculum Integrity', () {
    final mbPlan = TransformationPlansData.muscleBuilding90;

    test('1. Blueprint metadata matches 90-day hypertrophy requirements', () {
      expect(mbPlan.id, equals('muscle_building_90'));
      expect(mbPlan.durationDays, equals(90));
      expect(mbPlan.goal, equals('GAIN'));
      expect(mbPlan.difficulty, equals('Beginner to Intermediate'));
      expect(mbPlan.highlights.length, greaterThanOrEqualTo(4));
      expect(mbPlan.highlights.any((h) => h.contains('4-5 Day Hypertrophy Split')), isTrue);
      expect(mbPlan.highlights.any((h) => h.contains('10-15% Clean Caloric Surplus')), isTrue);
      expect(mbPlan.highlights.any((h) => h.contains('Progressive Overload Tracking')), isTrue);
      expect(mbPlan.highlights.any((h) => h.contains('Scheduled Deload Weeks')), isTrue);
    });

    test('2. Total days across all 13 weeks equals exactly 90 days without ghost days', () {
      int totalDays = 0;
      for (final phase in mbPlan.phases) {
        for (final week in phase.weeks) {
          totalDays += week.days.length;
        }
      }
      expect(totalDays, equals(90), reason: 'All weeks combined must equal exactly 90 days');
      expect(mbPlan.durationDays, equals(90));

      expect(mbPlan.phases.length, equals(3));
      // Phase 1 (Weeks 1-4): 28 days
      expect(mbPlan.phases[0].weeks.fold(0, (sum, w) => sum + w.days.length), equals(28));
      // Phase 2 (Weeks 5-8): 28 days
      expect(mbPlan.phases[1].weeks.fold(0, (sum, w) => sum + w.days.length), equals(28));
      // Phase 3 (Weeks 9-13): 4 weeks x 7 days + Week 13 (6 days) = 34 days -> 28 + 28 + 34 = 90
      expect(mbPlan.phases[2].weeks.fold(0, (sum, w) => sum + w.days.length), equals(34));

      // Week 13 has exactly 6 days
      expect(mbPlan.allWeeks[12].days.length, equals(6));
      expect(mbPlan.getDayBlueprint(90), isNotNull);
      expect(mbPlan.getDayBlueprint(91), isNull, reason: 'Day 91 must not exist');
    });

    test('3. Scheduled deload weeks at Week 4 and Week 8 feature reduced volume', () {
      // Week 4 deload
      final week4 = mbPlan.allWeeks[3];
      final week4Workout = week4.days.firstWhere((d) => d.dayType == 'workout');
      expect(week4Workout.targetSets, equals(2));
      expect(week4Workout.targetReps, equals('8-10'));
      expect(week4.weekTip?.toLowerCase(), contains('deload'));

      // Week 8 deload
      final week8 = mbPlan.allWeeks[7];
      final week8Workout = week8.days.firstWhere((d) => d.dayType == 'workout');
      expect(week8Workout.targetSets, equals(2));
      expect(week8Workout.targetReps, equals('8-10'));
      expect(week8.weekTip?.toLowerCase(), contains('deload'));

      // Non-deload weeks have higher volume (3 or 4 sets)
      final week2Workout = mbPlan.allWeeks[1].days.firstWhere((d) => d.dayType == 'workout');
      expect(week2Workout.targetSets, equals(4));
    });

    test('4. All 20 exercises match canonical names in ExerciseData catalog', () {
      final allBlueprintExerciseNames = <String>{};
      for (final phase in mbPlan.phases) {
        for (final week in phase.weeks) {
          for (final day in week.days) {
            allBlueprintExerciseNames.addAll(day.exerciseNames);
          }
        }
      }

      expect(allBlueprintExerciseNames.length, equals(20));

      final canonicalCatalogNames = ExerciseData.all.map((e) => e.name).toSet();
      for (final exerciseName in allBlueprintExerciseNames) {
        expect(
          canonicalCatalogNames.contains(exerciseName),
          isTrue,
          reason: '$exerciseName must exist in canonical ExerciseData.all',
        );
      }

      // Check key canonical corrected names
      expect(allBlueprintExerciseNames.contains('Barbell Close Grip Bench Press'), isTrue);
      expect(allBlueprintExerciseNames.contains('Cable Pulldown'), isTrue);
      expect(allBlueprintExerciseNames.contains('Dumbbell Standing Calf Raise'), isTrue);
      expect(allBlueprintExerciseNames.contains('Military Press'), isTrue);
    });

    test('5. Day 90 is dedicated to Titan celebration and graduation pathways', () {
      final day90 = mbPlan.getDayBlueprint(90);
      expect(day90, isNotNull);
      expect(day90!.dayType, equals('active_recovery'));
      expect(day90.muscleGroup, contains('Celebration & Graduation'));
      expect(day90.notes, contains('graduation'));
    });
  });

  group('Gym Buddy — Phase 5 Equipment Adaptation & Progressive Overload Engine', () {
    test('6. TransformationEquipmentAdapter converts gym apparatus to dumbbells for home lifters', () {
      const gymExercises = [
        'Barbell Bench Press',
        'Incline Dumbbell Press',
        'Cable Standing Fly',
        'Barbell Close Grip Bench Press',
        'Cable Pushdown',
        'Barbell Underhand Bent Over Row',
        'Cable Pulldown',
        'Cable Seated Row',
        'Classic Barbell Squat',
        'Leg Press',
        'Military Press',
      ];

      final homeAdapted = TransformationEquipmentAdapter.adaptExercisesForEnvironment(
        exerciseNames: gymExercises,
        workoutLocation: 'home',
        availableEquipment: ['dumbbells'],
      );

      expect(homeAdapted.length, equals(gymExercises.length));
      // Barbells, cables, and machines should be adapted to dumbbells
      expect(homeAdapted.contains('Barbell Bench Press'), isFalse);
      expect(homeAdapted.contains('Incline Dumbbell Press'), isTrue);
      expect(homeAdapted.contains('Dumbbell Fly'), isTrue);
      expect(homeAdapted.contains('Dumbbell Close Grip Press'), isTrue);
      expect(homeAdapted.contains('Dumbbell Bent Over Row'), isTrue);
      expect(homeAdapted.contains('Dumbbell Goblet Squat'), isTrue);
      expect(homeAdapted.contains('Dumbbell Bench Seated Press'), isTrue);
    });

    test('7. TransformationEquipmentAdapter preserves commercial gym apparatus for gym lifters', () {
      const gymExercises = [
        'Barbell Bench Press',
        'Cable Standing Fly',
        'Cable Pulldown',
        'Classic Barbell Squat',
        'Military Press',
      ];

      final gymAdapted = TransformationEquipmentAdapter.adaptExercisesForEnvironment(
        exerciseNames: gymExercises,
        workoutLocation: 'gym',
        availableEquipment: ['barbell', 'dumbbells', 'cables', 'machines'],
      );

      expect(gymAdapted, equals(gymExercises));
    });

    test('8. Injury safeguards replace spinal and knee loading in hypertrophy exercises', () {
      const exercises = [
        'Classic Barbell Squat',
        'Barbell Underhand Bent Over Row',
      ];

      final lowerBackAdapted = TransformationEquipmentAdapter.adaptExercisesForEnvironment(
        exerciseNames: exercises,
        workoutLocation: 'gym',
        availableEquipment: ['barbell', 'dumbbells'],
        injuries: 'lower back strain',
      );

      // Classic Barbell Squat should be swapped to Dumbbell Goblet Squat
      expect(lowerBackAdapted[0], equals('Dumbbell Goblet Squat'));
      // Barbell Underhand Row should be swapped to chest-supported Dumbbell Incline Row
      expect(lowerBackAdapted[1], equals('Dumbbell Incline Row'));
    });
  });

  group('Gym Buddy — Phase 5 Provider State Transitions & Progression', () {
    test('9. Enrolment in muscle_building_90 initializes 90-day active state', () async {
      Map<String, dynamic>? savedDoc;
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'mb_tester_1';
      provider.activeDocSaverForTesting = (uid, data) async {
        savedDoc = data;
      };
      provider.activeDocFetcherForTesting = (uid) => savedDoc;

      final blueprint = TransformationPlansData.muscleBuilding90;
      await provider.enrollInPlan(
        blueprint: blueprint,
        targetCalories: 2800.0,
        targetMacros: const {'protein': 180.0, 'carbs': 350.0, 'fat': 75.0},
        workoutLocation: 'gym',
        experienceLevel: 'Intermediate',
      );

      expect(provider.hasActiveTransformation, isTrue);
      expect(provider.activeTransformation?.planId, equals('muscle_building_90'));
      expect(provider.activeTransformation?.totalDays, equals(90));
      expect(provider.activeTransformation?.currentDay, equals(1));
    });

    test('10. Progressing through workouts updates completed days', () async {
      Map<String, dynamic>? savedDoc;
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'mb_tester_1';
      provider.activeDocSaverForTesting = (uid, data) async {
        savedDoc = data;
      };
      provider.activeDocFetcherForTesting = (uid) => savedDoc;

      final blueprint = TransformationPlansData.muscleBuilding90;
      await provider.enrollInPlan(
        blueprint: blueprint,
        targetCalories: 2800.0,
        targetMacros: const {'protein': 180.0, 'carbs': 350.0, 'fat': 75.0},
        workoutLocation: 'gym',
        experienceLevel: 'Intermediate',
      );

      await provider.markDayCompleted(1);
      expect(provider.isDayCompleted(1), isTrue);
      expect(savedDoc?['completedDayIndices'], contains(1));
    });

    test('11. Completing transformation transitions plan to completed state', () async {
      Map<String, dynamic>? savedDoc;
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'mb_tester_1';
      provider.activeDocSaverForTesting = (uid, data) async {
        savedDoc = data;
      };
      provider.activeDocFetcherForTesting = (uid) => savedDoc;

      final blueprint = TransformationPlansData.muscleBuilding90;
      await provider.enrollInPlan(
        blueprint: blueprint,
        targetCalories: 2800.0,
        targetMacros: const {'protein': 180.0, 'carbs': 350.0, 'fat': 75.0},
        workoutLocation: 'gym',
        experienceLevel: 'Intermediate',
      );

      await provider.completePlan();
      expect(provider.hasActiveTransformation, isFalse);
    });
  });

  group('Gym Buddy — Phase 5 Widget UX & Navigation', () {
    testWidgets('12. Detail Screen renders Muscle Gain Guide Card with all expectations & shortcuts', (tester) async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'hypertrophy_tester';

      await tester.pumpWidget(
        wrapWithScreenUtilAndRouter(
          child: const TransformationPlanDetailScreen(planId: 'muscle_building_90'),
          transformationProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('90-Day Muscle Building Challenge'), findsOneWidget);
      expect(find.text('90 DAYS'), findsOneWidget);
      expect(find.text('Muscle Gain Guide: What to Expect'), findsOneWidget);

      // Verify Muscle Gain Guide Card exists
      final guideCardFinder = find.byKey(const Key('muscle_gain_onboarding_guide_card'));
      expect(guideCardFinder, findsOneWidget);

      // Verify guidance points
      expect(find.text('90-Day Hypertrophy: Science & Overload Guidelines'), findsOneWidget);
      expect(find.text('4–5 Training Days per Week'), findsOneWidget);
      expect(find.text('Progressive Overload Principle'), findsOneWidget);
      expect(find.text('Scheduled Deload Weeks'), findsOneWidget);
      expect(find.text('Clean Caloric Surplus (10–15%)'), findsOneWidget);

      // Verify companion action buttons
      expect(find.byKey(const Key('explore_bulking_diet_from_detail_btn')), findsOneWidget);
      expect(find.byKey(const Key('explore_strength_from_detail_btn')), findsOneWidget);
    });

    testWidgets('13. Roadmap Screen renders orientation banner, progressive overload card, and nutrition actions', (tester) async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'hypertrophy_tester';
      provider.activeDocSaverForTesting = (uid, data) async {};

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.muscleBuilding90,
        targetCalories: 2800.0,
        targetMacros: const {'protein': 180.0, 'carbs': 350.0, 'fat': 75.0},
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
      expect(find.byKey(const Key('muscle_gain_roadmap_orientation_banner')), findsOneWidget);
      expect(find.textContaining('Hypertrophy Rule: Progressive Overload'), findsOneWidget);

      // Scroll to Progressive Overload Advisory Card
      final overloadCard = find.byKey(const Key('muscle_gain_progressive_overload_card'));
      await tester.scrollUntilVisible(overloadCard, 300);
      expect(overloadCard, findsOneWidget);
      expect(find.byKey(const Key('roadmap_strength_analytics_btn')), findsOneWidget);
      expect(find.byKey(const Key('roadmap_bulking_diet_btn')), findsOneWidget);

      // Verify nutrition bar actions
      expect(find.byKey(const Key('nutrition_bar_log_meal_btn')), findsOneWidget);
      expect(find.byKey(const Key('nutrition_bar_log_water_btn')), findsOneWidget);
      expect(find.text('Bulking Diet'), findsNWidgets(2));
    });

    testWidgets('14. Progress Screen renders hypertrophic nutrition targets and Bulking Diet bridge', (tester) async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'hypertrophy_tester';
      provider.activeDocSaverForTesting = (uid, data) async {};

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.muscleBuilding90,
        targetCalories: 2800.0,
        targetMacros: const {'protein': 180.0, 'carbs': 350.0, 'fat': 75.0},
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

      // Verify nutrition card exists
      final nutritionCard = find.byKey(const Key('transformation_nutrition_hydration_card'));
      await tester.scrollUntilVisible(nutritionCard, 300);
      expect(nutritionCard, findsOneWidget);
      expect(find.textContaining('Personalized targets to support lean muscle hypertrophy'), findsOneWidget);

      // Verify Bulking Diet bridge
      final bulkingDietBtn = find.byKey(const Key('progress_bulking_diet_btn'));
      await tester.scrollUntilVisible(bulkingDietBtn, 200);
      expect(bulkingDietBtn, findsOneWidget);

      await tester.tap(bulkingDietBtn);
      await tester.pumpAndSettle();
      expect(find.text('Bulking Diet Page'), findsOneWidget);
    });

    testWidgets('15. Completion Screen renders all 4 Muscle Building graduation pathways without auto-enrolment', (tester) async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'hypertrophy_tester';

      final completedState = UserTransformationState(
        planId: 'muscle_building_90',
        planTitle: '90-Day Muscle Building Challenge',
        startDate: DateTime.now().subtract(const Duration(days: 90)),
        targetEndDate: DateTime.now(),
        currentDay: 90,
        totalDays: 90,
        status: 'completed',
        completedAt: DateTime.now(),
        completedDayIndices: List.generate(90, (i) => i + 1),
        startingWeight: 75.0,
        targetCalories: 2800.0,
        targetMacros: const {'protein': 180.0, 'carbs': 350.0, 'fat': 75.0},
      );

      await tester.pumpWidget(
        wrapWithScreenUtilAndRouter(
          child: TransformationCompletionScreen(completedState: completedState),
          transformationProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      // Verify 4 graduation pathways exist
      expect(find.text('90-Day Muscle Building Challenge'), findsOneWidget);
      expect(find.text('Graduate to Your Next Chapter'), findsOneWidget);

      expect(find.text('Repeat 90-Day Hypertrophy Cycle'), findsOneWidget);
      expect(find.byKey(const Key('graduate_mb_to_repeat_btn')), findsOneWidget);

      expect(find.text('12-Week Strength Building Challenge'), findsOneWidget);
      expect(find.byKey(const Key('graduate_mb_to_strength_btn')), findsOneWidget);

      expect(find.text('General Fitness & Muscle Maintenance'), findsOneWidget);
      expect(find.byKey(const Key('graduate_mb_to_maintenance_btn')), findsOneWidget);

      expect(find.text('60-Day Fat Loss & Cutting Challenge'), findsOneWidget);
      expect(find.byKey(const Key('graduate_mb_to_cut_btn')), findsOneWidget);

      // Verify user is NOT auto-enrolled
      expect(provider.hasActiveTransformation, isFalse);
    });
  });
}
