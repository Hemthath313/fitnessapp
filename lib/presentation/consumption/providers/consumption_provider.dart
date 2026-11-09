import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/model/meal_model.dart';
import 'package:fitness_app/model/water_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fitness_app/services/notification_service.dart';
import 'package:home_widget/home_widget.dart';

class ConsumptionProvider with ChangeNotifier {
  final List<MealModel> _meals = [];
  final List<WaterModel> _water = [];
  double kCalaDay = 0.0;
  double waterADay = 0.0;
  int consumedCalories = 0;
  double _waterGoalLiters = 2.5;

  /// How many days of logged meals are loaded.
  static const int mealHistoryDays = 90;

  /// Calories from the Bulking / Cutting / Maintain plan screens today (read
  /// from the day's mealRecords document).
  int _planConsumedCalories = 0;

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Meals logged by hand today (the manual "Add Meal" log).
  List<MealModel> get todaysMeals {
    final now = DateTime.now();
    return _meals.where((m) => _isSameDay(m.dateTime, now)).toList();
  }

  double get manualCaloriesToday =>
      todaysMeals.fold(0.0, (total, m) => total + m.calories);
  double get manualProteinToday =>
      todaysMeals.fold(0.0, (total, m) => total + m.proteins);
  double get manualCarbsToday =>
      todaysMeals.fold(0.0, (total, m) => total + m.carbs);
  double get manualFatsToday =>
      todaysMeals.fold(0.0, (total, m) => total + m.fats);

  /// Today's total: plan meals ticked off + meals logged by hand. This is the
  /// number the Home calorie ring shows.
  void _recomputeConsumed() {
    consumedCalories = _planConsumedCalories + manualCaloriesToday.round();
  }

  @visibleForTesting
  void setMealsForTesting(List<MealModel> meals, {int planCalories = 0}) {
    _meals
      ..clear()
      ..addAll(meals);
    _planConsumedCalories = planCalories;
    _recomputeConsumed();
  }

  double get waterGoalLiters => _waterGoalLiters;

  void setWaterGoal(double liters) {
    if (liters > 0) {
      _waterGoalLiters = liters;
      notifyListeners();
    }
  }

  List<MealModel> get meals {
    return [..._meals];
  }

