import 'package:fitness_app/utils/units.dart';
import 'package:fitness_app/model/personal_record_model.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';

/// Helper for robust canonical exercise name cleaning and normalization
class ExerciseIdentity {
  /// Cleans brackets, prefixes, and extraneous whitespaces for display.
  /// Handles prefixes like '[Monday]', '[Day 1]', '[Push]', '[Chest & Back]', etc.
  static String cleanDisplayName(String rawName) {
    if (rawName.isEmpty) return 'Exercise';
    var cleaned = rawName.replaceAll(RegExp(r'^\[[^\]]+\]\s*'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    return cleaned.isNotEmpty ? cleaned : rawName.trim();
  }

  /// Canonical lowercase key for hash maps, comparisons, and groupings
  static String canonicalKey(String rawName) {
    return cleanDisplayName(rawName).toLowerCase();
  }
}

/// Status classification for deterministic adaptive strength insights
enum StrengthStatus {
  newPR,
  improving,
  stable,
  stalled,
}

class ExerciseInsight {
  final String exerciseName;
  final StrengthStatus status;
  final String message;
  final double latestWeight;
  final double latestEstimated1RM;
  final double change; // weight difference compared to prior session

  const ExerciseInsight({
    required this.exerciseName,
    required this.status,
    required this.message,
    required this.latestWeight,
    required this.latestEstimated1RM,
    required this.change,
  });
}

class StrengthService {
  // Singleton pattern for easy shared use across widgets
  static final StrengthService _instance = StrengthService._internal();
  factory StrengthService() => _instance;
  StrengthService._internal();

  /// Calculates Estimated 1RM using the Epley formula:
  /// Estimated 1RM = Weight * (1 + Reps / 30)
  ///
  /// Product Guardrails:
  /// - Reps must be between 1 and 12 (beyond 12, linear 1RM formulas become inaccurate)
  /// - Weight must be strictly greater than 0
  /// - Set must be completed
  /// - Warmup sets are strictly excluded
  static double calculateEstimated1RM(WorkoutSet set) {
    if (!set.isCompleted) return 0.0;
    if (set.type == SetType.warmup) return 0.0;
    if (set.weight <= 0) return 0.0;
    if (set.reps <= 0) return 0.0;

    // 1-rep test is exactly the weight lifted
    if (set.reps == 1) return set.weight;

    // Linear formula is valid for reps 2 through 12
    if (set.reps > 12) {
      // Conservative cap: calculate 1RM as if 12 reps to prevent distorted values on 20+ rep sets
      return set.weight * (1.0 + 12.0 / 30.0);
    }

    return set.weight * (1.0 + set.reps / 30.0);
  }

  /// Convenience 1RM calculator from raw numbers (respecting the same guardrails)
  static double calculateEstimated1RMFromValues({
    required double weight,
    required int reps,
    bool isWarmup = false,
  }) {
    if (isWarmup || weight <= 0 || reps <= 0) return 0.0;
    if (reps == 1) return weight;
    final effectiveReps = reps > 12 ? 12 : reps;
    return weight * (1.0 + effectiveReps / 30.0);
  }

  /// Extracts all-time Personal Records across a user's canonical WorkoutSessions.
  /// Optionally considers legacy WorkoutLogs if provided.
  Map<String, PersonalRecord> getAllTimePRs({
    required List<WorkoutSession> sessions,
    List<WorkoutLog>? legacyLogs,
  }) {
    final Map<String, PersonalRecord> prMap = {};

    // 1. Process canonical sessions (sorted chronologically)
    final sortedSessions = List<WorkoutSession>.from(sessions)
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

    for (final session in sortedSessions) {
      for (final ex in session.exercises) {
        final key = ExerciseIdentity.canonicalKey(ex.exerciseName);
        final displayName = ExerciseIdentity.cleanDisplayName(ex.exerciseName);

        for (final set in ex.sets) {
          if (!set.isCompleted || set.type == SetType.warmup || set.weight <= 0) {
            continue;
          }

          final est1RM = calculateEstimated1RM(set);
          final existing = prMap[key];

          if (existing == null || est1RM > existing.estimated1RM || (est1RM == existing.estimated1RM && set.weight > existing.weight)) {
            prMap[key] = PersonalRecord(
              exerciseName: displayName,
              weight: set.weight,
              reps: set.reps,
              estimated1RM: est1RM,
              achievedAt: session.completedAt ?? session.startedAt,
              type: PRType.estimated1RM,
              sessionId: session.id,
            );
          }
        }
      }
    }

    // 2. Fallback / supplementary check for legacy logs if sessions don't have this exercise
    if (legacyLogs != null && legacyLogs.isNotEmpty) {
      final sortedLegacy = List<WorkoutLog>.from(legacyLogs)
        ..sort((a, b) => a.date.compareTo(b.date));

      for (final log in sortedLegacy) {
        final key = ExerciseIdentity.canonicalKey(log.exerciseName);
        final displayName = ExerciseIdentity.cleanDisplayName(log.exerciseName);

        for (final set in log.sets) {
          if (!set.isCompleted || set.type == SetType.warmup || set.weight <= 0) {
            continue;
          }

          final est1RM = calculateEstimated1RM(set);
          final existing = prMap[key];

          if (existing == null || est1RM > existing.estimated1RM) {
            prMap[key] = PersonalRecord(
              exerciseName: displayName,
              weight: set.weight,
              reps: set.reps,
              estimated1RM: est1RM,
              achievedAt: log.date,
              type: PRType.estimated1RM,
              sessionId: null, // Legacy log has no session ID
            );
          }
        }
      }
    }

    return prMap;
  }

  /// Detects whether any new PRs were set in a specific session
  List<PersonalRecord> detectPRsInSession({
    required WorkoutSession session,
    required List<WorkoutSession> allSessions,
    List<WorkoutLog>? legacyLogs,
  }) {
    // Determine prior sessions before this session's timestamp
    final priorSessions = allSessions.where((s) => s.id != session.id && s.startedAt.isBefore(session.startedAt)).toList();
    final priorPRs = getAllTimePRs(sessions: priorSessions, legacyLogs: legacyLogs);

    final List<PersonalRecord> newPRs = [];

    for (final ex in session.exercises) {
      final key = ExerciseIdentity.canonicalKey(ex.exerciseName);
      final displayName = ExerciseIdentity.cleanDisplayName(ex.exerciseName);
      final priorPR = priorPRs[key];

      for (final set in ex.sets) {
        if (!set.isCompleted || set.type == SetType.warmup || set.weight <= 0) {
          continue;
        }

        final est1RM = calculateEstimated1RM(set);
        final isNew1RM = priorPR == null || est1RM > priorPR.estimated1RM;
        final isNewWeight = priorPR == null || (set.weight > priorPR.weight && set.reps >= 1);

        if (isNew1RM || isNewWeight) {
          newPRs.add(PersonalRecord(
            exerciseName: displayName,
            weight: set.weight,
            reps: set.reps,
            estimated1RM: est1RM,
            achievedAt: session.completedAt ?? session.startedAt,
            type: isNew1RM ? PRType.estimated1RM : PRType.heaviestWeight,
            sessionId: session.id,
          ));
          // Update local benchmark so multiple sets of same exercise in one session only report best
          priorPRs[key] = PersonalRecord(
            exerciseName: displayName,
            weight: set.weight,
            reps: set.reps,
            estimated1RM: est1RM,
            achievedAt: session.completedAt ?? session.startedAt,
            type: PRType.estimated1RM,
            sessionId: session.id,
          );
        }
      }
    }

    return newPRs;
  }

  /// Deterministic Rule-Based Adaptive Insights for an exercise.
  /// Analyzes progression trend without requiring any external AI or network calls.
  List<ExerciseInsight> generateInsights({
    required List<WorkoutSession> sessions,
    List<WorkoutLog>? legacyLogs,
  }) {
    final Map<String, List<_HistoryPoint>> exerciseHistory = {};

    // Group history points chronologically
    for (final s in sessions) {
      for (final ex in s.exercises) {
        final key = ExerciseIdentity.canonicalKey(ex.exerciseName);
        final completedSets = ex.sets.where((st) => st.isCompleted && st.type != SetType.warmup && st.weight > 0).toList();
        if (completedSets.isEmpty) continue;

        double maxWeight = 0;
        double max1RM = 0;
        for (final st in completedSets) {
          if (st.weight > maxWeight) maxWeight = st.weight;
          final est = calculateEstimated1RM(st);
          if (est > max1RM) max1RM = est;
        }

        exerciseHistory.putIfAbsent(key, () => []).add(_HistoryPoint(
          date: s.completedAt ?? s.startedAt,
          maxWeight: maxWeight,
          estimated1RM: max1RM,
          displayName: ExerciseIdentity.cleanDisplayName(ex.exerciseName),
        ));
      }
    }

    // Include legacy logs if session history is sparse
    if (legacyLogs != null) {
      for (final l in legacyLogs) {
        final key = ExerciseIdentity.canonicalKey(l.exerciseName);
        if (exerciseHistory.containsKey(key) && exerciseHistory[key]!.length >= 2) {
          continue; // Already has modern session points
        }
        final completedSets = l.sets.where((st) => st.isCompleted && st.type != SetType.warmup && st.weight > 0).toList();
        if (completedSets.isEmpty) continue;

        double maxWeight = 0;
        double max1RM = 0;
        for (final st in completedSets) {
          if (st.weight > maxWeight) maxWeight = st.weight;
          final est = calculateEstimated1RM(st);
          if (est > max1RM) max1RM = est;
        }

        exerciseHistory.putIfAbsent(key, () => []).add(_HistoryPoint(
          date: l.date,
          maxWeight: maxWeight,
          estimated1RM: max1RM,
          displayName: ExerciseIdentity.cleanDisplayName(l.exerciseName),
        ));
      }
    }

    final List<ExerciseInsight> insights = [];
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    for (final entry in exerciseHistory.entries) {
      final history = entry.value..sort((a, b) => a.date.compareTo(b.date));
      if (history.isEmpty) continue;

      final latest = history.last;
      final displayName = latest.displayName;

      if (history.length == 1) {
        insights.add(ExerciseInsight(
          exerciseName: displayName,
          status: StrengthStatus.stable,
          message: 'Baseline recorded at ${Units.fmt(latest.maxWeight, 1)} ${Units.label}. Keep logging to track progression!',
          latestWeight: latest.maxWeight,
          latestEstimated1RM: latest.estimated1RM,
          change: 0.0,
        ));
        continue;
      }

      final prev = history[history.length - 2];
      final weightDiff = latest.maxWeight - prev.maxWeight;
      final isRecentPR = latest.date.isAfter(sevenDaysAgo) && latest.maxWeight > prev.maxWeight;

      if (isRecentPR) {
        insights.add(ExerciseInsight(
          exerciseName: displayName,
          status: StrengthStatus.newPR,
          message: 'New PR! +${Units.fmt(weightDiff, 1)} ${Units.label} increase over previous session.',
          latestWeight: latest.maxWeight,
          latestEstimated1RM: latest.estimated1RM,
          change: weightDiff,
        ));
      } else if (weightDiff > 0) {
        insights.add(ExerciseInsight(
          exerciseName: displayName,
          status: StrengthStatus.improving,
          message: 'Up +${Units.fmt(weightDiff, 1)} ${Units.label} from previous session (${Units.fmt(prev.maxWeight, 1)} ${Units.label} → ${Units.fmt(latest.maxWeight, 1)} ${Units.label}).',
          latestWeight: latest.maxWeight,
          latestEstimated1RM: latest.estimated1RM,
          change: weightDiff,
        ));
      } else if (weightDiff == 0) {
        // Check if stalled across 3+ sessions or 14+ days
        if (history.length >= 3) {
          final prior2 = history[history.length - 3];
          if (prior2.maxWeight == latest.maxWeight && now.difference(prior2.date).inDays >= 14) {
            insights.add(ExerciseInsight(
              exerciseName: displayName,
              status: StrengthStatus.stalled,
              message: 'Weight unchanged for 2+ weeks. Consider adding 1 rep per set or a slight ${Units.useLb ? '5 lb' : '2.5 kg'} bump.',
              latestWeight: latest.maxWeight,
              latestEstimated1RM: latest.estimated1RM,
              change: 0.0,
            ));
            continue;
          }
        }
        insights.add(ExerciseInsight(
          exerciseName: displayName,
          status: StrengthStatus.stable,
          message: 'Solid baseline maintained at ${Units.fmt(latest.maxWeight, 1)} ${Units.label}. Aim for +1 rep next time.',
          latestWeight: latest.maxWeight,
          latestEstimated1RM: latest.estimated1RM,
          change: 0.0,
        ));
      } else {
        insights.add(ExerciseInsight(
          exerciseName: displayName,
          status: StrengthStatus.stable,
          message: 'Down ${Units.fmt(weightDiff.abs(), 1)} ${Units.label} (likely deload or accessory variation).',
          latestWeight: latest.maxWeight,
          latestEstimated1RM: latest.estimated1RM,
          change: weightDiff,
        ));
      }
    }

    return insights;
  }

  /// Calculates weekly metrics: total volume (kg) and session counts
  WeeklyStrengthMetrics calculateWeeklyMetrics(List<WorkoutSession> sessions) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfThisWeek = DateTime(monday.year, monday.month, monday.day);
    final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));

