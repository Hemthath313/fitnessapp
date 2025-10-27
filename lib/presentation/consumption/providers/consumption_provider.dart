import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/model/meal_model.dart';
import 'package:fitness_app/model/water_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConsumptionProvider with ChangeNotifier {
  final List<MealModel> _meals = [];
  final List<WaterModel> _water = [];
  double kCalaDay = 0.0;
  double waterADay = 0.0;
  int consumedCalories = 0;

  List<MealModel> get meals {
    return [..._meals];
  }

  List<WaterModel> get water {
    return [..._water];
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
      User? user = FirebaseAuth.instance.currentUser;

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
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('No user found for fetching meals');
      return;
    }

    try {
      final mealsSnapshot = await FirebaseFirestore.instance
          .collection('meals')
          .doc(user.uid)
          .collection('mealData')
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

  Future<void> clearMealsIfNeeded() async {
    final lastClearedDate = await getLastClearedDate();
    DateTime now = DateTime.now();

    if (lastClearedDate == null ||
        isLastDateTimeDifferent(now, lastClearedDate)) {
      await clearAllMeals(); // clear all meals directly
      await setLastClearedDate(now); // update Firestore after clear
    }
  }

  Future<void> clearAllMeals() async {
    User? user = FirebaseAuth.instance.currentUser;
    final mealsCollection = FirebaseFirestore.instance
        .collection('meals')
        .doc(user!.uid)
        .collection('mealData');

    final meals = await mealsCollection.get();
    for (var doc in meals.docs) {
      await doc.reference.delete();
    }
    _meals.clear();
    kCalaDay = 0;
    notifyListeners();
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
  }) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

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
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<DateTime?> getLastClearedDate() async {
    User? user = FirebaseAuth.instance.currentUser;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('dailyReset')
        .doc('resetTracker')
        .get();

    if (doc.exists && doc.data() != null) {
      return (doc['lastClearedDate'] as Timestamp).toDate();
    }
    return null;
  }

  Future<void> setLastClearedDate(DateTime date) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('No user found for setting last cleared date');
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('dailyReset')
        .doc('resetTracker')
        .set({
      'lastClearedDate': Timestamp.fromDate(date),
    });
  }

  Future fetchAndSetWater() async {
    User? user = FirebaseAuth.instance.currentUser;

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
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('No user found for clearing water data');
      return;
    }

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
  }

  Future<void> fetchConsumedCalories() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? 'testUser';
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('mealRecords')
        .doc(todayDate)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      notifyListeners(); // Update UI
      return data['consumedCalories'] ?? 0;
    }
  }

  Future<void> deleteMeal(String mealID) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('meals')
          .doc(user!.uid)
          .collection('mealData')
          .doc(mealID)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  String getTodayDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> getConsumedCalories() async {
    print("getConsumedCalories");
    User? user = FirebaseAuth.instance.currentUser;
    String todayDate = getTodayDate();

    DocumentReference mealRecordRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('mealRecords')
        .doc(todayDate);

    DocumentSnapshot snapshot = await mealRecordRef.get();

    if (snapshot.exists) {
      consumedCalories = snapshot['consumedCalories'] ?? 0;
      print('Consumed Calories123: ${consumedCalories}');
    } else {
      consumedCalories = 0;
    }

    notifyListeners();
  }
}
