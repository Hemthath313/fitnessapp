import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/presentation/transformation_plans/models/transformation_daily_log_model.dart';
import 'package:fitness_app/presentation/transformation_plans/models/transformation_schedule_override.dart';

/// Single day blueprint within a transformation week
class TransformationDayBlueprint {
  final int dayIndex; // 1-7 representing day of week or sequential day
  final String dayType; // 'workout' | 'rest' | 'active_recovery'
  final String? muscleGroup; // e.g. 'Chest & Triceps'
  final List<String> exerciseNames; // Matches names from ExerciseData
  final List<String> warmupExercises; // 5-10 min dynamic mobility preparation
  final List<String> cooldownExercises; // 5 min recovery stretching
  final String? notes;
  final int targetSets;
  final String targetReps;

  const TransformationDayBlueprint({
    required this.dayIndex,
    required this.dayType,
    this.muscleGroup,
    this.exerciseNames = const [],
    this.warmupExercises = const [],
    this.cooldownExercises = const [],
    this.notes,
    this.targetSets = 3,
    this.targetReps = '8-12',
  });

  bool get isRestDay => dayType == 'rest' || dayType == 'active_recovery';

  Map<String, dynamic> toMap() {
    return {
      'dayIndex': dayIndex,
      'dayType': dayType,
      'muscleGroup': muscleGroup,
      'exerciseNames': exerciseNames,
      'warmupExercises': warmupExercises,
      'cooldownExercises': cooldownExercises,
      'notes': notes,
      'targetSets': targetSets,
      'targetReps': targetReps,
    };
  }