    double thisWeekVolume = 0;
    int thisWeekSessions = 0;
    double lastWeekVolume = 0;
    int lastWeekSessions = 0;

    for (final s in sessions) {
      final date = s.completedAt ?? s.startedAt;
      if (!date.isBefore(startOfThisWeek)) {
        thisWeekVolume += s.totalVolume;
        thisWeekSessions++;
      } else if (!date.isBefore(startOfLastWeek) && date.isBefore(startOfThisWeek)) {
        lastWeekVolume += s.totalVolume;
        lastWeekSessions++;
      }
    }

    double volumeChangePct = 0;
    if (lastWeekVolume > 0) {
      volumeChangePct = ((thisWeekVolume - lastWeekVolume) / lastWeekVolume) * 100.0;
    }

    return WeeklyStrengthMetrics(
      thisWeekVolume: thisWeekVolume,
      lastWeekVolume: lastWeekVolume,
      volumeChangePct: volumeChangePct,
      thisWeekSessions: thisWeekSessions,
      lastWeekSessions: lastWeekSessions,
    );
  }
}

class _HistoryPoint {
  final DateTime date;
  final double maxWeight;
  final double estimated1RM;
  final String displayName;

  _HistoryPoint({
    required this.date,
    required this.maxWeight,
    required this.estimated1RM,
    required this.displayName,
  });
}

class WeeklyStrengthMetrics {
  final double thisWeekVolume;
  final double lastWeekVolume;
  final double volumeChangePct;
  final int thisWeekSessions;
  final int lastWeekSessions;

  const WeeklyStrengthMetrics({
    required this.thisWeekVolume,
    required this.lastWeekVolume,
    required this.volumeChangePct,
    required this.thisWeekSessions,
    required this.lastWeekSessions,
  });
}
