import 'package:fitness_app/presentation/transformation_plans/data/transformation_food_library.dart';
import 'package:fitness_app/presentation/transformation_plans/models/transformation_meal_plan_model.dart';

/// Intelligent meal-planning engine that generates a complete, personalized 5-meal daily schedule
/// adapted to the user's calculated caloric & macronutrient targets, dietary preference (Non-Veg, Veg, Vegan),
/// allergen safeguards, and day-to-day rotational variety.
class TransformationMealPlanGenerator {
  /// Generates a practical daily meal schedule matching calculated calories and macros within nutritional tolerance
  static TransformationDailyMealPlan generateDailyMealPlan({
    required int dayNumber,
    required double targetCalories,
    required Map<String, double> targetMacros,
    required String? dietaryPreference,
    required List<String> allergies,
    String? programmeId,
    Map<String, String>? customSubstitutions,
  }) {
    final cleanPref = (dietaryPreference ?? 'non-vegetarian').trim().toLowerCase();
    final isVegan = cleanPref.contains('vegan');
    final isVeg = !cleanPref.contains('non') && cleanPref.contains('veg') && !isVegan;

    final cleanAllergies = allergies.map((a) => a.trim().toLowerCase()).toList();

    // Check for extreme conflicting restrictions (e.g. Vegan + Soy + Nuts)
    if (isVegan &&
        cleanAllergies.any((a) => a.contains('soy')) &&
        cleanAllergies.any((a) => a.contains('nut'))) {
      return TransformationDailyMealPlan(
        dayNumber: dayNumber,
        plannedCalories: targetCalories,
        plannedProtein: targetMacros['protein'] ?? 140.0,
        plannedCarbs: targetMacros['carbs'] ?? 200.0,
        plannedFat: targetMacros['fat'] ?? 55.0,
        meals: const [],
        isSafe: false,
        flaggedForReview: true,
        reviewMessage:
            'Due to multiple severe allergen restrictions (Vegan + Soy + Nuts), an automated meal plan cannot safely meet your high-protein targets without medical amino acid supplementation. Please consult a registered sports dietician.',
      );
    }

    // Caloric distribution across 5 meals:
    // Breakfast: 25% | Mid-Morning: 10% | Lunch: 30% | Evening: 10% | Dinner: 25%
    final breakfastCalories = targetCalories * 0.25;
    final midMorningCalories = targetCalories * 0.10;
    final lunchCalories = targetCalories * 0.30;
    final eveningCalories = targetCalories * 0.10;
    final dinnerCalories = targetCalories * 0.25;

    // Daily template rotation index (0, 1, 2)
    final templateIndex = (dayNumber - 1) % 3;

    final breakfast = _buildMeal(
      mealId: 'breakfast',
      mealName: 'Breakfast',
      timeGuidance: '8:00 AM – 9:00 AM',
      targetMealCalories: breakfastCalories,
      templateIndex: templateIndex,
      isVeg: isVeg,
      isVegan: isVegan,
      userAllergies: cleanAllergies,
      customSubstitutions: customSubstitutions,
      dayNumber: dayNumber,
    );

    final midMorning = _buildMeal(
      mealId: 'mid_morning',
      mealName: 'Mid-Morning Snack',
      timeGuidance: '11:00 AM – 11:30 AM',
      targetMealCalories: midMorningCalories,
      templateIndex: templateIndex,
      isVeg: isVeg,
      isVegan: isVegan,
      userAllergies: cleanAllergies,
      customSubstitutions: customSubstitutions,
      dayNumber: dayNumber,
    );

    final lunch = _buildMeal(
      mealId: 'lunch',
      mealName: 'Lunch',
      timeGuidance: '1:00 PM – 2:00 PM',
      targetMealCalories: lunchCalories,
      templateIndex: templateIndex,
      isVeg: isVeg,
      isVegan: isVegan,
      userAllergies: cleanAllergies,
      customSubstitutions: customSubstitutions,
      dayNumber: dayNumber,
    );

    final evening = _buildMeal(
      mealId: 'evening',
      mealName: 'Evening Snack',
      timeGuidance: '5:00 PM – 5:30 PM',
      targetMealCalories: eveningCalories,
      templateIndex: templateIndex,
      isVeg: isVeg,
      isVegan: isVegan,
      userAllergies: cleanAllergies,
      customSubstitutions: customSubstitutions,
      dayNumber: dayNumber,
    );

    final dinner = _buildMeal(
      mealId: 'dinner',
      mealName: 'Dinner',
      timeGuidance: '8:00 PM – 9:00 PM',
      targetMealCalories: dinnerCalories,
      templateIndex: templateIndex,
      isVeg: isVeg,
      isVegan: isVegan,
      userAllergies: cleanAllergies,
      customSubstitutions: customSubstitutions,
      dayNumber: dayNumber,
    );

    return TransformationDailyMealPlan(
      dayNumber: dayNumber,
      plannedCalories: targetCalories,
      plannedProtein: targetMacros['protein'] ?? 140.0,
      plannedCarbs: targetMacros['carbs'] ?? 200.0,
      plannedFat: targetMacros['fat'] ?? 55.0,
      meals: [breakfast, midMorning, lunch, evening, dinner],
      isSafe: true,
      flaggedForReview: false,
    );
  }

