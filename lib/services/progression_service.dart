import 'package:fitness_app/utils/units.dart';
import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/model/workout_log.dart';

enum ProgressionType {
  baseline,
  increaseWeight,
  increaseReps,
  maintain,
  deload,
}

class ProgressionRecommendation {
  final double recommendedWeight;
  final bool hasRecommendedWeight;
  final int targetMinReps;
  final int targetMaxReps;
  final String reason;
  final String badgeLabel;
  final ProgressionType type;

  const ProgressionRecommendation({
    required this.recommendedWeight,
    this.hasRecommendedWeight = true,
    required this.targetMinReps,
    required this.targetMaxReps,
    required this.reason,
    required this.badgeLabel,
    required this.type,
  });

  /// Formatted initial weight string for input controllers.
  /// Returns an empty string `''` when [hasRecommendedWeight] is false so that
  /// ambiguous-equipment and unknown custom exercises remain explicitly unconfigured.
  /// Recommended weight as input text, in the user's unit (kg or lb).
  String get formattedWeight => !hasRecommendedWeight
      ? ''
      : (Units.useLb
          ? Units.inputText(recommendedWeight)
          : ProgressionService.formatWeight(recommendedWeight));

  /// Target summary string for the progressive overload banner.
  String get targetSummary => hasRecommendedWeight
      ? 'Target: ${Units.fmt(recommendedWeight, 1)} ${Units.label} × $targetMinReps-$targetMaxReps'
      : 'Target: Select load × $targetMinReps-$targetMaxReps';
}

class ProgressionService {
  /// Safe neutral fallback (in kg) for known catalog external-resistance
  /// exercises (e.g. cable/machine movements) when no prior workout history
  /// exists and no more specific barbell/dumbbell default applies.
  static const double neutralDefaultWeight = 15.0;

  static const Set<String> _compoundExercises = {
    'bench press',
    'barbell bench press',
    'barbell squat',
    'squat',
    'deadlift',
    'barbell deadlift',
    'overhead press',
    'barbell overhead press',
    'military press',
    'barbell row',
    'barbell bent over row',
    'bent over row',
    'romanian deadlift',
    'leg press',
    'incline bench press',
    'incline dumbbell press',
    'chest dips',
    'pull-ups',
    'chin-ups',
  };

  static String formatWeight(double weight) {
    if (weight < 0) return '0';
    return weight.toStringAsFixed(weight % 1 == 0 ? 0 : 1);
  }

  static bool isCompound(String exerciseName) {
    final lower = ExerciseData.normalizeExerciseName(exerciseName).toLowerCase().trim();
    return _compoundExercises.any((c) => lower.contains(c));
  }

  static double getWeightIncrement(String exerciseName) {
    return isCompound(exerciseName) ? 2.5 : 1.0;
  }

