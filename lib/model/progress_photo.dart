import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressPhoto {
  final String id;
  final String imageUrl;
  final DateTime date;
  final double? weight;
  final String? notes;
  final String category; // 'front', 'side', 'back'

  ProgressPhoto({
    required this.id,
    required this.imageUrl,
    required this.date,
    this.weight,
    this.notes,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'notes': notes,
      'category': category,
    };
  }

  factory ProgressPhoto.fromMap(Map<String, dynamic> map, String documentId) {
    return ProgressPhoto(
      id: documentId,
      imageUrl: map['imageUrl'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      weight: map['weight']?.toDouble(),
      notes: map['notes'],
      category: map['category'] ?? 'front',
    );
  }

  // Helper to get a display-friendly category name
  String get categoryDisplay {
    switch (category) {
      case 'front':
        return 'Front View';
      case 'side':
        return 'Side View';
      case 'back':
        return 'Back View';
      default:
        return category;
    }
  }
}