  /// Builds a specific meal based on template slot, dietary preference, and allergen filtering
  static TransformationMeal _buildMeal({
    required String mealId,
    required String mealName,
    required String timeGuidance,
    required double targetMealCalories,
    required int templateIndex,
    required bool isVeg,
    required bool isVegan,
    required List<String> userAllergies,
    Map<String, String>? customSubstitutions,
    required int dayNumber,
  }) {
    List<String> rawFoodIds;

    if (mealId == 'breakfast') {
      if (isVegan) {
        if (templateIndex == 0) {
          rawFoodIds = ['raw_rolled_oats', 'unsweetened_soy_milk', 'chia_seeds', 'ripe_banana'];
        } else if (templateIndex == 1) {
          rawFoodIds = ['firm_tofu', 'whole_wheat_bread', 'olive_oil', 'gala_apple'];
        } else {
          rawFoodIds = ['raw_rolled_oats', 'natural_peanut_butter', 'ripe_banana'];
        }
      } else if (isVeg) {
        if (templateIndex == 0) {
          rawFoodIds = ['low_fat_paneer', 'whole_wheat_roti', 'desi_cow_ghee'];
        } else if (templateIndex == 1) {
          rawFoodIds = ['raw_rolled_oats', 'toned_cow_milk', 'raw_almonds', 'ripe_banana'];
        } else {
          rawFoodIds = ['low_fat_paneer', 'whole_wheat_bread', 'gala_apple'];
        }
      } else {
        // Non-veg
        if (templateIndex == 0) {
          rawFoodIds = ['boiled_whole_egg', 'boiled_egg_white', 'whole_wheat_bread', 'olive_oil'];
        } else if (templateIndex == 1) {
          rawFoodIds = ['raw_rolled_oats', 'toned_cow_milk', 'boiled_whole_egg', 'ripe_banana'];
        } else {
          rawFoodIds = ['boiled_whole_egg', 'boiled_egg_white', 'whole_wheat_roti'];
        }
      }
    } else if (mealId == 'mid_morning') {
      if (isVegan) {
        rawFoodIds = templateIndex == 0
            ? ['gala_apple', 'raw_almonds']
            : (templateIndex == 1 ? ['fresh_orange', 'roasted_pumpkin_seeds'] : ['papaya_cubes', 'raw_walnuts']);
      } else if (isVeg) {
        rawFoodIds = templateIndex == 0
            ? ['greek_yogurt', 'raw_almonds']
            : (templateIndex == 1 ? ['low_fat_curd', 'gala_apple'] : ['papaya_cubes', 'raw_walnuts']);
      } else {
        rawFoodIds = templateIndex == 0
            ? ['boiled_whole_egg', 'fresh_orange']
            : (templateIndex == 1 ? ['greek_yogurt', 'raw_almonds'] : ['gala_apple', 'raw_walnuts']);
      }
    } else if (mealId == 'lunch') {
      if (isVegan) {
        if (templateIndex == 0) {
          rawFoodIds = ['cooked_brown_rice', 'cooked_moong_dal', 'firm_tofu', 'steamed_broccoli'];
        } else if (templateIndex == 1) {
          rawFoodIds = ['cooked_white_rice', 'boiled_rajma', 'sauteed_spinach', 'olive_oil'];
        } else {
          rawFoodIds = ['cooked_brown_rice', 'soya_chunks_dry', 'boiled_chana', 'mixed_green_salad'];
        }
      } else if (isVeg) {
        if (templateIndex == 0) {
          rawFoodIds = ['cooked_brown_rice', 'low_fat_paneer', 'cooked_moong_dal', 'steamed_broccoli'];
        } else if (templateIndex == 1) {
          rawFoodIds = ['whole_wheat_roti', 'low_fat_paneer', 'sauteed_spinach', 'low_fat_curd'];
        } else {
          rawFoodIds = ['cooked_white_rice', 'boiled_rajma', 'low_fat_paneer', 'mixed_green_salad'];
        }
      } else {
        // Non-veg
        if (templateIndex == 0) {
          rawFoodIds = ['cooked_brown_rice', 'grilled_chicken_breast', 'steamed_broccoli', 'olive_oil'];
        } else if (templateIndex == 1) {
          rawFoodIds = ['cooked_white_rice', 'steamed_white_fish', 'cooked_moong_dal', 'mixed_green_salad'];
        } else {
          rawFoodIds = ['whole_wheat_roti', 'grilled_chicken_breast', 'sauteed_capsicum_onion', 'low_fat_curd'];
        }
      }
    } else if (mealId == 'evening') {
      if (isVegan) {
        rawFoodIds = templateIndex == 0
            ? ['roasted_pumpkin_seeds', 'fresh_orange']
            : (templateIndex == 1 ? ['sprouted_moong', 'mixed_green_salad'] : ['gala_apple', 'natural_peanut_butter']);
      } else if (isVeg) {
        rawFoodIds = templateIndex == 0
            ? ['greek_yogurt', 'chia_seeds']
            : (templateIndex == 1 ? ['toned_cow_milk', 'raw_almonds'] : ['low_fat_paneer', 'mixed_green_salad']);
      } else {
        rawFoodIds = templateIndex == 0
            ? ['boiled_egg_white', 'gala_apple']
            : (templateIndex == 1 ? ['canned_tuna_water', 'mixed_green_salad'] : ['greek_yogurt', 'raw_almonds']);
      }
    } else {
      // Dinner
      if (isVegan) {
        if (templateIndex == 0) {
          rawFoodIds = ['whole_wheat_roti', 'firm_tofu', 'cooked_moong_dal', 'mixed_green_salad'];
        } else if (templateIndex == 1) {
          rawFoodIds = ['cooked_brown_rice', 'boiled_chana', 'sauteed_spinach', 'olive_oil'];
        } else {
          rawFoodIds = ['cooked_quinoa', 'soya_chunks_dry', 'steamed_carrots_beans'];
        }
      } else if (isVeg) {
        if (templateIndex == 0) {
          rawFoodIds = ['whole_wheat_roti', 'low_fat_paneer', 'cooked_moong_dal', 'mixed_green_salad'];
        } else if (templateIndex == 1) {
          rawFoodIds = ['cooked_brown_rice', 'boiled_chana', 'sauteed_spinach', 'low_fat_curd'];
        } else {
          rawFoodIds = ['whole_wheat_roti', 'low_fat_paneer', 'steamed_carrots_beans', 'desi_cow_ghee'];
        }
      } else {
        // Non-veg
        if (templateIndex == 0) {
          rawFoodIds = ['whole_wheat_roti', 'grilled_chicken_breast', 'cooked_moong_dal', 'mixed_green_salad'];
        } else if (templateIndex == 1) {
          rawFoodIds = ['cooked_brown_rice', 'grilled_salmon', 'steamed_broccoli', 'olive_oil'];
        } else {
          rawFoodIds = ['whole_wheat_roti', 'grilled_chicken_breast', 'sauteed_spinach', 'low_fat_curd'];
        }
      }
    }

    // Resolve safe items, applying substitutions and allergen filters
    final resolvedFoods = <TransformationFoodItem>[];

    for (int i = 0; i < rawFoodIds.length; i++) {
      String foodId = rawFoodIds[i];

      // Check if user set a custom substitution
      final subKey = 'day_${dayNumber}_meal_${mealId}_food_$i';
      if (customSubstitutions != null && customSubstitutions.containsKey(subKey)) {
        final chosenSubId = customSubstitutions[subKey]!;
        final subCandidate = TransformationFoodLibrary.getById(chosenSubId);
        if (subCandidate != null && !_containsAllergen(subCandidate, userAllergies)) {
          foodId = chosenSubId;
        }
      }

      var food = TransformationFoodLibrary.getById(foodId);
      if (food == null) continue;

      // Filter allergens: if the food contains user allergens, find safe substitute
      if (_containsAllergen(food, userAllergies)) {
        final safeSubs = TransformationFoodLibrary.getSafeSubstitutes(
          foodId: food.id,
          userAllergies: userAllergies,
          dietaryPreference: isVegan ? 'vegan' : (isVeg ? 'vegetarian' : 'non-vegetarian'),
        );
        if (safeSubs.isNotEmpty) {
          food = safeSubs.first;
        } else {
          // Skip if no safe substitute exists
          continue;
        }
      }

      resolvedFoods.add(food);
    }

    // Calculate initial unscaled meal calories
    final initialCalories = resolvedFoods.fold(0.0, (acc, f) => acc + f.calories);
    final scaleFactor = initialCalories > 0 ? (targetMealCalories / initialCalories) : 1.0;

    // Scale portion quantities sensibly (preserving reasonable cooking units)
    final scaledFoods = resolvedFoods.map((f) {
      double newQty;
      if (f.unit == 'piece' || f.unit == 'slice') {
        // Scale discrete units in increments of 1, minimum 1
        newQty = (f.quantity * scaleFactor).roundToDouble();
        if (newQty < 1.0) newQty = 1.0;
      } else if (f.unit == 'tbsp' || f.unit == 'tsp') {
        newQty = double.parse((f.quantity * scaleFactor).clamp(0.5, 3.0).toStringAsFixed(1));
      } else if (f.unit == 'ml') {
        newQty = ((f.quantity * scaleFactor) / 25.0).roundToDouble() * 25.0;
        if (newQty < 50.0) newQty = 50.0;
      } else {
        // Grams: scale in practical 10g/25g increments
        newQty = ((f.quantity * scaleFactor) / 10.0).roundToDouble() * 10.0;
        if (newQty < 20.0) newQty = 20.0;
      }

      return f.copyWithScaledQuantity(newQty);
    }).toList();

    return TransformationMeal(
      id: mealId,
      name: mealName,
      timeGuidance: timeGuidance,
      foods: scaledFoods,
    );
  }

  static bool _containsAllergen(TransformationFoodItem food, List<String> userAllergies) {
    if (food.allergens.isEmpty || userAllergies.isEmpty) return false;
    for (final fa in food.allergens) {
      final faLower = fa.toLowerCase();
      for (final ua in userAllergies) {
        final uaLower = ua.toLowerCase();
        if (faLower.contains(uaLower) || uaLower.contains(faLower)) {
          return true;
        }
      }
    }
    return false;
  }
}