  List<WaterModel> get water {
    return [..._water];
  }

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<void> addNewMeal({
    required String title,
    required double amount,
    required double calories,
    required double fats,
    required double carbs,
    required double proteins,
    required DateTime dateTime,
  }) async {
    try {
      User? user = _currentUser;

      await FirebaseFirestore.instance
          .collection('meals')
          .doc(user!.uid)
          .collection('mealData')
          .doc()
          .set({
        'title': title,
        'amount': amount,
        'calories': calories,
        'fats': fats,
        'carbs': carbs,
        'proteins': proteins,
        'dateTime': dateTime,
      });

      // Immediately fetch and update meal data
      await fetchAndSetMeals();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  bool isNewDay(DateTime now, DateTime lastDate) {
    return now.year > lastDate.year ||
        now.month > lastDate.month ||
        now.day > lastDate.day;
  }

  Future fetchAndSetMeals() async {
    User? user = _currentUser;

    if (user == null) {
      print('No user found for fetching meals');
      return;
    }

    try {
      // Meal history is kept (it feeds programme progress), but only the
      // recent window is loaded so the download does not grow forever.
      final cutoff = DateTime.now().subtract(const Duration(days: mealHistoryDays));
      final mealsSnapshot = await FirebaseFirestore.instance
          .collection('meals')
          .doc(user.uid)
          .collection('mealData')
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
          .get();

      final List<MealModel> loadedMeals = [];

      for (var doc in mealsSnapshot.docs) {
        final mealData = doc.data();
        loadedMeals.add(MealModel(
          id: doc.id,
          title: mealData['title'] ?? '',
          amount: (mealData['amount'] ?? 0).toDouble(),
          calories: (mealData['calories'] ?? 0).toDouble(),
          fats: (mealData['fats'] ?? 0).toDouble(),
          carbs: (mealData['carbs'] ?? 0).toDouble(),
          proteins: (mealData['proteins'] ?? 0).toDouble(),
          dateTime: mealData['dateTime'] != null
              ? (mealData['dateTime'] as Timestamp).toDate()
              : DateTime.now(),
        ));
      }
      loadedMeals.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      _meals.clear();
      _meals.addAll(loadedMeals);
      await getConsumedCalories();
      notifyListeners();
    } catch (e) {
      print('Error fetching meals: $e');
      // Don't rethrow, just log the error
    }
  }

  getkCal() async {
    kCalaDay = 0.0;
    for (var meal in _meals) {
      kCalaDay += meal.calories;
    }
    notifyListeners();
  }

  /// Deletes every logged meal. Meals are NOT cleared daily any more: they are
  /// history. Only call this for an explicit user action (e.g. account reset).
  Future<void> clearAllMeals() async {
    User? user = _currentUser;
    if (user == null) return;

    try {
      final mealsCollection = FirebaseFirestore.instance
          .collection('meals')
          .doc(user.uid)
          .collection('mealData');

      final meals = await mealsCollection.get();
      for (var doc in meals.docs) {
        await doc.reference.delete();
      }
      _meals.clear();
      kCalaDay = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('ConsumptionProvider: clearAllMeals error (offline): $e');
    }
  }

  bool isLastDateTimeDifferent(DateTime now, DateTime lastDateTime) {
    return now.year != lastDateTime.year ||
        now.month != lastDateTime.month ||
        now.day != lastDateTime.day;
  }

  bool isInputTimeDifferent(DateTime now, DateTime inputDateTime) {
    return now.year != inputDateTime.year ||
        now.month != inputDateTime.month ||
        now.day != inputDateTime.day;
  }

  Future<void> addWater({
    required double amount,
    required DateTime dateTime,
    /// The user's daily water goal in LITERS (the unit water is stored and
    /// shown in). Defaults to the provider's goal.
    double? goalLiters,
  }) async {
    try {
      User? user = _currentUser;

      await FirebaseFirestore.instance
          .collection('meals')
          .doc(user!.uid)
          .collection('waterData')
          .doc()
          .set({
        'amount': amount,
        'dateTime': dateTime,
      });

      // Immediately fetch and update water data
      await fetchAndSetWater();
      
      // Stop the reminder once today's goal is reached.
      // waterADay is in liters, so the goal must be too. (It used to be compared
      // against 2500, which could never be reached, so the reminder never
      // switched off.)
      final goal = (goalLiters != null && goalLiters > 0)
          ? goalLiters
          : _waterGoalLiters;
      if (waterADay >= goal) {
        await NotificationService().cancelWaterReminder();
      } else {
        await NotificationService().scheduleWaterReminder();
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Removes the most recent water entry logged today (undo for a mis-tap).
  /// Returns the amount removed in liters, or null when there is nothing to undo.
  Future<double?> undoLastWater({double? goalLiters}) async {
    final user = _currentUser;
    if (user == null || _water.isEmpty) return null;
    final last = _water.reduce((a, b) => a.dateTime.isAfter(b.dateTime) ? a : b);

    await FirebaseFirestore.instance
        .collection('meals')
        .doc(user.uid)
        .collection('waterData')
        .doc(last.id)
        .delete();
    await fetchAndSetWater();

    final goal = (goalLiters != null && goalLiters > 0)
        ? goalLiters
        : _waterGoalLiters;
    if (waterADay < goal) {
      await NotificationService().scheduleWaterReminder();
    }
    return last.amount;
  }

  /// Saves the daily water goal (liters) to the profile and applies it now.
  Future<void> saveWaterGoal(double liters) async {
    if (liters < 0.5 || liters > 10) {
      throw ArgumentError('Water goal must be between 0.5 and 10 liters');
    }
    setWaterGoal(liters);
    final user = _currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({'waterGoal': liters}, SetOptions(merge: true));
  }

  Future<DateTime?> getLastClearedDate() async {
    try {
      User? user = _currentUser;
      if (user == null) return null;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('dailyReset')
          .doc('resetTracker')
          .get();

      if (doc.exists && doc.data() != null) {
        return (doc['lastClearedDate'] as Timestamp).toDate();
      }
      return null;
    } catch (e) {
      debugPrint('ConsumptionProvider: getLastClearedDate error (offline): $e');
      return null;
    }
  }

  Future<void> setLastClearedDate(DateTime date) async {
    User? user = _currentUser;

    if (user == null) {
      debugPrint('No user found for setting last cleared date');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('dailyReset')
          .doc('resetTracker')
          .set({
        'lastClearedDate': Timestamp.fromDate(date),
      });
    } catch (e) {
      debugPrint('ConsumptionProvider: setLastClearedDate error (offline): $e');
    }
  }

  Future fetchAndSetWater() async {
    User? user = _currentUser;

    if (user == null) {
      print('No user found for fetching water data');
      return;
    }

    try {
      final mealsSnapshot = await FirebaseFirestore.instance
          .collection('meals')
          .doc(user.uid)
          .collection('waterData')
          .get();

      final List<WaterModel> loadedWater = [];

      for (var doc in mealsSnapshot.docs) {
        final mealData = doc.data();
        loadedWater.add(WaterModel(
          id: doc.id,
          amount: (mealData['amount'] ?? 0).toDouble(),
          dateTime: mealData['dateTime'] != null
              ? (mealData['dateTime'] as Timestamp).toDate()
              : DateTime.now(),
        ));
      }
      _water.clear();
      _water.addAll(loadedWater);
      await getWater();
      notifyListeners();
    } catch (e) {
      print('Error fetching water data: $e');
      // Don't rethrow, just log the error
    }
  }

  getWater() async {
    waterADay = 0.0;
    for (var water in _water) {
      waterADay += water.amount;
    }
    
    // Update Home Screen Widget
    await HomeWidget.saveWidgetData<double>('water', waterADay);
    await HomeWidget.updateWidget(androidName: 'FitnessWidgetProvider');
    
    notifyListeners();
  }

  Future<void> clearWaterIfNeeded() async {
    final lastClearedDate = await getLastClearedDate();
    DateTime now = DateTime.now();

    if (lastClearedDate == null ||
        isLastDateTimeDifferent(now, lastClearedDate)) {
      await clearAllWater(); // Clear all water entries
      waterADay = 0.0; // Reset the daily water counter
      await setLastClearedDate(now); // Update the last cleared date
      notifyListeners();
    }
  }

  Future<void> clearAllWater() async {
    User? user = _currentUser;

    if (user == null) {
      debugPrint('No user found for clearing water data');
      return;
    }

    try {
      final waterCollection = FirebaseFirestore.instance
          .collection('meals')
          .doc(user.uid)
          .collection('waterData');

      final water = await waterCollection.get();
      for (var doc in water.docs) {
        await doc.reference.delete();
      }
      _water.clear();
      waterADay = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('ConsumptionProvider: clearAllWater error (offline): $e');
    }
  }

  Future<int> fetchConsumedCalories() async {
    try {
      String? userId = _currentUser?.uid;
      if (userId == null) return 0;
      String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('mealRecords')
          .doc(todayDate)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        notifyListeners(); // Update UI
        return (data['consumedCalories'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('ConsumptionProvider: fetchConsumedCalories error (offline): $e');
      return 0;
    }
  }

  Future<void> deleteMeal(String mealID) async {
    try {
      User? user = _currentUser;

      await FirebaseFirestore.instance
          .collection('meals')
          .doc(user!.uid)
          .collection('mealData')
          .doc(mealID)
          .delete();
      _meals.removeWhere((m) => m.id == mealID);
      _recomputeConsumed();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  String getTodayDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> getConsumedCalories() async {
    try {
      User? user = _currentUser;
      if (user == null) {
        _planConsumedCalories = 0;
        consumedCalories = 0;
        notifyListeners();
        return;
      }
      String todayDate = getTodayDate();

      DocumentReference mealRecordRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('mealRecords')
          .doc(todayDate);

      DocumentSnapshot snapshot = await mealRecordRef.get();

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        _planConsumedCalories =
            (data['consumedCalories'] as num?)?.toInt() ?? 0;
      } else {
        _planConsumedCalories = 0;
      }
      _recomputeConsumed();

      notifyListeners();
    } catch (e) {
      debugPrint('ConsumptionProvider: getConsumedCalories error (offline): $e');
      // Keep the last known plan calories, but still include meals logged by hand.
      _recomputeConsumed();
      notifyListeners();
    }
  }
}
