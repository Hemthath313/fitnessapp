import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_onboarding_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_roadmap_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/utils/tdee_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _configureTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class MockHomeProvider extends HomeProvider {
  final Map<String, dynamic> _mockData;

  MockHomeProvider(this._mockData);

  @override
  Map<String, dynamic> get userData => _mockData;

  @override
  Future<Map<String, dynamic>> fetchUserData() async => _mockData;
}

Widget _buildExperienceTestWidget(
  Widget child,
  TransformationProvider transformationProvider, {
  HomeProvider? homeProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TransformationProvider>.value(
        value: transformationProvider,
      ),
      if (homeProvider != null)
        ChangeNotifierProvider<HomeProvider>.value(value: homeProvider),
    ],
    child: ScreenUtilInit(
      designSize: const Size(430, 810),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Transformation Onboarding Flow Tests', () {
    testWidgets('1. Prefills existing profile information without asking user to re-enter',
        (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'test_user';

      final mockHome = MockHomeProvider({
        'age': 28,
        'height': 182.0,
        'weight': 84.0,
        'gender': 'Male',
        'activity': 'MODERATE',
        'goal': 'LOSE',
      });

      await tester.pumpWidget(
        _buildExperienceTestWidget(
          const TransformationOnboardingScreen(
            plan: null,
            planId: 'weight_loss_60',
          ),
          transformationProvider,
          homeProvider: mockHome,
        ),
      );
      await tester.pumpAndSettle();

      // Check that existing profile values are prefilled in text controllers
      expect(find.text('28'), findsOneWidget);
      expect(find.text('182'), findsOneWidget);
      expect(find.text('84.0'), findsOneWidget);
      expect(find.text('Profile & Metrics'), findsOneWidget);
    });

    testWidgets('2. Multi-step navigation progresses and validates selections',
        (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'test_user';

      final mockHome = MockHomeProvider({
        'age': 25,
        'height': 175.0,
        'weight': 70.0,
        'gender': 'Female',
        'activity': 'LIGHT',
        'goal': 'GAIN',
      });

      await tester.pumpWidget(
        _buildExperienceTestWidget(
          TransformationOnboardingScreen(
            plan: TransformationPlansData.muscleBuilding90,
          ),
          transformationProvider,
          homeProvider: mockHome,
        ),
      );
      await tester.pumpAndSettle();

      // Step 1 -> Step 2
      final continueButton = find.byKey(const Key('onboarding_next_or_confirm_button'));
      expect(continueButton, findsOneWidget);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.text('Workout Environment'), findsOneWidget);
      expect(find.text('Full Gym'), findsOneWidget);
      expect(find.text('Home Workout'), findsOneWidget);

      // Select Home Workout
      await tester.tap(find.text('Home Workout'));
      await tester.pumpAndSettle();

      // Step 2 -> Step 3
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.text('Nutrition & Preferences'), findsOneWidget);
      expect(find.text('Dietary Type'), findsOneWidget);

      // Select Vegetarian
      await tester.tap(find.text('Vegetarian'));
      await tester.pumpAndSettle();

      // Step 3 -> Step 4 (Review & Calibrate)
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.text('CALIBRATED NUTRITION TARGET'), findsOneWidget);
      expect(find.text('Launch Programme Roadmap'), findsOneWidget);
    });
  });

  group('Transformation Roadmap & Workout Integration Tests', () {
    testWidgets('3. Renders Roadmap, daily workouts, milestones and nutrition targets',
        (tester) async {
      _configureTestViewport(tester);

      final now = DateTime.now();
      final activeState = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Weight Loss Challenge',
        startDate: now,
        targetEndDate: now.add(const Duration(days: 60)),
        currentDay: 1,
        totalDays: 60,
        completedDayIndices: [],
        targetCalories: 1950,
        targetMacros: const {'protein': 160, 'carbs': 185, 'fat': 50},
        milestones: const [
          TransformationMilestone(
            id: 'wl_day_7',
            title: 'Week 1 Survivor',
            description: 'First week done!',
            triggerDay: 7,
          ),
        ],
      );

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'test_user';
      transformationProvider.activeDocFetcherForTesting = (_) => activeState.toMap();
      await transformationProvider.loadTransformation();

      await tester.pumpWidget(
        _buildExperienceTestWidget(
          const TransformationRoadmapScreen(),
          transformationProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Header Progress
      expect(find.text('60-Day Weight Loss Challenge'), findsOneWidget);
      expect(find.text('Day 1 of 60'), findsOneWidget);

      // Milestone Bar
      final milestoneFinder = find.textContaining('Next: Week 1 Survivor');
      await tester.scrollUntilVisible(
        milestoneFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(milestoneFinder, findsOneWidget);

      // Tips, nutrition and advice live in the folded "Plan guide" section.
      await tester.ensureVisible(find.byKey(const Key('plan_guide_toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('plan_guide_toggle')));
      await tester.pumpAndSettle();
      // Nutrition Bar
      expect(find.text('Daily Nutrition Target'), findsOneWidget);
      expect(find.text('1950'), findsOneWidget);
      expect(find.text('160g'), findsOneWidget);

      // Day 1 Workout Card
      final day1Finder = find.text('Day 1');
      await tester.scrollUntilVisible(
        day1Finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(day1Finder, findsOneWidget);
      expect(find.byKey(const Key('start_workout_day_1')), findsOneWidget);

      // Scroll to Day 3 Rest Card
      await tester.scrollUntilVisible(
        find.text('Day 3'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Day 3'), findsOneWidget);
      expect(find.text('Rest & Recovery'), findsWidgets);
    });

    testWidgets('4. Only rest days can be ticked, and unticking asks first',
        (tester) async {
      _configureTestViewport(tester);

      Map<String, dynamic>? savedDoc;
      final now = DateTime.now();
      final activeState = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Weight Loss Challenge',
        startDate: now,
        targetEndDate: now.add(const Duration(days: 60)),
        currentDay: 1,
        totalDays: 60,
        completedDayIndices: [],
        targetCalories: 2000,
        targetMacros: const {'protein': 150, 'carbs': 190, 'fat': 50},
      );

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'test_user';
      transformationProvider.activeDocFetcherForTesting = (_) => savedDoc ?? activeState.toMap();
      transformationProvider.activeDocSaverForTesting = (_, data) async {
        savedDoc = data;
      };
      await transformationProvider.loadTransformation();

      await tester.pumpWidget(
        _buildExperienceTestWidget(
          const TransformationRoadmapScreen(),
          transformationProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Workout days are completed by finishing the workout, not by a tick.
      expect(find.byKey(const Key('toggle_day_1_button')), findsNothing);

      // Rest days can still be ticked by hand.
      final blueprint = TransformationPlansData.getById('weight_loss_60')!;
      final restDay = List.generate(60, (i) => i + 1)
          .firstWhere((d) => blueprint.getDayBlueprint(d)?.isRestDay ?? false);
      final toggleBtn = find.byKey(Key('toggle_day_${restDay}_button'));
      await tester.scrollUntilVisible(
        toggleBtn,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(toggleBtn, findsOneWidget);

      await tester.tap(toggleBtn);
      await tester.pumpAndSettle();

      expect(transformationProvider.isDayCompleted(restDay), isTrue);
      expect(transformationProvider.activeTransformation?.completedDayIndices.length, equals(1));
      // Ticking a future rest day does not move the plan forward.
      expect(transformationProvider.activeTransformation?.currentDay, equals(1));

      // Unticking asks for confirmation first.
      await tester.tap(toggleBtn);
      await tester.pumpAndSettle();
      expect(transformationProvider.isDayCompleted(restDay), isTrue);
      await tester.tap(find.byKey(const Key('confirm_unmark_day_button')));
      await tester.pumpAndSettle();

      expect(transformationProvider.isDayCompleted(restDay), isFalse);
      expect(transformationProvider.activeTransformation?.completedDayIndices.length, equals(0));
    });

    testWidgets('5. Renders graceful empty state when user has no active plan',
        (tester) async {
      _configureTestViewport(tester);

      final transformationProvider = TransformationProvider(autoLoad: false);
      transformationProvider.userIdOverrideForTesting = 'test_user';
      transformationProvider.activeDocFetcherForTesting = (_) => null;

      await tester.pumpWidget(
        _buildExperienceTestWidget(
          const TransformationRoadmapScreen(),
          transformationProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Active Programme'), findsOneWidget);
      expect(find.text('Explore Transformation Plans'), findsOneWidget);
    });
  });

  group('WorkoutSession Tagging & Safeguards', () {
    test('WorkoutSession serializes optional planId and planDay cleanly', () {
      final session = WorkoutSession(
        id: 'sess_123',
        userId: 'usr_456',
        workoutName: '60-Day Weight Loss Challenge • Day 1',
        dayName: 'Monday',
        startedAt: DateTime.now(),
        totalVolume: 4200.0,
        exercises: [],
        planId: 'weight_loss_60',
        planDay: 1,
      );

      final map = session.toMap();
      expect(map['planId'], equals('weight_loss_60'));
      expect(map['planDay'], equals(1));

      final restored = WorkoutSession.fromMap(map, 'sess_123');
      expect(restored.planId, equals('weight_loss_60'));
      expect(restored.planDay, equals(1));
    });

    test('Nutrition Safeguard: Calorie targets clamp to safe biological floors', () {
      // Female minimum safeguard = 1200 kcal
      final femaleExtremeDeficit = TDEECalculator.calculateTargetCalories(
        tdee: 1200.0,
        goal: 'LOSE',
        gender: 'Female',
      );
      expect(femaleExtremeDeficit, equals(1200.0));

      // Male minimum safeguard = 1500 kcal
      final maleExtremeDeficit = TDEECalculator.calculateTargetCalories(
        tdee: 1600.0,
        goal: 'LOSE',
        gender: 'Male',
      );
      expect(maleExtremeDeficit, equals(1500.0));
    });
  });
}
