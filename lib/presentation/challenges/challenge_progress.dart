import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Where the user is in the 30-day Six-Pack challenge.
///
/// Pure value object so the "which day is open / completed / waiting" rules
/// can be tested without Firebase.
class ChallengeProgress {
  const ChallengeProgress({this.lastCompletedDay = 0, this.completionDate});

  /// Tolerates missing keys and numeric types coming back from Firestore.
  factory ChallengeProgress.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ChallengeProgress();
    final rawDay = map['lastCompletedDay'];
    final rawDate = map['completionDate'];
    return ChallengeProgress(
      lastCompletedDay: rawDay is num ? rawDay.toInt().clamp(0, 30).toInt() : 0,
      completionDate: rawDate is String
          ? DateTime.tryParse(rawDate)?.toLocal()
          : null,
    );
  }

  final int lastCompletedDay;
  final DateTime? completionDate;

  /// The next day the user is allowed to start.
  int get currentDay => lastCompletedDay + 1;

  bool isCompleted(int day) => day <= lastCompletedDay;

  /// Finishing [day] only moves progress forward. Re-doing an earlier day must
  /// never rewind the challenge or re-lock tomorrow's day.
  bool advancesProgress(int day) => day > lastCompletedDay;

  /// Why a tile is not openable yet, in words the user can act on.
  ///
  /// [day] must be locked (a future day, or today's slot after finishing).
  String lockedMessage(int day, DateTime now) {
    if (day == currentDay && isCompletedToday(now)) {
      return "You've finished today's workout. Day $day unlocks tomorrow.";
    }
    final next = currentDay;
    if (next > 30) return 'You have completed the whole challenge!';
    return 'Day $day unlocks after you finish Day ${day - 1}. '
        "You're on Day $next.";
  }

  bool isCompletedToday(DateTime now) {
    final d = completionDate;
    return d != null &&
        d.year == now.year &&
        d.month == now.month &&
        d.day == now.day;
  }
}

/// Storage seam for the challenge screens (Firestore in the app, a fake in
/// tests).
abstract class SixPackProgressStore {
  Future<ChallengeProgress> load();

  /// Moves `lastCompletedDay` / `completionDate` forward. May throw
  /// [TimeoutException] when the write is still waiting for the network (it is
  /// queued by Firestore and will sync later).
  Future<void> saveCompletion(int day);

  /// Adds the finished day to the general workout history.
  Future<void> recordWorkout(int day);

  /// Saves the free-text feedback left after finishing Day 30.
  Future<void> saveFeedback(String text);
}

class FirestoreSixPackProgressStore implements SixPackProgressStore {
  const FirestoreSixPackProgressStore({
    this.loadTimeout = const Duration(seconds: 8),
    this.saveTimeout = const Duration(seconds: 8),
  });

  final Duration loadTimeout;
  final Duration saveTimeout;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  Future<ChallengeProgress> load() async {
    final uid = _uid;
    if (uid == null) return const ChallengeProgress();
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);

    DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await ref.get().timeout(loadTimeout);
    } on TimeoutException {
      snap = await ref.get(const GetOptions(source: Source.cache));
    } on FirebaseException {
      snap = await ref.get(const GetOptions(source: Source.cache));
    }

    final raw = snap.data()?['progress'];
    final challenge = raw is Map ? raw['sixPackChallenge'] : null;
    return ChallengeProgress.fromMap(
      challenge is Map ? Map<String, dynamic>.from(challenge) : null,
    );
  }

  @override
  Future<void> saveCompletion(int day) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'progress.sixPackChallenge.lastCompletedDay': day,
      'progress.sixPackChallenge.completionDate':
          DateTime.now().toIso8601String(),
    }).timeout(saveTimeout);
  }

  @override
  Future<void> saveFeedback(String text) async {
    final uid = _uid;
    final trimmed = text.trim();
    if (uid == null || trimmed.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('challengeFeedback')
        .doc('sixPack30')
        .set({
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> recordWorkout(int day) async {
    final uid = _uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('finishedWorkouts')
        .doc(uid)
        .collection('finishedWorkoutsData')
        .add({
      'name': 'Six-Pack Challenge Day $day',
      'repNumber': 0,
      'setNumber': 3,
      'dateTime': DateTime.now(),
      'id': 'challenge_day_$day',
    });
  }
}