  factory TransformationDayBlueprint.fromMap(Map<String, dynamic> map) {
    return TransformationDayBlueprint(
      dayIndex: (map['dayIndex'] as num?)?.toInt() ?? 1,
      dayType: map['dayType']?.toString() ?? 'workout',
      muscleGroup: map['muscleGroup']?.toString(),
      exerciseNames: (map['exerciseNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      warmupExercises: (map['warmupExercises'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      cooldownExercises: (map['cooldownExercises'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      notes: map['notes']?.toString(),
      targetSets: (map['targetSets'] as num?)?.toInt() ?? 3,
      targetReps: map['targetReps']?.toString() ?? '8-12',
    );
  }
}

/// A week blueprint containing 7 day schedules
class TransformationWeekBlueprint {
  final int weekNumber; // 1-based
  final String focus; // e.g. 'Foundational Hypertrophy'
  final List<TransformationDayBlueprint> days;
  final String? weekTip;

  const TransformationWeekBlueprint({
    required this.weekNumber,
    required this.focus,
    required this.days,
    this.weekTip,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekNumber': weekNumber,
      'focus': focus,
      'days': days.map((d) => d.toMap()).toList(),
      'weekTip': weekTip,
    };
  }

  factory TransformationWeekBlueprint.fromMap(Map<String, dynamic> map) {
    return TransformationWeekBlueprint(
      weekNumber: (map['weekNumber'] as num?)?.toInt() ?? 1,
      focus: map['focus']?.toString() ?? '',
      days: (map['days'] as List<dynamic>?)
              ?.map((d) => TransformationDayBlueprint.fromMap(
                  Map<String, dynamic>.from(d as Map)))
              .toList() ??
          const [],
      weekTip: map['weekTip']?.toString(),
    );
  }
}

/// A curriculum phase grouping multiple weeks
class TransformationPhase {
  final int phaseNumber;
  final String phaseName; // e.g. 'Phase 1 – Foundation'
  final String description;
  final List<TransformationWeekBlueprint> weeks;
  final String nutritionFocus;

  const TransformationPhase({
    required this.phaseNumber,
    required this.phaseName,
    required this.description,
    required this.weeks,
    required this.nutritionFocus,
  });

  Map<String, dynamic> toMap() {
    return {
      'phaseNumber': phaseNumber,
      'phaseName': phaseName,
      'description': description,
      'weeks': weeks.map((w) => w.toMap()).toList(),
      'nutritionFocus': nutritionFocus,
    };
  }

  factory TransformationPhase.fromMap(Map<String, dynamic> map) {
    return TransformationPhase(
      phaseNumber: (map['phaseNumber'] as num?)?.toInt() ?? 1,
      phaseName: map['phaseName']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      weeks: (map['weeks'] as List<dynamic>?)
              ?.map((w) => TransformationWeekBlueprint.fromMap(
                  Map<String, dynamic>.from(w as Map)))
              .toList() ??
          const [],
      nutritionFocus: map['nutritionFocus']?.toString() ?? '',
    );
  }
}

/// Static blueprint definition for an entire transformation programme
class TransformationPlanBlueprint {
  final String id; // e.g. 'weight_loss_60'
  final String title;
  final String subtitle;
  final String description;
  final int durationDays;
  final String goal; // 'LOSE' | 'GAIN' | 'STRENGTH'
  final String difficulty; // 'Beginner' | 'Intermediate' | 'Advanced'
  final List<TransformationPhase> phases;
  final String gradientColorHex;
  final String iconEmoji;
  final List<String> highlights;

  const TransformationPlanBlueprint({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.durationDays,
    required this.goal,
    required this.difficulty,
    required this.phases,
    required this.gradientColorHex,
    required this.iconEmoji,
    required this.highlights,
  });

  int get totalWeeks => (durationDays / 7).ceil();

  /// Flat list of all weeks across all phases in chronological order
  List<TransformationWeekBlueprint> get allWeeks =>
      phases.expand((p) => p.weeks).toList();

  /// Resolves the specific day blueprint given a 1-based sequential day number
  TransformationDayBlueprint? getDayBlueprint(int dayNumber) {
    if (dayNumber < 1 || dayNumber > durationDays) return null;
    final weekIndex = (dayNumber - 1) ~/ 7; // 0-based week
    final dayIndexInWeek = ((dayNumber - 1) % 7) + 1; // 1 to 7

    int currentWeekCounter = 0;
    for (final phase in phases) {
      for (final week in phase.weeks) {
        if (currentWeekCounter == weekIndex) {
          try {
            return week.days.firstWhere((d) => d.dayIndex == dayIndexInWeek);
          } catch (_) {
            return null;
          }
        }
        currentWeekCounter++;
      }
    }
    return null;
  }
}

/// Checkpoint milestone along the transformation roadmap
class TransformationMilestone {
  final String id;
  final String title;
  final String description;
  final int triggerDay; // Day number (e.g. 7, 14, 30)
  final bool isAchieved;
  final DateTime? achievedAt;

  const TransformationMilestone({
    required this.id,
    required this.title,
    required this.description,
    required this.triggerDay,
    this.isAchieved = false,
    this.achievedAt,
  });

  TransformationMilestone copyWith({
    bool? isAchieved,
    DateTime? achievedAt,
  }) {
    return TransformationMilestone(
      id: id,
      title: title,
      description: description,
      triggerDay: triggerDay,
      isAchieved: isAchieved ?? this.isAchieved,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'triggerDay': triggerDay,
      'isAchieved': isAchieved,
      'achievedAt': achievedAt != null ? Timestamp.fromDate(achievedAt!) : null,
    };
  }

  factory TransformationMilestone.fromMap(Map<String, dynamic> map) {
    DateTime? achieved;
    final a = map['achievedAt'];
    if (a is Timestamp) {
      achieved = a.toDate();
    } else if (a is String) {
      achieved = DateTime.tryParse(a);
    }
    return TransformationMilestone(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      triggerDay: (map['triggerDay'] as num?)?.toInt() ?? 1,
      isAchieved: map['isAchieved'] as bool? ?? false,
      achievedAt: achieved,
    );
  }
}

/// Structured weekly check-in record for transformation progress
class TransformationWeeklyCheckIn {
  final int weekNumber;
  final DateTime checkInDate;
  final double? weight;
  final double? weightChange; // weight change since startingWeight
  final int workoutsCompleted;
  final int workoutsScheduled;
  final double adherencePercentage;
  final Map<String, double> measurements; // e.g. {'waist': 82.0, 'chest': 98.0}
  final String? fatigueLevel; // 'Low', 'Normal', 'High'
  final String? notes;

  const TransformationWeeklyCheckIn({
    required this.weekNumber,
    required this.checkInDate,
    this.weight,
    this.weightChange,
    this.workoutsCompleted = 0,
    this.workoutsScheduled = 0,
    this.adherencePercentage = 0.0,
    this.measurements = const {},
    this.fatigueLevel,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekNumber': weekNumber,
      'checkInDate': Timestamp.fromDate(checkInDate),
      'weight': weight,
      'weightChange': weightChange,
      'workoutsCompleted': workoutsCompleted,
      'workoutsScheduled': workoutsScheduled,
      'adherencePercentage': adherencePercentage,
      'measurements': measurements,
      'fatigueLevel': fatigueLevel,
      'notes': notes,
    };
  }

  factory TransformationWeeklyCheckIn.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    final rawMeasurements = map['measurements'] as Map<dynamic, dynamic>? ?? {};
    final measurementsMap = <String, double>{};
    rawMeasurements.forEach((k, v) {
      if (v is num) {
        measurementsMap[k.toString()] = v.toDouble();
      }
    });

    return TransformationWeeklyCheckIn(
      weekNumber: (map['weekNumber'] as num?)?.toInt() ?? 1,
      checkInDate: parseDate(map['checkInDate']),
      weight: (map['weight'] as num?)?.toDouble(),
      weightChange: (map['weightChange'] as num?)?.toDouble(),
      workoutsCompleted: (map['workoutsCompleted'] as num?)?.toInt() ?? 0,
      workoutsScheduled: (map['workoutsScheduled'] as num?)?.toInt() ?? 0,
      adherencePercentage: (map['adherencePercentage'] as num?)?.toDouble() ?? 0.0,
      measurements: measurementsMap,
      fatigueLevel: map['fatigueLevel']?.toString(),
      notes: map['notes']?.toString(),
    );
  }
}

/// User's active or archived programme state persisted in Firestore
class UserTransformationState {
  final String planId;
  final String planTitle;
  final DateTime startDate;
  final DateTime targetEndDate;
  final int currentDay; // 1-based sequential day
  final int totalDays;
  final String status; // 'active' | 'completed' | 'paused'
  final List<int> completedDayIndices; // 1-based days completed
  final double targetCalories;
  final Map<String, double> targetMacros; // {'protein': g, 'carbs': g, 'fat': g}
  final List<TransformationMilestone> milestones;

