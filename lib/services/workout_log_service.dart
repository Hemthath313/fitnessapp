import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/services/session_edit.dart';

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

  /// Saves a corrected [edited] version of [original] and keeps the data that
  /// was mirrored from it in step: the per-exercise logs (used by progression,
  /// analytics and the plan hints) and the legacy finished-workout entry.
  Future<void> updateSession(
      WorkoutSession original, WorkoutSession edited) async {
    final date = original.completedAt ?? original.startedAt;
    final keepNames =
        edited.exercises.map((e) => e.exerciseName).toSet();

    // In-memory copies (offline / signed-out use).
    final li = _localSessions.indexWhere((s) => s.id == original.id);
    if (li >= 0) _localSessions[li] = edited;
    for (final ex in original.exercises) {
      final idx = _localLogs.indexWhere(
          (l) => l.exerciseName == ex.exerciseName && l.date == date);
      if (idx < 0) continue;
      final match = edited.exercises
          .where((e) => e.exerciseName == ex.exerciseName)
          .toList();
      final sets = match.isEmpty ? <WorkoutSet>[] : SessionEdit.loggedSets(match.first);
      if (sets.isEmpty) {
        _localLogs.removeAt(idx);
      } else {
        final old = _localLogs[idx];
        final updated = WorkoutLog(
          id: old.id,
          exerciseName: old.exerciseName,
          date: old.date,
          sets: sets,
          notes: old.notes,
          category: old.category,
        );
        _localLogs[idx] = updated;
        seedLastLogCache(updated.exerciseName, updated);
      }
    }

    if (_uid == null) return;

    // Read what has to change first, then write everything in one batch.
    final logSnaps = <String, QuerySnapshot>{};
    for (final ex in original.exercises) {
      logSnaps[ex.exerciseName] = await _logsCollection
          .where('exerciseName', isEqualTo: ex.exerciseName)
          .where('date', isEqualTo: Timestamp.fromDate(date))
          .get();
    }
    final finishedSnap = await _db
        .collection('finishedWorkouts')
        .doc(_uid)
        .collection('finishedWorkoutsData')
        .where('id', isEqualTo: original.id)
        .get();

    final batch = _db.batch();
    batch.set(_sessionsCollection.doc(original.id), edited.toMap());

    for (final entry in logSnaps.entries) {
      final match =
          edited.exercises.where((e) => e.exerciseName == entry.key).toList();
      final sets = match.isEmpty ? <WorkoutSet>[] : SessionEdit.loggedSets(match.first);
      for (final doc in entry.value.docs) {
        if (sets.isEmpty || !keepNames.contains(entry.key)) {
          batch.delete(doc.reference);
        } else {
          batch.update(doc.reference, {
            'sets': sets.map((s) => s.toMap()).toList(),
          });
        }
      }
    }
    for (final doc in finishedSnap.docs) {
      batch.update(doc.reference, {
        'setNumber': edited.exercises.where((e) => e.isCompleted).length,
        'totalVolume': edited.totalVolume,
      });
    }
    await batch.commit();
  }
}

