import 'package:fitness_app/utils/managers/layout_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'dart:convert';
import 'package:fitness_app/presentation/diet_nutrition/widgets/pro_feature_gate.dart';
import 'package:fitness_app/presentation/diet_nutrition/widgets/custom_meal_dialog.dart';
import 'package:fitness_app/presentation/diet_nutrition/nutrition_targets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/diet_nutrition/meals/meal_card.dart';
import 'package:fitness_app/presentation/diet_nutrition/meals/meal_details.dart';
import 'package:fitness_app/presentation/diet_nutrition/summary_card.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// What differs between the Bulking, Cutting and Maintain plans. Everything
/// else (targets, tracking, custom meals, saving) is shared.
class DietPlanConfig {
  const DietPlanConfig({required this.title, required this.assetFile});

  /// App bar title.
  final String title;

  /// Meal plan JSON in `assets/json/`.
  final String assetFile;

  static const bulking = DietPlanConfig(
    title: 'Bulking Meal Plan',
    assetFile: 'bulkingdiet.json',
  );
  static const cutting = DietPlanConfig(
    title: 'Cutting Meal Plan',
    assetFile: 'cuttingdiet.json',
  );
  static const maintain = DietPlanConfig(
    title: 'Maintenance Meal Plan',
    assetFile: 'maintaindiet.json',
  );
}

