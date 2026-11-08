import 'package:carousel_slider/carousel_slider.dart';
import 'package:fitness_app/presentation/home/pages/home_page.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_home_box.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_slider_home_widget.dart';
import 'package:fitness_app/presentation/home/widgets/fitness_data_widget.dart';
import 'package:fitness_app/presentation/home/widgets/home_ai_routine_card.dart';
import 'package:fitness_app/presentation/home/widgets/quick_actions_widget.dart';
import 'package:fitness_app/presentation/home/widgets/recent_prs_widget.dart';
import 'package:fitness_app/presentation/home/widgets/streak_calendar_widget.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StubSubscriptionProvider extends ChangeNotifier
    implements SubscriptionProvider {
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

class MockConsumptionProvider extends ConsumptionProvider {
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

Widget _wrapWithProviders(
  Widget child, {
  StatisticsProvider? statsProvider,
  ConsumptionProvider? consumptionProvider,
  HomeProvider? homeProvider,
  WorkoutProvider? workoutProvider,
  SubscriptionProvider? subscriptionProvider,
}) {
  return ScreenUtilInit(
    key: UniqueKey(),
    designSize: const Size(430, 932),
    minTextAdapt: true,
    splitScreenMode: true,
    child: child,
    builder: (_, wrappedChild) => MultiProvider(
      providers: [
        ChangeNotifierProvider<StatisticsProvider>(
          create: (_) => statsProvider ?? StatisticsProvider(),
        ),
        ChangeNotifierProvider<ConsumptionProvider>(
          create: (_) => consumptionProvider ?? MockConsumptionProvider(),
        ),
        ChangeNotifierProvider<HomeProvider>(
          create: (_) => homeProvider ?? HomeProvider(),
        ),
        ChangeNotifierProvider<WorkoutProvider>(
          create: (_) => workoutProvider ?? WorkoutProvider(),
        ),
        ChangeNotifierProvider<SubscriptionProvider>(
          create: (_) => subscriptionProvider ?? StubSubscriptionProvider(),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: wrappedChild)),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Home Screen Hierarchy and Challenges Verification', () {
    testWidgets('1. CarouselSliderHomeWidget removes Workout Splits card and displays genuine challenges only', (tester) async {
      _configureTestViewport(tester);

      await tester.pumpWidget(
        _wrapWithProviders(const CarouselSliderHomeWidget()),
      );
      await tester.pump();

      // Workout Splits promotional card must be completely removed from challenges
      expect(find.text(StringsManager.workoutsplit), findsNothing);
      expect(find.text('EXPLORE SPLITS'), findsNothing);

      // Page 0: Genuine 30-Day Six-Pack Challenge (Not started badge)
      expect(find.text(StringsManager.sixPackChallenge), findsOneWidget);
      expect(find.text('30-DAY CHALLENGE'), findsOneWidget);

      // Verify viewport fraction is 1.0 (no awkward peeking clutter)
      final carouselFinder = find.byType(CarouselSlider);
      expect(carouselFinder, findsOneWidget);
      final carouselWidget = tester.widget<CarouselSlider>(carouselFinder);
      expect(carouselWidget.options.viewportFraction, 1.0);

      // Drag to Page 1: Weekly Technique Spotlight
      await tester.drag(carouselFinder, const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text(StringsManager.exerciseOfWeek), findsOneWidget);
      expect(find.text('WEEKLY TECHNIQUE'), findsOneWidget);
    });

    testWidgets('2. CarouselHomeBox renders compact height, badges, subtitle, and progress bar cleanly', (tester) async {
      _configureTestViewport(tester);

      await tester.pumpWidget(
        _wrapWithProviders(
          CarouselHomeBox(
            deviceWidth: 430,
            image: 'assets/images/abs_workout.jpg',
            title: '30-Day Core Challenge',
            badge: 'ACTIVE CHALLENGE',
            subtitle: '12 of 30 days completed',
            progress: 0.4,
            actionText: 'Continue Day 13',
            onTap: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('30-Day Core Challenge'), findsOneWidget);
      expect(find.text('ACTIVE CHALLENGE'), findsOneWidget);
      expect(find.text('12 of 30 days completed'), findsOneWidget);
      expect(find.text('Continue Day 13'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('3. RecentPRsWidget displays clean empty state when no PR history exists', (tester) async {
      _configureTestViewport(tester);

      await tester.pumpWidget(
        _wrapWithProviders(const RecentPRsWidget()),
      );
      await tester.pump();

      // Header row
      expect(find.text('Personal Records'), findsOneWidget);
      expect(find.text('PR Vault'), findsOneWidget);

      // Clean, motivating empty state
      expect(
        find.text('Log your sets during workouts to unlock automatic PR detection, estimated 1RMs, and strength curves.'),
        findsOneWidget,
      );
    });

    testWidgets('4. HomePage layout strictly follows the prioritized hierarchy', (tester) async {
      _configureTestViewport(tester);

      await tester.pumpWidget(
        _wrapWithProviders(const HomePage()),
      );
      await tester.pump();

      // Verify all components exist in the tree
      expect(find.byType(HomeAiRoutineCard), findsOneWidget);
      expect(find.byType(StreakCalendarWidget), findsOneWidget);
      expect(find.byType(QuickActionsWidget), findsOneWidget);
      expect(find.byType(RecentPRsWidget), findsOneWidget);
      expect(find.byType(CarouselSliderHomeWidget), findsOneWidget);
      expect(find.byType(FitnessDataWidget), findsOneWidget);

      // Verify the vertical ordering (top-to-bottom hierarchy)
      final nextWorkoutY = tester.getTopLeft(find.byType(HomeAiRoutineCard)).dy;
      final streakY = tester.getTopLeft(find.byType(StreakCalendarWidget)).dy;
      final quickActionsY = tester.getTopLeft(find.byType(QuickActionsWidget)).dy;
      final fitnessDataY = tester.getTopLeft(find.byType(FitnessDataWidget)).dy;
      final recentPRsY = tester.getTopLeft(find.byType(RecentPRsWidget)).dy;
      final challengesY = tester.getTopLeft(find.byType(CarouselSliderHomeWidget)).dy;

      // 1. Next Workout is at the top
      expect(nextWorkoutY < streakY, isTrue, reason: 'Next workout must precede consistency streak');
      // 2. Weekly Consistency is below Next Workout
      expect(streakY < quickActionsY, isTrue, reason: 'Consistency streak must precede quick actions');
      // 3. Quick Actions is below Consistency
      expect(quickActionsY < fitnessDataY, isTrue, reason: 'Quick actions must precede fitness data');
      // 4. Fitness Data is above Recent PRs
      expect(fitnessDataY < recentPRsY, isTrue, reason: 'Fitness data must precede recent PRs');
      // 5. Recent PRs is above Challenges
      expect(recentPRsY < challengesY, isTrue, reason: 'Recent PRs must precede challenges');
    });

    testWidgets('5. FitnessDataWidget does not render SpinKitSpinningLines loader', (tester) async {
      _configureTestViewport(tester);

      await tester.pumpWidget(
        _wrapWithProviders(const FitnessDataWidget()),
      );
      await tester.pump();

      // Ensure no SpinKit widget exists
      final typeFinder = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString().contains('SpinKit'),
      );
      expect(typeFinder, findsNothing);
    });
  });
}
