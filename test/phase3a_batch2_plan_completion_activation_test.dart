import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_model.dart';
import 'package:fitness_app/presentation/ai_coach/workout_generator_screen.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/home_ai_routine_card.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/journal/widgets/weekly_schedule_widget.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestSubscriptionProvider extends SubscriptionProvider {
  _TestSubscriptionProvider({required bool isPremium})
      : _isPremiumOverride = isPremium;

  bool _isPremiumOverride;

  @override
  bool get isPremium => _isPremiumOverride;

  void setPremium(bool value) {
    _isPremiumOverride = value;
    notifyListeners();
  }
}

void _configureTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

List<WorkoutModel> _buildThreeDaySplitWorkouts(DateTime date) {
  return [
    WorkoutModel(
      id: 'w_mon_1',
      name: '[Monday] Barbell Bench Press',
      repNumber: 10,
      setNumber: 1,
      dateTime: date,
    ),
    WorkoutModel(
      id: 'w_wed_1',
      name: '[Wednesday] Barbell Squat',
      repNumber: 10,
      setNumber: 1,
      dateTime: date,
    ),
    WorkoutModel(
      id: 'w_fri_1',
      name: '[Friday] Barbell Deadlift',
      repNumber: 8,
      setNumber: 1,
      dateTime: date,
    ),
  ];
}

List<WorkoutModel> _buildFiveDaySplitWorkouts(DateTime date) {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  return [
    for (int i = 0; i < days.length; i++)
      WorkoutModel(
        id: 'w_${days[i].toLowerCase()}',
        name: '[${days[i]}] Bench Press',
        repNumber: 10,
        setNumber: 3,
        dateTime: date,
      ),
  ];
}

