import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/model/meal_model.dart';
import 'package:fitness_app/model/water_model.dart';
import 'package:flutter/material.dart';

class ConsumptionProvider with ChangeNotifier {
  final List<MealModel> _meals = [];
  final List<WaterModel> _water = [];
  double kCalaDay = 0.0;
  double waterADay = 0.0;

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

    try {
      final mealsSnapshot = await FirebaseFirestore.instance
          .collection('meals')
          .doc(user!.uid)
          .collection('mealData')
          .get();

      final List<MealModel> loadedMeals = [];

      for (var doc in mealsSnapshot.docs) {
        final mealData = doc.data();
        loadedMeals.add(MealModel(
          id: doc.id,
          title: mealData['title'],
          amount: mealData['amount'],
          calories: mealData['calories'],
          fats: mealData['fats'],
          carbs: mealData['carbs'],
          proteins: mealData['proteins'],
          dateTime: (mealData['dateTime'] as Timestamp).toDate(),
        ));
      }
      loadedMeals.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      _meals.clear();
      _meals.addAll(loadedMeals);
      await getkCal();
      notifyListeners();
    } catch (e) {
      rethrow;
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
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('dailyReset')
        .doc('resetTracker')
        .set({
      'lastClearedDate': Timestamp.fromDate(date),
    });
  }

  Future fetchAndSetWater() async {
    User? user = FirebaseAuth.instance.currentUser;

    try {
      final mealsSnapshot = await FirebaseFirestore.instance
          .collection('meals')
          .doc(user!.uid)
          .collection('waterData')
          .get();

      final List<WaterModel> loadedWater = [];

      for (var doc in mealsSnapshot.docs) {
        final mealData = doc.data();
        loadedWater.add(WaterModel(
          id: doc.id,
          amount: mealData['amount'],
          dateTime: (mealData['dateTime'] as Timestamp).toDate(),
        ));
      }
      _water.clear();
      _water.addAll(loadedWater);
      await getWater();
      notifyListeners();
    } catch (e) {
      rethrow;
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
    final waterCollection = FirebaseFirestore.instance
        .collection('meals')
        .doc(user!.uid)
        .collection('waterData');

    final water = await waterCollection.get();
    for (var doc in water.docs) {
      await doc.reference.delete();
    }
    _water.clear();
    waterADay = 0;
    notifyListeners();
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
}
