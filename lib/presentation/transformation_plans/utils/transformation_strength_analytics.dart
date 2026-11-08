import 'package:fitness_app/model/personal_record_model.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/services/strength_service.dart';

/// Single data point for exercise strength progression chart
class StrengthChartPoint {
  final DateTime date;
  final double workingWeight;
  final double estimated1RM;

  const StrengthChartPoint({
    required this.date,
    required this.workingWeight,
    required this.estimated1RM,
  });
}

/// Exercise-level progression summary comparing baseline vs latest
class ExerciseStrengthProgression {
  final String exerciseName;
  final double startingWeight;
  final double latestWeight;
  final double weightDifference;
  final double percentageImprovement;
  final double startingEstimated1RM;
  final double latestEstimated1RM;
  final double estimated1RMDifference;
  final List<StrengthChartPoint> historyPoints;

  const ExerciseStrengthProgression({
    required this.exerciseName,
    required this.startingWeight,
    required this.latestWeight,
    required this.weightDifference,
    required this.percentageImprovement,
    required this.startingEstimated1RM,
    required this.latestEstimated1RM,
    required this.estimated1RMDifference,
    required this.historyPoints,
  });
}

/// Comprehensive strength analytics summary for a transformation plan
class TransformationStrengthSummary {
  final int totalStrengthWorkouts;
  final List<PersonalRecord> prsAchieved;
  final List<ExerciseStrengthProgression> exerciseProgressions;
  final double totalEstimated1RMGain;
  final bool hasData;

  const TransformationStrengthSummary({
    required this.totalStrengthWorkouts,
    required this.prsAchieved,
    required this.exerciseProgressions,
    required this.totalEstimated1RMGain,
    required this.hasData,
  });

  static TransformationStrengthSummary empty() {
    return const TransformationStrengthSummary(
      totalStrengthWorkouts: 0,
      prsAchieved: [],
      exerciseProgressions: [],
      totalEstimated1RMGain: 0.0,
      hasData: false,
    );
  }
}

/// Dedicated analytics engine bridging Transformation Plans with StrengthService & WorkoutSession history
class TransformationStrengthAnalytics {
  static final StrengthService _strengthService = StrengthService();

  /// Analyzes strength progression for the given transformation state from recorded workout sessions
  static TransformationStrengthSummary analyze({
    required UserTransformationState state,
    required List<WorkoutSession> sessions,
  }) {
    if (sessions.isEmpty) {
      return TransformationStrengthSummary.empty();
    }

    // Filter sessions belonging to this transformation
    final transformationSessions = sessions.where((s) {
      final matchesPlanId = s.planId == state.planId;
      final startFloor = state.startDate.subtract(const Duration(minutes: 10));
      final endCeiling = state.completedAt != null
          ? state.completedAt!.add(const Duration(days: 1))
          : DateTime.now().add(const Duration(days: 1));

      final fallsWithinWindow = s.startedAt.isAfter(startFloor) && s.startedAt.isBefore(endCeiling);
      return matchesPlanId || fallsWithinWindow;
    }).toList();

    if (transformationSessions.isEmpty) {
      return TransformationStrengthSummary.empty();
    }

    // Sort chronologically
    transformationSessions.sort((a, b) => a.startedAt.compareTo(b.startedAt));

    // 1. Detect PRs achieved during transformation
    final List<PersonalRecord> prs = [];

    for (final session in transformationSessions) {
      final sessionPRs = _strengthService.detectPRsInSession(
        session: session,
        allSessions: sessions,
      );
      for (final pr in sessionPRs) {
        if (!prs.any((existing) =>
            existing.exerciseName.toLowerCase() == pr.exerciseName.toLowerCase() &&
            existing.weight == pr.weight &&
            existing.reps == pr.reps)) {
          prs.add(pr);
        }
      }
    }

    // 2. Exercise-level progression
    final Map<String, List<StrengthChartPoint>> exerciseMap = {};
    final Map<String, String> displayNames = {};

    for (final s in transformationSessions) {
      final sessionDate = s.completedAt ?? s.startedAt;

      for (final ex in s.exercises) {
        final key = ExerciseIdentity.canonicalKey(ex.exerciseName);
        final displayName = ExerciseIdentity.cleanDisplayName(ex.exerciseName);
        displayNames[key] = displayName;

        // Filter valid sets: completed, not warmup, weight > 0
        final validSets = ex.sets.where((st) =>
            st.isCompleted &&
            st.type != SetType.warmup &&
            st.weight > 0 &&
            st.reps > 0).toList();

        if (validSets.isEmpty) continue;

        double maxWeight = 0.0;
        double max1RM = 0.0;

        for (final st in validSets) {
          if (st.weight > maxWeight) maxWeight = st.weight;
          final est = StrengthService.calculateEstimated1RM(st);
          if (est > max1RM) max1RM = est;
        }

        exerciseMap.putIfAbsent(key, () => []).add(StrengthChartPoint(
          date: sessionDate,
          workingWeight: maxWeight,
          estimated1RM: max1RM,
        ));
      }
    }

    final List<ExerciseStrengthProgression> progressions = [];
    double total1RMGain = 0.0;

    for (final entry in exerciseMap.entries) {
      final points = entry.value..sort((a, b) => a.date.compareTo(b.date));
      if (points.isEmpty) continue;

      final startPoint = points.first;
      final latestPoint = points.last;

      final weightDiff = latestPoint.workingWeight - startPoint.workingWeight;
      final pctImprovement = startPoint.workingWeight > 0
          ? ((weightDiff / startPoint.workingWeight) * 100.0)
          : 0.0;

      final e1rmDiff = latestPoint.estimated1RM - startPoint.estimated1RM;
      if (e1rmDiff > 0) {
        total1RMGain += e1rmDiff;
      }

      progressions.add(ExerciseStrengthProgression(
        exerciseName: displayNames[entry.key] ?? entry.key,
        startingWeight: startPoint.workingWeight,
        latestWeight: latestPoint.workingWeight,
        weightDifference: weightDiff,
        percentageImprovement: pctImprovement,
        startingEstimated1RM: startPoint.estimated1RM,
        latestEstimated1RM: latestPoint.estimated1RM,
        estimated1RMDifference: e1rmDiff,
        historyPoints: points,
      ));
    }

    // Sort exercises by most improved
    progressions.sort((a, b) => b.weightDifference.compareTo(a.weightDifference));

    return TransformationStrengthSummary(
      totalStrengthWorkouts: transformationSessions.length,
      prsAchieved: prs,
      exerciseProgressions: progressions,
      totalEstimated1RMGain: total1RMGain,
      hasData: transformationSessions.isNotEmpty,
    );
  }
}
