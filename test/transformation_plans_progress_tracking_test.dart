import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_completion_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_progress_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_weekly_check_in_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/utils/transformation_recommendations.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/dashboard_challenge_section.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/milestone_celebration_dialog.dart';

class MockHomeProvider extends ChangeNotifier implements HomeProvider {
  final Map<String, dynamic> _userData = {
    'name': 'Alex Fitness',
    'age': 28,
    'gender': 'Male',
    'height': 180.0,
    'weight': 82.5,
    'activity': 'MODERATE',
    'goal': 'LOSE',
    'waist': 86.0,
    'chest': 102.0,
    'biceps': 36.5,
    'hips': 98.0,
    'thigh': 58.0,
  };

  @override
  Map<String, dynamic> get userData => _userData;

  @override
  double get usersBMI => 25.4;

  @override
  double get userBMRwithGoal => 1950.0;

  @override
  Future<Map<String, dynamic>> fetchUserData() async => _userData;

  @override
  Future<double> getUsersBMI({required double height, required double weight}) async => 25.4;

  @override
  Future<double> getUsersBMR({
    required String gender,
    required double weight,
    required double height,
    required int age,
    required String activity,
    required String goal,
  }) async => 1950.0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void _configureTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _wrapWithScreenUtil({
  required Widget child,
  TransformationProvider? transformationProvider,
  HomeProvider? homeProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TransformationProvider?>.value(
        value: transformationProvider,
      ),
      ChangeNotifierProvider<HomeProvider?>.value(
        value: homeProvider ?? MockHomeProvider(),
      ),
    ],
    child: ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        home: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Transformation Progress Tracking & Programme Completion Tests', () {
    test('1. Intelligent Programme Progression generates transparent insights', () {
      final now = DateTime.now();
      // Case A: High consistency (completed 12 of 14 days)
      final activeStateHigh = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Weight Loss Challenge',
        startDate: now.subtract(const Duration(days: 14)),
        targetEndDate: now.add(const Duration(days: 46)),
        currentDay: 14,
        totalDays: 60,
        completedDayIndices: List.generate(12, (i) => i + 1),
        targetCalories: 1900,
        targetMacros: const {'protein': 150, 'carbs': 180, 'fat': 50},
        startingWeight: 85.0,
      );

      final insightsHigh = TransformationRecommendations.generateInsights(
        state: activeStateHigh,
        currentWeight: 83.5,
      );
      expect(insightsHigh.any((i) => i.type == 'progression'), isTrue);
      expect(insightsHigh.first.title, 'Optimal Training Consistency');

      // Case B: Rapid weight drop (> 1.2 kg / week alert)
      final activeStateFastDrop = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Weight Loss Challenge',
        startDate: now.subtract(const Duration(days: 14)),
        targetEndDate: now.add(const Duration(days: 46)),
        currentDay: 14,
        totalDays: 60,
        completedDayIndices: [1, 2, 3],
        targetCalories: 1900,
        targetMacros: const {'protein': 150, 'carbs': 180, 'fat': 50},
        startingWeight: 85.0,
      );
      final insightsDrop = TransformationRecommendations.generateInsights(
        state: activeStateFastDrop,
        currentWeight: 81.0, // 4kg drop in 2 weeks = 2kg/wk (>1.2kg/wk)
      );
      expect(insightsDrop.any((i) => i.title.contains('Rapid Weight Drop')), isTrue);

      // Case C: High Fatigue alert from weekly check-in
      final activeStateFatigue = activeStateHigh.copyWith(
        weeklyCheckIns: [
          TransformationWeeklyCheckIn(
            weekNumber: 2,
            checkInDate: now,
            weight: 83.5,
            fatigueLevel: 'High / Fatigued',
          ),
        ],
      );
      final insightsFatigue = TransformationRecommendations.generateInsights(
        state: activeStateFatigue,
        currentWeight: 83.5,
      );
      expect(insightsFatigue.any((i) => i.type == 'recovery'), isTrue);
    });

    testWidgets('2. TransformationProgressScreen renders actual weight, measurements & consistency',
        (tester) async {
      _configureTestViewport(tester);

      final now = DateTime.now();
      final activeState = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Weight Loss Challenge',
        startDate: now.subtract(const Duration(days: 14)),
        targetEndDate: now.add(const Duration(days: 46)),
        currentDay: 14,
        totalDays: 60,
        completedDayIndices: [1, 2, 4, 5, 8, 9, 11, 12],
        targetCalories: 1950,
        targetMacros: const {'protein': 160, 'carbs': 180, 'fat': 50},
        startingWeight: 85.0,
        targetWeight: 78.0,
        startingMeasurements: const {
          'waist': 90.0,
          'chest': 105.0,
          'biceps': 36.0,
          'hips': 100.0,
          'thigh': 60.0,
        },
        weeklyCheckIns: [
          TransformationWeeklyCheckIn(
            weekNumber: 1,
            checkInDate: now.subtract(const Duration(days: 7)),
            weight: 84.0,
            workoutsCompleted: 4,
            workoutsScheduled: 7,
            adherencePercentage: 4 / 7,
          ),
        ],
        milestones: [
          TransformationMilestone(
            id: 'm1',
            title: 'Week 1 Survivor',
            description: 'Completed 7 full days',
            triggerDay: 7,
            isAchieved: true,
            achievedAt: now.subtract(const Duration(days: 7)),
          ),
          TransformationMilestone(
            id: 'm2',
            title: '14-Day Consistency',
            description: 'Half a month of discipline',
            triggerDay: 14,
            isAchieved: false,
          ),
        ],
      );

      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user';
      provider.activeDocFetcherForTesting = (_) => activeState.toMap();
      await provider.loadTransformation();

      await tester.pumpWidget(
        _wrapWithScreenUtil(
          child: const TransformationProgressScreen(),
          transformationProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('60-Day Weight Loss Challenge'), findsOneWidget);
      expect(find.text('Day 14 of 60'), findsOneWidget);
      expect(find.text('Workouts'), findsWidgets);
      expect(find.text('8 Done'), findsOneWidget); // 8 completed days

      // Weight Journey verification
      expect(find.text('Weight Journey'), findsOneWidget);
      expect(find.text('85.0 kg'), findsOneWidget); // Starting
      expect(find.text('82.5 kg'), findsOneWidget); // Current from mock
      expect(find.text('78.0 kg'), findsOneWidget); // Target
      expect(find.text('-2.5 kg'), findsOneWidget); // Net Change

      // Body Measurements verification
      expect(find.text('Body Measurements'), findsOneWidget);
      expect(find.text('Waist'), findsOneWidget);
      expect(find.text('90.0 cm'), findsOneWidget); // Start waist
      expect(find.text('86.0 cm'), findsOneWidget); // Current waist from mock
      expect(find.text('-4.0'), findsOneWidget); // Delta waist

      // Progress Photos verified as completely removed
      expect(find.text('Progress Photos'), findsNothing);

      // Milestones verification
      expect(find.text('Week 1 Survivor'), findsOneWidget);
      expect(find.text('14-Day Consistency'), findsOneWidget);
    });

    testWidgets('3. Weekly Check-In screen validates and saves actual check-in data',
        (tester) async {
      _configureTestViewport(tester);

      final now = DateTime.now();
      Map<String, dynamic>? savedDoc;

      final activeState = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Weight Loss Challenge',
        startDate: now.subtract(const Duration(days: 7)),
        targetEndDate: now.add(const Duration(days: 53)),
        currentDay: 7,
        totalDays: 60,
        completedDayIndices: [1, 2, 3, 4, 5],
        targetCalories: 1950,
        targetMacros: const {'protein': 160, 'carbs': 180, 'fat': 50},
        startingWeight: 85.0,
      );

      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user';
      provider.activeDocFetcherForTesting = (_) => activeState.toMap();
      provider.activeDocSaverForTesting = (_, data) async {
        savedDoc = data;
      };
      await provider.loadTransformation();

      await tester.pumpWidget(
        _wrapWithScreenUtil(
          child: const TransformationWeeklyCheckInScreen(weekNumber: 1),
          transformationProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Week 1 Check-In'), findsOneWidget);
      expect(find.text('Workouts completed: 5 of 7 scheduled days (Days 1–7)'), findsOneWidget);

      // Enter weight and notes
      await tester.enterText(find.byKey(const Key('weekly_weight_input')), '83.8');
      await tester.enterText(
          find.byKey(const Key('weekly_notes_input')), 'Felt energetic and recovery was smooth.');
      await tester.pumpAndSettle();

      // Submit check-in
      await tester.ensureVisible(find.byKey(const Key('save_weekly_check_in_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save_weekly_check_in_button')));
      await tester.pumpAndSettle();

      // Verify check-in saved to provider and state
      expect(savedDoc, isNotNull);
      final checkIns = savedDoc!['weeklyCheckIns'] as List<dynamic>;
      expect(checkIns.length, 1);
      expect(checkIns.first['weight'], 83.8);
      expect(checkIns.first['workoutsCompleted'], 5);
      expect(checkIns.first['notes'], 'Felt energetic and recovery was smooth.');
    });

    testWidgets('4. MilestoneCelebrationDialog displays milestone and marks celebrated once',
        (tester) async {
      _configureTestViewport(tester);

      bool celebrated = false;
      final milestone = TransformationMilestone(
        id: 'halfway_hero',
        title: 'Halfway Hero',
        description: 'Completed 30 transformation days',
        triggerDay: 30,
        isAchieved: true,
        achievedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        _wrapWithScreenUtil(
          child: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                key: const Key('trigger_celebration_test'),
                onPressed: () {
                  MilestoneCelebrationDialog.show(
                    ctx,
                    milestone: milestone,
                    onDismiss: () => celebrated = true,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('trigger_celebration_test')));
      await tester.pumpAndSettle();

      expect(find.text('MILESTONE UNLOCKED!'), findsOneWidget);
      expect(find.text('Halfway Hero'), findsOneWidget);
      expect(find.text('Completed 30 transformation days'), findsOneWidget);

      // Tap Claim
      await tester.tap(find.byKey(const Key('milestone_claim_button')));
      await tester.pumpAndSettle();

      expect(celebrated, isTrue);
      expect(find.text('MILESTONE UNLOCKED!'), findsNothing);
    });

    testWidgets('5. TransformationCompletionScreen renders summary and preserves history',
        (tester) async {
      _configureTestViewport(tester);

      final now = DateTime.now();
      final completedState = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Weight Loss Challenge',
        startDate: now.subtract(const Duration(days: 60)),
        targetEndDate: now,
        currentDay: 60,
        totalDays: 60,
        status: 'completed',
        completedAt: now,
        completedDayIndices: List.generate(60, (i) => i + 1),
        targetCalories: 1950,
        targetMacros: const {'protein': 160, 'carbs': 180, 'fat': 50},
        startingWeight: 85.0,
        targetWeight: 78.0,
        startingMeasurements: const {
          'waist': 90.0,
          'chest': 105.0,
          'biceps': 36.0,
          'hips': 100.0,
          'thigh': 60.0,
        },
        milestones: [
          TransformationMilestone(
            id: 'legend',
            title: 'Transformation Legend',
            description: 'Finished all 60 days',
            triggerDay: 60,
            isAchieved: true,
          ),
        ],
      );

      final provider = TransformationProvider(autoLoad: false);

      await tester.pumpWidget(
        _wrapWithScreenUtil(
          child: TransformationCompletionScreen(completedState: completedState),
          transformationProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ACHIEVEMENT UNLOCKED'), findsOneWidget);
      expect(find.text('60-Day Weight Loss Challenge'), findsOneWidget);
      expect(find.text('Workouts'), findsOneWidget);
      expect(find.text('60'), findsOneWidget); // 60 workouts
      expect(find.text('Start Weight'), findsOneWidget);
      expect(find.text('85.0 kg'), findsOneWidget);
      expect(find.text('Final Weight'), findsOneWidget);
      expect(find.text('82.5 kg'), findsOneWidget); // From mock userData
      expect(find.text('Transformation Legend'), findsOneWidget);
      expect(find.byKey(const Key('completion_explore_another_cta')), findsOneWidget);
      expect(find.byKey(const Key('completion_back_dashboard_cta')), findsOneWidget);
    });

    testWidgets('6. DashboardChallengeSection provides Progress and Results CTAs for Active & Completed states',
        (tester) async {
      _configureTestViewport(tester);

      final now = DateTime.now();

      // State A: Active Challenge
      final activeState = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Weight Loss Challenge',
        startDate: now,
        targetEndDate: now.add(const Duration(days: 60)),
        currentDay: 5,
        totalDays: 60,
        status: 'active',
        completedDayIndices: [1, 2, 3],
        targetCalories: 1950,
        targetMacros: const {'protein': 160, 'carbs': 180, 'fat': 50},
        startingWeight: 85.0,
      );

      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user';
      provider.activeDocFetcherForTesting = (_) => activeState.toMap();
      await provider.loadTransformation();

      await tester.pumpWidget(
        _wrapWithScreenUtil(
          child: const Material(child: SingleChildScrollView(child: DashboardChallengeSection(suppressActiveTransformation: false))),
          transformationProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      // Active card shows both Continue and Progress CTAs
      expect(find.byKey(const Key('continue_challenge_cta')), findsOneWidget);
      expect(find.byKey(const Key('view_progress_cta')), findsOneWidget);

      // State B: Completed Challenge
      final completedState = activeState.copyWith(
        status: 'completed',
        completedAt: now,
      );
      provider.activeDocFetcherForTesting = (_) => null;
      provider.historyDocFetcherForTesting = (_) => [completedState.toMap()];
      await provider.loadTransformation();

      await tester.pumpWidget(
        _wrapWithScreenUtil(
          child: const Material(child: SingleChildScrollView(child: DashboardChallengeSection(suppressActiveTransformation: false))),
          transformationProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      // Completed card shows both View Results and Explore Plans CTAs
      expect(find.byKey(const Key('view_results_cta')), findsOneWidget);
      expect(find.byKey(const Key('explore_another_challenge_cta')), findsOneWidget);
    });

    test('7. Model serialization supports weekly check-ins, starting metrics and celebrated milestones', () {
      final now = DateTime.now();
      final checkIn = TransformationWeeklyCheckIn(
        weekNumber: 2,
        checkInDate: now,
        weight: 81.5,
        weightChange: -3.5,
        workoutsCompleted: 4,
        workoutsScheduled: 4,
        adherencePercentage: 1.0,
        measurements: {'waist': 84.0, 'chest': 101.0},
        fatigueLevel: 'Normal / Manageable',
        notes: 'Steady progress',
      );

      final map = checkIn.toMap();
      final parsed = TransformationWeeklyCheckIn.fromMap(map);

      expect(parsed.weekNumber, 2);
      expect(parsed.weight, 81.5);
      expect(parsed.weightChange, -3.5);
      expect(parsed.workoutsCompleted, 4);
      expect(parsed.adherencePercentage, 1.0);
      expect(parsed.measurements['waist'], 84.0);
      expect(parsed.fatigueLevel, 'Normal / Manageable');
      expect(parsed.notes, 'Steady progress');

      // UserTransformationState serialization
      final state = UserTransformationState(
        planId: 'strength_12_week',
        planTitle: '12-Week Strength Programme',
        startDate: now,
        targetEndDate: now.add(const Duration(days: 84)),
        currentDay: 14,
        totalDays: 84,
        targetCalories: 2400,
        targetMacros: const {'protein': 180, 'carbs': 260, 'fat': 70},
        startingWeight: 80.0,
        targetWeight: 84.0,
        startingMeasurements: const {'waist': 82.0, 'chest': 100.0},
        weeklyCheckIns: [checkIn],
        celebratedMilestoneIds: const ['m1', 'm2'],
      );

      final stateMap = state.toMap();
      final parsedState = UserTransformationState.fromMap(stateMap);

      expect(parsedState.startingWeight, 80.0);
      expect(parsedState.targetWeight, 84.0);
      expect(parsedState.startingMeasurements['waist'], 82.0);
      expect(parsedState.weeklyCheckIns.length, 1);
      expect(parsedState.weeklyCheckIns.first.weight, 81.5);
      expect(parsedState.celebratedMilestoneIds, contains('m1'));
      expect(parsedState.celebratedMilestoneIds, contains('m2'));
    });
  });
}