  // Onboarding answers
  final String? workoutLocation; // 'gym' | 'home'
  final String? experienceLevel; // 'Beginner' | 'Intermediate' | 'Advanced'
  final List<String> availableEquipment;
  final String? dietaryPreference; // 'Vegetarian' | 'Non-vegetarian' | 'Vegan' | 'Other'
  final String? foodRestrictions;
  final List<String> allergies;
  final String? injuries;
  final int workoutDurationMinutes;
  final int workoutDaysPerWeek;
  final DateTime? completedAt;

  // Progress tracking & weekly check-in data
  final double? startingWeight;
  final double? targetWeight;
  final Map<String, double> startingMeasurements;
  final List<TransformationWeeklyCheckIn> weeklyCheckIns;
  final List<String> celebratedMilestoneIds;
  final Map<String, String> mealSubstitutions;
  final double dailyWaterTargetMl;
  final Map<String, TransformationDailyLog> dailyLogs; // Keyed by YYYY-MM-DD
  final Map<int, TransformationScheduleOverride> scheduleOverrides; // Keyed by dayNumber (1-based)

  UserTransformationState({
    required this.planId,
    required this.planTitle,
    required this.startDate,
    required this.targetEndDate,
    required this.currentDay,
    required this.totalDays,
    this.status = 'active',
    this.completedDayIndices = const [],
    required this.targetCalories,
    required this.targetMacros,
    this.milestones = const [],
    this.workoutLocation,
    this.experienceLevel,
    this.availableEquipment = const [],
    this.dietaryPreference,
    this.foodRestrictions,
    this.allergies = const [],
    this.injuries,
    this.workoutDurationMinutes = 45,
    this.workoutDaysPerWeek = 4,
    this.completedAt,
    this.startingWeight,
    this.targetWeight,
    this.startingMeasurements = const {},
    this.weeklyCheckIns = const [],
    this.celebratedMilestoneIds = const [],
    this.mealSubstitutions = const {},
    this.dailyWaterTargetMl = 2500.0,
    this.dailyLogs = const {},
    this.scheduleOverrides = const {},
  });

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool isDayCompleted(int dayNumber) => completedDayIndices.contains(dayNumber);

