import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/workout_logs/widgets/repeat_workout_widgets.dart';
import 'package:fitness_app/services/repeat_workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSet _set(int reps, {SetType type = SetType.normal}) =>
    WorkoutSet(weight: 50, reps: reps, type: type, isCompleted: true);

SessionExercise _ex(String name, int order, List<WorkoutSet> sets) =>
    SessionExercise(exerciseName: name, order: order, sets: sets);

WorkoutSession _session({
  String id = 's1',
  String workoutName = 'Push Day',
  String dayName = 'Monday',
  DateTime? at,
  List<SessionExercise>? exercises,
}) {
  final when = at ?? DateTime(2026, 11, 5, 18);
  return WorkoutSession(
    id: id,
    userId: 'u',
    workoutName: workoutName,
    dayName: dayName,
    startedAt: when,
    completedAt: when,
    totalVolume: 1000,
    exercises: exercises ??
        [
          _ex('Bench Press', 0, [_set(8), _set(8), _set(10)]),
        ],
  );
}

void main() {
  group('RepeatWorkout.exercisesFor', () {
    test('sorts by order and counts working sets only', () {
      final s = _session(exercises: [
        _ex('Squat', 1, [_set(5), _set(5), _set(5), _set(5)]),
        _ex('Bench Press', 0,
            [_set(12, type: SetType.warmup), _set(8), _set(8), _set(6)]),
      ]);
      final result = RepeatWorkout.exercisesFor(s);
      expect(result.map((e) => e['name']), ['Bench Press', 'Squat']);
      expect(result[0]['setNumber'], 3);
      expect(result[0]['repNumber'], 8);
      expect(result[1]['setNumber'], 4);
      expect(result[1]['repNumber'], 5);
    });

    test('falls back to defaults when there are no sets', () {
      final s = _session(exercises: [_ex('Plank', 0, [])]);
      final r = RepeatWorkout.exercisesFor(s).single;
      expect(r['setNumber'], RepeatWorkout.defaultSets);
      expect(r['repNumber'], RepeatWorkout.defaultReps);
    });

    test('skips empty names', () {
      final s = _session(exercises: [
        _ex('  ', 0, [_set(8)]),
        _ex('Row', 1, [_set(10)]),
      ]);
      expect(RepeatWorkout.exercisesFor(s).map((e) => e['name']), ['Row']);
    });
  });

  group('RepeatWorkout.latest', () {
    test('returns the newest session that has exercises', () {
      final older = _session(id: 'a', at: DateTime(2026, 11, 1));
      final newer = _session(id: 'b', at: DateTime(2026, 11, 4));
      final empty = _session(id: 'c', at: DateTime(2026, 11, 7), exercises: []);
      expect(RepeatWorkout.latest([older, empty, newer])?.id, 'b');
    });

    test('returns null when nothing can be repeated', () {
      expect(RepeatWorkout.latest([]), isNull);
      expect(RepeatWorkout.latest([_session(exercises: [])]), isNull);
    });
  });

  group('RepeatWorkout.whenLabel', () {
    final now = DateTime(2026, 11, 8, 10);
    test('labels', () {
      expect(RepeatWorkout.whenLabel(DateTime(2026, 11, 8, 6), now), 'today');
      expect(RepeatWorkout.whenLabel(DateTime(2026, 11, 7, 23), now), 'yesterday');
      expect(RepeatWorkout.whenLabel(DateTime(2026, 11, 5), now), '3 days ago');
      expect(RepeatWorkout.whenLabel(DateTime(2026, 11, 1), now), '1 week ago');
      expect(RepeatWorkout.whenLabel(DateTime(2026, 10, 18), now), '3 weeks ago');
      expect(RepeatWorkout.whenLabel(DateTime(2026, 7, 1), now), '4 months ago');
    });
  });

  group('LastWorkoutStrip', () {
    Future<void> pump(WidgetTester tester, List<WorkoutSession> sessions) {
      return tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(430, 810),
          builder: (_, __) => MaterialApp(
            home: Scaffold(
              body: LastWorkoutStrip(
                sessions: sessions,
                now: DateTime(2026, 11, 8, 10),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows title, age and a repeat button', (tester) async {
      await pump(tester, [_session()]);
      expect(find.byKey(const Key('last_workout_strip')), findsOneWidget);
      expect(find.text('Push Day'), findsOneWidget);
      expect(find.textContaining('3 days ago'), findsOneWidget);
      expect(find.byKey(const Key('repeat_workout_button')), findsOneWidget);
    });

    testWidgets('renders nothing without sessions', (tester) async {
      await pump(tester, []);
      expect(find.byKey(const Key('last_workout_strip')), findsNothing);
    });
  });
}