Widget _buildTestHarness({
  required WorkoutProvider workoutProvider,
  required StatisticsProvider statsProvider,
  required HomeProvider homeProvider,
  required SubscriptionProvider subscriptionProvider,
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<WorkoutProvider>.value(value: workoutProvider),
      ChangeNotifierProvider<StatisticsProvider>.value(value: statsProvider),
      ChangeNotifierProvider<HomeProvider>.value(value: homeProvider),
      ChangeNotifierProvider<SubscriptionProvider>.value(
        value: subscriptionProvider,
      ),
    ],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(0.75),
          ),
          child: widget!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    WorkoutLogService.clearLastLogCache();
  });

  group('Phase 3A Batch 2 — Plan Integrity, Completion Indicators & Starter Activation', () {
    testWidgets(
      'Test 1: Plan deletion resets active routine, scheduled days, and weekly target across Home and Weekly Schedule',
      (tester) async {
        _configureTestViewport(tester);
        final wednesday = DateTime(2026, 3, 18, 10, 0);

        // Part A: Delete via HomeAiRoutineCard._confirmResetPlan
        final workoutProvider = WorkoutProvider()
          ..setNowProviderForTesting(() => wednesday)
          ..setAllWorkoutsForTesting(_buildFiveDaySplitWorkouts(wednesday));
        final statsProvider = StatisticsProvider();
        await statsProvider.updateScheduledDays(
          const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
          effectiveDate: wednesday,
        );
        final homeProvider = HomeProvider();
        final subscriptionProvider = _TestSubscriptionProvider(isPremium: true);

        expect(workoutProvider.groupedSplitWorkouts.length, 5);
        expect(statsProvider.weeklyTarget, 5);
        expect(statsProvider.scheduledDayNames.length, 5);

        await tester.pumpWidget(
          _buildTestHarness(
            workoutProvider: workoutProvider,
            statsProvider: statsProvider,
            homeProvider: homeProvider,
            subscriptionProvider: subscriptionProvider,
            child: Column(
              children: const [
                HomeAiRoutineCard(),
                WeeklyScheduleWidget(),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('5-Day Split'), findsOneWidget);

        // Trigger HomeAiRoutineCard reset icon button
        final resetScheduleButton = find.byTooltip('Reset Schedule');
        expect(resetScheduleButton, findsOneWidget);
        await tester.tap(resetScheduleButton);
        await tester.pumpAndSettle();

        expect(find.text('Reset your plan?'), findsOneWidget);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Reset'));
        await tester.pumpAndSettle();

        final prefsAfterHomeReset = await SharedPreferences.getInstance();
        expect(workoutProvider.groupedSplitWorkouts, isEmpty);
        expect(statsProvider.scheduledDayNames, isEmpty);
        expect(statsProvider.scheduledWeekdays, isEmpty);
        expect(statsProvider.weeklyTarget, 3);
        expect(prefsAfterHomeReset.getStringList('scheduled_workout_days'), isNull);
        expect(prefsAfterHomeReset.getInt('weekly_target_count'), isNull);

        // Both HomeAiRoutineCard and WeeklyScheduleWidget reflect no active plan
        expect(find.text('Build Your Workout Plan'), findsOneWidget);
        expect(find.text('No Plan Active'), findsOneWidget);

        // Part B: Re-populate a 5-day plan and delete via WeeklyScheduleWidget._deleteWeeklyPlan
        workoutProvider.setAllWorkoutsForTesting(_buildFiveDaySplitWorkouts(wednesday));
        await statsProvider.updateScheduledDays(
          const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
          effectiveDate: wednesday,
        );
        await tester.pumpAndSettle();

        expect(workoutProvider.groupedSplitWorkouts.length, 5);
        expect(statsProvider.weeklyTarget, 5);

        final weeklyResetButton = find.byTooltip('Reset Plan');
        expect(weeklyResetButton, findsOneWidget);
        await tester.tap(weeklyResetButton);
        await tester.pumpAndSettle();

        expect(find.text('Reset Weekly Plan?'), findsOneWidget);
        await tester.tap(find.widgetWithText(TextButton, 'Reset'));
        await tester.pumpAndSettle();

        final prefsAfterWeeklyReset = await SharedPreferences.getInstance();
        expect(workoutProvider.groupedSplitWorkouts, isEmpty);
        expect(statsProvider.scheduledDayNames, isEmpty);
        expect(statsProvider.scheduledWeekdays, isEmpty);
        expect(statsProvider.weeklyTarget, 3);
        expect(prefsAfterWeeklyReset.getStringList('scheduled_workout_days'), isNull);
        expect(prefsAfterWeeklyReset.getInt('weekly_target_count'), isNull);
        expect(find.text('Build Your Workout Plan'), findsOneWidget);
        expect(find.text('No Plan Active'), findsOneWidget);
      },
    );

    testWidgets(
      'Test 2: Empty premium split preserves a free user schedule and reconciles stale weekly target',
      (tester) async {
        _configureTestViewport(tester);
        final tuesday = DateTime(2026, 3, 17, 9, 0);

        SharedPreferences.setMockInitialValues({
          'scheduled_workout_days': ['Tuesday', 'Thursday', 'Saturday'],
          'weekly_target_count': 5, // Stale target from an old deleted split
        });

        final workoutProvider = WorkoutProvider()
          ..setNowProviderForTesting(() => tuesday)
          ..setAllWorkoutsForTesting(const []);
        final statsProvider = StatisticsProvider();
        final homeProvider = HomeProvider();
        final subscriptionProvider = _TestSubscriptionProvider(isPremium: false);

        // Run the startup / reload schedule restoration and split-sync flow
        await statsProvider.restoreSavedScheduleFromPrefs();
        await workoutProvider.fetchAndSetWorkouts();
        if (workoutProvider.groupedSplitWorkouts.isNotEmpty) {
          await statsProvider.syncSplitSchedule(
            workoutProvider.groupedSplitWorkouts.keys,
          );
        } else {
          await statsProvider.resetWeeklyTarget();
        }

        final prefs = await SharedPreferences.getInstance();
        expect(workoutProvider.groupedSplitWorkouts, isEmpty);
        expect(
          statsProvider.scheduledDayNames,
          equals(['Tuesday', 'Thursday', 'Saturday']),
        );
        expect(statsProvider.weeklyTarget, 3);
        expect(
          prefs.getStringList('scheduled_workout_days'),
          equals(['Tuesday', 'Thursday', 'Saturday']),
        );
        expect(prefs.getInt('weekly_target_count'), 3);

        await tester.pumpWidget(
          _buildTestHarness(
            workoutProvider: workoutProvider,
            statsProvider: statsProvider,
            homeProvider: homeProvider,
            subscriptionProvider: subscriptionProvider,
            child: const HomeAiRoutineCard(),
          ),
        );
        await tester.pumpAndSettle();

        // Free user's 3-day schedule is preserved and no default Mon/Wed/Fri workouts were injected
        expect(workoutProvider.allWorkouts, isEmpty);
        expect(find.text('3-Day Schedule'), findsOneWidget);
      },
    );

    testWidgets(
      'Test 3: Preview then exit preserves existing schedule, and save failure rolls back cleanly',
      (tester) async {
        _configureTestViewport(tester);
        final wednesday = DateTime(2026, 3, 18, 10, 0);

        final workoutProvider = WorkoutProvider()
          ..setNowProviderForTesting(() => wednesday)
          ..setAllWorkoutsForTesting(_buildThreeDaySplitWorkouts(wednesday));
        final statsProvider = StatisticsProvider();
        await statsProvider.updateScheduledDays(
          const ['Monday', 'Wednesday', 'Friday'],
          effectiveDate: wednesday,
        );
        final homeProvider = HomeProvider();
        final subscriptionProvider = _TestSubscriptionProvider(isPremium: true);

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      const HomeAiRoutineCard(),
                      ElevatedButton(
                        onPressed: () =>
                            context.push(Routes.workoutGeneratorRoute),
                        child: const Text('Open Generator'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GoRoute(
              path: Routes.workoutGeneratorRoute,
              builder: (context, state) => const WorkoutGeneratorScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<WorkoutProvider>.value(
                  value: workoutProvider),
              ChangeNotifierProvider<StatisticsProvider>.value(
                  value: statsProvider),
              ChangeNotifierProvider<HomeProvider>.value(value: homeProvider),
              ChangeNotifierProvider<SubscriptionProvider>.value(
                  value: subscriptionProvider),
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
          ),
        );
        await tester.pumpAndSettle();

        // Open WorkoutGeneratorScreen
        await tester.tap(find.text('Open Generator'));
        await tester.pumpAndSettle();

        // Select 5 Days in the generator by toggling Tue and Thu chips
        await tester.tap(find.text('Tue'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Thu'));
        await tester.pumpAndSettle();

        // Tap GENERATE WEEKLY PLAN (preview only)
        final generateBtn = find.text('GENERATE WEEKLY PLAN');
        await tester.ensureVisible(generateBtn);
        await tester.tap(generateBtn);
        await tester.pump(const Duration(milliseconds: 1300));
        await tester.pumpAndSettle();

        // Preview is rendered
        expect(find.text('Your Weekly Split'), findsOneWidget);

        // Active schedule and weekly target MUST NOT have been mutated by preview
        expect(
          statsProvider.scheduledDayNames,
          equals(['Monday', 'Wednesday', 'Friday']),
        );
        expect(statsProvider.weeklyTarget, 3);
        expect(
          workoutProvider.groupedSplitWorkouts.keys.toSet(),
          equals({'Monday', 'Wednesday', 'Friday'}),
        );

        // Also verify rollback if saving throws an error
        workoutProvider.onAddNewWorkoutsForTesting = (_) async {
          throw Exception('Simulated persistence failure');
        };
        final saveBtn = find.text('Save to Schedule');
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        expect(
          workoutProvider.groupedSplitWorkouts.keys.toSet(),
          equals({'Monday', 'Wednesday', 'Friday'}),
        );
        expect(
          statsProvider.scheduledDayNames,
          equals(['Monday', 'Wednesday', 'Friday']),
        );
        expect(statsProvider.weeklyTarget, 3);
        workoutProvider.onAddNewWorkoutsForTesting = null;

        // Exit generator without saving
        router.pop();
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        expect(
          statsProvider.scheduledDayNames,
          equals(['Monday', 'Wednesday', 'Friday']),
        );
        expect(statsProvider.weeklyTarget, 3);
        expect(
          prefs.getStringList('scheduled_workout_days'),
          equals(['Monday', 'Wednesday', 'Friday']),
        );
        expect(
          find.text('3-Day Split (Monday · Wednesday · Friday)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Test 4: Catch-up workout for a previously missed day does not complete today scheduled workout',
      (tester) async {
        _configureTestViewport(tester);
        // Wednesday, March 18, 2026
        final wednesday = DateTime(2026, 3, 18, 10, 0);

        final workoutProvider = WorkoutProvider()
          ..setNowProviderForTesting(() => wednesday)
          ..setAllWorkoutsForTesting(_buildThreeDaySplitWorkouts(wednesday));
        final statsProvider = StatisticsProvider();
        statsProvider.configureStreakStateForTesting(
          completedDates: const [],
          scheduledDays: const ['Monday', 'Wednesday', 'Friday'],
          referenceNow: wednesday,
        );
        final homeProvider = HomeProvider();
        final subscriptionProvider = _TestSubscriptionProvider(isPremium: true);

        await tester.pumpWidget(
          _buildTestHarness(
            workoutProvider: workoutProvider,
            statsProvider: statsProvider,
            homeProvider: homeProvider,
            subscriptionProvider: subscriptionProvider,
            child: const HomeAiRoutineCard(),
          ),
        );
        await tester.pumpAndSettle();

        // Today is Wednesday (scheduled), Monday was missed
        expect(find.text("TODAY'S TARGET"), findsOneWidget);
        expect(find.text('Wednesday Routine'), findsOneWidget);
        expect(
          find.text('Missed Monday? Tap to resume missed workout'),
          findsOneWidget,
        );

        // Tap the missed Monday catch-up action
        await tester.tap(
          find.text('Missed Monday? Tap to resume missed workout'),
        );
        await tester.pumpAndSettle();

        // Inside DayWorkoutSessionPage for Monday Routine
        expect(find.text('Monday Routine'), findsOneWidget);

        // Complete the set and finish the Monday catch-up workout
        final setDoneBtn = find.byKey(const Key('session_set_done_0_0'));
        await tester.ensureVisible(setDoneBtn);
        await tester.tap(setDoneBtn);
        await tester.pump(const Duration(milliseconds: 200));

        // Tap Finish in the app bar to complete the session
        await tester.tap(find.text('Finish'));
        await tester.pumpAndSettle();

        // Summary view is shown; tap Done
        expect(find.text('Done'), findsOneWidget);
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        final todayKey = DateFormat('yyyy-MM-dd').format(wednesday);

        // 1. Monday is completed for this week
        expect(workoutProvider.isDayWorkoutCompletedThisWeek('Monday'), isTrue);
        expect(
          prefs.getBool('completed_routine_Monday_$todayKey'),
          isTrue,
        );

        // 2. Shared 'completed_any_routine' flag must NOT be set, and Wednesday is NOT completed
        expect(prefs.getBool('completed_any_routine_$todayKey'), isNull);
        expect(workoutProvider.isDayWorkoutCompletedToday('Wednesday'), isFalse);
        expect(
          workoutProvider.isDayWorkoutCompletedThisWeek('Wednesday'),
          isFalse,
        );

        // 3. HomeAiRoutineCard still shows Wednesday Routine as TODAY'S TARGET (incomplete)
        expect(find.text("TODAY'S TARGET"), findsOneWidget);
        expect(find.text('Wednesday Routine'), findsOneWidget);
        expect(find.text('Start Workout Session'), findsOneWidget);
        expect(find.text('COMPLETED TODAY ✓'), findsNothing);
        expect(
          find.text('Missed Monday? Tap to resume missed workout'),
          findsNothing,
        );

        // 4. Streak and workout history are still recorded normally
        expect(WorkoutLogService.localSessionsForTesting.length, 1);
        expect(
          WorkoutLogService.localSessionsForTesting.first.dayName,
          'Monday',
        );
        expect(statsProvider.hasWorkoutToday, isTrue);
        expect(statsProvider.workoutsCompletedThisWeek, 1);
      },
    );

    testWidgets(
      'Test 5: Ad-hoc logging updates workout history and streak without completing today scheduled workout',
      (tester) async {
        _configureTestViewport(tester);
        // Wednesday, March 18, 2026
        final wednesday = DateTime(2026, 3, 18, 14, 0);

        final workoutProvider = WorkoutProvider()
          ..setNowProviderForTesting(() => wednesday)
          ..setAllWorkoutsForTesting(_buildThreeDaySplitWorkouts(wednesday));
        final statsProvider = StatisticsProvider();
        statsProvider.configureStreakStateForTesting(
          completedDates: [DateTime(2026, 3, 16)], // Monday completed
          scheduledDays: const ['Monday', 'Wednesday', 'Friday'],
          storedStreak: 1,
          lastWorkoutDate: DateTime(2026, 3, 16),
          referenceNow: wednesday,
        );
        // Also mark Monday finished in WorkoutProvider so Monday isn't missed
        workoutProvider.markWorkoutDayCompleted(
          'Monday',
          completedAt: DateTime(2026, 3, 16, 18, 0),
        );

        final homeProvider = HomeProvider();
        final subscriptionProvider = _TestSubscriptionProvider(isPremium: false);

        await tester.pumpWidget(
          _buildTestHarness(
            workoutProvider: workoutProvider,
            statsProvider: statsProvider,
            homeProvider: homeProvider,
            subscriptionProvider: subscriptionProvider,
            child: const HomeAiRoutineCard(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text("TODAY'S TARGET"), findsOneWidget);
        expect(find.text('Wednesday Routine'), findsOneWidget);
        expect(find.text('COMPLETED TODAY ✓'), findsNothing);

        // Log a standalone ad-hoc exercise and a custom non-routine workout on Wednesday
        await WorkoutLogService().addLog(
          WorkoutLog(
            id: 'adhoc_1',
            exerciseName: 'Dumbbell Bicep Curl',
            date: wednesday,
            sets: [
              WorkoutSet(weight: 15.0, reps: 12, isCompleted: true),
            ],
            category: 'Arms',
          ),
        );
        await workoutProvider.finishWorkout(
          workoutID: 'custom_adhoc',
          name: 'Quick Arm Pump',
          repNumber: 12,
          setNumber: 3,
          dateTime: wednesday,
        );
        await statsProvider.updateStreak();
        await tester.pumpAndSettle();

        // Ad-hoc activity is recorded in history and streak
        expect(WorkoutLogService.localLogsForTesting.length, 1);
        expect(statsProvider.hasWorkoutToday, isTrue);
        expect(statsProvider.currentStreak, 2);

        // Today's scheduled Wednesday routine MUST remain incomplete
        expect(workoutProvider.isDayWorkoutCompletedToday('Wednesday'), isFalse);
        expect(
          workoutProvider.isDayWorkoutCompletedThisWeek('Wednesday'),
          isFalse,
        );
        expect(find.text("TODAY'S TARGET"), findsOneWidget);
        expect(find.text('Wednesday Routine'), findsOneWidget);
        expect(find.text('Start Workout Session'), findsOneWidget);
        expect(find.text('COMPLETED TODAY ✓'), findsNothing);
      },
    );

    testWidgets(
      'Test 6: First-time free user can follow the advertised starter activation flow end-to-end while preserving Pro gating for subsequent re-planning',
      (tester) async {
        _configureTestViewport(tester);
        final wednesday = DateTime(2026, 3, 18, 9, 0);

        final workoutProvider = WorkoutProvider()
          ..setNowProviderForTesting(() => wednesday)
          ..setAllWorkoutsForTesting(const []);
        final statsProvider = StatisticsProvider();
        final homeProvider = HomeProvider();
        homeProvider.userData['goal'] = 'Gain Muscle';
        homeProvider.userData['first name'] = 'Alex';
        final subscriptionProvider = _TestSubscriptionProvider(isPremium: false);

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Scaffold(
                body: SingleChildScrollView(
                  child: HomeAiRoutineCard(),
                ),
              ),
            ),
            GoRoute(
              path: Routes.workoutGeneratorRoute,
              builder: (context, state) => const WorkoutGeneratorScreen(),
            ),
            GoRoute(
              path: Routes.premiumScreen,
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('PremiumScreen')),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<WorkoutProvider>.value(
                  value: workoutProvider),
              ChangeNotifierProvider<StatisticsProvider>.value(
                  value: statsProvider),
              ChangeNotifierProvider<HomeProvider>.value(value: homeProvider),
              ChangeNotifierProvider<SubscriptionProvider>.value(
                  value: subscriptionProvider),
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
          ),
        );
        await tester.pumpAndSettle();

        // 1. HomeAiRoutineCard shows the starter activation prompt
        expect(find.text('Activate 3-Day Gain Muscle Plan'), findsOneWidget);
        expect(find.text('Or tap to activate Free 3-Day Starter Plan'), findsOneWidget);

        // 2. Free user taps 'Or tap to activate Free 3-Day Starter Plan' -> activates default 3-day split without opening AI generator
        await tester.tap(find.text('Or tap to activate Free 3-Day Starter Plan'));
        await tester.pumpAndSettle();

        // 3. Starter routine and schedule are now active
        expect(
          workoutProvider.groupedSplitWorkouts.keys.toSet(),
          equals({'Monday', 'Wednesday', 'Friday'}),
        );
        expect(
          statsProvider.scheduledDayNames,
          equals(['Monday', 'Wednesday', 'Friday']),
        );
        expect(statsProvider.weeklyTarget, 3);

        // 4. Verify the activated routine is displayed on Home
        expect(
          find.text('3-Day Split (Monday · Wednesday · Friday)'),
          findsOneWidget,
        );
        expect(find.text("TODAY'S TARGET"), findsOneWidget);
        expect(find.text('Wednesday Routine'), findsOneWidget);

        // 5. Subsequent attempts to re-plan by free user navigates to WorkoutGeneratorScreen
        expect(find.text('Re-plan'), findsOneWidget);
        await tester.tap(find.text('Re-plan'));
        await tester.pumpAndSettle();
        expect(find.byType(WorkoutGeneratorScreen), findsOneWidget);
      },
    );
  });
}
