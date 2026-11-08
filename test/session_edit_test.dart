import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/services/session_edit.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSet _s(double w, int r, {bool done = true, SetType t = SetType.normal}) =>
    WorkoutSet(weight: w, reps: r, type: t, isCompleted: done);

WorkoutSession _session() {
  final exercises = [
    SessionExercise(
      exerciseName: 'Bench Press',
      order: 0,
      sets: [_s(60, 8), _s(60, 8), _s(60, 6, done: false)],
    ),
    SessionExercise(
      exerciseName: 'Row',
      order: 1,
      sets: [_s(40, 10)],
    ),
  ];
  return WorkoutSession(
    id: 's1',
    userId: 'u',
    workoutName: 'Push',
    dayName: 'Monday',
    startedAt: DateTime(2026, 11, 5, 18),
    completedAt: DateTime(2026, 11, 5, 19),
    durationSeconds: 3600,
    totalVolume: SessionEdit.volumeOf(exercises),
    exercises: exercises,
    planId: 'p',
    planDay: 2,
  );
}

void main() {
  test('volume counts completed sets only', () {
    // 60*8 + 60*8 + 40*10 = 1360 (the unchecked set is ignored)
    expect(_session().totalVolume, 1360);
  });

  test('updateSet changes weight and reps and recomputes volume', () {
    final edited = SessionEdit.updateSet(
      _session(),
      exerciseIndex: 0,
      setIndex: 1,
      weight: 62.5,
      reps: 7,
    );
    final set = edited.exercises[0].sets[1];
    expect(set.weight, 62.5);
    expect(set.reps, 7);
    expect(set.isCompleted, isTrue);
    expect(edited.totalVolume, 60 * 8 + 62.5 * 7 + 40 * 10);
    // identity fields are preserved
    expect(edited.id, 's1');
    expect(edited.planId, 'p');
    expect(edited.planDay, 2);
    expect(edited.durationSeconds, 3600);
  });

  test('updateSet keeps the set type and ignores bad indexes', () {
    final base = _session();
    expect(
      SessionEdit.updateSet(base, exerciseIndex: 9, setIndex: 0, weight: 1, reps: 1),
      same(base),
    );
    expect(
      SessionEdit.updateSet(base, exerciseIndex: 0, setIndex: 9, weight: 1, reps: 1),
      same(base),
    );
  });

  test('removeSet drops the set and the exercise when it was the last one', () {
    final one = SessionEdit.removeSet(_session(), exerciseIndex: 0, setIndex: 0);
    expect(one.exercises[0].sets.length, 2);
    expect(one.totalVolume, 60 * 8 + 40 * 10);

    final gone = SessionEdit.removeSet(_session(), exerciseIndex: 1, setIndex: 0);
    expect(gone.exercises.map((e) => e.exerciseName), ['Bench Press']);
    expect(gone.totalVolume, 960);
  });

  test('loggedSets returns completed sets only', () {
    expect(SessionEdit.loggedSets(_session().exercises[0]).length, 2);
  });
}
