import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StatisticsProvider with ChangeNotifier {
  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastWorkoutDate;
  int _totalWorkouts = 0;
  List<String> _unlockedAchievements = [];

  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  DateTime? get lastWorkoutDate => _lastWorkoutDate;
  int get totalWorkouts => _totalWorkouts;
  List<String> get unlockedAchievements => [..._unlockedAchievements];

  Future<void> loadStreakData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('statistics')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        _currentStreak = doc.data()?['currentStreak'] ?? 0;
        _longestStreak = doc.data()?['longestStreak'] ?? 0;
        _totalWorkouts = doc.data()?['totalWorkouts'] ?? 0;
        _unlockedAchievements =
            List<String>.from(doc.data()?['achievements'] ?? []);

        if (doc.data()?['lastWorkoutDate'] != null) {
          _lastWorkoutDate =
              (doc.data()!['lastWorkoutDate'] as Timestamp).toDate();

          // Check if streak is broken (more than 1 day since last workout)
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final lastDate = DateTime(_lastWorkoutDate!.year,
              _lastWorkoutDate!.month, _lastWorkoutDate!.day);
          final diffDays = today.difference(lastDate).inDays;

          if (diffDays > 1) {
            _currentStreak = 0;
            // Persist reset to Firestore
            await FirebaseFirestore.instance
                .collection('statistics')
                .doc(user.uid)
                .update({'currentStreak': 0});
          }
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error loading streak data: $e');
    }
  }

  Future<void> updateStreak() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check if user worked out today or yesterday
      if (_lastWorkoutDate != null) {
        final lastDate = DateTime(_lastWorkoutDate!.year,
            _lastWorkoutDate!.month, _lastWorkoutDate!.day);
        final diffDays = today.difference(lastDate).inDays;

        if (diffDays == 0) {
          // Same day, don't increase streak
          return;
        } else if (diffDays == 1) {
          // Yesterday, increment streak
          _currentStreak++;
          if (_currentStreak > _longestStreak) {
            _longestStreak = _currentStreak;
          }
        } else {
          // Streak broken
          _currentStreak = 1;
        }
      } else {
        // First workout
        _currentStreak = 1;
        _longestStreak = 1;
      }

      _lastWorkoutDate = now;
      _totalWorkouts++;

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('statistics')
          .doc(user.uid)
          .set({
        'currentStreak': _currentStreak,
        'longestStreak': _longestStreak,
        'lastWorkoutDate': Timestamp.fromDate(now),
        'totalWorkouts': _totalWorkouts,
        'achievements': _unlockedAchievements,
      }, SetOptions(merge: true));

      // Check for new achievements
      await _checkAchievements();

      notifyListeners();
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  Future<void> _checkAchievements() async {
    final newAchievements = <String>[];

    // First Workout
    if (_totalWorkouts == 1 &&
        !_unlockedAchievements.contains('First Workout')) {
      newAchievements.add('First Workout');
    }

    // 7 Day Streak
    if (_currentStreak >= 7 &&
        !_unlockedAchievements.contains('7 Day Streak')) {
      newAchievements.add('7 Day Streak');
    }

    // Monthly Warrior
    if (_currentStreak >= 30 &&
        !_unlockedAchievements.contains('Monthly Warrior')) {
      newAchievements.add('Monthly Warrior');
    }

    // Strong Start
    if (_totalWorkouts >= 10 &&
        !_unlockedAchievements.contains('Strong Start')) {
      newAchievements.add('Strong Start');
    }

    // Centurion
    if (_totalWorkouts >= 100 && !_unlockedAchievements.contains('Centurion')) {
      newAchievements.add('Centurion');
    }

    if (newAchievements.isNotEmpty) {
      _unlockedAchievements.addAll(newAchievements);
      notifyListeners();
      // Store updated achievements
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('statistics')
              .doc(user.uid)
              .update({
            'achievements': _unlockedAchievements,
          });
        }
      } catch (e) {
        print('Error saving achievements: $e');
      }
    }
  }

  Future<List<String>> getRecentlyUnlockedAchievements() async {
    return _unlockedAchievements;
  }

  // Weekly statistics
  Future<Map<String, dynamic>> getWeeklyStats() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return {'workouts': 0, 'calories': 0, 'water': 0};

      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      // Get workouts from last 7 days
      final workoutsSnapshot = await FirebaseFirestore.instance
          .collection('finishedWorkouts')
          .doc(user.uid)
          .collection('finishedWorkoutsData')
          .where('dateTime', isGreaterThan: Timestamp.fromDate(weekAgo))
          .get();

      // Get meals for calories
      final mealsSnapshot = await FirebaseFirestore.instance
          .collection('meals')
          .doc(user.uid)
          .collection('mealData')
          .where('dateTime', isGreaterThan: Timestamp.fromDate(weekAgo))
          .get();

      double totalCalories = 0;
      for (var doc in mealsSnapshot.docs) {
        final calories = doc.data()['calories'];
        if (calories != null) {
          totalCalories += (calories is int) ? calories.toDouble() : calories;
        }
      }

      // Get water data
      final waterSnapshot = await FirebaseFirestore.instance
          .collection('meals')
          .doc(user.uid)
          .collection('waterData')
          .where('dateTime', isGreaterThan: Timestamp.fromDate(weekAgo))
          .get();

      double totalWater = 0;
      for (var doc in waterSnapshot.docs) {
        final amount = doc.data()['amount'];
        if (amount != null) {
          totalWater += (amount is int) ? amount.toDouble() : amount;
        }
      }

      return {
        'workouts': workoutsSnapshot.docs.length,
        'calories': totalCalories.round(),
        'water': totalWater / 7, // Average per day
      };
    } catch (e) {
      print('Error getting weekly stats: $e');
      return {'workouts': 0, 'calories': 0, 'water': 0};
    }
  }

  bool get isMaintainingStreak {
    if (_lastWorkoutDate == null) return false;
    final now = DateTime.now();
    final daysDiff = now.difference(_lastWorkoutDate!).inDays;
    return daysDiff <= 1;
  }
}
