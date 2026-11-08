import 'package:cloud_firestore/cloud_firestore.dart';

/// Configurable thresholds for daily transformation accountability and adherence scoring.
class AccountabilityThresholds {
  // Caloric target tolerances
  static const double calorieCompleteTolerancePercent = 0.10; // Within +/- 10%
  static const double caloriePartialTolerancePercent = 0.20;  // Within +/- 20%
  static const double calorieAbsoluteToleranceKcal = 200.0;   // Or within +/- 200 kcal

  // Protein target tolerances
  static const double proteinCompleteThresholdRatio = 0.90;   // >= 90% of target
  static const double proteinPartialThresholdRatio = 0.70;    // >= 70% of target

  // Water goal tolerances
  static const double waterCompleteThresholdRatio = 0.80;     // >= 80% of configured goal
  static const double waterPartialThresholdRatio = 0.50;      // >= 50% of configured goal

  // Scoring weights (out of 100 total when 5 components are assessable)
  static const double standardComponentWeight = 20.0;
}

/// Standardized status strings for accountability items
class AccountabilityStatus {
  static const String pending = 'pending';
  static const String completed = 'completed';
  static const String partiallyCompleted = 'partially_completed';
  static const String notCompleted = 'not_completed';
  static const String notApplicable = 'not_applicable';
}

/// Structured daily record tracking accountability, consumption, and adherence
class TransformationDailyLog {
  final String planId;
  final int dayNumber;
  final String dateString; // YYYY-MM-DD
  final String workoutStatus; // pending, completed, partially_completed, not_completed, not_applicable
  final String calorieStatus;
  final String proteinStatus;
  final String waterStatus;
  final String recoveryStatus;
  final double dailyAdherenceScore; // 0.0 - 100.0
  final DateTime lastUpdated;

  // Actual vs target summary values (stored as lightweight summaries, not duplicating logs)
  final double actualCalories;
  final double targetCalories;
  final double actualProtein;
  final double targetProtein;
  final double actualWaterMl;
  final double targetWaterMl;
  final String? recoveryLevel; // 'good', 'moderate', 'poor'
  final String? recoveryNote;
  final bool isRestDay;

  const TransformationDailyLog({
    required this.planId,
    required this.dayNumber,
    required this.dateString,
    required this.workoutStatus,
    required this.calorieStatus,
    required this.proteinStatus,
    required this.waterStatus,
    required this.recoveryStatus,
    required this.dailyAdherenceScore,
    required this.lastUpdated,
    this.actualCalories = 0.0,
    this.targetCalories = 2000.0,
    this.actualProtein = 0.0,
    this.targetProtein = 140.0,
    this.actualWaterMl = 0.0,
    this.targetWaterMl = 2500.0,
    this.recoveryLevel,
    this.recoveryNote,
    this.isRestDay = false,
  });

  /// Total assessable components for this day (4 on rest days, 5 on training days)
  int get totalAssessableComponents => isRestDay ? 4 : 5;

  /// Count of activities where tracking data has been recorded (not pending)
  int get trackedComponentsCount {
    int count = 0;
    if (!isRestDay && workoutStatus != AccountabilityStatus.pending) count++;
    if (calorieStatus != AccountabilityStatus.pending) count++;
    if (proteinStatus != AccountabilityStatus.pending) count++;
    if (waterStatus != AccountabilityStatus.pending) count++;
    if (recoveryStatus != AccountabilityStatus.pending) count++;
    return count;
  }

  /// Whether enough data exists to calculate a meaningful adherence score
  bool get hasEnoughData => trackedComponentsCount > 0;

  /// Human-readable coverage summary (e.g. "60% – 3 of 5 activities tracked" or "Not enough data")
  String get coverageText {
    if (!hasEnoughData) {
      return 'Not enough data';
    }
    return '${dailyAdherenceScore.round()}% – $trackedComponentsCount of $totalAssessableComponents activities tracked';
  }

