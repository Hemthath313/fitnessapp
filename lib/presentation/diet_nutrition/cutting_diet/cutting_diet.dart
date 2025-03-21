import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/presentation/diet_nutrition/meals/meal_card.dart';
import 'package:fitness_app/presentation/diet_nutrition/meals/meal_details.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CuttingDietScreen extends StatefulWidget {
  const CuttingDietScreen({super.key});

  @override
  State<CuttingDietScreen> createState() => _CuttingDietScreenState();
}

class _CuttingDietScreenState extends State<CuttingDietScreen> {
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
        await rootBundle.loadString('assets/json/cuttingdiet.json');
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
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final userData = homeProvider.userData;

      double storedBMR = userData['bmr'] ?? 0.0;
      double storedBMI = userData['bmi'] ?? 0.0;
      int dailyCalories =
          (storedBMR > 0) ? storedBMR.toInt() : (storedBMI * 30).toInt();

      dailySummary['calories'] = dailyCalories; // 💥 Replac
      _resetRemainingMacros();
    });

    await _loadSavedMealsFromFirestore();
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
        'image': meal['image'], // ✅ Add this line
        'calories': meal['calories'],
        'protein': meal['protein'],
        'carbs': meal['carbs'],
        'fats': meal['fats'],
        'foods': meal['foods'] ?? [],
        'isCompleted': meal['isCompleted']
      };
    }).toList();

    await mealRecordRef.set({
      'completedMeals': completedMeals,
      'consumedCalories': dailySummary['calories'] - remainingCalories,
      'remainingCalories': remainingCalories,
      'remainingProtein': remainingProtein,
      'remainingCarbs': remainingCarbs,
      'remainingFats': remainingFats,
      'swappedMeals': storedMeals, // 🔹 Save swapped meals
      'timestamp': FieldValue.serverTimestamp(),
      'lastUpdated': todayDate,
    }, SetOptions(merge: true));
    print("consumedcalories: ${dailySummary['calories'] - remainingCalories}");
    print('remaingProtein: $remainingProtein');

    print("Meal record saved for $todayDate with swapped meals.");
  }

  Widget _buildSummaryCard() {
    final homeProvider = Provider.of<HomeProvider>(context);
    final userData = homeProvider.userData;

    double storedBMR = userData['bmr'] ?? 0.0;
    double storedBMI = userData['bmi'] ?? 0.0;

// Use storedBMI or storedBMR directly to calculate
    int dailyCalories =
        (storedBMR > 0) ? storedBMR.toInt() : (storedBMI * 30).toInt();
    double weight = userData['weight'] ?? 60.0; // fallback weight if not stored
    int protein = (weight * 2.0).toInt(); // 2g per kg
    int carbs = (weight * 4.0).toInt(); // 4g per kg
    int fats = (weight * 1.0).toInt(); // 1g per kg

// Example Macro Calculation
    return Card(
      color: ColorManager.black54,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _progressBar(
                'Calories', dailyCalories, remainingCalories, Colors.orange),
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
        Text(
          '$label: ${total - remaining}/$total',
          style: TextStyle(color: ColorManager.white),
        ),
        LinearProgressIndicator(
            value: progress, color: color, backgroundColor: Colors.grey[300]),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMealList() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: ListView.builder(
        key: ValueKey(meals.length),
        itemCount: meals.length + 1, // +1 for custom meal button
        itemBuilder: (context, index) {
          if (index == meals.length) {
            return _buildAddCustomMealButton();
          }
          return MealCard(
            meal: meals[index],
            index: index,
            onToggleMeal: (value) => _toggleMeal(index, value),
            onTap: () => _showMealDetails(index),
          );
        },
      ),
    );
  }

  Widget _buildAddCustomMealButton() {
    return GestureDetector(
      onTap: _showAddCustomMealDialog,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorManager.black54,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: const Center(
          child: Text(
            '+ Add Custom Meal',
            style: TextStyle(
              color: Colors.orangeAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddCustomMealDialog() {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ColorManager.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Add Custom Meal',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ColorManager.limerGreen2,
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField('Meal Name', nameController),
                _buildTextField('Calories', caloriesController, isNumber: true),
                _buildTextField('Protein (g)', proteinController,
                    isNumber: true),
                _buildTextField('Carbs (g)', carbsController, isNumber: true),
                _buildTextField('Fats (g)', fatsController, isNumber: true),
              ]
                  .map((widget) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: widget,
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: ColorManager.white,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.limerGreen2,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                _addCustomMeal(
                  nameController.text,
                  int.tryParse(caloriesController.text) ?? 0,
                  int.tryParse(proteinController.text) ?? 0,
                  int.tryParse(carbsController.text) ?? 0,
                  int.tryParse(fatsController.text) ?? 0,
                );
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addCustomMeal(
      String name, int calories, int protein, int carbs, int fats) {
    final newMeal = {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'foods': [], // optional if needed
      'isCompleted': false,
      'image':
          'assets/images/chana_salad.jpeg' // You can use a placeholder image for custom meals
    };

    setState(() {
      meals.add(newMeal);
    });

    _updateRemainingMacros(); // Save to Firestore immediately
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return TextField(
      style: const TextStyle(color: ColorManager.white),
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
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
      backgroundColor: ColorManager.darkGrey,
      builder: (context) {
        return MealDetailsSheet(
          meal: meal,
          onSwapMeal: () => _openMealLibrary(index),
        );
      },
    );
  }

  void _openMealLibrary(int mealIndex) {
    Navigator.pop(context); // Close bottom sheet

    showModalBottomSheet(
      context: context,
      backgroundColor: ColorManager.darkGrey, // Consistent dark theme
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return ListView.builder(
          itemCount: mealLibrary.length,
          itemBuilder: (context, libIndex) {
            final meal = mealLibrary[libIndex];
            return ListTile(
              tileColor: ColorManager.black54, // Matches cards and buttons
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                meal['name'],
                style: const TextStyle(
                  color: ColorManager.white, // Consistent text color
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${meal['calories']} kcal | ${meal['protein']}g Protein',
                style: const TextStyle(color: Colors.orangeAccent),
              ),
              onTap: () => _swapMeal(mealIndex, meal),
            );
          },
        );
      },
    );
  }

  void _swapMeal(int mealIndex, Map<String, dynamic> newMeal) {
    setState(() {
      meals[mealIndex] = {
        ...newMeal,
        'isCompleted': false,
        'foods': newMeal['foods'] ?? [], // ✅ Ensure foods are included
      };
    });
    _updateRemainingMacros();
    Navigator.pop(context);
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
      backgroundColor: ColorManager.darkGrey,
      appBar: AppBar(
          backgroundColor: ColorManager.black,
          title: const Text(
            'Cutting Diet Plan',
            style: TextStyle(color: ColorManager.white),
          )),
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
        backgroundColor: ColorManager.limerGreen2,
        onPressed: _markAllMealsComplete,
        // icon: const Icon(Icons.check_circle),
        label: const Text(
          'Complete All Meals',
          style:
              TextStyle(color: ColorManager.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
