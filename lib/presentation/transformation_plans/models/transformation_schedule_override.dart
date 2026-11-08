import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a scheduling override for a specific programme day.
/// Preserves the original programme sequence while allowing flexible calendar dates.
class TransformationScheduleOverride {
  final int dayNumber;
  final DateTime originalDate;
  final DateTime scheduledDate;
  final String status; // 'rescheduled', 'skipped', 'scheduled'
  final DateTime? updatedAt;
  final String? note;

  const TransformationScheduleOverride({
    required this.dayNumber,
    required this.originalDate,
    required this.scheduledDate,
    this.status = 'rescheduled',
    this.updatedAt,
    this.note,
  });

  bool get isSkipped => status == 'skipped';
  bool get isRescheduled => status == 'rescheduled';

  TransformationScheduleOverride copyWith({
    int? dayNumber,
    DateTime? originalDate,
    DateTime? scheduledDate,
    String? status,
    DateTime? updatedAt,
    String? note,
  }) {
    return TransformationScheduleOverride(
      dayNumber: dayNumber ?? this.dayNumber,
      originalDate: originalDate ?? this.originalDate,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayNumber': dayNumber,
      'originalDate': Timestamp.fromDate(originalDate),
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'status': status,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (note != null) 'note': note,
    };
  }

  factory TransformationScheduleOverride.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    final now = DateTime.now();
    return TransformationScheduleOverride(
      dayNumber: (map['dayNumber'] as num?)?.toInt() ?? 1,
      originalDate: parseDate(map['originalDate'], now),
      scheduledDate: parseDate(map['scheduledDate'], now),
      status: map['status']?.toString() ?? 'rescheduled',
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt'], now) : null,
      note: map['note']?.toString(),
    );
  }
}
