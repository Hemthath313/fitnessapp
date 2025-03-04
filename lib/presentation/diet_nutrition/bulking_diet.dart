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
          .map((meal) => {
                ...meal as Map<String, dynamic>,
                'isCompleted': false,
              })
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

      if (data['lastUpdated'] != todayDate) {
        print("🔄 New day detected! Resetting meal records...");
        _resetRemainingMacros();
        _saveToFirestore([]);
        return;
      }

      setState(() {
        remainingCalories =
            data['remainingCalories'] ?? dailySummary['calories'];
        remainingProtein = data['remainingProtein'] ?? dailySummary['protein'];
        remainingCarbs = data['remainingCarbs'] ?? dailySummary['carbs'];
        remainingFats = data['remainingFats'] ?? dailySummary['fats'];

        // 🔹 Load swapped meals if available
        if (data.containsKey('swappedMeals')) {
          meals = List<Map<String, dynamic>>.from(data['swappedMeals']);
        }

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

    // 🔹 Store all meals, including swapped ones
    List<Map<String, dynamic>> storedMeals = meals.map((meal) {
      return {
        'name': meal['name'],
        'calories': meal['calories'],
        'protein': meal['protein'],
        'carbs': meal['carbs'],
        'fats': meal['fats'],
        'isCompleted': meal['isCompleted']
      };
    }).toList();

    await mealRecordRef.set({
      'completedMeals': completedMeals,
      'remainingCalories': remainingCalories,
      'remainingProtein': remainingProtein,
      'remainingCarbs': remainingCarbs,
      'remainingFats': remainingFats,
      'swappedMeals': storedMeals, // 🔹 Save swapped meals
      'timestamp': FieldValue.serverTimestamp(),
      'lastUpdated': todayDate,
    }, SetOptions(merge: true));

    print("Meal record saved for $todayDate with swapped meals.");
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
    double progress = (total - remaining) / total;
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
        onTap: () => _showMealDetails(index),
      ),
    );
  }

  void _toggleMeal(int index, bool isCompleted) {
    setState(() {
      meals[index]['isCompleted'] = isCompleted;
    });
    _updateRemainingMacros();
  }

  void _showMealDetails(int index) {
    final meal = meals[index];
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(meal['name'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20)),
              const Divider(),
              Text('Foods:',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              ...meal['foods'].map<Widget>((food) => Text('- $food')).toList(),
              const Divider(),
              Text(
                  'Macros: ${meal['calories']} kcal | ${meal['protein']}g P | ${meal['carbs']}g C | ${meal['fats']}g F'),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _openMealLibrary(index),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Swap Meal'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openMealLibrary(int mealIndex) {
    Navigator.pop(context); // Close bottom sheet

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: mealLibrary.length,
          itemBuilder: (context, libIndex) {
            final meal = mealLibrary[libIndex];
            return ListTile(
              title: Text(meal['name']),
              subtitle: Text(
                  '${meal['calories']} kcal | ${meal['protein']}g Protein'),
              onTap: () => _swapMeal(mealIndex, meal),
            );
          },
        );
      },
    );
  }

  void _swapMeal(int mealIndex, Map<String, dynamic> newMeal) {
    setState(() {
      meals[mealIndex] = {...newMeal, 'isCompleted': false};
    });
    _updateRemainingMacros();
    Navigator.pop(context); // Close meal library sheet
  }

  void _markAllMealsComplete() {
    setState(() {
      for (var meal in meals) {
        meal['isCompleted'] = true;
      }
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _markAllMealsComplete,
        icon: const Icon(Icons.check_circle),
        label: const Text('Complete All Meals'),
      ),
    );
  }
}
