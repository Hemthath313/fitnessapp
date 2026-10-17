import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/model/workout_log.dart';

class SessionExercise {
  final String exerciseName;
  final int order;
  final List<WorkoutSet> sets;
  final String? notes;
  final bool isCompleted;

  SessionExercise({
    required this.exerciseName,
    required this.order,
    required this.sets,
    this.notes,
    this.isCompleted = false,
  });

  double get totalVolume {
    double vol = 0;
    for (var s in sets) {
      if (s.isCompleted) {
        vol += s.weight * s.reps;
      }
    }
    return vol;
  }

  int get completedSetsCount {
    return sets.where((s) => s.isCompleted).length;
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseName': exerciseName,
      'order': order,
      'sets': sets.map((s) => s.toMap()).toList(),
      'notes': notes,
      'isCompleted': isCompleted,
    };
  }

  factory SessionExercise.fromMap(Map<String, dynamic> map) {
    return SessionExercise(
      exerciseName: map['exerciseName'] ?? '',
      order: (map['order'] as num?)?.toInt() ?? 0,
      sets: (map['sets'] as List<dynamic>?)
              ?.map((s) => WorkoutSet.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      notes: map['notes'],
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }

  SessionExercise copyWith({
    String? exerciseName,
    int? order,
    List<WorkoutSet>? sets,
    String? notes,
    bool? isCompleted,
  }) {
    return SessionExercise(
      exerciseName: exerciseName ?? this.exerciseName,
      order: order ?? this.order,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class WorkoutSession {
  final String id;
  final String userId;
  final String workoutName;
  final String dayName;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int durationSeconds;
  final String status; // 'completed' or 'partial'
  final double totalVolume;
  final List<SessionExercise> exercises;

  WorkoutSession({
    required this.id,
    required this.userId,
    required this.workoutName,
    required this.dayName,
    required this.startedAt,
    this.completedAt,
    this.durationSeconds = 0,
    this.status = 'completed',
    required this.totalVolume,
    required this.exercises,
  });

  bool get isPartial => status == 'partial';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'workoutName': workoutName,
      'dayName': dayName,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'durationSeconds': durationSeconds,
      'status': status,
      'totalVolume': totalVolume,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map, String documentId) {
    return WorkoutSession(
      id: documentId,
      userId: map['userId'] ?? '',
      workoutName: map['workoutName'] ?? '',
      dayName: map['dayName'] ?? '',
      startedAt: (map['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      status: map['status'] ?? 'completed',
      totalVolume: (map['totalVolume'] as num?)?.toDouble() ?? 0.0,
      exercises: (map['exercises'] as List<dynamic>?)
              ?.map((e) => SessionExercise.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