  /// Returns the scheduled calendar date for a day, accounting for any user rescheduling
  DateTime getScheduledDateForDay(int dayNumber) {
    final override = scheduleOverrides[dayNumber];
    if (override != null) {
      return override.scheduledDate;
    }
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    return normalizedStart.add(Duration(days: dayNumber - 1));
  }

  /// Returns the original planned calendar date for a day
  DateTime getOriginalDateForDay(int dayNumber) {
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    return normalizedStart.add(Duration(days: dayNumber - 1));
  }

  /// Whether the day has been explicitly skipped
  bool isDaySkipped(int dayNumber) => scheduleOverrides[dayNumber]?.isSkipped ?? false;

  /// Whether the day has been rescheduled to a different calendar date
  bool isDayRescheduled(int dayNumber) => scheduleOverrides[dayNumber]?.isRescheduled ?? false;

  /// Returns override object for the given day number, if any
  TransformationScheduleOverride? getScheduleOverride(int dayNumber) => scheduleOverrides[dayNumber];

  double get completionPercentage {
    if (totalDays <= 0) return 0.0;
    return (completedDayIndices.length / totalDays).clamp(0.0, 1.0);
  }

  int get currentWeekNumber => ((currentDay - 1) ~/ 7) + 1;

  /// Returns true if this state contains any persisted user-specific progress or customization.
  /// Used to ensure unstarted programmes with custom metrics or check-in data are not discarded.
  bool get hasTrackedData {
    // 1. Completed workout days
    if (completedDayIndices.isNotEmpty) return true;

    // 2. Progress tracking & weekly check-in data
    if (weeklyCheckIns.isNotEmpty) return true;
    if (dailyLogs.isNotEmpty) return true;
    if (scheduleOverrides.isNotEmpty) return true;
    if (celebratedMilestoneIds.isNotEmpty) return true;
    if (mealSubstitutions.isNotEmpty) return true;

    // 3. User onboarding metrics & target customizations
    if (startingWeight != null && startingWeight! > 0) return true;
    if (targetWeight != null && targetWeight! > 0) return true;
    if (startingMeasurements.isNotEmpty) return true;

    // 4. Equipment, injury or allergy customizations
    if (availableEquipment.isNotEmpty) return true;
    if (allergies.isNotEmpty) return true;
    if (foodRestrictions != null &&
        foodRestrictions!.trim().isNotEmpty &&
        foodRestrictions!.toLowerCase() != 'none') {
      return true;
    }
    if (injuries != null &&
        injuries!.trim().isNotEmpty &&
        injuries!.toLowerCase() != 'none') {
      return true;
    }

    return false;
  }

