import 'package:cloud_firestore/cloud_firestore.dart';

class DataBase {
  final String uid;

  DataBase(this.uid);
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference mealCollection =
      FirebaseFirestore.instance.collection('meals');

  /// Sub-collections stored under users/{uid}.
  static const List<String> userSubcollections = [
    'active_transformation',
    'transformation_history',
    'workout_logs',
    'workout_sessions',
    'mealRecords',
    'dailyReset',
    'challengeFeedback',
    'progress_photos',
  ];

  /// Top-level collections keyed by uid, with their sub-collections.
  static const Map<String, List<String>> perUserCollections = {
    'workouts': ['workoutData'],
    'allWorkouts': ['allWorkoutsData'],
    'finishedWorkouts': ['finishedWorkoutsData'],
    'meals': ['mealData', 'waterData'],
    'statistics': [],
    'flSpots': ['flSpotsData'],
    'measurementSpots': [
      'chest',
      'waist',
      'hips',
      'thigh',
      'calf',
      'biceps',
      'shoulders',
    ],
  };

  /// Deletes everything this app stores for the user (Play / App Store
  /// account-deletion requirement). Firestore does not cascade deletes, so
  /// each sub-collection is cleared before its parent document.
  Future<void> deleteUserData() async {
    final db = FirebaseFirestore.instance;
    for (final entry in perUserCollections.entries) {
      final parent = db.collection(entry.key).doc(uid);
      for (final sub in entry.value) {
        await _deleteCollection(parent.collection(sub));
      }
      await parent.delete();
    }
    final userDoc = userCollection.doc(uid);
    for (final sub in userSubcollections) {
      await _deleteCollection(userDoc.collection(sub));
    }
    await userDoc.delete();
  }

  Future<void> _deleteCollection(CollectionReference ref) async {
    while (true) {
      final snap = await ref.limit(200).get();
      if (snap.docs.isEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      if (snap.docs.length < 200) return;
    }
  }

  Future<void> deleteMealData() {
    return mealCollection.doc(uid).delete();
  }
}