  /// Returns true when the exercise requires no external load (0 kg default),
  /// such as bodyweight calisthenics, unweighted ab/core work, cardio drills,
  /// and stretching movements.
  static bool isBodyweightOrNoExternalLoad(
    String exerciseName, {
    String? equipment,
    String? category,
  }) {
    final cleanName = ExerciseData.normalizeExerciseName(exerciseName);
    final lower = cleanName.toLowerCase().trim();
    if (lower.isEmpty) return false;

    final catalogExercise = ExerciseData.findByName(cleanName);
    final resolvedEquipment =
        (equipment ?? catalogExercise?.equipment ?? '').trim().toLowerCase();
    final resolvedCategory =
        (category ?? ExerciseData.categoryFor(cleanName) ?? '').trim().toLowerCase();

    // Explicit external-resistance apparatus is never treated as 0 kg bodyweight.
    const externalApparatusKeywords = <String>[
      'dip machine',
      'cable',
      'ab machine',
      'pec deck',
      'leg press',
      'leg extension',
      'leg curl',
      'calf machine',
      'smith machine',
      'sled',
      'barbell',
      'ez bar',
      'dumbbell',
      'kettlebell',
      'trap bar',
      'ankle weight',
      'resistance band',
    ];
    if (externalApparatusKeywords.any((k) => resolvedEquipment.contains(k))) {
      return false;
    }

    // Explicit bodyweight / no-external-load equipment labels in catalog.
    if (resolvedEquipment == 'bodyweight' ||
        resolvedEquipment == 'none' ||
        resolvedEquipment == 'no equipment' ||
        resolvedEquipment == 'roman chair' ||
        resolvedEquipment == 'parallel bars' ||
        resolvedEquipment == 'bench or parallel bars' ||
        resolvedEquipment == 'pull-up bar' ||
        resolvedEquipment == 'ab bench') {
      return true;
    }

    // Cardio drills without external resistance apparatus default to 0 kg.
    if (resolvedCategory == 'cardio' || resolvedCategory == 'stretching') {
      return true;
    }

    // Guard against weighted/machine variants in the exercise name itself.
    if (lower.contains('lever') ||
        lower.contains('machine') ||
        lower.contains('weighted') ||
        lower.contains('dumbbell') ||
        lower.contains('barbell') ||
        lower.contains('cable') ||
        lower.contains('smith') ||
        lower.contains('band')) {
      return false;
    }

    const bodyweightNameKeywords = <String>[
      'push-up',
      'pushup',
      'pull-up',
      'pullup',
      'chin-up',
      'chinup',
      'dips',
      'plank',
      'burpee',
      'jumping jack',
      'mountain climber',
      'high knee',
      'fast run',
      'skater hop',
      'scissors jump',
      'tuck jump',
      'v-up',
      'crunch',
      'sit-up',
      'sit up',
      'leg raise',
      'hip raise',
      'bridge pose',
      'hyperextension',
      'stretching:',
    ];
    return bodyweightNameKeywords.any((k) => lower.contains(k));
  }

  /// Returns true when the catalog or passed equipment metadata is ambiguous
  /// (e.g. optional load, dual bodyweight/weighted apparatus, elastic bands)
  /// or when the exercise is an unknown custom exercise not in the canonical
  /// catalog and not identifiable as bodyweight.
  static bool hasAmbiguousEquipmentMetadata(
    String exerciseName, {
    String? equipment,
    String? category,
  }) {
    if (isBodyweightOrNoExternalLoad(
      exerciseName,
      equipment: equipment,
      category: category,
    )) {
      return false;
    }

    final cleanName = ExerciseData.normalizeExerciseName(exerciseName);
    final catalogExercise = ExerciseData.findByName(cleanName);
    final resolvedEquipment =
        (equipment ?? catalogExercise?.equipment ?? '').trim().toLowerCase();

    if (resolvedEquipment.contains('optional') ||
        resolvedEquipment == 'machine or bench' ||
        resolvedEquipment == 'dumbbell or ankle weights' ||
        resolvedEquipment.contains('resistance band') ||
        resolvedEquipment == 'band') {
      return true;
    }

    // Unknown custom exercises not present in the canonical catalog should not
    // receive an invented 15 kg recommendation when no history exists.
    if (catalogExercise == null) {
      return true;
    }

    return false;
  }

  /// Checks whether [previousLog] has usable weight/rep history for seeding.
  static bool hasUsableWeightHistory(
    WorkoutLog? previousLog, {
    bool isBodyweight = false,
  }) {
    if (previousLog == null || previousLog.sets.isEmpty) return false;
    final workingSets =
        previousLog.sets.where((s) => s.type != SetType.warmup).toList();
    final setsToAnalyze =
        workingSets.isNotEmpty ? workingSets : previousLog.sets;
    if (isBodyweight) {
      return setsToAnalyze.any((s) => s.weight >= 0 && s.reps > 0);
    }
    return setsToAnalyze.any((s) => s.weight > 0 && s.reps > 0);
  }