  UserTransformationState copyWith({
    String? planId,
    String? planTitle,
    DateTime? startDate,
    DateTime? targetEndDate,
    int? currentDay,
    int? totalDays,
    String? status,
    List<int>? completedDayIndices,
    double? targetCalories,
    Map<String, double>? targetMacros,
    List<TransformationMilestone>? milestones,
    String? workoutLocation,
    String? experienceLevel,
    List<String>? availableEquipment,
    String? dietaryPreference,
    String? foodRestrictions,
    List<String>? allergies,
    String? injuries,
    int? workoutDurationMinutes,
    int? workoutDaysPerWeek,
    DateTime? completedAt,
    double? startingWeight,
    double? targetWeight,
    Map<String, double>? startingMeasurements,
    List<TransformationWeeklyCheckIn>? weeklyCheckIns,
    List<String>? celebratedMilestoneIds,
    Map<String, String>? mealSubstitutions,
    double? dailyWaterTargetMl,
    Map<String, TransformationDailyLog>? dailyLogs,
    Map<int, TransformationScheduleOverride>? scheduleOverrides,
  }) {
    return UserTransformationState(
      planId: planId ?? this.planId,
      planTitle: planTitle ?? this.planTitle,
      startDate: startDate ?? this.startDate,
      targetEndDate: targetEndDate ?? this.targetEndDate,
      currentDay: currentDay ?? this.currentDay,
      totalDays: totalDays ?? this.totalDays,
      status: status ?? this.status,
      completedDayIndices: completedDayIndices ?? this.completedDayIndices,
      targetCalories: targetCalories ?? this.targetCalories,
      targetMacros: targetMacros ?? this.targetMacros,
      milestones: milestones ?? this.milestones,
      workoutLocation: workoutLocation ?? this.workoutLocation,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      foodRestrictions: foodRestrictions ?? this.foodRestrictions,
      allergies: allergies ?? this.allergies,
      injuries: injuries ?? this.injuries,
      workoutDurationMinutes: workoutDurationMinutes ?? this.workoutDurationMinutes,
      workoutDaysPerWeek: workoutDaysPerWeek ?? this.workoutDaysPerWeek,
      completedAt: completedAt ?? this.completedAt,
      startingWeight: startingWeight ?? this.startingWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      startingMeasurements: startingMeasurements ?? this.startingMeasurements,
      weeklyCheckIns: weeklyCheckIns ?? this.weeklyCheckIns,
      celebratedMilestoneIds: celebratedMilestoneIds ?? this.celebratedMilestoneIds,
      mealSubstitutions: mealSubstitutions ?? this.mealSubstitutions,
      dailyWaterTargetMl: dailyWaterTargetMl ?? this.dailyWaterTargetMl,
      dailyLogs: dailyLogs ?? this.dailyLogs,
      scheduleOverrides: scheduleOverrides ?? this.scheduleOverrides,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'planTitle': planTitle,
      'startDate': Timestamp.fromDate(startDate),
      'targetEndDate': Timestamp.fromDate(targetEndDate),
      'currentDay': currentDay,
      'totalDays': totalDays,
      'status': status,
      'completedDayIndices': completedDayIndices,
      'targetCalories': targetCalories,
      'targetMacros': targetMacros,
      'milestones': milestones.map((m) => m.toMap()).toList(),
      'workoutLocation': workoutLocation,
      'experienceLevel': experienceLevel,
      'availableEquipment': availableEquipment,
      'dietaryPreference': dietaryPreference,
      'foodRestrictions': foodRestrictions,
      'allergies': allergies,
      'injuries': injuries,
      'workoutDurationMinutes': workoutDurationMinutes,
      'workoutDaysPerWeek': workoutDaysPerWeek,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'startingWeight': startingWeight,
      'targetWeight': targetWeight,
      'startingMeasurements': startingMeasurements,
      'weeklyCheckIns': weeklyCheckIns.map((w) => w.toMap()).toList(),
      'celebratedMilestoneIds': celebratedMilestoneIds,
      'mealSubstitutions': mealSubstitutions,
      'dailyWaterTargetMl': dailyWaterTargetMl,
      'dailyLogs': dailyLogs.map((k, v) => MapEntry(k, v.toMap())),
      'scheduleOverrides': scheduleOverrides.map((k, v) => MapEntry(k.toString(), v.toMap())),
    };
  }

  factory UserTransformationState.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? fallback;
      return fallback;
    }

    final start = parseDate(map['startDate'], DateTime.now());
    final end = parseDate(map['targetEndDate'], start.add(const Duration(days: 60)));
    final comp = map['completedAt'] != null ? parseDate(map['completedAt'], DateTime.now()) : null;

    final macrosRaw = map['targetMacros'] as Map<dynamic, dynamic>? ?? {};
    final macros = <String, double>{
      'protein': (macrosRaw['protein'] as num?)?.toDouble() ?? 140.0,
      'carbs': (macrosRaw['carbs'] as num?)?.toDouble() ?? 200.0,
      'fat': (macrosRaw['fat'] as num?)?.toDouble() ?? 60.0,
    };

