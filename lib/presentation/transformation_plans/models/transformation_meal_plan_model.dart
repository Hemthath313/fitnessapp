// Model classes for personalized transformation meal planning,
// food items, exact quantities, raw vs. cooked weight indications, and daily nutrition targets.

/// Represents an individual ingredient or food item in a meal
class TransformationFoodItem {
  final String id;
  final String name;
  final double quantity; // in grams, ml, or piece count
  final String unit; // 'g', 'ml', 'piece', 'slice', 'tbsp', 'tsp'
  final bool isRawWeight; // true for raw meat/grains, false for cooked
  final String preparationNote; // 'Raw weight' or 'Cooked weight'
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final List<String> allergens; // 'dairy', 'gluten', 'nuts', 'eggs', 'fish', 'soy'
  final String dietaryCategory; // 'vegetarian', 'vegan', 'non_vegetarian'
  final List<String> substituteFoodIds;

  const TransformationFoodItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.isRawWeight,
    required this.preparationNote,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.allergens = const [],
    required this.dietaryCategory,
    this.substituteFoodIds = const [],
  });

  TransformationFoodItem copyWithScaledQuantity(double newQuantity) {
    if (quantity <= 0) return this;
    final scale = newQuantity / quantity;
    return TransformationFoodItem(
      id: id,
      name: name,
      quantity: double.parse(newQuantity.toStringAsFixed(1)),
      unit: unit,
      isRawWeight: isRawWeight,
      preparationNote: preparationNote,
      calories: double.parse((calories * scale).toStringAsFixed(1)),
      protein: double.parse((protein * scale).toStringAsFixed(1)),
      carbs: double.parse((carbs * scale).toStringAsFixed(1)),
      fat: double.parse((fat * scale).toStringAsFixed(1)),
      allergens: allergens,
      dietaryCategory: dietaryCategory,
      substituteFoodIds: substituteFoodIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'isRawWeight': isRawWeight,
      'preparationNote': preparationNote,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'allergens': allergens,
      'dietaryCategory': dietaryCategory,
      'substituteFoodIds': substituteFoodIds,
    };
  }

  factory TransformationFoodItem.fromMap(Map<String, dynamic> map) {
    return TransformationFoodItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit']?.toString() ?? 'g',
      isRawWeight: map['isRawWeight'] == true,
      preparationNote: map['preparationNote']?.toString() ?? 'Cooked weight',
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      allergens: (map['allergens'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      dietaryCategory: map['dietaryCategory']?.toString() ?? 'vegetarian',
      substituteFoodIds: (map['substituteFoodIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

/// Represents one of the 5 daily scheduled meals
class TransformationMeal {
  final String id;
  final String name; // 'Breakfast', 'Mid-Morning Snack', 'Lunch', 'Evening Snack', 'Dinner'
  final String timeGuidance;
  final List<TransformationFoodItem> foods;
  final bool isLogged;

  const TransformationMeal({
    required this.id,
    required this.name,
    required this.timeGuidance,
    required this.foods,
    this.isLogged = false,
  });

  double get totalCalories =>
      double.parse(foods.fold(0.0, (acc, f) => acc + f.calories).toStringAsFixed(1));
  double get totalProtein =>
      double.parse(foods.fold(0.0, (acc, f) => acc + f.protein).toStringAsFixed(1));
  double get totalCarbs =>
      double.parse(foods.fold(0.0, (acc, f) => acc + f.carbs).toStringAsFixed(1));
  double get totalFat =>
      double.parse(foods.fold(0.0, (acc, f) => acc + f.fat).toStringAsFixed(1));

  TransformationMeal copyWith({
    String? id,
    String? name,
    String? timeGuidance,
    List<TransformationFoodItem>? foods,
    bool? isLogged,
  }) {
    return TransformationMeal(
      id: id ?? this.id,
      name: name ?? this.name,
      timeGuidance: timeGuidance ?? this.timeGuidance,
      foods: foods ?? this.foods,
      isLogged: isLogged ?? this.isLogged,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'timeGuidance': timeGuidance,
      'foods': foods.map((f) => f.toMap()).toList(),
      'isLogged': isLogged,
    };
  }

  factory TransformationMeal.fromMap(Map<String, dynamic> map) {
    return TransformationMeal(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      timeGuidance: map['timeGuidance']?.toString() ?? '',
      foods: (map['foods'] as List<dynamic>?)
              ?.map((f) => TransformationFoodItem.fromMap(
                  Map<String, dynamic>.from(f as Map)))
              .toList() ??
          const [],
      isLogged: map['isLogged'] == true,
    );
  }
}

/// Complete daily meal plan for a specific day of a transformation programme
class TransformationDailyMealPlan {
  final int dayNumber;
  final double plannedCalories;
  final double plannedProtein;
  final double plannedCarbs;
  final double plannedFat;
  final List<TransformationMeal> meals; // Breakfast, Mid-Morning, Lunch, Evening, Dinner
  final bool isSafe;
  final bool flaggedForReview;
  final String? reviewMessage;

  const TransformationDailyMealPlan({
    required this.dayNumber,
    required this.plannedCalories,
    required this.plannedProtein,
    required this.plannedCarbs,
    required this.plannedFat,
    required this.meals,
    this.isSafe = true,
    this.flaggedForReview = false,
    this.reviewMessage,
  });

  double get actualTotalCalories =>
      double.parse(meals.fold(0.0, (acc, m) => acc + m.totalCalories).toStringAsFixed(1));
  double get actualTotalProtein =>
      double.parse(meals.fold(0.0, (acc, m) => acc + m.totalProtein).toStringAsFixed(1));
  double get actualTotalCarbs =>
      double.parse(meals.fold(0.0, (acc, m) => acc + m.totalCarbs).toStringAsFixed(1));
  double get actualTotalFat =>
      double.parse(meals.fold(0.0, (acc, m) => acc + m.totalFat).toStringAsFixed(1));

  Map<String, dynamic> toMap() {
    return {
      'dayNumber': dayNumber,
      'plannedCalories': plannedCalories,
      'plannedProtein': plannedProtein,
      'plannedCarbs': plannedCarbs,
      'plannedFat': plannedFat,
      'meals': meals.map((m) => m.toMap()).toList(),
      'isSafe': isSafe,
      'flaggedForReview': flaggedForReview,
      'reviewMessage': reviewMessage,
    };
  }

  factory TransformationDailyMealPlan.fromMap(Map<String, dynamic> map) {
    return TransformationDailyMealPlan(
      dayNumber: (map['dayNumber'] as num?)?.toInt() ?? 1,
      plannedCalories: (map['plannedCalories'] as num?)?.toDouble() ?? 2000.0,
      plannedProtein: (map['plannedProtein'] as num?)?.toDouble() ?? 150.0,
      plannedCarbs: (map['plannedCarbs'] as num?)?.toDouble() ?? 200.0,
      plannedFat: (map['plannedFat'] as num?)?.toDouble() ?? 55.0,
      meals: (map['meals'] as List<dynamic>?)
              ?.map((m) => TransformationMeal.fromMap(
                  Map<String, dynamic>.from(m as Map)))
              .toList() ??
          const [],
      isSafe: map['isSafe'] ?? true,
      flaggedForReview: map['flaggedForReview'] ?? false,
      reviewMessage: map['reviewMessage']?.toString(),
    );
  }
}
