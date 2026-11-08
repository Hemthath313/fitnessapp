import 'package:fitness_app/model/personal_record_model.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/auth/pages/plan_ready_screen.dart';
import 'package:fitness_app/presentation/custom_workouts/widgets/workout_reward_view.dart';
import 'package:fitness_app/presentation/home/widgets/achievements_widget.dart';
import 'package:fitness_app/presentation/home/widgets/next_badge_card.dart';
import 'package:fitness_app/presentation/widgets/reminder_opt_in_card.dart';
import 'package:fitness_app/services/session_reward_service.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(home: child),
    );

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

WorkoutSession _session({
  required String id,
  required DateTime startedAt,
  required List<SessionExercise> exercises,
  String status = 'completed',
}) =>
    WorkoutSession(
      id: id,
      userId: 'u',
      workoutName: 'Push Routine',
      dayName: 'Monday',
      startedAt: startedAt,
      completedAt: startedAt.add(const Duration(minutes: 45)),
      durationSeconds: 2700,
      status: status,
      totalVolume: 4200,
      exercises: exercises,
    );

SessionExercise _ex(String name, double kg, int reps,
        {SetType type = SetType.normal}) =>
    SessionExercise(
      exerciseName: name,
      order: 0,
      sets: [WorkoutSet(weight: kg, reps: reps, type: type, isCompleted: true)],
      isCompleted: true,
    );