    final rawMilestones = (map['milestones'] as List<dynamic>?) ?? [];
    final milestones = rawMilestones
        .map((m) => TransformationMilestone.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();

    final completedDays = (map['completedDayIndices'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        [];

    final equipmentList = (map['availableEquipment'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final rawAllergies = (map['allergies'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ((map['foodRestrictions'] as String?)
                ?.split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty && e.toLowerCase() != 'none')
                .toList() ??
            []);

    final rawStartingMeasurements = map['startingMeasurements'] as Map<dynamic, dynamic>? ?? {};
    final startingMeasurementsMap = <String, double>{};
    rawStartingMeasurements.forEach((k, v) {
      if (v is num) {
        startingMeasurementsMap[k.toString()] = v.toDouble();
      }
    });

    final rawCheckIns = (map['weeklyCheckIns'] as List<dynamic>?) ?? [];
    final checkIns = rawCheckIns
        .map((w) => TransformationWeeklyCheckIn.fromMap(Map<String, dynamic>.from(w as Map)))
        .toList();

    final celebratedIds = (map['celebratedMilestoneIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final rawSubstitutions = map['mealSubstitutions'] as Map<dynamic, dynamic>? ?? {};
    final mealSubstitutionsMap = <String, String>{};
    rawSubstitutions.forEach((k, v) {
      if (v != null) {
        mealSubstitutionsMap[k.toString()] = v.toString();
      }
    });

    final rawDailyLogs = map['dailyLogs'] as Map<dynamic, dynamic>? ?? {};
    final dailyLogsMap = <String, TransformationDailyLog>{};
    rawDailyLogs.forEach((k, v) {
      if (v is Map) {
        dailyLogsMap[k.toString()] =
            TransformationDailyLog.fromMap(Map<String, dynamic>.from(v));
      }
    });

    final rawOverrides = map['scheduleOverrides'] as Map<dynamic, dynamic>? ?? {};
    final scheduleOverridesMap = <int, TransformationScheduleOverride>{};
    rawOverrides.forEach((k, v) {
      if (v is Map) {
        final dayNum = int.tryParse(k.toString());
        if (dayNum != null) {
          scheduleOverridesMap[dayNum] =
              TransformationScheduleOverride.fromMap(Map<String, dynamic>.from(v));
        }
      }
    });

    return UserTransformationState(
      planId: map['planId']?.toString() ?? '',
      planTitle: map['planTitle']?.toString() ?? '',
      startDate: start,
      targetEndDate: end,
      currentDay: (map['currentDay'] as num?)?.toInt() ?? 1,
      totalDays: (map['totalDays'] as num?)?.toInt() ?? 60,
      status: map['status']?.toString() ?? 'active',
      completedDayIndices: completedDays,
      targetCalories: (map['targetCalories'] as num?)?.toDouble() ?? 2000.0,
      targetMacros: macros,
      milestones: milestones,
      workoutLocation: map['workoutLocation']?.toString(),
      experienceLevel: map['experienceLevel']?.toString(),
      availableEquipment: equipmentList,
      dietaryPreference: map['dietaryPreference']?.toString(),
      foodRestrictions: map['foodRestrictions']?.toString(),
      allergies: rawAllergies,
      injuries: map['injuries']?.toString(),
      workoutDurationMinutes: (map['workoutDurationMinutes'] as num?)?.toInt() ?? 45,
      workoutDaysPerWeek: (map['workoutDaysPerWeek'] as num?)?.toInt() ?? 4,
      completedAt: comp,
      startingWeight: (map['startingWeight'] as num?)?.toDouble(),
      targetWeight: (map['targetWeight'] as num?)?.toDouble(),
      startingMeasurements: startingMeasurementsMap,
      weeklyCheckIns: checkIns,
      celebratedMilestoneIds: celebratedIds,
      mealSubstitutions: mealSubstitutionsMap,
      dailyWaterTargetMl: (map['dailyWaterTargetMl'] as num?)?.toDouble() ?? 2500.0,
      dailyLogs: dailyLogsMap,
      scheduleOverrides: scheduleOverridesMap,
    );
  }
}