  /// Returns a sensible initial default weight (in kg) when determinable from
  /// canonical catalog metadata, or `null` when equipment metadata is ambiguous
  /// or the exercise is an unknown custom exercise.
  static double? getInitialDefaultWeight(
    String exerciseName, {
    String? equipment,
    String? category,
  }) {
    if (isBodyweightOrNoExternalLoad(
      exerciseName,
      equipment: equipment,
      category: category,
    )) {
      return 0.0;
    }

    if (hasAmbiguousEquipmentMetadata(
      exerciseName,
      equipment: equipment,
      category: category,
    )) {
      return null;
    }

    final cleanName = ExerciseData.normalizeExerciseName(exerciseName);
    final lower = cleanName.toLowerCase().trim();
    final catalogExercise = ExerciseData.findByName(cleanName);
    final resolvedEquipment =
        (equipment ?? catalogExercise?.equipment ?? '').trim().toLowerCase();

    if (lower.contains('dumbbell') ||
        resolvedEquipment == 'dumbbell' ||
        resolvedEquipment == 'dumbbells') {
      return 10.0;
    }
    if (lower.contains('deadlift')) return 60.0;
    if (lower.contains('squat')) return 50.0;
    if (lower.contains('bench press')) return 40.0;
    if (lower.contains('overhead press') || lower.contains('military press')) {
      return 30.0;
    }
    if (lower.contains('barbell') || resolvedEquipment == 'barbell') {
      return 30.0;
    }
    if (lower.contains('curl') || lower.contains('raise')) return 10.0;
    return neutralDefaultWeight;
  }

  /// Returns a formatted initial weight string for seeding input fields when no
  /// prior workout history exists, or `''` (explicit unconfigured state) when
  /// equipment is ambiguous or the exercise is an unknown custom exercise.
  static String formatInitialWeight(
    String exerciseName, {
    String? equipment,
    String? category,
  }) {
    final initial = getInitialDefaultWeight(
      exerciseName,
      equipment: equipment,
      category: category,
    );
    if (initial == null) return '';
    return Units.useLb ? Units.inputText(initial) : formatWeight(initial);
  }

  /// Internal numeric fallback for callers requiring a non-null `double`.
  /// For UI seeding and progression banners, prefer [getInitialDefaultWeight],
  /// [formatInitialWeight], or [calculateNextTarget] which preserve an explicit
  /// unconfigured state when [hasAmbiguousEquipmentMetadata] is true.
  static double getSensibleDefaultWeight(
    String exerciseName, {
    String? equipment,
    String? category,
  }) {
    return getInitialDefaultWeight(
          exerciseName,
          equipment: equipment,
          category: category,
        ) ??
        neutralDefaultWeight;
  }

  /// One-line hint for the plan card, derived from the same rule the guided
  /// session uses, so the card never promises a heavier weight than the
  /// session will actually prefill. Returns null with no usable history.
  static String? nudgeFor(String exerciseName, WorkoutLog? previousLog) {
    if (previousLog == null || previousLog.sets.isEmpty) return null;
    final rec = calculateNextTarget(
      exerciseName: exerciseName,
      previousLog: previousLog,
    );
    final hasWeight = rec.hasRecommendedWeight && rec.recommendedWeight > 0;
    final weight = Units.useLb
        ? Units.inputText(rec.recommendedWeight)
        : formatWeight(rec.recommendedWeight);
    final u = Units.label;
    switch (rec.type) {
      case ProgressionType.increaseWeight:
        return '🔺 Try $weight $u today';
      case ProgressionType.increaseReps:
        return hasWeight
            ? 'Same $weight $u, aim for +1 rep per set'
            : 'Aim for +1 rep per set';
      case ProgressionType.maintain:
        return hasWeight
            ? 'Hold $weight $u, aim for ${rec.targetMinReps}+ clean reps'
            : 'Aim for ${rec.targetMinReps}+ clean reps';
      case ProgressionType.deload:
        return hasWeight ? 'Ease back to $weight $u' : 'Take it lighter today';
      case ProgressionType.baseline:
        return null;
    }
  }

