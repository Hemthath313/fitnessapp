import 'package:cloud_firestore/cloud_firestore.dart';

enum PRType {
  heaviestWeight,
  estimated1RM,
  repPR,
}

class PersonalRecord {
  final String exerciseName;
  final double weight;
  final int reps;
  final double estimated1RM;
  final DateTime achievedAt;
  final PRType type;
  final String? sessionId;

  const PersonalRecord({
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.estimated1RM,
    required this.achievedAt,
    this.type = PRType.heaviestWeight,
    this.sessionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'exerciseName': exerciseName,
      'weight': weight,
      'reps': reps,
      'estimated1RM': estimated1RM,
      'achievedAt': Timestamp.fromDate(achievedAt),
      'type': type.name,
      'sessionId': sessionId,
    };
  }

  factory PersonalRecord.fromMap(Map<String, dynamic> map) {
    return PersonalRecord(
      exerciseName: map['exerciseName'] ?? '',
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      reps: (map['reps'] as num?)?.toInt() ?? 0,
      estimated1RM: (map['estimated1RM'] as num?)?.toDouble() ?? 0.0,
      achievedAt: (map['achievedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: PRType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PRType.heaviestWeight,
      ),
      sessionId: map['sessionId'],
    );
  }
}
