import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutLog {
  final String id;
  final String exerciseName;
  final DateTime date;
  final List<WorkoutSet> sets;
  final String? notes;
  final String category;

  WorkoutLog({
    required this.id,
    required this.exerciseName,
    required this.date,
    required this.sets,
    this.notes,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exerciseName': exerciseName,
      'date': Timestamp.fromDate(date),
      'sets': sets.map((s) => s.toMap()).toList(),
      'notes': notes,
      'category': category,
    };
  }

  factory WorkoutLog.fromMap(Map<String, dynamic> map, String documentId) {
    return WorkoutLog(
      id: documentId,
      exerciseName: map['exerciseName'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      // Every set in a log is one that was performed. Older standalone logs
      // were saved with the completed flag off, so read them as completed.
      sets: (map['sets'] as List<dynamic>?)
              ?.map((s) => WorkoutSet.fromMap(s as Map<String, dynamic>))
              .map((s) => s.isCompleted
                  ? s
                  : WorkoutSet(
                      weight: s.weight,
                      reps: s.reps,
                      type: s.type,
                      rpe: s.rpe,
                      isCompleted: true,
                    ))
              .toList() ??
          [],
      notes: map['notes'],
      category: map['category'] ?? 'General',
    );
  }
}

enum SetType { normal, warmup, drop, failure }

class WorkoutSet {
  final double weight;
  final int reps;
  final SetType type;
  final int? rpe;
  final bool isCompleted;

  WorkoutSet({
    required this.weight,
    required this.reps,
    this.type = SetType.normal,
    this.rpe,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'reps': reps,
      'type': type.name,
      if (rpe != null) 'rpe': rpe,
      'isCompleted': isCompleted,
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      reps: (map['reps'] as num?)?.toInt() ?? 0,
      type: SetType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SetType.normal,
      ),
      rpe: (map['rpe'] as num?)?.toInt(),
      isCompleted: map['isCompleted'] as bool? ?? true,
    );
  }

  WorkoutSet copyWith({
    double? weight,
    int? reps,
    SetType? type,
    int? rpe,
    bool? isCompleted,
  }) {
    return WorkoutSet(
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      type: type ?? this.type,
      rpe: rpe ?? this.rpe,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