  /// Evaluates and calculates a daily log given current live data
  factory TransformationDailyLog.calculate({
    required String planId,
    required int dayNumber,
    required String dateString,
    required bool workoutCompleted,
    required bool isRestDay,
    required double actualCalories,
    required double targetCalories,
    required double actualProtein,
    required double targetProtein,
    required double actualWaterMl,
    required double targetWaterMl,
    String? recoveryLevel,
    String? recoveryNote,
    bool isToday = true,
  }) {
    // 1. Workout Status
    String wStatus;
    if (isRestDay) {
      wStatus = AccountabilityStatus.notApplicable;
    } else if (workoutCompleted) {
      wStatus = AccountabilityStatus.completed;
    } else if (isToday) {
      wStatus = AccountabilityStatus.pending;
    } else {
      wStatus = AccountabilityStatus.notCompleted;
    }

    // 2. Calorie Status
    String cStatus;
    if (actualCalories <= 0) {
      cStatus = isToday ? AccountabilityStatus.pending : AccountabilityStatus.notCompleted;
    } else {
      final safeTarget = targetCalories > 0 ? targetCalories : 2000.0;
      final diff = (actualCalories - safeTarget).abs();
      final diffPercent = diff / safeTarget;

      if (diffPercent <= AccountabilityThresholds.calorieCompleteTolerancePercent ||
          diff <= AccountabilityThresholds.calorieAbsoluteToleranceKcal) {
        cStatus = AccountabilityStatus.completed;
      } else if (diffPercent <= AccountabilityThresholds.caloriePartialTolerancePercent) {
        cStatus = AccountabilityStatus.partiallyCompleted;
      } else {
        cStatus = AccountabilityStatus.notCompleted;
      }
    }

    // 3. Protein Status
    String pStatus;
    if (actualProtein <= 0) {
      pStatus = isToday ? AccountabilityStatus.pending : AccountabilityStatus.notCompleted;
    } else {
      final safeTarget = targetProtein > 0 ? targetProtein : 140.0;
      final ratio = actualProtein / safeTarget;

      if (ratio >= AccountabilityThresholds.proteinCompleteThresholdRatio) {
        pStatus = AccountabilityStatus.completed;
      } else if (ratio >= AccountabilityThresholds.proteinPartialThresholdRatio) {
        pStatus = AccountabilityStatus.partiallyCompleted;
      } else {
        pStatus = AccountabilityStatus.notCompleted;
      }
    }

    // 4. Water Status
    String wtStatus;
    if (actualWaterMl <= 0) {
      wtStatus = isToday ? AccountabilityStatus.pending : AccountabilityStatus.notCompleted;
    } else {
      final safeTarget = targetWaterMl > 0 ? targetWaterMl : 2500.0;
      final ratio = actualWaterMl / safeTarget;

      if (ratio >= AccountabilityThresholds.waterCompleteThresholdRatio) {
        wtStatus = AccountabilityStatus.completed;
      } else if (ratio >= AccountabilityThresholds.waterPartialThresholdRatio) {
        wtStatus = AccountabilityStatus.partiallyCompleted;
      } else {
        wtStatus = AccountabilityStatus.notCompleted;
      }
    }

    // 5. Recovery Status
    String rStatus;
    if (recoveryLevel == null || recoveryLevel.trim().isEmpty) {
      rStatus = isToday ? AccountabilityStatus.pending : AccountabilityStatus.notCompleted;
    } else if (recoveryLevel.toLowerCase() == 'poor') {
      rStatus = AccountabilityStatus.partiallyCompleted;
    } else {
      rStatus = AccountabilityStatus.completed;
    }

    // 6. Score Calculation (Strictly normalizes earned points over assessable points)
    final double maxPoints = isRestDay ? 80.0 : 100.0;
    double earnedPoints = 0.0;

    // Workout points
    if (!isRestDay) {
      if (wStatus == AccountabilityStatus.completed) {
        earnedPoints += AccountabilityThresholds.standardComponentWeight;
      } else if (wStatus == AccountabilityStatus.partiallyCompleted) {
        earnedPoints += AccountabilityThresholds.standardComponentWeight * 0.5;
      }
    }

    // Calories points
    if (cStatus == AccountabilityStatus.completed) {
      earnedPoints += AccountabilityThresholds.standardComponentWeight;
    } else if (cStatus == AccountabilityStatus.partiallyCompleted) {
      earnedPoints += AccountabilityThresholds.standardComponentWeight * 0.5;
    }

    // Protein points
    if (pStatus == AccountabilityStatus.completed) {
      earnedPoints += AccountabilityThresholds.standardComponentWeight;
    } else if (pStatus == AccountabilityStatus.partiallyCompleted) {
      earnedPoints += AccountabilityThresholds.standardComponentWeight * 0.5;
    }

    // Water points
    if (wtStatus == AccountabilityStatus.completed) {
      earnedPoints += AccountabilityThresholds.standardComponentWeight;
    } else if (wtStatus == AccountabilityStatus.partiallyCompleted) {
      earnedPoints += AccountabilityThresholds.standardComponentWeight * 0.5;
    }

    // Recovery points
    if (rStatus == AccountabilityStatus.completed) {
      if (recoveryLevel?.toLowerCase() == 'moderate') {
        earnedPoints += AccountabilityThresholds.standardComponentWeight * 0.75; // 15 pts
      } else {
        earnedPoints += AccountabilityThresholds.standardComponentWeight; // 20 pts (good)
      }
    } else if (rStatus == AccountabilityStatus.partiallyCompleted) {
      earnedPoints += AccountabilityThresholds.standardComponentWeight * 0.5; // 10 pts (poor)
    }

    final double score = maxPoints > 0 ? ((earnedPoints / maxPoints) * 100.0).clamp(0.0, 100.0) : 0.0;

    return TransformationDailyLog(
      planId: planId,
      dayNumber: dayNumber,
      dateString: dateString,
      workoutStatus: wStatus,
      calorieStatus: cStatus,
      proteinStatus: pStatus,
      waterStatus: wtStatus,
      recoveryStatus: rStatus,
      dailyAdherenceScore: score,
      lastUpdated: DateTime.now(),
      actualCalories: actualCalories,
      targetCalories: targetCalories,
      actualProtein: actualProtein,
      targetProtein: targetProtein,
      actualWaterMl: actualWaterMl,
      targetWaterMl: targetWaterMl,
      recoveryLevel: recoveryLevel,
      recoveryNote: recoveryNote,
      isRestDay: isRestDay,
    );
  }

