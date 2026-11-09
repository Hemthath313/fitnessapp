import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/custom_workouts/widgets/workout_reward_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(home: child),
    );

WorkoutSession _session() => WorkoutSession(
      id: 's1',
      userId: 'u',
      workoutName: 'Monday Routine',
      dayName: 'Monday',
      startedAt: DateTime(2026, 11, 2, 18),
      completedAt: DateTime(2026, 11, 2, 18, 45),
      durationSeconds: 2700,
      totalVolume: 1000,
      exercises: [
        SessionExercise(
          exerciseName: 'Bench Press',
          order: 0,
          sets: [WorkoutSet(weight: 60, reps: 8, isCompleted: true)],
          isCompleted: true,
        ),
      ],
    );

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('the button says Done and calls onDone', (tester) async {
    _viewport(tester);
    var done = false;
    await tester.pumpWidget(_wrap(WorkoutRewardView(
      session: _session(),
      dayName: 'Monday',
      playHaptic: false,
      reminderCard: const SizedBox.shrink(),
      onDone: () => done = true,
      data: const WorkoutRewardData(streakBefore: 1, streakAfter: 2),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Back to Home'), findsNothing);
    await tester.tap(find.byKey(const Key('reward_done_button')));
    expect(done, isTrue);
  });

  testWidgets('View session link only shows when a handler is given',
      (tester) async {
    _viewport(tester);
    var opened = false;
    await tester.pumpWidget(_wrap(WorkoutRewardView(
      session: _session(),
      dayName: 'Monday',
      playHaptic: false,
      reminderCard: const SizedBox.shrink(),
      onDone: () {},
      onViewSession: () => opened = true,
      data: const WorkoutRewardData(streakBefore: 1, streakAfter: 2),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reward_view_session')));
    expect(opened, isTrue);

    await tester.pumpWidget(_wrap(WorkoutRewardView(
      session: _session(),
      dayName: 'Monday',
      playHaptic: false,
      reminderCard: const SizedBox.shrink(),
      onDone: () {},
      data: const WorkoutRewardData(streakBefore: 1, streakAfter: 2),
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reward_view_session')), findsNothing);
  });

  testWidgets('weekly card shows a Next up line when the plan has one',
      (tester) async {
    _viewport(tester);
    await tester.pumpWidget(_wrap(WorkoutRewardView(
      session: _session(),
      dayName: 'Monday',
      playHaptic: false,
      reminderCard: const SizedBox.shrink(),
      onDone: () {},
      data: const WorkoutRewardData(
        streakBefore: 1,
        streakAfter: 2,
        workoutsThisWeek: 1,
        weeklyTarget: 3,
        nextUp: 'Wednesday · 5 exercises',
      ),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Next up: Wednesday · 5 exercises'), findsOneWidget);

    await tester.pumpWidget(_wrap(WorkoutRewardView(
      session: _session(),
      dayName: 'Monday',
      playHaptic: false,
      reminderCard: const SizedBox.shrink(),
      onDone: () {},
      data: const WorkoutRewardData(streakBefore: 1, streakAfter: 2),
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reward_next_up')), findsNothing);
  });
}
