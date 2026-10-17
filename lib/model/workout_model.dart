class WorkoutModel {
  final String id;
  final String name;
  final int setNumber;
  final int repNumber;
  final DateTime dateTime;

  WorkoutModel({
    required this.id,
    required this.name,
    required this.repNumber,
    required this.setNumber,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'repNumber': repNumber,
      'setNumber': setNumber,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory WorkoutModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    final dt = map['dateTime'];
    if (dt is String) {
      parsedDate = DateTime.tryParse(dt) ?? DateTime.now();
    } else if (dt is DateTime) {
      parsedDate = dt;
    } else {
      parsedDate = DateTime.now();
    }
    return WorkoutModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      repNumber: (map['repNumber'] as num?)?.toInt() ?? 0,
      setNumber: (map['setNumber'] as num?)?.toInt() ?? 0,
      dateTime: parsedDate,
    );
  }
}
