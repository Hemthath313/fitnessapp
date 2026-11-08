import 'package:fitness_app/model/personal_record_model.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/services/strength_service.dart';

/// Pure helpers for the post-workout reward screen.
class SessionRewards {
  SessionRewards._();

  /// New personal records set in [session], excluding exercises the user had
  /// never logged before (a first log is not a "record" worth celebrating, and
  /// would flag every exercise on a new user's first workout).
  ///
  /// One entry per exercise, the strongest set first.
  static List<PersonalRecord> meaningfulPRs({
    required WorkoutSession session,
    required List<WorkoutSession> allSessions,
    StrengthService? strength,
  }) {
    final service = strength ?? StrengthService();

    final prior = allSessions
        .where((s) =>
            s.id != session.id && s.startedAt.isBefore(session.startedAt))
        .toList();

    final priorKeys = <String>{};
    for (final s in prior) {
      for (final ex in s.exercises) {
        final hadWeightedSet = ex.sets.any((set) =>
            set.isCompleted && set.type != SetType.warmup && set.weight > 0);
        if (hadWeightedSet) {
          priorKeys.add(ExerciseIdentity.canonicalKey(ex.exerciseName));
        }
      }
    }
    if (priorKeys.isEmpty) return const [];

    final detected = service.detectPRsInSession(
      session: session,
      allSessions: allSessions,
    );

    final best = <String, PersonalRecord>{};
    for (final pr in detected) {
      final key = ExerciseIdentity.canonicalKey(pr.exerciseName);
      if (!priorKeys.contains(key)) continue;
      final existing = best[key];
      if (existing == null || pr.estimated1RM > existing.estimated1RM) {
        best[key] = pr;
      }
    }

    final result = best.values.toList()
      ..sort((a, b) => b.estimated1RM.compareTo(a.estimated1RM));
    return result;
  }

  /// "Day 5 streak" / "Streak extended to 5" wording for the reward screen.
  static String streakCaption({
    required int before,
    required int after,
  }) {
    if (after <= 0) return 'Your streak starts with the next workout';
    if (after > before) {
      return before == 0 && after == 1
          ? 'Streak started. Day 1 is done'
          : 'Streak extended to $after days';
    }
    return 'Already counted today. Come back tomorrow to keep it going';
  }
}
