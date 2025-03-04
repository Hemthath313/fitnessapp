import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class BulkingDietScreen extends StatefulWidget {
  const BulkingDietScreen({super.key});

  @override
  State<BulkingDietScreen> createState() => _BulkingDietScreenState();
}

class _BulkingDietScreenState extends State<BulkingDietScreen> {
  Map<String, dynamic> dailySummary = {};
  List<dynamic> mealLibrary = [];
  List<dynamic> meals = [];
  int remainingCalories = 0,
      remainingProtein = 0,
      remainingCarbs = 0,
      remainingFats = 0;

  @override
  void initState() {
    super.initState();
    loadMealPlan();
  }

  /// 🔹 Get current date in YYYY-MM-DD format
  String getTodayDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// 🔹 Get current user ID from FirebaseAuth
  String getUserId() {
    return FirebaseAuth.instance.currentUser?.uid ??
        'testUser'; // Replace with actual user handling
  }

  /// 🔹 Load meal plan from JSON and check Firestore for saved progress
  Future<void> loadMealPlan() async {
    final jsonString =
        await rootBundle.loadString('assets/json/bulkingdiet.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;

    setState(() {
      mealLibrary = data['mealLibrary'];
      meals = (data['meals'] as List)
          .map(
              (meal) => {...meal as Map<String, dynamic>, 'isCompleted': false})
          .toList();
      dailySummary = data['dailySummary'];
      _resetRemainingMacros();
    });

    await _loadSavedMealsFromFirestore(); // Load previously saved meals
  }

  /// 🔹 Reset remaining macros based on the daily summary
  void _resetRemainingMacros() {
    remainingCalories = dailySummary['calories'] ?? 0;
    remainingProtein = dailySummary['protein'] ?? 0;
    remainingCarbs = dailySummary['carbs'] ?? 0;
    remainingFats = dailySummary['fats'] ?? 0;
  }

  /// 🔹 Load completed meals from Firestore
  Future<void> _loadSavedMealsFromFirestore() async {
    String userId = getUserId();
    String todayDate = getTodayDate();

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('mealRecords')
        .doc(todayDate)
        .get();

    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // 🔹 Check if the last saved date is different from today
      if (data['lastUpdated'] != todayDate) {
        print("🔄 New day detected! Resetting meal records...");
        _resetRemainingMacros(); // Reset macros
        _saveToFirestore([]); // Clear completed meals in Firestore
        return;
      }

      setState(() {
        remainingCalories =
            data['remainingCalories'] ?? dailySummary['calories'];
        remainingProtein = data['remainingProtein'] ?? dailySummary['protein'];
        remainingCarbs = data['remainingCarbs'] ?? dailySummary['carbs'];
        remainingFats = data['remainingFats'] ?? dailySummary['fats'];

        List<String> completedMeals =
            List<String>.from(data['completedMeals'] ?? []);
        for (var meal in meals) {
          if (completedMeals.contains(meal['name'])) {
            meal['isCompleted'] = true;
          }
        }
      });
    }
  }

  /// 🔹 Update remaining macros and save progress to Firestore
  void _updateRemainingMacros() {
    int consumedCalories = 0,
        consumedProtein = 0,
        consumedCarbs = 0,
        consumedFats = 0;
    List<String> completedMeals = [];

    for (var meal in meals.where((m) => m['isCompleted'])) {
      consumedCalories += (meal['calories'] as num).toInt();
      consumedProtein += (meal['protein'] as num).toInt();
      consumedCarbs += (meal['carbs'] as num).toInt();
      consumedFats += (meal['fats'] as num).toInt();
      completedMeals.add(meal['name']);
    }

    setState(() {
      remainingCalories = (dailySummary['calories'] - consumedCalories)
          .clamp(0, dailySummary['calories']);
      remainingProtein = (dailySummary['protein'] - consumedProtein)
          .clamp(0, dailySummary['protein']);
      remainingCarbs = (dailySummary['carbs'] - consumedCarbs)
          .clamp(0, dailySummary['carbs']);
      remainingFats =
          (dailySummary['fats'] - consumedFats).clamp(0, dailySummary['fats']);
    });

    _saveToFirestore(completedMeals);
  }

  /// 🔹 Save completed meals and remaining macros to Firestore
  void _saveToFirestore(List<String> completedMeals) async {
    String userId = getUserId();
    String todayDate = getTodayDate();

    DocumentReference mealRecordRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('mealRecords')
        .doc(todayDate);

    await mealRecordRef.set({
      'completedMeals': completedMeals,
      'remainingCalories': remainingCalories,
      'remainingProtein': remainingProtein,
      'remainingCarbs': remainingCarbs,
      'remainingFats': remainingFats,
      'timestamp': FieldValue.serverTimestamp(),
      'lastUpdated': todayDate, // 🔹 Save the last updated date
    }, SetOptions(merge: true));

    print("Meal record saved for $todayDate");
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _progressBar('Calories', dailySummary['calories'],
                remainingCalories, Colors.orange),
            _progressBar('Protein', dailySummary['protein'], remainingProtein,
                Colors.green),
            _progressBar(
                'Carbs', dailySummary['carbs'], remainingCarbs, Colors.blue),
            _progressBar(
                'Fats', dailySummary['fats'], remainingFats, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _progressBar(String label, int total, int remaining, Color color) {
    double progress = total > 0 ? (total - remaining) / total : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${total - remaining}/$total'),
        LinearProgressIndicator(
            value: progress, color: color, backgroundColor: Colors.grey[300]),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMealList() {
    return ListView.builder(
      itemCount: meals.length,
      itemBuilder: (context, index) => _mealCard(meals[index], index),
    );
  }

  Widget _mealCard(Map<String, dynamic> meal, int index) {
    return Card(
      child: ListTile(
        title: Text(meal['name'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle:
            Text('${meal['calories']} kcal | ${meal['protein']}g Protein'),
        trailing: Checkbox(
          value: meal['isCompleted'],
          onChanged: (value) => _toggleMeal(index, value ?? false),
        ),
      ),
    );
  }

  void _toggleMeal(int index, bool isCompleted) {
    setState(() {
      meals[index]['isCompleted'] = isCompleted;
    });
    _updateRemainingMacros();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.black,
      appBar: AppBar(title: const Text('Bulking Diet Plan')),
      body: meals.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadMealPlan,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    Expanded(child: _buildMealList()),
                  ],
                ),
              ),
            ),
    );
  }
}
