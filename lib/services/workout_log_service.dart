import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/model/workout_log.dart';

class WorkoutLogService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference get _logsCollection {
    if (_uid == null) throw Exception("User not authenticated");
    return _db.collection('users').doc(_uid).collection('workout_logs');
  }

  Future<void> addLog(WorkoutLog log) async {
    await _logsCollection.add(log.toMap());
  }

  Stream<List<WorkoutLog>> getLogs() {
    return _logsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutLog.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> deleteLog(String id) async {
    await _logsCollection.doc(id).delete();
  }
}
