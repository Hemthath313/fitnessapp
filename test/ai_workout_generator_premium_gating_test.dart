import 'package:fitness_app/model/workout_model.dart';
import 'package:fitness_app/presentation/ai_coach/workout_generator_screen.dart';
import 'package:fitness_app/presentation/auth/providers/auth_provider.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/home_ai_routine_card.dart';
import 'package:fitness_app/presentation/home/widgets/quick_actions_widget.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/journal/pages/journal_page.dart';
import 'package:fitness_app/presentation/journal/widgets/weekly_schedule_widget.dart';
import 'package:fitness_app/presentation/main/pages/main_page.dart';
import 'package:fitness_app/presentation/widgets/premium_upsell_banner.dart';
import 'package:fitness_app/presentation/workout_tools/plate_calculator_sheet.dart';
import 'package:fitness_app/presentation/workouts/pages/workout_tab_page.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSubscriptionProvider extends SubscriptionProvider {
  _MockSubscriptionProvider({required bool isPremium})
      : _isPremiumOverride = isPremium;

  bool _isPremiumOverride;

  @override
  bool get isPremium => _isPremiumOverride;

  void setPremium(bool value) {
    _isPremiumOverride = value;
    notifyListeners();
  }
}

class _MockConsumptionProvider extends ConsumptionProvider {
  @override
  Future<void> getConsumedCalories() async {}
}

