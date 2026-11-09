import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../progress/progress_data.dart';

class ProfileProvider with ChangeNotifier {
  final List<double> _weight = [];

  List<double> get weight {
    return [..._weight];
  }

  final List<FlSpot> _flSpots = [
    const FlSpot(
      1.0,
      10,
    ),
    const FlSpot(
      2.0,
      10,
    ),
    const FlSpot(
      3.0,
      10,
    ),
    const FlSpot(
      4.0,
      10,
    ),
    const FlSpot(
      5.0,
      10,
    ),
    const FlSpot(
      6.0,
      10,
    ),
    const FlSpot(
      7.0,
      10,
    ),
    const FlSpot(
      8.0,
      10,
    ),
    const FlSpot(
      9.0,
      10,
    ),
    const FlSpot(
      10.0,
      10,
    ),
    const FlSpot(
      11.0,
      10,
    ),
    const FlSpot(
      12.0,
      10,
    ),
  ];

  List<FlSpot> get flSpots {
    return [..._flSpots];
  }

  /// Every real weigh-in, oldest -> newest, with its true date.
  final List<TimedValue> _weightEntries = [];

  List<TimedValue> get weightEntries => List.unmodifiable(_weightEntries);

  /// Real, dated measurement readings per body part ('chest', 'waist', ...).
  final Map<String, List<TimedValue>> _measurementHistory = {};

  Map<String, List<TimedValue>> get measurementHistory =>
      Map.unmodifiable(_measurementHistory);

