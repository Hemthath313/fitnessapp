import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';

class WorkoutLogService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // In-memory cache for fast Ghost Value retrieval
  static final Map<String, WorkoutLog> _lastLogCache = {};
  static final List<WorkoutLog> _localLogs = [];
  static final List<WorkoutSession> _localSessions = [];

  static List<WorkoutLog> get localLogsForTesting =>
      List<WorkoutLog>.unmodifiable(_localLogs);

  static List<WorkoutSession> get localSessionsForTesting =>
      List<WorkoutSession>.unmodifiable(_localSessions);

  static String _cacheKeyFor(String rawExerciseName) {
    final cleanName = ExerciseData.normalizeExerciseName(rawExerciseName);
    final catalogExercise = ExerciseData.findByName(cleanName);
    return (catalogExercise?.name ?? cleanName).trim().toLowerCase();
  }

  /// Synchronously returns the cached last log for [rawExerciseName], if available.
  static WorkoutLog? getCachedLastLog(String rawExerciseName) {
    final cleanName = ExerciseData.normalizeExerciseName(rawExerciseName);
    final rawKey = cleanName.trim().toLowerCase();
    final canonicalKey = _cacheKeyFor(rawExerciseName);
    return _lastLogCache[canonicalKey] ?? _lastLogCache[rawKey];
  }

  /// Populates the in-memory last-log cache for [exerciseName] (and its canonical alias).
  static void seedLastLogCache(String exerciseName, WorkoutLog log) {
    final cleanName = ExerciseData.normalizeExerciseName(exerciseName);
    final rawKey = cleanName.trim().toLowerCase();
    final canonicalKey = _cacheKeyFor(exerciseName);
    if (rawKey.isNotEmpty) {
      _lastLogCache[rawKey] = log;
    }
    if (canonicalKey.isNotEmpty) {
      _lastLogCache[canonicalKey] = log;
    }
  }

  /// Clears the in-memory last-log cache.
  static void clearLastLogCache() {
    _lastLogCache.clear();
    _localLogs.clear();
    _localSessions.clear();
  }

  String? get _uid {
    try {
      return _auth.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  CollectionReference get _logsCollection {
    if (_uid == null) throw Exception("User not authenticated");
    return _db.collection('users').doc(_uid).collection('workout_logs');
  }

  CollectionReference get _sessionsCollection {
    if (_uid == null) throw Exception("User not authenticated");
    return _db.collection('users').doc(_uid).collection('workout_sessions');
  }

  Future<void> addLog(WorkoutLog log) async {
    final savedLog = log.id.isNotEmpty
        ? log
        : WorkoutLog(
            id: 'local_log_${DateTime.now().microsecondsSinceEpoch}_${_localLogs.length}',
            exerciseName: log.exerciseName,
            date: log.date,
            sets: log.sets,
            notes: log.notes,
            category: log.category,
          );
    _localLogs.insert(0, savedLog);
    seedLastLogCache(savedLog.exerciseName, savedLog);

    if (_uid != null) {
      await _logsCollection.add(log.toMap());
    }
  }

  Stream<List<WorkoutLog>> getLogs() {
    if (_uid == null) {
      return Stream<List<WorkoutLog>>.value(List<WorkoutLog>.from(_localLogs));
    }
    return _logsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutLog.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> deleteLog(String id) async {
    _localLogs.removeWhere((l) => l.id == id);
    if (_uid != null) {
      await _logsCollection.doc(id).delete();
    }
  }

  /// Ghost Values: Query latest completed log for an exercise to pre-fill past weights
  Future<WorkoutLog?> getLastExerciseLog(String rawExerciseName) async {
    final cached = getCachedLastLog(rawExerciseName);
    if (cached != null) {
      return cached;
    }

    final cleanName = ExerciseData.normalizeExerciseName(rawExerciseName);

    try {
      if (_uid == null) return null;

      // Query latest log where exerciseName matches
      final snapshot = await _logsCollection
          .where('exerciseName', isEqualTo: cleanName)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final log = WorkoutLog.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
          snapshot.docs.first.id,
        );
        seedLastLogCache(cleanName, log);
        return log;
      }
    } catch (e) {
      print('Error querying last exercise log for $cleanName: $e');
    }
    return null;
  }

  /// Atomic Batch Save: Bridges WorkoutSession, WorkoutLog, and finishedWorkoutsData in 1 transaction!
  Future<void> saveWorkoutSession(WorkoutSession session) async {
    _localSessions.insert(0, session);
    for (var ex in session.exercises) {
      final completedSets = ex.sets.where((s) => s.isCompleted).toList();
      if (completedSets.isNotEmpty) {
        final localLog = WorkoutLog(
          id: 'local_session_log_${DateTime.now().microsecondsSinceEpoch}_${_localLogs.length}',
          exerciseName: ex.exerciseName,
          date: session.completedAt ?? session.startedAt,
          sets: completedSets,
          notes: ex.notes,
          category: 'Strength',
        );
        _localLogs.insert(0, localLog);
        seedLastLogCache(ex.exerciseName, localLog);
      }
    }

    if (_uid == null) return;

    final batch = _db.batch();

    // 1. Write canonical WorkoutSession document
    final sessionDocRef = _sessionsCollection.doc(session.id.isNotEmpty ? session.id : null);
    batch.set(sessionDocRef, session.toMap());

    // 2. Write individual WorkoutLog documents for backward-compatibility with History & Analytics
    for (var ex in session.exercises) {
      final completedSets = ex.sets.where((s) => s.isCompleted).toList();
      if (completedSets.isNotEmpty) {
        final logDocRef = _logsCollection.doc();
        final log = WorkoutLog(
          id: logDocRef.id,
          exerciseName: ex.exerciseName,
          date: session.completedAt ?? session.startedAt,
          sets: completedSets,
          notes: ex.notes,
          category: 'Strength',
        );
        batch.set(logDocRef, log.toMap());
        seedLastLogCache(ex.exerciseName, log);
      }
    }

    // 3. Write to finishedWorkoutsData for backward-compatibility with calendars and old streak checks
    final finishedDocRef = _db
        .collection('finishedWorkouts')
        .doc(_uid)
        .collection('finishedWorkoutsData')
        .doc();
    batch.set(finishedDocRef, {
      'name': session.dayName,
      'repNumber': 0,
      'setNumber': session.exercises.where((e) => e.isCompleted).length,
      'dateTime': session.completedAt ?? session.startedAt,
      'id': sessionDocRef.id,
      'status': session.status,
      'totalVolume': session.totalVolume,
    });

    await batch.commit();
  }

  Stream<List<WorkoutSession>> getSessions() {
    if (_uid == null) {
      return Stream<List<WorkoutSession>>.value(
          List<WorkoutSession>.from(_localSessions));
    }
    return _sessionsCollection
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutSession.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<WorkoutSession?> getSessionById(String id) async {
    for (final s in _localSessions) {
      if (s.id == id) return s;
    }
    try {
      if (_uid == null) return null;
      final doc = await _sessionsCollection.doc(id).get();
      if (doc.exists && doc.data() != null) {
        return WorkoutSession.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print('Error fetching session $id: $e');
    }
    return null;
  }

  Future<List<WorkoutSession>> getSessionsFuture({int limit = 100}) async {
    if (_uid == null) {
      return _localSessions.take(limit).toList();
    }
    try {
      final snap = await _sessionsCollection
          .orderBy('startedAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs
          .map((doc) => WorkoutSession.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error fetching sessions future: $e');
      return [];
    }
  }

  Future<void> deleteSession(String id) async {
    await _sessionsCollection.doc(id).delete();
  }
}

