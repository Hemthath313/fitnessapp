import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fitness_app/services/notification_service.dart';
import 'package:fitness_app/services/review_service.dart';
import 'package:home_widget/home_widget.dart';

class StatisticsProvider with ChangeNotifier {
  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastWorkoutDate;
  int _totalWorkouts = 0;
  List<String> _unlockedAchievements = [];
  List<DateTime> _completedWorkoutDates = [];

  /// Holds newly unlocked achievement IDs since last read (for showing celebration dialog)
  List<String> _newlyUnlockedAchievements = [];

  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  DateTime? get lastWorkoutDate => _lastWorkoutDate;
  int get totalWorkouts => _totalWorkouts;
  List<String> get unlockedAchievements => [..._unlockedAchievements];
  List<DateTime> get completedWorkoutDates => _completedWorkoutDates;

  bool get hasWorkoutToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_completedWorkoutDates.any((d) =>
        d.year == today.year && d.month == today.month && d.day == today.day)) {
      return true;
    }
    if (_lastWorkoutDate == null) return false;
    return _lastWorkoutDate!.year == now.year &&
        _lastWorkoutDate!.month == now.month &&
        _lastWorkoutDate!.day == now.day;
  }

  /// Returns and clears newly unlocked achievements (consume once to show dialog)
  List<String> consumeNewlyUnlocked() {
    final result = [..._newlyUnlockedAchievements];
    _newlyUnlockedAchievements.clear();
    return result;
  }

  /// Helper: calculate consecutive streak days directly from unique workout dates
  int _calculateCurrentStreak(Set<DateTime> normalizedDates) {
    if (normalizedDates.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(today.year, today.month, today.day - 1);

    // If user worked out today, streak is anchored at today.
    // If not worked out today but worked out yesterday, streak is still active (anchored at yesterday).
    // If neither, streak is 0.
    DateTime currentCheck;
    if (normalizedDates.contains(today)) {
      currentCheck = today;
    } else if (normalizedDates.contains(yesterday)) {
      currentCheck = yesterday;
    } else {
      return 0;
    }

    int streak = 0;
    while (normalizedDates.contains(currentCheck)) {
      streak++;
      currentCheck = DateTime(currentCheck.year, currentCheck.month, currentCheck.day - 1);
    }
    return streak;
  }

  /// Helper: calculate maximum consecutive streak ever achieved
  int _calculateLongestStreak(Set<DateTime> normalizedDates) {
    if (normalizedDates.isEmpty) return 0;
    final sortedList = normalizedDates.toList()..sort();
    int maxStreak = 1;
    int currentRun = 1;
    for (int i = 1; i < sortedList.length; i++) {
      final prev = sortedList[i - 1];
      final curr = sortedList[i];
      final expectedNext = DateTime(prev.year, prev.month, prev.day + 1);
      if (curr.year == expectedNext.year &&
          curr.month == expectedNext.month &&
          curr.day == expectedNext.day) {
        currentRun++;
        if (currentRun > maxStreak) {
          maxStreak = currentRun;
        }
      } else {
        currentRun = 1;
      }
    }
    return maxStreak;
  }

  Future<void> loadStreakData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Read existing doc to get achievements and historical longest streak
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
        }
      }

      // 2. Fetch all actual workout dates from BOTH finishedWorkouts and workout_logs
      await fetchCompletedWorkoutDates();

      // 3. Recalculate streak dynamically from the aggregated dates (self-healing)
      final normalizedDates = _completedWorkoutDates.toSet();
      if (normalizedDates.isNotEmpty) {
        final calculatedStreak = _calculateCurrentStreak(normalizedDates);
        final calculatedLongest = _calculateLongestStreak(normalizedDates);

        _currentStreak = calculatedStreak;
        if (calculatedLongest > _longestStreak) {
          _longestStreak = calculatedLongest;
        }
        if (_currentStreak > _longestStreak) {
          _longestStreak = _currentStreak;
        }

        final sortedDates = normalizedDates.toList()..sort();
        if (sortedDates.isNotEmpty) {
          _lastWorkoutDate = sortedDates.last;
        }
        _totalWorkouts = [
          _totalWorkouts,
          normalizedDates.length
        ].reduce((a, b) => a > b ? a : b);

        // Sync reconciled statistics back to Firestore
        await FirebaseFirestore.instance
            .collection('statistics')
            .doc(user.uid)
            .set({
          'currentStreak': _currentStreak,
          'longestStreak': _longestStreak,
          'lastWorkoutDate': _lastWorkoutDate != null
              ? Timestamp.fromDate(_lastWorkoutDate!)
              : null,
          'totalWorkouts': _totalWorkouts,
          'achievements': _unlockedAchievements,
        }, SetOptions(merge: true));
      }

      // 4. Update home widget
      await HomeWidget.saveWidgetData<int>('streak', _currentStreak);
      await HomeWidget.updateWidget(androidName: 'FitnessWidgetProvider');

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
      final todayDate = DateTime(now.year, now.month, now.day);

      // Re-fetch all dates from both sources and ensure today is included
      await fetchCompletedWorkoutDates();
      final normalizedDates = _completedWorkoutDates.toSet()..add(todayDate);
      _completedWorkoutDates = normalizedDates.toList();

      _currentStreak = _calculateCurrentStreak(normalizedDates);
      final calculatedLongest = _calculateLongestStreak(normalizedDates);
      if (calculatedLongest > _longestStreak) {
        _longestStreak = calculatedLongest;
      }
      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
      }

      _lastWorkoutDate = now;
      _totalWorkouts = [
        _totalWorkouts + 1,
        normalizedDates.length
      ].reduce((a, b) => a > b ? a : b);

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

      // Schedule notification reminder to maintain streak
      await NotificationService().scheduleStreakReminder();

      // Schedule water reminder for 6 PM
      await NotificationService().scheduleWaterReminder();

      // Reset re-engagement timers (3, 7, 14 days)
      await NotificationService().scheduleReEngagementNotifications();

      // Update Home Screen Widget
      await HomeWidget.saveWidgetData<int>('streak', _currentStreak);
      await HomeWidget.updateWidget(androidName: 'FitnessWidgetProvider');

      // Trigger in-app review at key milestones
      try {
        final shouldReview = await ReviewService().incrementWorkoutsLogged();
        if (shouldReview) {
          await ReviewService().requestNativeReview();
          await ReviewService().markAsPrompted();
        }
      } catch (e) {
        print('Error handling review prompt in StatisticsProvider: $e');
      }

      notifyListeners();
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  Future<void> fetchCompletedWorkoutDates() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final Set<DateTime> dates = {};

      // 1. Fetch from finishedWorkouts (AI routines & custom session workouts)
      try {
        final finishedSnap = await FirebaseFirestore.instance
            .collection('finishedWorkouts')
            .doc(user.uid)
            .collection('finishedWorkoutsData')
            .get();

        for (var doc in finishedSnap.docs) {
          if (doc.data()['dateTime'] != null) {
            final date = (doc.data()['dateTime'] as Timestamp).toDate();
            dates.add(DateTime(date.year, date.month, date.day));
          }
        }
      } catch (e) {
        print('Error fetching finishedWorkouts dates: $e');
      }

      // 2. Fetch from users/{uid}/workout_logs (manual lifts & exercise trackers)
      try {
        final logsSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workout_logs')
            .get();

        for (var doc in logsSnap.docs) {
          if (doc.data()['date'] != null) {
            final date = (doc.data()['date'] as Timestamp).toDate();
            dates.add(DateTime(date.year, date.month, date.day));
          }
        }
      } catch (e) {
        print('Error fetching workout_logs dates: $e');
      }

      if (_lastWorkoutDate != null) {
        dates.add(DateTime(_lastWorkoutDate!.year, _lastWorkoutDate!.month, _lastWorkoutDate!.day));
      }

      _completedWorkoutDates = dates.toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching completed workout dates: $e');
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
      _newlyUnlockedAchievements.addAll(newAchievements); // expose to UI
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
