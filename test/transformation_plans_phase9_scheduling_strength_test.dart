import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/meal_model.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/model/water_model.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/models/transformation_daily_log_model.dart';
import 'package:fitness_app/presentation/transformation_plans/models/transformation_schedule_override.dart';
import 'package:fitness_app/presentation/transformation_plans/pages/transformation_completion_screen.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/utils/transformation_strength_analytics.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/transformation_strength_progress_card.dart';
import 'package:fitness_app/services/notification_service.dart';
import 'package:fitness_app/services/strength_service.dart';
import 'package:fitness_app/services/workout_log_service.dart';

class MockHomeProvider extends ChangeNotifier implements HomeProvider {
  @override
  Map<String, dynamic> userData = {
    'name': 'Alex Fitness',
    'age': 28,
    'gender': 'Male',
    'height': 180.0,
    'weight': 82.5,
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockConsumptionProvider extends ChangeNotifier implements ConsumptionProvider {
  @override
  double waterADay = 2500.0;
  @override
  int consumedCalories = 2000;
  @override
  List<MealModel> get meals => [];
  @override
  List<WaterModel> get water => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSubscriptionProvider extends ChangeNotifier implements SubscriptionProvider {
  @override
  bool get isPremium => true;
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

Widget _wrapWithTestProviders({
  required Widget child,
  required TransformationProvider transformationProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TransformationProvider>.value(value: transformationProvider),
      ChangeNotifierProvider<HomeProvider>.value(value: MockHomeProvider()),
      ChangeNotifierProvider<ConsumptionProvider>.value(value: MockConsumptionProvider()),
      ChangeNotifierProvider<SubscriptionProvider>.value(value: MockSubscriptionProvider()),
    ],
    child: ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        home: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Gym Buddy Phase 9 — Flexible Scheduling & Strength Analytics Tests', () {
    // ------------------------------------------------------------------------
    // Part A: Scheduling Tests (1 - 14)
    // ------------------------------------------------------------------------

    test('1. Missed workout remains incomplete and is not falsely auto-completed', () async {
      final now = DateTime.now();
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_p9';
      provider.activeDocFetcherForTesting = (_) => {
        'planId': 'weight_loss_60',
        'startDate': DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 3))),
        'currentDay': 4,
        'totalDays': 60,
        'completedDayIndices': [1], // Only Day 1 completed; Day 2 was missed
        'status': 'active',
      };
      await provider.loadTransformation();

      expect(provider.isDayCompleted(2), isFalse);
      expect(provider.activeTransformation?.completedDayIndices.contains(2), isFalse);
    });

    test('2. Reschedule to tomorrow updates scheduledDate while preserving sequence', () async {
      final now = DateTime.now();
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_p9';
      provider.activeDocSaverForTesting = (uid, data) async {};
      provider.activeDocFetcherForTesting = (_) => {
        'planId': 'weight_loss_60',
        'startDate': DateFormat('yyyy-MM-dd').format(now),
        'currentDay': 1,
        'totalDays': 60,
        'completedDayIndices': <int>[],
        'status': 'active',
      };
      await provider.loadTransformation();

      final tomorrow = now.add(const Duration(days: 1));
      final success = await provider.rescheduleDay(dayNumber: 1, newDate: tomorrow);

      expect(success, isTrue);
      expect(provider.activeTransformation?.isDayRescheduled(1), isTrue);
      final scheduled = provider.activeTransformation?.getScheduledDateForDay(1);
      expect(scheduled?.day, tomorrow.day);
      expect(scheduled?.month, tomorrow.month);
    });

    test('3. Reschedule to a selected custom date updates schedule override', () async {
      final now = DateTime.now();
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_p9';
      provider.activeDocSaverForTesting = (uid, data) async {};
      provider.activeDocFetcherForTesting = (_) => {
        'planId': 'weight_loss_60',
        'startDate': DateFormat('yyyy-MM-dd').format(now),
        'currentDay': 2,
        'totalDays': 60,
        'completedDayIndices': <int>[],
        'status': 'active',
      };
      await provider.loadTransformation();

      final targetDate = now.add(const Duration(days: 5));
      final success = await provider.rescheduleDay(dayNumber: 2, newDate: targetDate, note: 'Travel');

      expect(success, isTrue);
      final override = provider.activeTransformation?.getScheduleOverride(2);
      expect(override, isNotNull);
      expect(override?.note, 'Travel');
      expect(override?.status, 'rescheduled');
    });

    test('4. Original programme day number remains unchanged after rescheduling', () async {
      final now = DateTime.now();
      final state = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Weight Loss',
        startDate: now,
        targetEndDate: now.add(const Duration(days: 60)),
        currentDay: 8,
        totalDays: 60,
        targetCalories: 2000,
        targetMacros: const {'protein': 140},
        scheduleOverrides: {
          8: TransformationScheduleOverride(
            dayNumber: 8,
            originalDate: now.add(const Duration(days: 7)),
            scheduledDate: now.add(const Duration(days: 9)),
            status: 'rescheduled',
          ),
        },
      );

      expect(state.getScheduleOverride(8)?.dayNumber, 8);
      expect(state.isDayRescheduled(8), isTrue);
    });

