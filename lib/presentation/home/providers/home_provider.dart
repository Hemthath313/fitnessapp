import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fitness_app/services/notification_copy.dart';

class HomeProvider with ChangeNotifier {
  final Map<String, dynamic> _userData = {};
  double usersBMR = 0.0;
  double basicBMR = 0.0;
  double userBMRwithGoal = 0.0;
  double usersBMI = 0.0;

  Future<Map<String, dynamic>> fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        DocumentSnapshot userDataSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDataSnapshot.exists && userDataSnapshot.data() != null) {
          final data = userDataSnapshot.data() as Map<String, dynamic>;
          _userData['first name'] = data['first name'] ?? '';
          // Cache for personalised notification copy (service has no context).
          NotificationProfile.saveName(data['first name']?.toString());
          _userData['surname'] = data['surname'] ?? '';
          _userData['age'] = data['age'] ?? 0;
          _userData['height'] = (data['height'] ?? 0).toDouble();
          _userData['weight'] = (data['weight'] ?? 0).toDouble();
          _userData['gender'] = data['gender'] ?? '';
          _userData['activity'] = data['activity'] ?? '';
          _userData['bmr'] = (data['bmr'] ?? 0).toDouble();
          _userData['goal'] = data['goal'] ?? '';
          _userData['bmi'] = (data['bmi'] ?? 0).toDouble();
          _userData['email'] = data['email'] ?? '';
          _userData['chest'] = (data['chest'] ?? 0).toDouble();
          _userData['shoulders'] = (data['shoulders'] ?? 0).toDouble();
          _userData['biceps'] = (data['biceps'] ?? 0).toDouble();
          _userData['foreArm'] = (data['foreArm'] ?? 0).toDouble();
          _userData['waist'] = (data['waist'] ?? 0).toDouble();
          _userData['hips'] = (data['hips'] ?? 0).toDouble();
          _userData['thigh'] = (data['thigh'] ?? 0).toDouble();
          _userData['calf'] = (data['calf'] ?? 0).toDouble();
          if (data['experience'] != null) _userData['experience'] = data['experience'];
          if (data['experienceLevel'] != null) _userData['experienceLevel'] = data['experienceLevel'];
          if (data['fitness_level'] != null) _userData['fitness_level'] = data['fitness_level'];
          if (data['fitnessLevel'] != null) _userData['fitnessLevel'] = data['fitnessLevel'];
          if (data['level'] != null) _userData['level'] = data['level'];
          if (data['targetCalories'] != null) _userData['targetCalories'] = (data['targetCalories'] as num).toDouble();
          if (data['target_calories'] != null) _userData['target_calories'] = (data['target_calories'] as num).toDouble();
          if (data['calorieGoal'] != null) _userData['calorieGoal'] = (data['calorieGoal'] as num).toDouble();
          if (data['tdee'] != null) _userData['tdee'] = (data['tdee'] as num).toDouble();
          if (data['waterGoal'] != null) _userData['waterGoal'] = (data['waterGoal'] as num).toDouble();
          if (data['dailyWaterTarget'] != null) _userData['dailyWaterTarget'] = (data['dailyWaterTarget'] as num).toDouble();
        } else {
          // Return empty data if document doesn't exist
          _userData.clear();
        }

        notifyListeners();
      } else {
        // Return empty data if user is null
        _userData.clear();
      }
    } catch (e) {
      // Log error and preserve existing in-memory cached data instead of wiping it
      debugPrint('HomeProvider: Error fetching user data (offline): $e');
    }
    return _userData;
  }

  Map<String, dynamic> get userData => _userData;

  Future<double> getUsersBMR({
    required String gender,
    required double weight,
    required double height,
    required int age,
    required String activity,
    required String goal,
  }) async {
    const double low = 1.2;
    const double light = 1.375;
    const double moderate = 1.55;
    const double high = 1.725;
    const double veryhigh = 1.9;

    var isMan = gender == 'Male';
    var isWoman = gender == 'Female';
    if (isMan) {
      var manBmrEquation =
          88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
      basicBMR = manBmrEquation;
    } else if (isWoman) {
      var womanBmrEquation =
          447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
      basicBMR = womanBmrEquation;
    }

    switch (activity) {
      case 'LOW':
        usersBMR = basicBMR * low;
        break;
      case 'LIGHT':
        usersBMR = basicBMR * light;
        break;
      case 'MODERATE':
        usersBMR = basicBMR * moderate;
        break;
      case 'HIGH':
        usersBMR = basicBMR * high;
        break;
      case 'VERY HIGH':
        usersBMR = basicBMR * veryhigh;
        break;
      default:
        throw Exception('Invalid activity level');
    }

    switch (goal) {
      case 'LOSE':
        userBMRwithGoal = usersBMR - (usersBMR * 0.2);
        break;
      case 'MAINTAIN':
        userBMRwithGoal = usersBMR;
        break;
      case 'GAIN':
        userBMRwithGoal = usersBMR + (usersBMR * 0.2);
        break;

      default:
        throw Exception('Invalid goal');
    }

    return userBMRwithGoal;
  }

  Future<double> getUsersBMI({
    required double height,
    required double weight,
  }) async {
    double heightInMeters = height / 100;
    usersBMI = (weight / (heightInMeters * heightInMeters));
    return usersBMI;
  }
}
