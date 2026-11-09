import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';

/// Pure helpers for correcting a finished session (no Flutter, no Firestore).
class SessionEdit {
  const SessionEdit._();

  /// Total volume the way the guided session computes it: completed sets only,
  /// weight × reps, with warm-up sets left out.
  static double volumeOf(Iterable<SessionExercise> exercises) {
    var vol = 0.0;
    for (final ex in exercises) {
      for (final s in ex.sets) {
        if (s.isCompleted && s.type != SetType.warmup) vol += s.weight * s.reps;
      }
    }
    return vol;
  }

  static WorkoutSession _rebuild(
    WorkoutSession s,
    List<SessionExercise> exercises,
  ) {
    return WorkoutSession(
      id: s.id,
      userId: s.userId,
      workoutName: s.workoutName,
      dayName: s.dayName,
      startedAt: s.startedAt,
      completedAt: s.completedAt,
      durationSeconds: s.durationSeconds,
      status: s.status,
      totalVolume: volumeOf(exercises),
      exercises: exercises,
      planId: s.planId,
      planDay: s.planDay,
    );
  }

  /// Replaces the weight and reps of one set, keeping its type and
  /// completion flag. Out-of-range indexes return [session] unchanged.
  static WorkoutSession updateSet(
    WorkoutSession session, {
    required int exerciseIndex,
    required int setIndex,
    required double weight,
    required int reps,
  }) {
    if (exerciseIndex < 0 || exerciseIndex >= session.exercises.length) {
      return session;
    }
    final ex = session.exercises[exerciseIndex];
    if (setIndex < 0 || setIndex >= ex.sets.length) return session;

    final old = ex.sets[setIndex];
    final sets = [...ex.sets];
    sets[setIndex] = WorkoutSet(
      weight: weight < 0 ? 0 : weight,
      reps: reps < 0 ? 0 : reps,
      type: old.type,
      rpe: old.rpe,
      isCompleted: old.isCompleted,
    );
    final exercises = [...session.exercises];
    exercises[exerciseIndex] = ex.copyWith(sets: sets);
    return _rebuild(session, exercises);
  }

  /// Removes one set. An exercise left without sets is removed as well, so
  /// the result can have no exercises at all (callers decide what to do then).
  static WorkoutSession removeSet(
    WorkoutSession session, {
    required int exerciseIndex,
    required int setIndex,
  }) {
    if (exerciseIndex < 0 || exerciseIndex >= session.exercises.length) {
      return session;
    }
    final ex = session.exercises[exerciseIndex];
    if (setIndex < 0 || setIndex >= ex.sets.length) return session;

    final sets = [...ex.sets]..removeAt(setIndex);
    final exercises = [...session.exercises];
    if (sets.isEmpty) {
      exercises.removeAt(exerciseIndex);
    } else {
      exercises[exerciseIndex] = ex.copyWith(sets: sets);
    }
    return _rebuild(session, exercises);
  }

  /// The completed sets of [exercise], which is what gets mirrored into the
  /// per-exercise workout log when the session is saved.
  static List<WorkoutSet> loggedSets(SessionExercise exercise) =>
      exercise.sets.where((s) => s.isCompleted).toList();
}