/// One screen for all three diet plans (it used to be three near-identical
/// copies). The plan only chooses the meal list and the title; calorie and
/// macro targets come from [NutritionTargets].
///
/// Product rule: logging and tracking meals is Pro-only, so the screen is
/// wrapped in [ProFeatureGate].
class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key, required this.plan});

  final DietPlanConfig plan;

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic> dailySummary = {};
  List<dynamic> mealLibrary = [];
  List<dynamic> meals = [];
  int remainingCalories = 0,
      remainingProtein = 0,
      remainingCarbs = 0,
      remainingFats = 0;
  // What has actually been eaten (never capped at the goal).
  int consumedCalories = 0,
      consumedProtein = 0,
      consumedCarbs = 0,
      consumedFats = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadMealPlan();
  }

  /// 🔹 Get current date in YYYY-MM-DD format
  String getTodayDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// The signed-in user's id, or null when signed out. Nothing is read from or
  /// written to Firestore without one (there is no shared fallback account).
  String? getUserId() => FirebaseAuth.instance.currentUser?.uid;

  /// The day this screen's progress belongs to. It is fixed when the plan is
  /// loaded, so leaving the screen open past midnight can never write
  /// yesterday's ticks into the new day's record; the plan is reloaded when
  /// the app resumes on a new day (see [didChangeAppLifecycleState]).
  String _recordDate = '';

  /// 🔹 Load meal plan from JSON and check Firestore for saved progress.
  ///
  /// Targets come from [NutritionTargets], the same source Home uses, so the
  /// plan never disagrees with the Home calorie ring.
  Future<void> loadMealPlan() async {
    final jsonString =
        await rootBundle.loadString('assets/json/${widget.plan.assetFile}');
    final data = json.decode(jsonString) as Map<String, dynamic>;
    if (!mounted) return;

    final userData = Provider.of<HomeProvider>(context, listen: false).userData;
    final targets = NutritionTargets.forUser(context, userData);

    setState(() {
      _recordDate = getTodayDate();
      mealLibrary = data['mealLibrary'];
      meals = (data['meals'] as List)
          .map((meal) => {
                ...meal as Map<String, dynamic>,
                'isCompleted': false,
              })
          .toList();

      dailySummary = data['dailySummary'];
      dailySummary['calories'] = targets.calories;
      dailySummary['protein'] = targets.protein;
      dailySummary['carbs'] = targets.carbs;
      dailySummary['fats'] = targets.fats;

      _recalculate();
    });

    await _loadSavedMealsFromFirestore();
  }

  int _goal(String key) => (dailySummary[key] as num?)?.toInt() ?? 0;

  /// Recomputes eaten and remaining totals from the meals ticked off. Eaten
  /// is never capped at the goal, so overeating is shown honestly; remaining
  /// stops at 0. Call inside setState.
  void _recalculate() {
    int kcal = 0, protein = 0, carbs = 0, fats = 0;
    for (final meal in meals.where((m) => m['isCompleted'] == true)) {
      kcal += (meal['calories'] as num?)?.toInt() ?? 0;
      protein += (meal['protein'] as num?)?.toInt() ?? 0;
      carbs += (meal['carbs'] as num?)?.toInt() ?? 0;
      fats += (meal['fats'] as num?)?.toInt() ?? 0;
    }
    consumedCalories = kcal;
    consumedProtein = protein;
    consumedCarbs = carbs;
    consumedFats = fats;

    int left(int goal, int used) => goal - used < 0 ? 0 : goal - used;
    remainingCalories = left(_goal('calories'), kcal);
    remainingProtein = left(_goal('protein'), protein);
    remainingCarbs = left(_goal('carbs'), carbs);
    remainingFats = left(_goal('fats'), fats);
  }

  List<String> _completedMealNames() => [
        for (final m in meals.where((m) => m['isCompleted'] == true))
          m['name'] as String
      ];

  /// 🔹 Load completed meals from Firestore
  Future<void> _loadSavedMealsFromFirestore() async {
    final userId = getUserId();
    if (userId == null || _recordDate.isEmpty) return;

    final DocumentSnapshot doc;
    try {
      doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('mealRecords')
          .doc(_recordDate)
          .get();
    } catch (e) {
      debugPrint('Diet plan: could not load saved meals: $e');
      return;
    }
    if (!mounted || !doc.exists || doc.data() == null) return;

    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      // 🔹 Load swapped / custom meals if available
      final saved = data['swappedMeals'];
      if (saved is List && saved.isNotEmpty) {
        meals = saved
            .map((m) => Map<String, dynamic>.from(m as Map))
            .toList();
      }

      final completedMeals = List<String>.from(data['completedMeals'] ?? []);
      for (var meal in meals) {
        if (completedMeals.contains(meal['name'])) {
          meal['isCompleted'] = true;
        }
      }
      // Totals always come from the meals themselves, never from stale
      // stored "remaining" values (the target may have changed since).
      _recalculate();
    });
  }

  /// 🔹 Recalculate totals and save progress to Firestore
  void _updateRemainingMacros() {
    setState(_recalculate);
    _saveToFirestore(_completedMealNames());
  }

  /// 🔹 Save completed meals and totals to Firestore, then tell Home so its
  /// calorie ring updates straight away.
  Future<void> _saveToFirestore(List<String> completedMeals) async {
    final userId = getUserId();
    if (userId == null || _recordDate.isEmpty) return;

    final recordDate = _recordDate;
    final consumption =
        Provider.of<ConsumptionProvider>(context, listen: false);

    // 🔹 Store all meals, including swapped and custom ones
    final List<Map<String, dynamic>> storedMeals = meals.map((meal) {
      return {
        'name': meal['name'],
        'image': meal['image'],
        'calories': meal['calories'],
        'protein': meal['protein'],
        'carbs': meal['carbs'],
        'fats': meal['fats'],
        'foods': meal['foods'] ?? [],
        'isCompleted': meal['isCompleted'],
        'isCustom': meal['isCustom'] ?? false,
      };
    }).toList();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('mealRecords')
          .doc(recordDate)
          .set({
        'completedMeals': completedMeals,
        'consumedCalories': consumedCalories,
        'consumedProtein': consumedProtein,
        'consumedCarbs': consumedCarbs,
        'consumedFats': consumedFats,
        'remainingCalories': remainingCalories,
        'remainingProtein': remainingProtein,
        'remainingCarbs': remainingCarbs,
        'remainingFats': remainingFats,
        'swappedMeals': storedMeals,
        'timestamp': FieldValue.serverTimestamp(),
        'lastUpdated': recordDate,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Diet plan: could not save meal record: $e');
      return;
    }

    if (recordDate == getTodayDate()) {
      await consumption.getConsumedCalories();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _recordDate.isNotEmpty &&
        _recordDate != getTodayDate()) {
      loadMealPlan();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget _buildSummaryCard() {
    return SummaryCard(
      totalCalories: _goal('calories'),
      totalProtein: _goal('protein'),
      totalCarbs: _goal('carbs'),
      totalFats: _goal('fats'),
      remainingCalories: remainingCalories,
      remainingProtein: remainingProtein,
      remainingCarbs: remainingCarbs,
      remainingFats: remainingFats,
      consumedCalories: consumedCalories,
      consumedProtein: consumedProtein,
      consumedCarbs: consumedCarbs,
      consumedFats: consumedFats,
    );
  }

  Widget _buildMealList() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
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
          color: ColorManager.surface,
          boxShadow: ColorManager.cardShadow,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: ColorManager.primary.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Text(
            '+ Add Custom Meal',
            style: TextStyle(
              color: ColorManager.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddCustomMealDialog() async {
    final input = await showCustomMealDialog(context);
    if (input == null || !mounted) return;
    _addCustomMeal(input);
  }

  void _addCustomMeal(CustomMealInput input) {
    final newMeal = {
      'name': input.name,
      'calories': input.calories,
      'protein': input.protein,
      'carbs': input.carbs,
      'fats': input.fats,
      'foods': [],
      'isCompleted': false,
      'isCustom': true,
      'image': 'assets/images/chana_salad.jpeg', // placeholder for custom meals
    };

    setState(() {
      meals.add(newMeal);
    });

    _updateRemainingMacros(); // Save to Firestore immediately
  }

  void _deleteCustomMeal(int index) {
    if (index < 0 || index >= meals.length) return;
    if (meals[index]['isCustom'] != true) return;
    setState(() {
      meals.removeAt(index);
    });
    _updateRemainingMacros();
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
      isScrollControlled: true, // Better for responsiveness with keyboard
      backgroundColor: ColorManager.background,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: MealDetailsSheet(
            meal: meal,
            onSwapMeal: () => _openMealLibrary(index),
            onAddFood: (foodName) => _addFoodToMeal(index, foodName),
            onDelete: meal['isCustom'] == true
                ? () {
                    Navigator.pop(context);
                    _deleteCustomMeal(index);
                  }
                : null,
          ),
        );
      },
    );
  }

  void _addFoodToMeal(int mealIndex, String foodName) {
    setState(() {
      if (meals[mealIndex]['foods'] == null) {
        meals[mealIndex]['foods'] = [];
      }
      // UI update
      meals[mealIndex]['foods'].add(foodName);
    });
    // Persist
    // We recreate the 'completedMeals' list to update firestore
    _saveToFirestore(_completedMealNames());
    
    // The details sheet holds a reference to the meal map and is stateless, so
    // close and re-open it to show the new food.
    Navigator.pop(context); // Close sheet to refresh or to confirm
    _showMealDetails(mealIndex); // Re-open to show new food
  }

  void _openMealLibrary(int mealIndex) {
    Navigator.pop(context); // Close bottom sheet

    showModalBottomSheet(
      context: context,
      backgroundColor: ColorManager.background, // Consistent dark theme
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return ListView.builder(
          itemCount: mealLibrary.length,
          itemBuilder: (context, libIndex) {
            final meal = mealLibrary[libIndex];
            return ListTile(
              tileColor: ColorManager.surface, // Matches cards and buttons
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                meal['name'],
                style:  TextStyle(
                  color: ColorManager.textPrimary, // Consistent text color
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${meal['calories']} kcal | ${meal['protein']}g Protein',
                style: TextStyle(color: ColorManager.primaryText),
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
        'foods': newMeal['foods'] != null ? List.from(newMeal['foods']) : [], 
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
    return ProFeatureGate(
      child: Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
          iconTheme: IconThemeData(color: ColorManager.textPrimary),
          backgroundColor: ColorManager.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title:  Text(
            widget.plan.title,
            style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: AppText.appBarTitle,
                fontWeight: FontWeight.w600),
          )),
      body: meals.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadMealPlan,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    Expanded(child: _buildMealList()),
                  ],
                ),
              ),
            ),
    ),
    );
  }
}
