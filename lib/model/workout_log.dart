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
      sets: (map['sets'] as List<dynamic>?)
              ?.map((s) => WorkoutSet.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      notes: map['notes'],
      category: map['category'] ?? 'General',
    );
  }
}

class WorkoutSet {
  final double weight;
  final int reps;

  WorkoutSet({required this.weight, required this.reps});

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'reps': reps,
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      weight: (map['weight'] as num).toDouble(),
      reps: map['reps'] as int,
    );
  }
}
