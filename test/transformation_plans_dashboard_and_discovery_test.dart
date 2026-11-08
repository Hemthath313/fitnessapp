import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_slider_home_widget.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_hub_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_plan_detail_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/dashboard_challenge_section.dart';
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

Widget _buildTestWidget(Widget child, TransformationProvider provider, {bool scrollable = false}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TransformationProvider>.value(value: provider),
    ],
    child: ScreenUtilInit(
      designSize: const Size(430, 810),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: scrollable ? SingleChildScrollView(child: child) : child,
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Dashboard Challenges Section Tests', () {
    testWidgets('1. Displays Featured Challenge Card when no active transformation',
        (tester) async {
      _configureTestViewport(tester);

      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user';
      provider.activeDocFetcherForTesting = (_) => null;

      await tester.pumpWidget(
        _buildTestWidget(const DashboardChallengeSection(suppressActiveTransformation: false), provider, scrollable: true),
      );
      await tester.pumpAndSettle();

      // Header row
      expect(find.text('Challenges'), findsOneWidget);
      expect(find.byKey(const Key('view_all_challenges_button')), findsOneWidget);

      // Featured Card
      expect(find.byKey(const Key('featured_challenge_card')), findsOneWidget);
      expect(find.text('FEATURED PROGRAMME'), findsOneWidget);
      expect(find.text('60-Day Weight Loss Challenge'), findsOneWidget);
      expect(find.byKey(const Key('explore_challenge_cta')), findsOneWidget);

      // Preserved carousel
      expect(find.text('Mini Challenges & Technique'), findsOneWidget);
      expect(find.byType(CarouselSliderHomeWidget), findsOneWidget);
    });

    testWidgets('2. Displays Active Challenge Card when user has active plan',
        (tester) async {
      _configureTestViewport(tester);

      final now = DateTime.now();
      final activeState = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Weight Loss Challenge',
        startDate: now,
        targetEndDate: now.add(const Duration(days: 60)),
        currentDay: 12,
        totalDays: 60,
        completedDayIndices: [1, 2, 3, 4, 5],
        targetCalories: 2000,
        targetMacros: const {'protein': 160, 'carbs': 190, 'fat': 55},
        milestones: const [
          TransformationMilestone(
            id: 'wl_day_14',
            title: 'Consistency Locked',
            description: 'Two weeks of uninterrupted nutrition and workouts logged.',
            triggerDay: 14,
          ),
        ],
      );

      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user';
      provider.activeDocFetcherForTesting = (_) => activeState.toMap();
      await provider.loadTransformation();

      await tester.pumpWidget(
        _buildTestWidget(const DashboardChallengeSection(suppressActiveTransformation: false), provider, scrollable: true),
      );
      await tester.pumpAndSettle();

      // Active Card
      expect(find.byKey(const Key('active_challenge_card')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('active_challenge_card')),
          matching: find.text('ACTIVE CHALLENGE'),
        ),
        findsOneWidget,
      );
      expect(find.text('60-Day Weight Loss Challenge'), findsOneWidget);
      expect(find.text('Day 12 of 60'), findsOneWidget);
      expect(find.text('8% Completed'), findsOneWidget);
      expect(find.byKey(const Key('continue_challenge_cta')), findsOneWidget);
      expect(find.textContaining('Next Milestone: Consistency Locked'), findsOneWidget);
    });

    testWidgets('3. Displays Completed Challenge Card when plan is finished in history',
        (tester) async {
      _configureTestViewport(tester);

      final completedState = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Weight Loss Challenge',
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        targetEndDate: DateTime.now(),
        currentDay: 60,
        totalDays: 60,
        status: 'completed',
        completedDayIndices: List.generate(60, (i) => i + 1),
        targetCalories: 2000,
        targetMacros: const {'protein': 160, 'carbs': 190, 'fat': 55},
        completedAt: DateTime.now(),
      );

      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user';
      provider.activeDocFetcherForTesting = (_) => null;
      provider.history.add(completedState);

      await tester.pumpWidget(
        _buildTestWidget(const DashboardChallengeSection(suppressActiveTransformation: false), provider, scrollable: true),
      );
      await tester.pumpAndSettle();

      // Completed Card
      expect(find.byKey(const Key('completed_challenge_card')), findsOneWidget);
      expect(find.text('PROGRAMME COMPLETED 🏆'), findsOneWidget);
      expect(find.text('60-Day Weight Loss Challenge'), findsOneWidget);
      expect(find.byKey(const Key('explore_another_challenge_cta')), findsOneWidget);
    });
  });

  group('Transformation Plans Hub & Detail Screen Tests', () {
    testWidgets('TransformationHubScreen renders primary and specialised programmes',
        (tester) async {
      _configureTestViewport(tester);

      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user';

      await tester.pumpWidget(
        _buildTestWidget(const TransformationHubScreen(), provider),
      );
      await tester.pumpAndSettle();

      // Title & Primary Section Header
      expect(find.text('Transformation Plans'), findsOneWidget);
      expect(find.text('Primary Programmes (3)'), findsOneWidget);

      // Primary programmes visible
      expect(find.text('Complete Beginner – 30 Days'), findsOneWidget);

      // Scroll to 60-Day Weight Loss Challenge
      await tester.scrollUntilVisible(
        find.text('60-Day Weight Loss Challenge'),
        300,
      );
      expect(find.text('60-Day Weight Loss Challenge'), findsOneWidget);

      // Scroll to 90-Day Muscle Building
      await tester.scrollUntilVisible(
        find.text('90-Day Muscle Building Challenge'),
        300,
      );
      expect(find.text('90-Day Muscle Building Challenge'), findsOneWidget);

      // Scroll to specialised section & programme
      await tester.scrollUntilVisible(
        find.text('12-Week Strength Building Challenge'),
        300,
      );
      expect(find.text('Specialised Programmes (1)'), findsOneWidget);
      expect(find.text('12-Week Strength Building Challenge'), findsOneWidget);
    });

    testWidgets('TransformationPlanDetailScreen renders dynamic programme curriculum',
        (tester) async {
      _configureTestViewport(tester);

      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user';

      final plan = TransformationPlansData.muscleBuilding90;

      await tester.pumpWidget(
        _buildTestWidget(
          TransformationPlanDetailScreen(plan: plan),
          provider,
        ),
      );
      await tester.pumpAndSettle();

      // Header & Title
      expect(find.text('90-Day Muscle Building Challenge'), findsOneWidget);
      expect(find.text('90 DAYS'), findsOneWidget);

      // Curriculum & Highlights
      expect(find.text('Programme Overview'), findsOneWidget);
      expect(find.text('Curriculum Roadmap'), findsOneWidget);
      expect(find.text('Milestone Checkpoints'), findsOneWidget);

      // Bottom CTA button
      expect(find.byKey(const Key('plan_detail_bottom_cta')), findsOneWidget);
      expect(find.text('Start 90-Day Muscle Building Challenge'), findsOneWidget);
    });
  });
}