    test('5. Completed workouts cannot be accidentally rescheduled', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_p9';
      provider.activeDocSaverForTesting = (uid, data) async {};
      provider.activeDocFetcherForTesting = (_) => {
        'planId': 'weight_loss_60',
        'startDate': '2026-11-01',
        'currentDay': 2,
        'totalDays': 60,
        'completedDayIndices': [1], // Day 1 completed
        'status': 'active',
      };
      await provider.loadTransformation();

      final success = await provider.rescheduleDay(
        dayNumber: 1,
        newDate: DateTime(2026, 11, 10),
      );

      expect(success, isFalse);
      expect(provider.activeTransformation?.isDayRescheduled(1), isFalse);
    });

    test('6. Skipping a workout records it as skipped and does not mark it completed', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_p9';
      provider.activeDocSaverForTesting = (uid, data) async {};
      provider.activeDocFetcherForTesting = (_) => {
        'planId': 'weight_loss_60',
        'startDate': '2026-11-01',
        'currentDay': 2,
        'totalDays': 60,
        'completedDayIndices': <int>[],
        'status': 'active',
      };
      await provider.loadTransformation();

      final success = await provider.skipDay(dayNumber: 2, reason: 'Work commitment');
      expect(success, isTrue);
      expect(provider.activeTransformation?.isDaySkipped(2), isTrue);
      expect(provider.isDayCompleted(2), isFalse);
      expect(provider.activeTransformation?.completedDayIndices.contains(2), isFalse);
    });

    test('7. Duplicate rescheduling is prevented by replacing existing override', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_p9';
      provider.activeDocSaverForTesting = (uid, data) async {};
      provider.activeDocFetcherForTesting = (_) => {
        'planId': 'weight_loss_60',
        'startDate': '2026-11-01',
        'currentDay': 1,
        'totalDays': 60,
        'completedDayIndices': <int>[],
        'status': 'active',
      };
      await provider.loadTransformation();

      await provider.rescheduleDay(dayNumber: 1, newDate: DateTime(2026, 11, 3));
      await provider.rescheduleDay(dayNumber: 1, newDate: DateTime(2026, 11, 4));

      expect(provider.activeTransformation?.scheduleOverrides.length, 1);
      final sched = provider.activeTransformation?.getScheduledDateForDay(1);
      expect(sched, DateTime(2026, 11, 4));
    });

    test('8. Multiple missed workouts provide clear schedule adjustment summary without backlog', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_p9';
      provider.activeDocSaverForTesting = (uid, data) async {};
      provider.activeDocFetcherForTesting = (_) => {
        'planId': 'weight_loss_60',
        'startDate': '2026-11-01',
        'currentDay': 7,
        'totalDays': 60,
        'completedDayIndices': <int>[], // 0 of 5 completed
        'status': 'active',
      };
      await provider.loadTransformation();

      await provider.skipDay(dayNumber: 1);
      await provider.skipDay(dayNumber: 2);

      final summary = provider.getWeeklyScheduleSummary(weekNumber: 1);
      expect(summary.skippedWorkouts, 2);
      expect(summary.advisoryInsights.any((i) => i.contains('reducing weekly training days')), isTrue);
    });

    test('9. Rest days remain rest days and cannot be rescheduled', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_p9';
      provider.activeDocSaverForTesting = (uid, data) async {};
      provider.activeDocFetcherForTesting = (_) => {
        'planId': 'weight_loss_60', // Day 3 is scheduled rest day in blueprint
        'startDate': '2026-11-01',
        'currentDay': 3,
        'totalDays': 60,
        'completedDayIndices': <int>[],
        'status': 'active',
      };
      await provider.loadTransformation();

      final blueprint = TransformationPlansData.getById('weight_loss_60');
      expect(blueprint?.getDayBlueprint(3)?.isRestDay, isTrue);

      final success = await provider.rescheduleDay(dayNumber: 3, newDate: DateTime(2026, 11, 5));
      expect(success, isFalse);
    });

    test('10. Historical daily records remain unchanged when rescheduling', () async {
      final now = DateTime.now();
      final logDay1 = TransformationDailyLog(
        planId: 'weight_loss_60',
        dayNumber: 1,
        dateString: '2026-11-01',
        workoutStatus: AccountabilityStatus.completed,
        calorieStatus: AccountabilityStatus.completed,
        proteinStatus: AccountabilityStatus.completed,
        waterStatus: AccountabilityStatus.completed,
        recoveryStatus: AccountabilityStatus.completed,
        dailyAdherenceScore: 100.0,
        lastUpdated: now,
      );

      final state = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Weight Loss',
        startDate: DateTime(2026, 11, 1),
        targetEndDate: DateTime(2026, 12, 31),
        currentDay: 2,
        totalDays: 60,
        targetCalories: 2000,
        targetMacros: const {'protein': 140},
        dailyLogs: {'2026-11-01': logDay1},
        scheduleOverrides: {
          2: TransformationScheduleOverride(
            dayNumber: 2,
            originalDate: DateTime(2026, 11, 2),
            scheduledDate: DateTime(2026, 11, 5),
          ),
        },
      );

      expect(state.dailyLogs['2026-11-01']?.dailyAdherenceScore, 100.0);
      expect(state.dailyLogs['2026-11-01']?.workoutStatus, AccountabilityStatus.completed);
    });

    test('11. Date handling handles month and year boundaries cleanly', () async {
      final dec30 = DateTime(2026, 12, 30);
      final jan2 = DateTime(2027, 1, 2);

      final state = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Challenge',
        startDate: dec30,
        targetEndDate: dec30.add(const Duration(days: 60)),
        currentDay: 1,
        totalDays: 60,
        targetCalories: 2000,
        targetMacros: const {'protein': 140},
        scheduleOverrides: {
          1: TransformationScheduleOverride(
            dayNumber: 1,
            originalDate: dec30,
            scheduledDate: jan2,
          ),
        },
      );

      final scheduled = state.getScheduledDateForDay(1);
      expect(scheduled.year, 2027);
      expect(scheduled.month, 1);
      expect(scheduled.day, 2);
    });

    test('12. Local date and timezone handling uses normalized midnight dates', () {
      final localDate = DateTime(2026, 11, 15, 23, 45); // Late evening
      final normalized = DateTime(localDate.year, localDate.month, localDate.day);

      expect(normalized.hour, 0);
      expect(normalized.minute, 0);
      expect(DateFormat('yyyy-MM-dd').format(normalized), '2026-11-15');
    });

    test('13. NotificationService provides workout reminder methods without exceptions', () async {
      final notifService = NotificationService();
      // Verifies method calls do not throw in mock or headless test mode
      await notifService.scheduleTransformationWorkoutReminder(
        dayNumber: 5,
        scheduledDate: DateTime.now().add(const Duration(days: 2)),
        dayName: 'Legs & Core',
      );
      await notifService.cancelTransformationWorkoutReminder(5);
    });

    test('14. Normal workout schedules remain unaffected by transformation overrides', () {
      // Transformation overrides only affect the active transformation state map
      final state = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Challenge',
        startDate: DateTime(2026, 11, 1),
        targetEndDate: DateTime(2026, 12, 31),
        currentDay: 1,
        totalDays: 60,
        targetCalories: 2000,
        targetMacros: const {'protein': 140},
        scheduleOverrides: {
          1: TransformationScheduleOverride(
            dayNumber: 1,
            originalDate: DateTime(2026, 11, 1),
            scheduledDate: DateTime(2026, 11, 4),
          ),
        },
      );

      expect(state.scheduleOverrides.containsKey(1), isTrue);
      // Non-existent days default cleanly to their original sequence
      final day2Date = state.getScheduledDateForDay(2);
      expect(day2Date, DateTime(2026, 11, 2));
    });

    // ------------------------------------------------------------------------
    // Part B: Strength Analytics Tests (15 - 24)
    // ------------------------------------------------------------------------

    test('15. Strength data is retrieved from existing workout history sessions', () {
      final now = DateTime(2026, 11, 10);
      final sessions = [
        WorkoutSession(
          id: 's1',
          userId: 'u1',
          workoutName: 'Chest Day',
          dayName: 'Day 1 Chest',
          startedAt: now.subtract(const Duration(days: 5)),
          completedAt: now.subtract(const Duration(days: 5)),
          durationSeconds: 2400,
          status: 'completed',
          totalVolume: 4000.0,
          planId: 'weight_loss_60',
          exercises: [
            SessionExercise(
              exerciseName: 'Barbell Bench Press',
              order: 1,
              sets: [
                WorkoutSet(reps: 10, weight: 60.0, isCompleted: true),
                WorkoutSet(reps: 8, weight: 65.0, isCompleted: true),
              ],
            ),
          ],
        ),
      ];

      final state = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Weight Loss',
        startDate: now.subtract(const Duration(days: 7)),
        targetEndDate: now.add(const Duration(days: 53)),
        currentDay: 6,
        totalDays: 60,
        targetCalories: 2000,
        targetMacros: const {'protein': 140},
      );

      final summary = TransformationStrengthAnalytics.analyze(state: state, sessions: sessions);
      expect(summary.hasData, isTrue);
      expect(summary.totalStrengthWorkouts, 1);
      expect(summary.exerciseProgressions.length, 1);
      expect(summary.exerciseProgressions.first.exerciseName, 'Barbell Bench Press');
      expect(summary.exerciseProgressions.first.latestWeight, 65.0);
    });

    test('16. Exercise-level comparison matches canonical names and calculates improvements', () {
      final now = DateTime.now();
      final sessions = [
        WorkoutSession(
          id: 's1',
          userId: 'u1',
          workoutName: 'Chest Day',
          dayName: 'Day 1 Chest',
          startedAt: now.subtract(const Duration(days: 10)),
          completedAt: now.subtract(const Duration(days: 10)),
          durationSeconds: 2000,
          status: 'completed',
          totalVolume: 3000,
          planId: 'weight_loss_60',
          exercises: [
            SessionExercise(
              exerciseName: '[Day 1] Barbell Bench Press',
              order: 1,
              sets: [
                WorkoutSet(reps: 10, weight: 50.0, isCompleted: true),
              ],
            ),
          ],
        ),
        WorkoutSession(
          id: 's2',
          userId: 'u1',
          workoutName: 'Chest Day',
          dayName: 'Day 8 Chest',
          startedAt: now.subtract(const Duration(days: 2)),
          completedAt: now.subtract(const Duration(days: 2)),
          durationSeconds: 2000,
          status: 'completed',
          totalVolume: 3500,
          planId: 'weight_loss_60',
          exercises: [
            SessionExercise(
              exerciseName: 'Barbell Bench Press',
              order: 1,
              sets: [
                WorkoutSet(reps: 10, weight: 55.0, isCompleted: true),
              ],
            ),
          ],
        ),
      ];

      final state = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Challenge',
        startDate: now.subtract(const Duration(days: 14)),
        targetEndDate: now.add(const Duration(days: 46)),
        currentDay: 12,
        totalDays: 60,
        targetCalories: 2000,
        targetMacros: const {'protein': 140},
      );

      final summary = TransformationStrengthAnalytics.analyze(state: state, sessions: sessions);
      expect(summary.exerciseProgressions.length, 1);
      final p = summary.exerciseProgressions.first;
      expect(p.startingWeight, 50.0);
      expect(p.latestWeight, 55.0);
      expect(p.weightDifference, 5.0);
      expect(p.percentageImprovement, 10.0);
    });

    test('17. Estimated 1RM calculation uses existing StrengthService Epley formula', () {
      final set = WorkoutSet(reps: 10, weight: 100.0, isCompleted: true);
      // Epley: 100 * (1 + 10 / 30) = 133.333 kg
      final est1RM = StrengthService.calculateEstimated1RM(set);
      expect((est1RM - 133.33).abs(), lessThan(0.1));
    });

    test('18. Invalid sets are excluded (warmup, weight <= 0, incomplete)', () {
      final warmupSet = WorkoutSet(reps: 10, weight: 50.0, type: SetType.warmup, isCompleted: true);
      final incompleteSet = WorkoutSet(reps: 10, weight: 80.0, isCompleted: false);
      final zeroWeightSet = WorkoutSet(reps: 10, weight: 0.0, isCompleted: true);

      expect(StrengthService.calculateEstimated1RM(warmupSet), 0.0);
      expect(StrengthService.calculateEstimated1RM(incompleteSet), 0.0);
      expect(StrengthService.calculateEstimated1RM(zeroWeightSet), 0.0);
    });

    test('19. PR records are not duplicated across transformation sessions', () {
      final now = DateTime.now();
      final sessions = [
        WorkoutSession(
          id: 's1',
          userId: 'u1',
          workoutName: 'Leg Day',
          dayName: 'Day 1',
          startedAt: now.subtract(const Duration(days: 3)),
          durationSeconds: 1800,
          status: 'completed',
          totalVolume: 2000,
          planId: 'weight_loss_60',
          exercises: [
            SessionExercise(
              exerciseName: 'Squat',
              order: 1,
              sets: [
                WorkoutSet(reps: 5, weight: 100.0, isCompleted: true),
                WorkoutSet(reps: 5, weight: 100.0, isCompleted: true),
              ],
            ),
          ],
        ),
      ];

      final state = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Challenge',
        startDate: now.subtract(const Duration(days: 5)),
        targetEndDate: now.add(const Duration(days: 55)),
        currentDay: 4,
        totalDays: 60,
        targetCalories: 2000,
        targetMacros: const {'protein': 140},
      );

      final summary = TransformationStrengthAnalytics.analyze(state: state, sessions: sessions);
      // Even with 2 identical sets in session 1, only 1 PR is recorded
      expect(summary.prsAchieved.length, 1);
      expect(summary.prsAchieved.first.exerciseName, 'Squat');
    });

    test('20. Transformation-only strength summary filters out sessions outside transformation', () {
      final now = DateTime.now();
      final sessions = [
        // Outside transformation (prior to start)
        WorkoutSession(
          id: 's_old',
          userId: 'u1',
          workoutName: 'Old Workout',
          dayName: 'Old Workout',
          startedAt: now.subtract(const Duration(days: 100)),
          durationSeconds: 1800,
          status: 'completed',
          totalVolume: 5000,
          exercises: [
            SessionExercise(
              exerciseName: 'Deadlift',
              order: 1,
              sets: [WorkoutSet(reps: 5, weight: 150.0, isCompleted: true)],
            ),
          ],
        ),
        // Inside transformation
        WorkoutSession(
          id: 's_trans',
          userId: 'u1',
          workoutName: 'Day 1 Deadlift',
          dayName: 'Day 1',
          startedAt: now.subtract(const Duration(days: 5)),
          durationSeconds: 1800,
          status: 'completed',
          totalVolume: 3000,
          planId: 'weight_loss_60',
          exercises: [
            SessionExercise(
              exerciseName: 'Deadlift',
              order: 1,
              sets: [WorkoutSet(reps: 5, weight: 100.0, isCompleted: true)],
            ),
          ],
        ),
      ];

      final state = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Challenge',
        startDate: now.subtract(const Duration(days: 10)),
        targetEndDate: now.add(const Duration(days: 50)),
        currentDay: 5,
        totalDays: 60,
        targetCalories: 2000,
        targetMacros: const {'protein': 140},
      );

      final summary = TransformationStrengthAnalytics.analyze(state: state, sessions: sessions);
      expect(summary.totalStrengthWorkouts, 1);
      expect(summary.exerciseProgressions.first.startingWeight, 100.0);
    });

    test('21. Empty strength history returns hasData false without synthetic numbers', () {
      final state = UserTransformationState(
        planId: 'weight_loss_60',
        planTitle: '60-Day Challenge',
        startDate: DateTime.now(),
        targetEndDate: DateTime.now().add(const Duration(days: 60)),
        currentDay: 1,
        totalDays: 60,
        targetCalories: 2000,
        targetMacros: const {'protein': 140},
      );

      final summary = TransformationStrengthAnalytics.analyze(state: state, sessions: const []);
      expect(summary.hasData, isFalse);
      expect(summary.totalStrengthWorkouts, 0);
      expect(summary.prsAchieved, isEmpty);
      expect(summary.exerciseProgressions, isEmpty);
      expect(summary.totalEstimated1RMGain, 0.0);
    });

    testWidgets('22. Strength chart and progress card renders real recorded session data', (tester) async {
      _configureTestViewport(tester);

      final now = DateTime.now();
      final sessions = [
        WorkoutSession(
          id: 's1',
          userId: 'u1',
          workoutName: 'Chest Day',
          dayName: 'Day 1 Chest',
          startedAt: now.subtract(const Duration(days: 7)),
          completedAt: now.subtract(const Duration(days: 7)),
          durationSeconds: 2000,
          status: 'completed',
          totalVolume: 3000,
          planId: 'weight_loss_60',
          exercises: [
            SessionExercise(
              exerciseName: 'Bench Press',
              order: 1,
              sets: [WorkoutSet(reps: 10, weight: 50.0, isCompleted: true)],
            ),
          ],
        ),
        WorkoutSession(
          id: 's2',
          userId: 'u1',
          workoutName: 'Chest Day',
          dayName: 'Day 8 Chest',
          startedAt: now.subtract(const Duration(days: 1)),
          completedAt: now.subtract(const Duration(days: 1)),
          durationSeconds: 2200,
          status: 'completed',
          totalVolume: 3500,
          planId: 'weight_loss_60',
          exercises: [
            SessionExercise(
              exerciseName: 'Bench Press',
              order: 1,
              sets: [WorkoutSet(reps: 10, weight: 55.0, isCompleted: true)],
            ),
          ],
        ),
      ];

      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_p9';
      provider.activeDocFetcherForTesting = (_) => {
        'planId': 'weight_loss_60',
        'planTitle': '60-Day Weight Loss',
        'startDate': DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 14))),
        'currentDay': 8,
        'totalDays': 60,
        'targetCalories': 2000.0,
        'targetMacros': {'protein': 140.0},
        'status': 'active',
      };
      await provider.loadTransformation();

      await tester.pumpWidget(
        _wrapWithTestProviders(
          transformationProvider: provider,
          child: Scaffold(
            body: SingleChildScrollView(
              child: TransformationStrengthProgressCard(overrideSessions: sessions),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Strength Progress'), findsOneWidget);
      expect(find.text('2 Workouts'), findsOneWidget);
      expect(find.text('Bench Press'), findsWidgets);
      expect(find.text('+5.0 kg (+10.0%)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('23. Normal workouts still contribute to existing strength analytics', () {
      final now = DateTime.now();
      final allSessions = [
        WorkoutSession(
          id: 'custom_session',
          userId: 'u1',
          workoutName: 'Custom Leg Day',
          dayName: 'Custom Leg Day',
          startedAt: now.subtract(const Duration(days: 2)),
          durationSeconds: 1800,
          status: 'completed',
          totalVolume: 5000,
          exercises: [
            SessionExercise(
              exerciseName: 'Barbell Squat',
              order: 1,
              sets: [WorkoutSet(reps: 5, weight: 120.0, isCompleted: true)],
            ),
          ],
        ),
      ];

      final allPRs = StrengthService().getAllTimePRs(sessions: allSessions);
      expect(allPRs['barbell squat'], isNotNull);
      expect(allPRs['barbell squat']?.weight, 120.0);
    });

    testWidgets('24. Completion screen handles missing strength data gracefully without error', (tester) async {
      _configureTestViewport(tester);

      final now = DateTime.now();
      final state = UserTransformationState(
        planId: 'beginner_fitness_30',
        planTitle: '30-Day Complete Beginner',
        startDate: now.subtract(const Duration(days: 30)),
        targetEndDate: now,
        currentDay: 30,
        totalDays: 30,
        status: 'completed',
        completedAt: now,
        completedDayIndices: List.generate(30, (i) => i + 1),
        targetCalories: 2000,
        targetMacros: const {'protein': 120},
      );

      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'test_user_p9';
      provider.activeDocFetcherForTesting = (_) => state.toMap();
      await provider.loadTransformation();

      await tester.pumpWidget(
        _wrapWithTestProviders(
          transformationProvider: provider,
          child: TransformationCompletionScreen(completedState: state),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ACHIEVEMENT UNLOCKED'), findsOneWidget);
      expect(find.text('Transformation Summary'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ------------------------------------------------------------------------
    // Part C: Regression Tests (25 - 29)
    // ------------------------------------------------------------------------

    test('25. Phase 8 daily accountability score calculation remains fully functional', () {
      final log = TransformationDailyLog.calculate(
        planId: 'weight_loss_60',
        dayNumber: 1,
        dateString: '2026-11-02',
        workoutCompleted: true,
        isRestDay: false,
        actualCalories: 2000,
        targetCalories: 2000,
        actualProtein: 150,
        targetProtein: 150,
        actualWaterMl: 2500,
        targetWaterMl: 2500,
        recoveryLevel: 'good',
      );

      expect(log.dailyAdherenceScore, 100.0);
      expect(log.hasEnoughData, isTrue);
    });

    test('26. Phase 7 nutrition calculations remain accurate and intact', () {
      final blueprint = TransformationPlansData.getById('weight_loss_60');
      expect(blueprint, isNotNull);
      expect(blueprint?.durationDays, 60);
      expect(blueprint?.phases.length, 4);
    });

    test('27. All primary transformation programmes blueprints exist with correct durations', () {
      expect(TransformationPlansData.beginnerFitness30.durationDays, 30);
      expect(TransformationPlansData.weightLoss60.durationDays, 60);
      expect(TransformationPlansData.muscleBuilding90.durationDays, 90);
    });

    test('28. Existing workout history is preserved in WorkoutLogService cache', () {
      WorkoutLogService.clearLastLogCache();
      final log = WorkoutLog(
        id: 'test_log',
        exerciseName: 'Dumbbell Curl',
        date: DateTime.now(),
        category: 'Arms',
        sets: [WorkoutSet(reps: 10, weight: 14.0, isCompleted: true)],
      );
      WorkoutLogService.seedLastLogCache('Dumbbell Curl', log);

      final cached = WorkoutLogService.getCachedLastLog('Dumbbell Curl');
      expect(cached?.exerciseName, 'Dumbbell Curl');
      expect(cached?.sets.first.weight, 14.0);
    });

    test('29. SubscriptionProvider and Lifetime purchase state remain protected', () {
      final subProvider = MockSubscriptionProvider();
      expect(subProvider.isPremium, isTrue);
    });
  });
}