  static ProgressionRecommendation calculateNextTarget({
    required String exerciseName,
    required WorkoutLog? previousLog,
    int defaultTargetReps = 8,
    String? equipment,
    String? category,
  }) {
    final bool compound = isCompound(exerciseName);
    final int minReps = compound ? 6 : 8;
    final int maxReps = compound ? 8 : 12;
    final double increment = getWeightIncrement(exerciseName);
    final bool isBodyweight = isBodyweightOrNoExternalLoad(
      exerciseName,
      equipment: equipment,
      category: category,
    );
    final double? initialDefaultWeight = getInitialDefaultWeight(
      exerciseName,
      equipment: equipment,
      category: category,
    );

    if (!hasUsableWeightHistory(previousLog, isBodyweight: isBodyweight)) {
      if (initialDefaultWeight == null) {
        return ProgressionRecommendation(
          recommendedWeight: 0.0,
          hasRecommendedWeight: false,
          targetMinReps: minReps,
          targetMaxReps: maxReps,
          reason:
              'Select a starting load based on your setup to establish a baseline.',
          badgeLabel: 'SELECT LOAD',
          type: ProgressionType.baseline,
        );
      }
      return ProgressionRecommendation(
        recommendedWeight: initialDefaultWeight,
        hasRecommendedWeight: true,
        targetMinReps: minReps,
        targetMaxReps: maxReps,
        reason: 'First session for this exercise. Establish a solid baseline.',
        badgeLabel: 'BASELINE',
        type: ProgressionType.baseline,
      );
    }

    // Filter to working sets (ignore warmups if marked)
    final workingSets = previousLog!.sets
        .where((s) => s.type != SetType.warmup && s.reps > 0)
        .toList();

    final setsToAnalyze = workingSets.isNotEmpty
        ? workingSets
        : previousLog.sets.where((s) => s.reps > 0).toList();

    // Determine the heaviest weight used in the working sets
    double lastHeaviestWeight = 0.0;
    for (var s in setsToAnalyze) {
      if (s.weight > lastHeaviestWeight) {
        lastHeaviestWeight = s.weight;
      }
    }

    // Bodyweight exercises performed without external weight stay at 0 kg default.
    if (isBodyweight && lastHeaviestWeight <= 0) {
      final bool allHitMinReps =
          setsToAnalyze.isNotEmpty && setsToAnalyze.every((s) => s.reps >= minReps);
      return ProgressionRecommendation(
        recommendedWeight: 0.0,
        targetMinReps: minReps,
        targetMaxReps: maxReps,
        reason: allHitMinReps
            ? 'Solid bodyweight session last time. Aim for +1 rep per set with strict form.'
            : 'Focus on controlled bodyweight reps to hit at least $minReps clean reps.',
        badgeLabel: allHitMinReps ? '+1 REP TARGET 🔥' : 'BODYWEIGHT BASE 🛡️',
        type: allHitMinReps ? ProgressionType.increaseReps : ProgressionType.maintain,
      );
    }

    // Check rep performance at the top working weight
    final topWeightSets = setsToAnalyze
        .where((s) => s.weight > 0 && s.weight >= lastHeaviestWeight - 2.5)
        .toList();
    final bool allHitTopReps =
        topWeightSets.isNotEmpty && topWeightSets.every((s) => s.reps >= maxReps);
    final bool allHitMinReps =
        topWeightSets.isNotEmpty && topWeightSets.every((s) => s.reps >= minReps);

    if (allHitTopReps) {
      // User crushed all sets at max target reps -> Step up weight (Double Progression)
      final newWeight = lastHeaviestWeight + increment;
      return ProgressionRecommendation(
        recommendedWeight: newWeight,
        targetMinReps: minReps,
        targetMaxReps: maxReps,
        reason:
            'Crushed $maxReps reps across all sets last time! Add +${Units.fmtSmart(increment)} ${Units.label} and reset to $minReps reps.',
        badgeLabel: '+${Units.fmt(increment, 1)} ${Units.label} STEP UP ⚡',
        type: ProgressionType.increaseWeight,
      );
    } else if (allHitMinReps) {
      // User is within target zone -> Hold weight, push for extra reps
      return ProgressionRecommendation(
        recommendedWeight: lastHeaviestWeight,
        targetMinReps: minReps,
        targetMaxReps: maxReps,
        reason:
            'Solid base last time. Keep ${Units.fmtSmart(lastHeaviestWeight)} ${Units.label} and aim for +1 rep on your final sets.',
        badgeLabel: '+1 REP TARGET 🔥',
        type: ProgressionType.increaseReps,
      );
    } else {
      // User missed minimum reps -> Consolidate form
      return ProgressionRecommendation(
        recommendedWeight: lastHeaviestWeight,
        targetMinReps: minReps,
        targetMaxReps: maxReps,
        reason:
            'Hold at ${Units.fmtSmart(lastHeaviestWeight)} ${Units.label}. Focus on strict form to hit at least $minReps clean reps.',
        badgeLabel: 'HOLD WEIGHT 🛡️',
        type: ProgressionType.maintain,
      );
    }
  }
}