  static bool _sameEntries(List<TimedValue> a, List<TimedValue> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].date != b[i].date || a[i].value != b[i].value) return false;
    }
    return true;
  }

  Future<void> fetchAndSetWeight() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final double? weight = snapshot.get('weight');
      if (weight != null) {
        _weight.add(weight);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changeUsersWeight({
    required double weight,
    required double bmi,
    required double bmr,
    required int weightDateTime,
    required BuildContext context,
    DateTime? date,
    String? entryId,
  }) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      final when = date ?? DateTime.now();

      // Only the newest reading is the user's "current" weight. A back-dated
      // entry must not overwrite today's weight, BMI and calorie target.
      if (_weightEntries.isEmpty) {
        try {
          await fetchAndSetFlSpots();
        } catch (_) {}
      }
      if (ProgressData.isOnOrAfterLatest(_weightEntries, when)) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
          'weight': weight,
          'bmi': bmi,
          'bmr': bmr,
        });
      }

      // One reading per calendar day: logging again the same day corrects it,
      // a different day (even in the same month) adds a new point. When an
      // existing entry is being edited its document is updated directly.
      final dayKey = ProgressData.dayKey(when);
      final collection = FirebaseFirestore.instance
          .collection('flSpots')
          .doc(user?.uid)
          .collection('flSpotsData');

      final payload = {
        'weight': weight,
        'weightDateTime': when.month, // kept for older readers
        'dateKey': dayKey,
        'timestamp': when.millisecondsSinceEpoch,
      };

      if (entryId != null) {
        await collection.doc(entryId).update(payload);
      } else {
        final docSnapshot =
            await collection.where('dateKey', isEqualTo: dayKey).get();
        if (docSnapshot.docs.isNotEmpty) {
          await docSnapshot.docs.first.reference.update(payload);
        } else {
          await collection.doc().set(payload);
        }
      }

      await fetchAndSetFlSpots();
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes one weigh-in. Returns the new latest reading when the deleted
  /// one was the latest (so the caller can resync the profile weight), else
  /// null.
  Future<TimedValue?> deleteWeightEntry(TimedValue entry) async {
    final user = FirebaseAuth.instance.currentUser;
    final id = entry.id;
    if (user == null || id == null) return null;

    final wasLatest = _weightEntries.isNotEmpty && _weightEntries.last.id == id;
    await FirebaseFirestore.instance
        .collection('flSpots')
        .doc(user.uid)
        .collection('flSpotsData')
        .doc(id)
        .delete();

    await fetchAndSetFlSpots();
    return wasLatest && _weightEntries.isNotEmpty ? _weightEntries.last : null;
  }

  /// Saves the personal details sign-up collected. [bmi] and [bmr] are only
  /// written when the caller could recalculate them.
  Future<void> updatePersonalInfo({
    required String firstName,
    required String surname,
    required int age,
    required double height,
    required String gender,
    double? bmi,
    double? bmr,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'first name': firstName,
      'surname': surname,
      'age': age,
      'height': height,
      'gender': gender,
      if (bmi != null) 'bmi': bmi,
      if (bmr != null) 'bmr': bmr,
    });
    notifyListeners();
  }

  /// Sets (or, with null, clears) the user's goal weight in kg.
  Future<void> updateGoalWeight(double? goalWeight) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'goalWeight': goalWeight ?? FieldValue.delete(),
    });
  }

  /// Writes the user's current weight, BMI and calorie target.
  Future<void> updateProfileWeight({
    required double weight,
    required double bmi,
    required double bmr,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'weight': weight,
      'bmi': bmi,
      'bmr': bmr,
    });
  }

  Future<void> fetchAndSetFlSpots() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final flSpotSnapshot = await FirebaseFirestore.instance
          .collection('flSpots')
          .doc(user.uid)
          .collection('flSpotsData')
          .get();

      final now = DateTime.now();
      final loaded = <TimedValue>[];

      for (var doc in flSpotSnapshot.docs) {
        final data = doc.data();
        final w = data['weight'];
        if (w is! num || w <= 0) continue;

        DateTime? date;
        final ts = data['timestamp'];
        if (ts is num) {
          date = DateTime.fromMillisecondsSinceEpoch(ts.toInt());
        } else if (ts is Timestamp) {
          date = ts.toDate();
        } else {
          // Older entries only stored a month number.
          final month = data['weightDateTime'];
          if (month is num) {
            date = ProgressData.legacyMonthToDate(month.toInt(), now);
          }
        }
        if (date == null) continue;
        loaded.add(TimedValue(date, w.toDouble(), id: doc.id));
      }

      final entries = ProgressData.sorted(loaded);

      // Month-based spots still feed the profile page chart: latest reading
      // of each month this year, 10 = "no reading" placeholder.
      final spots = List<FlSpot>.generate(
          12, (i) => FlSpot((i + 1).toDouble(), 10));
      for (final e in entries) {
        if (e.date.year == now.year) {
          spots[e.date.month - 1] = FlSpot(e.date.month.toDouble(), e.value);
        }
      }

      final changed = !_sameEntries(_weightEntries, entries);
      _weightEntries
        ..clear()
        ..addAll(entries);
      _flSpots
        ..clear()
        ..addAll(spots);
      if (changed) notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUsersData({
    required String activity,
    required String goal,
    required double chest,
    required double shoulders,
    required double biceps,
    required double foreArm,
    required double waist,
    required double hips,
    required double thigh,
    required double calf,
    required double bmr,
    required BuildContext context,
  }) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      int timestamp = DateTime.now().millisecondsSinceEpoch;
      int month = DateTime.now().month;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'activity': activity,
        'bmr': bmr,
        'goal': goal,
        'chest': chest,
        'shoulders': shoulders,
        'biceps': biceps,
        'foreArm': foreArm,
        'waist': waist,
        'hips': hips,
        'thigh': thigh,
        'calf': calf,
      });

      // Save history for Pro features (Advanced Analytics)
      final measurements = {
        'chest': chest,
        'shoulders': shoulders,
        'biceps': biceps,
        'foreArm': foreArm,
        'waist': waist,
        'hips': hips,
        'thigh': thigh,
        'calf': calf,
      };

      final dayKey = ProgressData.dayKey(DateTime.now());
      for (var entry in measurements.entries) {
        if (entry.value <= 0) continue; // never record "not measured" as 0
        final collection = FirebaseFirestore.instance
            .collection('measurementSpots')
            .doc(user.uid)
            .collection(entry.key);

        // One reading per calendar day; a new day adds a new point even
        // within the same month.
        final docSnapshot =
            await collection.where('dateKey', isEqualTo: dayKey).get();

        if (docSnapshot.docs.isNotEmpty) {
          await docSnapshot.docs.first.reference.update({
            'value': entry.value,
            'timestamp': timestamp,
          });
        } else {
          await collection.add({
            'value': entry.value,
            'month': month,
            'dateKey': dayKey,
            'timestamp': timestamp,
          });
        }
      }

      await loadMeasurementHistory();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<FlSpot>> fetchMeasurementSpots(String type) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('measurementSpots')
          .doc(user.uid)
          .collection(type)
          .orderBy('month')
          .get();

      // Several readings can now exist in one month: keep the latest per
      // month so the month-based charts keep one point per x.
      final latestPerMonth = <int, MapEntry<num, double>>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final month = data['month'];
        final value = data['value'];
        if (month is! num || value is! num) continue;
        final ts = (data['timestamp'] as num?) ?? 0;
        final existing = latestPerMonth[month.toInt()];
        if (existing == null || ts >= existing.key) {
          latestPerMonth[month.toInt()] = MapEntry(ts, value.toDouble());
        }
      }
      final months = latestPerMonth.keys.toList()..sort();
      return [
        for (final m in months) FlSpot(m.toDouble(), latestPerMonth[m]!.value),
      ];
    } catch (e) {
      debugPrint('Error fetching measurement spots for $type: $e');
      return [];
    }
  }

  static const List<String> _trackedMeasurements = [
    'chest',
    'shoulders',
    'biceps',
    'foreArm',
    'waist',
    'hips',
    'thigh',
    'calf',
  ];

  /// Loads real, dated readings for every tracked body part.
  Future<void> loadMeasurementHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final results = await Future.wait(_trackedMeasurements.map((part) async {
        final snapshot = await FirebaseFirestore.instance
            .collection('measurementSpots')
            .doc(user.uid)
            .collection(part)
            .get();

        final entries = <TimedValue>[];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final value = data['value'];
          if (value is! num || value <= 0) continue;
          final ts = data['timestamp'];
          if (ts is! num) continue;
          entries.add(TimedValue(
            DateTime.fromMillisecondsSinceEpoch(ts.toInt()),
            value.toDouble(),
          ));
        }
        return MapEntry(part, ProgressData.sorted(entries));
      }));
      final loaded = Map<String, List<TimedValue>>.fromEntries(results);

      _measurementHistory
        ..clear()
        ..addAll(loaded);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading measurement history: $e');
    }
  }
}