void main() {
  group('SessionRewards', () {
    final day1 = DateTime(2026, 11, 2, 18);
    final day2 = DateTime(2026, 11, 4, 18);

    test('first ever workout reports no PRs (nothing to beat)', () {
      final s = _session(id: 'a', startedAt: day1, exercises: [_ex('Bench Press', 60, 8)]);
      expect(SessionRewards.meaningfulPRs(session: s, allSessions: [s]), isEmpty);
    });

    test('beating a previous best on a known exercise is a PR', () {
      final first = _session(id: 'a', startedAt: day1, exercises: [_ex('Bench Press', 60, 8)]);
      final second = _session(id: 'b', startedAt: day2, exercises: [_ex('Bench Press', 70, 8)]);
      final prs = SessionRewards.meaningfulPRs(
          session: second, allSessions: [first, second]);
      expect(prs, hasLength(1));
      expect(prs.single.exerciseName, 'Bench Press');
      expect(prs.single.weight, 70);
    });

    test('a brand-new exercise is not reported as a PR', () {
      final first = _session(id: 'a', startedAt: day1, exercises: [_ex('Bench Press', 60, 8)]);
      final second = _session(id: 'b', startedAt: day2, exercises: [
        _ex('Bench Press', 55, 8),
        _ex('Overhead Press', 40, 8),
      ]);
      final prs = SessionRewards.meaningfulPRs(
          session: second, allSessions: [first, second]);
      expect(prs, isEmpty);
    });

    test('warm-up sets never count as records', () {
      final first = _session(id: 'a', startedAt: day1, exercises: [_ex('Squat', 80, 5)]);
      final second = _session(id: 'b', startedAt: day2, exercises: [
        _ex('Squat', 120, 5, type: SetType.warmup),
      ]);
      expect(
        SessionRewards.meaningfulPRs(session: second, allSessions: [first, second]),
        isEmpty,
      );
    });

    test('streakCaption wording', () {
      expect(SessionRewards.streakCaption(before: 0, after: 1),
          'Streak started. Day 1 is done');
      expect(SessionRewards.streakCaption(before: 4, after: 5),
          'Streak extended to 5 days');
      expect(SessionRewards.streakCaption(before: 5, after: 5),
          startsWith('Already counted today'));
      expect(SessionRewards.streakCaption(before: 0, after: 0),
          'Your streak starts with the next workout');
    });
  });

  group('WorkoutRewardView', () {
    final session = _session(
      id: 's',
      startedAt: DateTime(2026, 11, 4, 18),
      exercises: [_ex('Bench Press', 70, 8)],
    );

    testWidgets('counts the streak up and shows stats, PR, week and badge',
        (tester) async {
      _viewport(tester);
      var done = false;
      final pr = PersonalRecord(
        exerciseName: 'Bench Press',
        weight: 70,
        reps: 8,
        estimated1RM: 88,
        achievedAt: DateTime(2026, 11, 4),
      );
      await tester.pumpWidget(_wrap(WorkoutRewardView(
        session: session,
        dayName: 'Monday',
        playHaptic: false,
        reminderCard: const SizedBox.shrink(),
        onDone: () => done = true,
        data: WorkoutRewardData(
          streakBefore: 4,
          streakAfter: 5,
          longestStreak: 9,
          newPRs: [pr],
          workoutsThisWeek: 2,
          weeklyTarget: 3,
          nextBadge: nextBadgeProgress(
            unlocked: const ['First Workout'],
            totalWorkouts: 7,
            currentStreak: 5,
          ),
        ),
      )));
      await tester.pump();
      expect(find.byKey(const Key('reward_streak_value')), findsOneWidget);
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.byKey(const Key('reward_streak_value'))).data, '5');
      expect(find.text('Streak extended to 5 days'), findsOneWidget);
      expect(find.text('Workout Complete! 🔥'), findsOneWidget);
      expect(find.text('4200 kg'), findsOneWidget);
      expect(find.byKey(const Key('reward_pr_card')), findsOneWidget);
      expect(find.text('New personal record!'), findsOneWidget);
      expect(find.textContaining('Bench Press  70 kg × 8'), findsOneWidget);
      expect(find.text('2 of 3 workouts. 1 to go'), findsOneWidget);
      expect(find.byKey(const Key('next_badge_card')), findsOneWidget);

      await tester.tap(find.text('Back to Home'));
      expect(done, isTrue);
    });

    testWidgets('unlocked badge replaces the next-badge bar', (tester) async {
      _viewport(tester);
      final def = allAchievements.first;
      await tester.pumpWidget(_wrap(WorkoutRewardView(
        session: session,
        dayName: 'Monday',
        playHaptic: false,
        reminderCard: const SizedBox.shrink(),
        onDone: () {},
        data: WorkoutRewardData(
          streakBefore: 0,
          streakAfter: 1,
          unlockedBadges: [def],
          nextBadge: nextBadgeProgress(
              unlocked: const [], totalWorkouts: 0, currentStreak: 0),
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('reward_badge_${def.id}')), findsOneWidget);
      expect(find.text('BADGE UNLOCKED'), findsOneWidget);
      expect(find.byKey(const Key('next_badge_card')), findsNothing);
      expect(find.byKey(const Key('reward_pr_card')), findsNothing);
    });

    testWidgets('partial session uses the saved-early wording and Back to Home stays reachable',
        (tester) async {
      _viewport(tester);
      final partial = _session(
        id: 'p',
        startedAt: DateTime(2026, 11, 4, 18),
        exercises: [_ex('Bench Press', 70, 8)],
        status: 'partial',
      );
      await tester.pumpWidget(_wrap(WorkoutRewardView(
        session: partial,
        dayName: 'Monday',
        playHaptic: false,
        reminderCard: const SizedBox.shrink(),
        onDone: () {},
        data: const WorkoutRewardData(streakBefore: 2, streakAfter: 2),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Workout Saved Early!'), findsOneWidget);
      expect(find.textContaining('Already counted today'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ReminderOptInCard', () {
    testWidgets('hidden when not needed', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(_wrap(Scaffold(
        body: ReminderOptInCard(shouldPrompt: () async => false),
      )));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reminder_opt_in_card')), findsNothing);
    });

    testWidgets('ask -> enable passes the chosen time and confirms',
        (tester) async {
      _viewport(tester);
      TimeOfDay? enabledAt;
      await tester.pumpWidget(_wrap(Scaffold(
        body: ReminderOptInCard(
          shouldPrompt: () async => true,
          onEnable: (t) async {
            enabledAt = t;
            return true;
          },
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Never miss a session'), findsOneWidget);

      await tester.tap(find.byKey(const Key('reminder_enable')));
      await tester.pumpAndSettle();
      expect(enabledAt, ReminderOptIn.defaultTime);
      expect(find.byKey(const Key('reminder_opt_in_done')), findsOneWidget);
    });

    testWidgets('permission refused shows a gentle note, no nagging',
        (tester) async {
      _viewport(tester);
      await tester.pumpWidget(_wrap(Scaffold(
        body: ReminderOptInCard(
          shouldPrompt: () async => true,
          onEnable: (_) async => false,
        ),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reminder_enable')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reminder_opt_in_denied')), findsOneWidget);
      expect(find.byKey(const Key('reminder_enable')), findsNothing);
    });

    testWidgets('Not now records the dismissal and hides the card',
        (tester) async {
      _viewport(tester);
      var dismissed = false;
      await tester.pumpWidget(_wrap(Scaffold(
        body: ReminderOptInCard(
          shouldPrompt: () async => true,
          onDismiss: () async => dismissed = true,
        ),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reminder_not_now')));
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
      expect(find.byKey(const Key('reminder_opt_in_card')), findsNothing);
    });
  });

  group('PlanReadyScreen', () {
    Widget screen(PlanReadyArgs args, {VoidCallback? build, VoidCallback? skip}) =>
        _wrap(PlanReadyScreen(
          args: args,
          reminderCard: const SizedBox.shrink(),
          onBuildWorkout: build ?? () {},
          onSkip: skip ?? () {},
        ));

    testWidgets('shows the personal calorie target and goal copy',
        (tester) async {
      _viewport(tester);
      await tester.pumpWidget(screen(const PlanReadyArgs(
          name: 'Alice', goal: StringsManager.lose, calories: 1987.4)));
      await tester.pumpAndSettle();
      expect(find.text('Welcome, Alice'), findsOneWidget);
      expect(find.text('Your plan is ready'), findsOneWidget);
      expect(find.text('1,987'), findsOneWidget);
      expect(find.text('20% below your maintenance calories'), findsOneWidget);
      expect(find.text('Lose weight'), findsOneWidget);
      expect(find.text('Build my first workout'), findsOneWidget);
    });

    testWidgets('gain and maintain goals use their own explanation',
        (tester) async {
      _viewport(tester);
      await tester.pumpWidget(screen(const PlanReadyArgs(
          name: '', goal: StringsManager.gain, calories: 3100)));
      await tester.pumpAndSettle();
      expect(find.text('Welcome!'), findsOneWidget);
      expect(find.text('20% above your maintenance calories'), findsOneWidget);

      await tester.pumpWidget(screen(const PlanReadyArgs(
          name: 'Sam', goal: StringsManager.maintain, calories: 2400)));
      await tester.pumpAndSettle();
      expect(find.text('Matches your maintenance calories'), findsOneWidget);
    });

    testWidgets('both actions fire their callbacks', (tester) async {
      _viewport(tester);
      var built = 0;
      var skipped = 0;
      await tester.pumpWidget(screen(
        const PlanReadyArgs(name: 'A', goal: StringsManager.lose, calories: 2000),
        build: () => built++,
        skip: () => skipped++,
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('plan_ready_build_workout')));
      await tester.tap(find.byKey(const Key('plan_ready_skip')));
      expect(built, 1);
      expect(skipped, 1);
    });
  });
}
