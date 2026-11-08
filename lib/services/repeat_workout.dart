import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';

/// Pure helpers for "repeat this workout" (no Flutter, no providers).
class RepeatWorkout {
  const RepeatWorkout._();

  static const int defaultSets = 3;
  static const int defaultReps = 8;

  /// Converts a finished [session] into the list of exercise maps that the
  /// guided session accepts (`name`, `setNumber`, `repNumber`). Weights are
  /// not copied: the session prefills them from the user's last logs, so a
  /// repeat starts from the latest numbers, not the old ones.
  static List<Map<String, dynamic>> exercisesFor(WorkoutSession session) {
    final sorted = [...session.exercises]
      ..sort((a, b) => a.order.compareTo(b.order));
    final result = <Map<String, dynamic>>[];
    for (final ex in sorted) {
      final name = ex.exerciseName.trim();
      if (name.isEmpty) continue;
      final working =
          ex.sets.where((s) => s.type != SetType.warmup).toList(growable: false);
      final sets = working.isNotEmpty ? working : ex.sets;
      result.add({
        'name': name,
        'setNumber': sets.isEmpty ? defaultSets : sets.length,
        'repNumber': _commonReps(sets),
      });
    }
    return result;
  }

  /// Most frequent rep count among [sets] (ties: the first one seen).
  static int _commonReps(List<WorkoutSet> sets) {
    final counts = <int, int>{};
    final order = <int>[];
    for (final s in sets) {
      if (s.reps <= 0) continue;
      if (!counts.containsKey(s.reps)) order.add(s.reps);
      counts[s.reps] = (counts[s.reps] ?? 0) + 1;
    }
    if (order.isEmpty) return defaultReps;
    var best = order.first;
    for (final r in order) {
      if (counts[r]! > counts[best]!) best = r;
    }
    return best;
  }

  static DateTime dateOf(WorkoutSession s) => s.completedAt ?? s.startedAt;

  /// The most recent session that has something to repeat.
  static WorkoutSession? latest(Iterable<WorkoutSession> sessions) {
    WorkoutSession? best;
    for (final s in sessions) {
      if (exercisesFor(s).isEmpty) continue;
      if (best == null || dateOf(s).isAfter(dateOf(best))) best = s;
    }
    return best;
  }

  static String titleOf(WorkoutSession s) =>
      s.workoutName.isNotEmpty ? s.workoutName : s.dayName;

  /// "today", "yesterday", "3 days ago", "2 weeks ago", "3 months ago".
  static String whenLabel(DateTime when, DateTime now) {
    final a = DateTime(when.year, when.month, when.day);
    final b = DateTime(now.year, now.month, now.day);
    final days = b.difference(a).inDays;
    if (days <= 0) return 'today';
    if (days == 1) return 'yesterday';
    if (days < 7) return '$days days ago';
    if (days < 60) {
      final weeks = days ~/ 7;
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }
    return '${days ~/ 30} months ago';
  }
}