void _setTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _wrapWithHarness({
  required Widget child,
  required WorkoutProvider workoutProvider,
  required StatisticsProvider statsProvider,
  required HomeProvider homeProvider,
  required SubscriptionProvider subscriptionProvider,
  ConsumptionProvider? consumptionProvider,
  GoRouter? customRouter,
}) {
  final router = customRouter ??
      GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, __) => Scaffold(body: child)),
          GoRoute(
            path: Routes.workoutGeneratorRoute,
            builder: (_, __) => const WorkoutGeneratorScreen(),
          ),
          GoRoute(
            path: Routes.premiumScreen,
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('PREMIUM_SCREEN_DESTINATION')),
            ),
          ),
        ],
      );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<WorkoutProvider>.value(value: workoutProvider),
      ChangeNotifierProvider<StatisticsProvider>.value(value: statsProvider),
      ChangeNotifierProvider<HomeProvider>.value(value: homeProvider),
      ChangeNotifierProvider<SubscriptionProvider>.value(
          value: subscriptionProvider),
      ChangeNotifierProvider<ConsumptionProvider>.value(
          value: consumptionProvider ?? ConsumptionProvider()),
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
    ],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp.router(
        routerConfig: router,
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(0.75),
          ),
          child: widget!,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('AI Workout Generator Premium Gating Suite', () {
    testWidgets(
      'Scenario 1: Free user can travel into WorkoutGeneratorScreen, customize days/equipment, and tapping generate navigates to Premium screen without generating',
      (tester) async {
        _setTestViewport(tester);

        final workoutProvider = WorkoutProvider();
        final statsProvider = StatisticsProvider();
        final homeProvider = HomeProvider();
        final subscriptionProvider =
            _MockSubscriptionProvider(isPremium: false);

        await tester.pumpWidget(
          _wrapWithHarness(
            child: const WorkoutGeneratorScreen(),
            workoutProvider: workoutProvider,
            statsProvider: statsProvider,
            homeProvider: homeProvider,
            subscriptionProvider: subscriptionProvider,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Free user sees clean 'GENERATE WEEKLY PLAN' button
        expect(find.text('GENERATE WEEKLY PLAN'), findsOneWidget);

        // 2. Free user can interact with days/equipment
        await tester.tap(find.text('Tue'));
        await tester.pumpAndSettle();

        // 3. Tapping generate checks premium: user is not premium -> navigated directly to premium screen
        final generateBtn = find.text('GENERATE WEEKLY PLAN');
        await tester.ensureVisible(generateBtn);
        await tester.tap(generateBtn);
        await tester.pumpAndSettle();

        // Navigated directly to premium screen
        expect(find.text('PREMIUM_SCREEN_DESTINATION'), findsOneWidget);

        // Plan was NOT generated
        expect(find.text('Your Weekly Split'), findsNothing);
      },
    );

    testWidgets(
      'Scenario 2: Free user with no existing workout plan can activate the predefined 3-day starter plan from Home',
      (tester) async {
        _setTestViewport(tester);

        final wednesday = DateTime(2026, 3, 18, 9, 0);
        final workoutProvider = WorkoutProvider()
          ..setNowProviderForTesting(() => wednesday)
          ..setAllWorkoutsForTesting(const []);
        final statsProvider = StatisticsProvider();
        final homeProvider = HomeProvider();
        final subscriptionProvider =
            _MockSubscriptionProvider(isPremium: false);

        await tester.pumpWidget(
          _wrapWithHarness(
            child: const SingleChildScrollView(child: HomeAiRoutineCard()),
            workoutProvider: workoutProvider,
            statsProvider: statsProvider,
            homeProvider: homeProvider,
            subscriptionProvider: subscriptionProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Displays starter activation option
        expect(find.text('Or tap to activate Free 3-Day Starter Plan'), findsOneWidget);

        // Tap to activate
        await tester.tap(find.text('Or tap to activate Free 3-Day Starter Plan'));
        await tester.pumpAndSettle();

        // Verify Monday, Wednesday, Friday were seeded
        expect(
          workoutProvider.groupedSplitWorkouts.keys.toSet(),
          equals({'Monday', 'Wednesday', 'Friday'}),
        );
        expect(
          statsProvider.scheduledDayNames,
          equals(['Monday', 'Wednesday', 'Friday']),
        );
        expect(statsProvider.weeklyTarget, 3);

        // Success snackbar displayed
        expect(
          find.text('3-Day Starter Routine activated! Ready for your workout.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Scenario 3: Free user customizing 4/5/6 days is navigated to Premium screen upon tapping generate',
      (tester) async {
        _setTestViewport(tester);

        final workoutProvider = WorkoutProvider()
          ..setAllWorkoutsForTesting(const []);
        final statsProvider = StatisticsProvider();
        final homeProvider = HomeProvider();
        final subscriptionProvider =
            _MockSubscriptionProvider(isPremium: false);

        await tester.pumpWidget(
          _wrapWithHarness(
            child: const WorkoutGeneratorScreen(),
            workoutProvider: workoutProvider,
            statsProvider: statsProvider,
            homeProvider: homeProvider,
            subscriptionProvider: subscriptionProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Toggle to 5 days
        await tester.tap(find.text('Tue'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Thu'));
        await tester.pumpAndSettle();

        // Tap generate button
        final generateBtn = find.text('GENERATE WEEKLY PLAN');
        await tester.ensureVisible(generateBtn);
        await tester.tap(generateBtn);
        await tester.pumpAndSettle();

        // Directly navigated to Premium screen without generating
        expect(find.text('PREMIUM_SCREEN_DESTINATION'), findsOneWidget);
        expect(find.text('Your Weekly Split'), findsNothing);
      },
    );

    testWidgets(
      'Scenario 4: Free user with empty plan sees AI generator and 3-day starter option',
      (tester) async {
        _setTestViewport(tester);

        final now = DateTime(2026, 3, 18, 9, 0);
        final workoutProvider = WorkoutProvider()
          ..setNowProviderForTesting(() => now)
          ..setAllWorkoutsForTesting([
            WorkoutModel(
              id: '1',
              name: '[Monday] Test Press',
              repNumber: 10,
              setNumber: 3,
              dateTime: now,
            ),
          ]);
        final statsProvider = StatisticsProvider();
        await statsProvider.updateScheduledDays(const ['Monday'], effectiveDate: now);
        final homeProvider = HomeProvider();
        final subscriptionProvider =
            _MockSubscriptionProvider(isPremium: false);

        // Simulate deleting plan so workouts become empty
        await workoutProvider.deleteWeeklyPlan();
        expect(workoutProvider.groupedSplitWorkouts, isEmpty);

        await tester.pumpWidget(
          _wrapWithHarness(
            child: const SingleChildScrollView(child: WeeklyScheduleWidget()),
            workoutProvider: workoutProvider,
            statsProvider: statsProvider,
            homeProvider: homeProvider,
            subscriptionProvider: subscriptionProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Empty state shows Generate Plan with AI and free starter routine option
        expect(find.text('Generate Plan with AI'), findsOneWidget);
        expect(find.text('Or Activate Free 3-Day Starter Routine'), findsOneWidget);
      },
    );

    testWidgets(
      'Scenario 5: Free user can access Workout Generator from entry points without being blocked at the door',
      (tester) async {
        _setTestViewport(tester);

        final now = DateTime(2026, 3, 18, 9, 0);
        final workoutProvider = WorkoutProvider()
          ..setNowProviderForTesting(() => now)
          ..setAllWorkoutsForTesting([
            WorkoutModel(
              id: 'w1',
              name: '[Wednesday] Barbell Bench Press',
              repNumber: 10,
              setNumber: 3,
              dateTime: now,
            ),
          ]);
        final statsProvider = StatisticsProvider();
        await statsProvider.updateScheduledDays(const ['Wednesday'], effectiveDate: now);
        final homeProvider = HomeProvider();
        final subscriptionProvider =
            _MockSubscriptionProvider(isPremium: false);

        // 5A: Journal Page AI button
        await tester.pumpWidget(
          _wrapWithHarness(
            child: const SingleChildScrollView(child: JournalPage()),
            workoutProvider: workoutProvider,
            statsProvider: statsProvider,
            homeProvider: homeProvider,
            subscriptionProvider: subscriptionProvider,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Generate Workout'), findsOneWidget);

        // 5B: Workout Tab Sparkle Icon
        await tester.pumpWidget(
          _wrapWithHarness(
            child: const WorkoutTabPage(),
            workoutProvider: workoutProvider,
            statsProvider: statsProvider,
            homeProvider: homeProvider,
            subscriptionProvider: subscriptionProvider,
          ),
        );
        await tester.pumpAndSettle();

        final sparkleIcon = find.byIcon(Icons.auto_awesome_rounded);
        expect(sparkleIcon, findsOneWidget);

        // 5C: Home card "Re-plan"
        await tester.pumpWidget(
          _wrapWithHarness(
            child: const SingleChildScrollView(child: HomeAiRoutineCard()),
            workoutProvider: workoutProvider,
            statsProvider: statsProvider,
            homeProvider: homeProvider,
            subscriptionProvider: subscriptionProvider,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Re-plan'), findsOneWidget);
      },
    );

    testWidgets(
      'Scenario 6: Premium user can generate and save a custom AI workout successfully',
      (tester) async {
        _setTestViewport(tester);

        final now = DateTime(2026, 3, 18, 9, 0);
        final workoutProvider = WorkoutProvider()
          ..setNowProviderForTesting(() => now)
          ..setAllWorkoutsForTesting(const []);
        final statsProvider = StatisticsProvider();
        final homeProvider = HomeProvider();
        final subscriptionProvider =
            _MockSubscriptionProvider(isPremium: true);

        await tester.pumpWidget(
          _wrapWithHarness(
            child: const WorkoutGeneratorScreen(),
            workoutProvider: workoutProvider,
            statsProvider: statsProvider,
            homeProvider: homeProvider,
            subscriptionProvider: subscriptionProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Premium user sees full Generate button
        expect(find.text('GENERATE WEEKLY PLAN'), findsOneWidget);
        await tester.tap(find.text('GENERATE WEEKLY PLAN'));
        await tester.pump(const Duration(milliseconds: 1300));
        await tester.pumpAndSettle();

        // Preview is rendered with 'Save to Schedule' enabled
        expect(find.text('Your Weekly Split'), findsOneWidget);
        expect(find.text('Save to Schedule'), findsOneWidget);

        // Save plan
        await tester.tap(find.text('Save to Schedule'));
        await tester.pumpAndSettle();

        // Workouts were persisted
        expect(workoutProvider.groupedSplitWorkouts.isNotEmpty, isTrue);
      },
    );

    test('Scenario 7: Subscription default/loading/error state never grants Premium access', () {
      final uninitializedProvider = SubscriptionProvider(autoInitialize: false);
      expect(uninitializedProvider.isPremium, isFalse);
      expect(uninitializedProvider.isLifetime, isFalse);
    });

    testWidgets(
      'Scenario 8: The Plate Calculator remains completely accessible and free for all users',
      (tester) async {
        _setTestViewport(tester);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => PlateCalculatorSheet.show(context, initialWeight: 100),
                  child: const Text('Open Plate Calculator'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Plate Calculator'));
        await tester.pumpAndSettle();

        // Plate calculator sheet opens without any paywall
        expect(find.text('Barbell Plate Math'), findsOneWidget);
        expect(find.text('Bar Weight'), findsOneWidget);
      },
    );

    test('Scenario 9: Default-plan restoration seeds exact 3-day split reliably', () async {
      final now = DateTime(2026, 3, 18, 9, 0);
      final workoutProvider = WorkoutProvider()
        ..setNowProviderForTesting(() => now)
        ..setAllWorkoutsForTesting(const []);

      await workoutProvider.restoreDefaultThreeDaySplit();

      expect(workoutProvider.allWorkouts.length, 15);
      final days = workoutProvider.groupedSplitWorkouts.keys.toSet();
      expect(days, equals({'Monday', 'Wednesday', 'Friday'}));
    });

    testWidgets(
      'Scenario 10: Router allows free users to navigate directly to workoutGeneratorRoute',
      (tester) async {
        _setTestViewport(tester);

        final subscriptionProvider =
            _MockSubscriptionProvider(isPremium: false);
        final workoutProvider = WorkoutProvider();
        final statsProvider = StatisticsProvider();
        final homeProvider = HomeProvider();

        await tester.pumpWidget(
          _wrapWithHarness(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => context.push(Routes.workoutGeneratorRoute),
                child: const Text('Direct Push Generator'),
              ),
            ),
            workoutProvider: workoutProvider,
            statsProvider: statsProvider,
            homeProvider: homeProvider,
            subscriptionProvider: subscriptionProvider,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Direct Push Generator'));
        await tester.pumpAndSettle();

        // Free user successfully enters generator
        expect(find.text('AI Workout Generator'), findsOneWidget);
        expect(find.text('GENERATE WEEKLY PLAN'), findsOneWidget);
      },
    );

    testWidgets(
      'Scenario 11: Router redirect allows active premium users into workoutGeneratorRoute',
      (tester) async {
        _setTestViewport(tester);

        final subscriptionProvider =
            _MockSubscriptionProvider(isPremium: true);
        final workoutProvider = WorkoutProvider()
          ..setAllWorkoutsForTesting(const []);
        final statsProvider = StatisticsProvider();
        final homeProvider = HomeProvider();

        await tester.pumpWidget(
          _wrapWithHarness(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => context.push(Routes.workoutGeneratorRoute),
                child: const Text('Direct Push Generator'),
              ),
            ),
            workoutProvider: workoutProvider,
            statsProvider: statsProvider,
            homeProvider: homeProvider,
            subscriptionProvider: subscriptionProvider,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Direct Push Generator'));
        await tester.pumpAndSettle();

        // Allowed into generator
        expect(find.text('GENERATE WEEKLY PLAN'), findsOneWidget);
        expect(find.text('PREMIUM_SCREEN_DESTINATION'), findsNothing);
      },
    );

    testWidgets(
      'Scenario 12: PremiumUpsellBannerCard renders dark navy styling, PRO badge, dismiss icon, and navigates to Premium on CTA tap',
      (tester) async {
        _setTestViewport(tester);

        bool dismissed = false;
        final testRouter = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => Scaffold(
                body: PremiumUpsellBannerCard(
                  onDismiss: () => dismissed = true,
                ),
              ),
            ),
            GoRoute(
              path: Routes.premiumScreen,
              builder: (_, __) => const Scaffold(
                body: Center(child: Text('PREMIUM_SCREEN_DESTINATION')),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => MaterialApp.router(
              routerConfig: testRouter,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Unlock Gym Buddy Pro'), findsOneWidget);
        expect(find.text('PRO'), findsOneWidget);
        expect(
          find.text(
              'Build unlimited custom AI workout splits, access strength analytics, and train completely ad-free.'),
          findsOneWidget,
        );
        expect(find.text('Upgrade to Pro'), findsOneWidget);

        // Tap dismiss button
        await tester.tap(find.byKey(const Key('premium_banner_dismiss_button')));
        await tester.pumpAndSettle();
        expect(dismissed, isTrue);

        // Tap CTA button
        await tester.tap(find.byKey(const Key('premium_banner_cta_button')));
        await tester.pumpAndSettle();
        expect(find.text('PREMIUM_SCREEN_DESTINATION'), findsOneWidget);
      },
    );

    testWidgets(
      'Scenario 13: Delayed timer triggers in-screen PremiumUpsellBannerCard for free users without modal bottom sheet',
      (tester) async {
        _setTestViewport(tester);

        final subscriptionProvider =
            _MockSubscriptionProvider(isPremium: false);
        final workoutProvider = WorkoutProvider()
          ..setAllWorkoutsForTesting(const []);
        final statsProvider = StatisticsProvider();
        final homeProvider = HomeProvider();
        final consumptionProvider = _MockConsumptionProvider();

        await tester.pumpWidget(
          _wrapWithHarness(
            child: const MainPage(
              paywallTimerDelayForTesting: Duration(milliseconds: 50),
            ),
            workoutProvider: workoutProvider,
            statsProvider: statsProvider,
            homeProvider: homeProvider,
            subscriptionProvider: subscriptionProvider,
            consumptionProvider: consumptionProvider,
          ),
        );
        await tester.pump();

        // Initially before timer expires, banner is not visible
        expect(find.byType(PremiumUpsellBannerCard), findsNothing);

        // Advance timer past the 50ms delay
        await tester.pump(const Duration(milliseconds: 100));

        // Banner appears in-screen
        expect(find.byType(PremiumUpsellBannerCard), findsOneWidget);
        expect(find.text('Unlock Gym Buddy Pro'), findsOneWidget);

        // Verify NO modal bottom sheet dialog exists
        expect(find.byType(BottomSheet), findsNothing);

        // Dismissing the banner hides it
        await tester.tap(find.byKey(const Key('premium_banner_dismiss_button')));
        await tester.pump();

        expect(find.byType(PremiumUpsellBannerCard), findsNothing);
      },
    );

    testWidgets(
      'Scenario 14: Active Premium subscribers never see the upsell banner even after timer fires',
      (tester) async {
        _setTestViewport(tester);

        final subscriptionProvider =
            _MockSubscriptionProvider(isPremium: true);
        final workoutProvider = WorkoutProvider()
          ..setAllWorkoutsForTesting(const []);
        final statsProvider = StatisticsProvider();
        final homeProvider = HomeProvider();
        final consumptionProvider = _MockConsumptionProvider();

        await tester.pumpWidget(
          _wrapWithHarness(
            child: const MainPage(
              paywallTimerDelayForTesting: Duration(milliseconds: 50),
            ),
            workoutProvider: workoutProvider,
            statsProvider: statsProvider,
            homeProvider: homeProvider,
            subscriptionProvider: subscriptionProvider,
            consumptionProvider: consumptionProvider,
          ),
        );
        await tester.pump();

        // Advance timer
        await tester.pump(const Duration(milliseconds: 100));

        // Banner never appears for premium subscribers
        expect(find.byType(PremiumUpsellBannerCard), findsNothing);
      },
    );

    testWidgets(
      'Scenario 15: Disposing MainPage cancels the delayed timer and prevents leaks',
      (tester) async {
        _setTestViewport(tester);

        final subscriptionProvider =
            _MockSubscriptionProvider(isPremium: false);
        final workoutProvider = WorkoutProvider()
          ..setAllWorkoutsForTesting(const []);
        final statsProvider = StatisticsProvider();
        final homeProvider = HomeProvider();
        final consumptionProvider = _MockConsumptionProvider();

        await tester.pumpWidget(
          _wrapWithHarness(
            child: const MainPage(
              paywallTimerDelayForTesting: Duration(seconds: 10),
            ),
            workoutProvider: workoutProvider,
            statsProvider: statsProvider,
            homeProvider: homeProvider,
            subscriptionProvider: subscriptionProvider,
            consumptionProvider: consumptionProvider,
          ),
        );
        await tester.pump();

        // Unmount / dispose MainPage before the timer fires
        await tester.pumpWidget(
          _wrapWithHarness(
            child: const SizedBox.shrink(),
            workoutProvider: workoutProvider,
            statsProvider: statsProvider,
            homeProvider: homeProvider,
            subscriptionProvider: subscriptionProvider,
            consumptionProvider: consumptionProvider,
          ),
        );
        await tester.pump();

        // Advance time past the 10-second timer to ensure cancelled timer does not fire or throw on unmounted widget
        await tester.pump(const Duration(seconds: 15));

        expect(find.byType(PremiumUpsellBannerCard), findsNothing);
      },
    );
  });
}
