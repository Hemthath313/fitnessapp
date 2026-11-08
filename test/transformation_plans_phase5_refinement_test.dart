import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_completion_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_hub_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_onboarding_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHomeProvider extends ChangeNotifier implements HomeProvider {
  final Map<String, dynamic> _mockUserData = {
    'first name': 'Alex',
    'surname': 'Rider',
    'age': 28,
    'gender': 'Male',
    'height': 178.0,
    'weight': 74.0,
    'activity': 'LIGHT',
    'waist': 82.0,
    'chest': 98.0,
    'biceps': 34.0,
    'hips': 96.0,
    'thigh': 55.0,
  };

  @override
  Map<String, dynamic> get userData => _mockUserData;

  Future<Map<String, dynamic>> getUserData() async => _mockUserData;

  @override
  Future<Map<String, dynamic>> fetchUserData() async => _mockUserData;

  Future<double> getWeight() async => 74.0;

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

Widget _buildTestWidget({
  required Widget child,
  required TransformationProvider transformationProvider,
  HomeProvider? homeProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TransformationProvider>.value(
        value: transformationProvider,
      ),
      if (homeProvider != null)
        ChangeNotifierProvider<HomeProvider>.value(value: homeProvider)
      else
        ChangeNotifierProvider<HomeProvider>(create: (_) => MockHomeProvider()),
    ],
    child: ScreenUtilInit(
      designSize: const Size(430, 810),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 5: Primary Programme Catalogue Tests', () {
    test('1. Three primary programmes and one specialised programme are configured', () {
      final primary = TransformationPlansData.primaryPlans;
      final specialised = TransformationPlansData.specialisedPlans;
      final all = TransformationPlansData.allPlans;

      expect(primary.length, equals(3));
      expect(specialised.length, equals(1));
      expect(all.length, equals(4));

      final primaryIds = primary.map((p) => p.id).toList();
      expect(primaryIds, contains('beginner_fitness_30'));
      expect(primaryIds, contains('weight_loss_60'));
      expect(primaryIds, contains('muscle_building_90'));

      final specialisedIds = specialised.map((p) => p.id).toList();
      expect(specialisedIds, contains('strength_12_week'));
    });

    test('2. Complete Beginner – 30 Days blueprint has 30 days and 4 phases', () {
      final plan = TransformationPlansData.beginnerFitness30;

      expect(plan.id, equals('beginner_fitness_30'));
      expect(plan.durationDays, equals(30));
      expect(plan.goal, equals('MAINTAIN'));
      expect(plan.difficulty, equals('Beginner'));
      expect(plan.phases.length, equals(4));

      // Phase 1 (Week 1): Getting Started
      expect(plan.phases[0].phaseName, contains('Getting Started'));
      expect(plan.phases[0].weeks.first.days.length, equals(7));

      // Phase 4 (Weeks 4-5): Independence and Graduation
      expect(plan.phases[3].phaseName, contains('Independence'));
      expect(plan.phases[3].weeks.length, equals(2));

      // Day 1 is a workout day
      final day1 = plan.getDayBlueprint(1);
      expect(day1, isNotNull);
      expect(day1!.dayType, equals('workout'));
      expect(day1.exerciseNames.isNotEmpty, isTrue);

      // Day 2 is active recovery
      final day2 = plan.getDayBlueprint(2);
      expect(day2, isNotNull);
      expect(day2!.dayType, equals('active_recovery'));

      // Day 29 is 30-Day Fitness Benchmark Assessment
      final day29 = plan.getDayBlueprint(29);
      expect(day29, isNotNull);
      expect(day29!.dayType, equals('workout'));
      expect(day29.muscleGroup, contains('Benchmark Assessment'));

      // Day 30 is Graduation
      final day30 = plan.getDayBlueprint(30);
      expect(day30, isNotNull);
      expect(day30!.muscleGroup, contains('Graduation'));
    });

    test('3. Complete Beginner milestones are created at Days 7, 14, 21, and 30', () {
      final plan = TransformationPlansData.beginnerFitness30;
      final milestones = TransformationPlansData.createDefaultMilestones(plan);

      expect(milestones.length, equals(4));
      expect(milestones[0].triggerDay, equals(7));
      expect(milestones[1].triggerDay, equals(14));
      expect(milestones[2].triggerDay, equals(21));
      expect(milestones[3].triggerDay, equals(30));
    });

    test('4. Existing programmes maintain compatibility and duration', () {
      final wl = TransformationPlansData.getById('weight_loss_60');
      expect(wl, isNotNull);
      expect(wl!.durationDays, equals(60));
      expect(wl.goal, equals('LOSE'));

      final mb = TransformationPlansData.getById('muscle_building_90');
      expect(mb, isNotNull);
      expect(mb!.durationDays, equals(90));
      expect(mb.goal, equals('GAIN'));

      final st = TransformationPlansData.getById('strength_12_week');
      expect(st, isNotNull);
      expect(st!.durationDays, equals(84));
      expect(st.goal, equals('STRENGTH'));
    });
  });

  group('Phase 5: Transformation Hub Screen Discovery Tests', () {
    testWidgets('5. Renders Primary and Specialised sections with badges and info chips',
        (tester) async {
      _configureTestViewport(tester);

      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user';

      await tester.pumpWidget(
        _buildTestWidget(
          child: const TransformationHubScreen(),
          transformationProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      // Section titles
      expect(find.text('Primary Programmes (3)'), findsOneWidget);

      // Beginner recommendation callout banner
      expect(find.text('Recommended for You: Complete Beginner'), findsOneWidget);

      // Primary programme 1: Complete Beginner
      expect(find.text('Complete Beginner – 30 Days'), findsOneWidget);
      expect(find.text('Recommended for New Users'), findsOneWidget);
      expect(find.text('3 Days/Wk'), findsOneWidget);
      expect(find.text('Habits & Form'), findsOneWidget);

      // Scroll to 60-Day Weight Loss
      await tester.scrollUntilVisible(find.text('60-Day Weight Loss Challenge'), 300);
      expect(find.text('60-Day Weight Loss Challenge'), findsOneWidget);
      expect(find.text('Popular Fat Loss'), findsOneWidget);

      // Scroll to Specialised section
      await tester.scrollUntilVisible(find.text('Specialised Programmes (1)'), 300);
      expect(find.text('Specialised Programmes (1)'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('12-Week Strength Building Challenge'), 300);
      expect(find.text('12-Week Strength Building Challenge'), findsOneWidget);
      expect(find.text('Strength Specialisation'), findsOneWidget);
    });
  });

  group('Phase 5: Graduation and Onboarding Defaults Tests', () {
    testWidgets('6. Completion screen renders Graduation card for beginner_fitness_30',
        (tester) async {
      _configureTestViewport(tester);

      final now = DateTime.now();
      final completedState = UserTransformationState(
        planId: 'beginner_fitness_30',
        planTitle: 'Complete Beginner – 30 Days',
        startDate: now.subtract(const Duration(days: 30)),
        targetEndDate: now,
        completedAt: now,
        currentDay: 30,
        totalDays: 30,
        completedDayIndices: List.generate(14, (i) => (i * 2) + 1),
        startingWeight: 75.0,
        targetCalories: 2100,
        targetMacros: const {'protein': 140, 'carbs': 240, 'fat': 60},
        milestones: const [
          TransformationMilestone(
            id: 'beg_day_30',
            title: '30-Day Fitness Graduate',
            description: 'Foundation complete!',
            triggerDay: 30,
            isAchieved: true,
          ),
        ],
      );

      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user';

      await tester.pumpWidget(
        _buildTestWidget(
          child: TransformationCompletionScreen(completedState: completedState),
          transformationProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      // Completion Hero
      expect(find.text('Complete Beginner – 30 Days'), findsOneWidget);

      // Graduation card recommendations
      await tester.scrollUntilVisible(
        find.text('Graduate to Your Next Programme'),
        300,
      );
      expect(find.text('Graduate to Your Next Programme'), findsOneWidget);

      // Two next-programme pathways
      expect(find.byKey(const Key('graduate_to_weight_loss_btn')), findsOneWidget);
      expect(find.byKey(const Key('graduate_to_muscle_building_btn')), findsOneWidget);
    });

    testWidgets('7. Onboarding defaults to 3 days/week and 30 min duration for Complete Beginner',
        (tester) async {
      _configureTestViewport(tester);

      final plan = TransformationPlansData.beginnerFitness30;
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user';

      await tester.pumpWidget(
        _buildTestWidget(
          child: TransformationOnboardingScreen(plan: plan),
          transformationProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Profile & Metrics
      expect(find.text('Profile & Metrics'), findsOneWidget);

      // Tap Next to navigate to Step 2: Training Environment
      final nextButton = find.byKey(const Key('onboarding_next_or_confirm_button'));
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(find.text('Workout Environment'), findsOneWidget);

      // Check default schedule: 3 days per week and 30 min duration
      expect(find.text('Available Training Days per Week: 3 Days'), findsOneWidget);
      expect(find.text('Beginner'), findsOneWidget);
      expect(find.text('30 m'), findsOneWidget);
    });
  });
}