  TransformationDailyLog copyWith({
    String? planId,
    int? dayNumber,
    String? dateString,
    String? workoutStatus,
    String? calorieStatus,
    String? proteinStatus,
    String? waterStatus,
    String? recoveryStatus,
    double? dailyAdherenceScore,
    DateTime? lastUpdated,
    double? actualCalories,
    double? targetCalories,
    double? actualProtein,
    double? targetProtein,
    double? actualWaterMl,
    double? targetWaterMl,
    String? recoveryLevel,
    String? recoveryNote,
    bool? isRestDay,
  }) {
    return TransformationDailyLog(
      planId: planId ?? this.planId,
      dayNumber: dayNumber ?? this.dayNumber,
      dateString: dateString ?? this.dateString,
      workoutStatus: workoutStatus ?? this.workoutStatus,
      calorieStatus: calorieStatus ?? this.calorieStatus,
      proteinStatus: proteinStatus ?? this.proteinStatus,
      waterStatus: waterStatus ?? this.waterStatus,
      recoveryStatus: recoveryStatus ?? this.recoveryStatus,
      dailyAdherenceScore: dailyAdherenceScore ?? this.dailyAdherenceScore,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      actualCalories: actualCalories ?? this.actualCalories,
      targetCalories: targetCalories ?? this.targetCalories,
      actualProtein: actualProtein ?? this.actualProtein,
      targetProtein: targetProtein ?? this.targetProtein,
      actualWaterMl: actualWaterMl ?? this.actualWaterMl,
      targetWaterMl: targetWaterMl ?? this.targetWaterMl,
      recoveryLevel: recoveryLevel ?? this.recoveryLevel,
      recoveryNote: recoveryNote ?? this.recoveryNote,
      isRestDay: isRestDay ?? this.isRestDay,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'dayNumber': dayNumber,
      'dateString': dateString,
      'workoutStatus': workoutStatus,
      'calorieStatus': calorieStatus,
      'proteinStatus': proteinStatus,
      'waterStatus': waterStatus,
      'recoveryStatus': recoveryStatus,
      'dailyAdherenceScore': dailyAdherenceScore,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'actualCalories': actualCalories,
      'targetCalories': targetCalories,
      'actualProtein': actualProtein,
      'targetProtein': targetProtein,
      'actualWaterMl': actualWaterMl,
      'targetWaterMl': targetWaterMl,
      'recoveryLevel': recoveryLevel,
      'recoveryNote': recoveryNote,
      'isRestDay': isRestDay,
    };
  }

  factory TransformationDailyLog.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return TransformationDailyLog(
      planId: map['planId']?.toString() ?? '',
      dayNumber: (map['dayNumber'] as num?)?.toInt() ?? 1,
      dateString: map['dateString']?.toString() ?? '',
      workoutStatus: map['workoutStatus']?.toString() ?? AccountabilityStatus.pending,
      calorieStatus: map['calorieStatus']?.toString() ?? AccountabilityStatus.pending,
      proteinStatus: map['proteinStatus']?.toString() ?? AccountabilityStatus.pending,
      waterStatus: map['waterStatus']?.toString() ?? AccountabilityStatus.pending,
      recoveryStatus: map['recoveryStatus']?.toString() ?? AccountabilityStatus.pending,
      dailyAdherenceScore: (map['dailyAdherenceScore'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: parseDate(map['lastUpdated']),
      actualCalories: (map['actualCalories'] as num?)?.toDouble() ?? 0.0,
      targetCalories: (map['targetCalories'] as num?)?.toDouble() ?? 2000.0,
      actualProtein: (map['actualProtein'] as num?)?.toDouble() ?? 0.0,
      targetProtein: (map['targetProtein'] as num?)?.toDouble() ?? 140.0,
      actualWaterMl: (map['actualWaterMl'] as num?)?.toDouble() ?? 0.0,
      targetWaterMl: (map['targetWaterMl'] as num?)?.toDouble() ?? 2500.0,
      recoveryLevel: map['recoveryLevel']?.toString(),
      recoveryNote: map['recoveryNote']?.toString(),
      isRestDay: map['isRestDay'] as bool? ?? false,
    );
  }
}
