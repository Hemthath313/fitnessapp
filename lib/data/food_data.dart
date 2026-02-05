class FoodItem {
  final String name;
  final String protein; // e.g. "31g"
  final String carbs;   // e.g. "0g"
  final String fat;     // e.g. "3.6g"
  final String quantity; // e.g. "per 100g"
  final String calories; // Approx
  final String category;

  const FoodItem({
    required this.name,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.quantity,
    this.calories = '',
    required this.category,
  });
}

class FoodData {
  static const List<FoodItem> highProtein = [
    // Meats & Poultry
    FoodItem(name: 'Chicken Breast', protein: '31g', carbs: '0g', fat: '3.6g', quantity: '100g', category: 'Meat', calories: '165'),
    FoodItem(name: 'Chicken Thigh', protein: '26g', carbs: '0g', fat: '10.9g', quantity: '100g', category: 'Meat', calories: '209'),
    FoodItem(name: 'Turkey Breast', protein: '29g', carbs: '0g', fat: '1g', quantity: '100g', category: 'Meat', calories: '189'),
    FoodItem(name: 'Lean Beef (95%)', protein: '26g', carbs: '0g', fat: '5g', quantity: '100g', category: 'Meat', calories: '170'),
    FoodItem(name: 'Steak (Sirloin)', protein: '27g', carbs: '0g', fat: '11g', quantity: '100g', category: 'Meat', calories: '240'),
    FoodItem(name: 'Pork Chop', protein: '27g', carbs: '0g', fat: '14g', quantity: '100g', category: 'Meat', calories: '242'),
    FoodItem(name: 'Lamb Chop', protein: '25g', carbs: '0g', fat: '21g', quantity: '100g', category: 'Meat', calories: '294'),
    
    // Fish & Seafood
    FoodItem(name: 'Tuna (Canned)', protein: '28g', carbs: '0g', fat: '1g', quantity: '100g', category: 'Fish', calories: '132'),
    FoodItem(name: 'Salmon', protein: '20g', carbs: '0g', fat: '13g', quantity: '100g', category: 'Fish', calories: '208'),
    FoodItem(name: 'Tilapia', protein: '26g', carbs: '0g', fat: '2.7g', quantity: '100g', category: 'Fish', calories: '129'),
    FoodItem(name: 'Cod', protein: '18g', carbs: '0g', fat: '0.7g', quantity: '100g', category: 'Fish', calories: '82'),
    FoodItem(name: 'Shrimp', protein: '24g', carbs: '0.2g', fat: '0.3g', quantity: '100g', category: 'Fish', calories: '99'),
    FoodItem(name: 'Sardines', protein: '25g', carbs: '0g', fat: '11g', quantity: '100g', category: 'Fish', calories: '208'),
    
    // Dairy & Eggs
    FoodItem(name: 'Egg (Whole)', protein: '6g', carbs: '0.6g', fat: '5g', quantity: '1 large', category: 'Dairy/Egg', calories: '78'),
    FoodItem(name: 'Egg Whites', protein: '3.6g', carbs: '0.2g', fat: '0g', quantity: '1 large', category: 'Dairy/Egg', calories: '17'),
    FoodItem(name: 'Greek Yogurt (0%)', protein: '10g', carbs: '3.6g', fat: '0.4g', quantity: '100g', category: 'Dairy', calories: '59'),
    FoodItem(name: 'Cottage Cheese', protein: '11g', carbs: '3.4g', fat: '4.3g', quantity: '100g', category: 'Dairy', calories: '98'),
    FoodItem(name: 'Milk (Whole)', protein: '3.4g', carbs: '4.8g', fat: '3.2g', quantity: '100ml', category: 'Dairy', calories: '61'),
    FoodItem(name: 'Cheddar Cheese', protein: '25g', carbs: '1.3g', fat: '33g', quantity: '100g', category: 'Dairy', calories: '402'),
    
    // Supplements
    FoodItem(name: 'Whey Protein', protein: '25g', carbs: '3g', fat: '1g', quantity: '1 scoop', category: 'Supplements', calories: '120'),
    FoodItem(name: 'Casein Protein', protein: '24g', carbs: '3g', fat: '1g', quantity: '1 scoop', category: 'Supplements', calories: '120'),
  ];

  static const List<FoodItem> vegetarian = [
    // Legumes
    FoodItem(name: 'Lentils', protein: '9g', carbs: '20g', fat: '0.4g', quantity: '100g (cooked)', category: 'Legume', calories: '116'),
    FoodItem(name: 'Chickpeas', protein: '7g', carbs: '27g', fat: '2.6g', quantity: '100g (cooked)', category: 'Legume', calories: '164'),
    FoodItem(name: 'Black Beans', protein: '8g', carbs: '23g', fat: '0.5g', quantity: '100g (cooked)', category: 'Legume', calories: '132'),
    FoodItem(name: 'Kidney Beans', protein: '9g', carbs: '22g', fat: '0.5g', quantity: '100g (cooked)', category: 'Legume', calories: '127'),
    
    // Soy
    FoodItem(name: 'Tofu (Firm)', protein: '8g', carbs: '1.9g', fat: '4.8g', quantity: '100g', category: 'Soy', calories: '76'),
    FoodItem(name: 'Edamame', protein: '11g', carbs: '10g', fat: '5g', quantity: '100g', category: 'Soy', calories: '122'),
    FoodItem(name: 'Tempeh', protein: '19g', carbs: '9g', fat: '11g', quantity: '100g', category: 'Soy', calories: '193'),
    FoodItem(name: 'Soy Chunks', protein: '52g', carbs: '33g', fat: '0.5g', quantity: '100g', category: 'Soy', calories: '345'),
    
    // Others
    FoodItem(name: 'Quinoa', protein: '4.4g', carbs: '21g', fat: '1.9g', quantity: '100g (cooked)', category: 'Grain', calories: '120'),
    FoodItem(name: 'Seitan', protein: '75g', carbs: '14g', fat: '1.9g', quantity: '100g', category: 'Wheat', calories: '370'),
  ];

  static const List<FoodItem> healthyFats = [
    FoodItem(name: 'Almonds', protein: '21g', carbs: '22g', fat: '49g', quantity: '100g', category: 'Nut', calories: '579'),
    FoodItem(name: 'Walnuts', protein: '15g', carbs: '14g', fat: '65g', quantity: '100g', category: 'Nut', calories: '654'),
    FoodItem(name: 'Peanuts', protein: '26g', carbs: '16g', fat: '49g', quantity: '100g', category: 'Nut', calories: '567'),
    FoodItem(name: 'Peanut Butter', protein: '8g', carbs: '6g', fat: '16g', quantity: '2 tbsp', category: 'Nut', calories: '188'),
    FoodItem(name: 'Chia Seeds', protein: '17g', carbs: '42g', fat: '31g', quantity: '100g', category: 'Seed', calories: '486'),
    FoodItem(name: 'Flax Seeds', protein: '18g', carbs: '29g', fat: '42g', quantity: '100g', category: 'Seed', calories: '534'),
    FoodItem(name: 'Avocado', protein: '2g', carbs: '9g', fat: '15g', quantity: '100g', category: 'Fruit', calories: '160'),
    FoodItem(name: 'Olive Oil', protein: '0g', carbs: '0g', fat: '100g', quantity: '100ml', category: 'Oil', calories: '884'),
  ];

  static const List<FoodItem> carbs = [
    // Grains
    FoodItem(name: 'White Rice', protein: '2.7g', carbs: '28g', fat: '0.3g', quantity: '100g (cooked)', category: 'Grain', calories: '130'),
    FoodItem(name: 'Brown Rice', protein: '2.6g', carbs: '23g', fat: '0.9g', quantity: '100g (cooked)', category: 'Grain', calories: '111'),
    FoodItem(name: 'Oats', protein: '13g', carbs: '66g', fat: '7g', quantity: '100g (raw)', category: 'Grain', calories: '389'),
    FoodItem(name: 'Pasta', protein: '5g', carbs: '25g', fat: '1g', quantity: '100g (cooked)', category: 'Grain', calories: '131'),
    FoodItem(name: 'Whole Wheat Bread', protein: '13g', carbs: '41g', fat: '3g', quantity: '100g', category: 'Grain', calories: '247'),
    
    // Starchy Veg
    FoodItem(name: 'Sweet Potato', protein: '1.6g', carbs: '20g', fat: '0.1g', quantity: '100g', category: 'Veg', calories: '86'),
    FoodItem(name: 'Potato', protein: '2g', carbs: '17g', fat: '0.1g', quantity: '100g', category: 'Veg', calories: '77'),
    FoodItem(name: 'Corn', protein: '3.2g', carbs: '19g', fat: '1.2g', quantity: '100g', category: 'Veg', calories: '86'),
  ];
  
  static const List<FoodItem> fruits = [
    FoodItem(name: 'Banana', protein: '1.1g', carbs: '23g', fat: '0.3g', quantity: '1 medium', category: 'Fruit', calories: '105'),
    FoodItem(name: 'Apple', protein: '0.3g', carbs: '14g', fat: '0.2g', quantity: '1 medium', category: 'Fruit', calories: '95'),
    FoodItem(name: 'Orange', protein: '0.9g', carbs: '12g', fat: '0.1g', quantity: '1 medium', category: 'Fruit', calories: '45'),
    FoodItem(name: 'Blueberries', protein: '0.7g', carbs: '14g', fat: '0.3g', quantity: '100g', category: 'Fruit', calories: '57'),
    FoodItem(name: 'Strawberries', protein: '0.7g', carbs: '8g', fat: '0.3g', quantity: '100g', category: 'Fruit', calories: '32'),
    FoodItem(name: 'Watermelon', protein: '0.6g', carbs: '8g', fat: '0.2g', quantity: '100g', category: 'Fruit', calories: '30'),
    FoodItem(name: 'Grapes', protein: '0.6g', carbs: '17g', fat: '0.2g', quantity: '100g', category: 'Fruit', calories: '67'),
    FoodItem(name: 'Pineapple', protein: '0.5g', carbs: '13g', fat: '0.1g', quantity: '100g', category: 'Fruit', calories: '50'),
  ];
  
   static const List<FoodItem> vegetables = [
    FoodItem(name: 'Broccoli', protein: '2.8g', carbs: '7g', fat: '0.4g', quantity: '100g', category: 'Veg', calories: '34'),
    FoodItem(name: 'Spinach', protein: '2.9g', carbs: '3.6g', fat: '0.4g', quantity: '100g', category: 'Veg', calories: '23'),
    FoodItem(name: 'Kale', protein: '2.9g', carbs: '4.4g', fat: '1.5g', quantity: '100g', category: 'Veg', calories: '33'),
    FoodItem(name: 'Carrot', protein: '0.9g', carbs: '10g', fat: '0.2g', quantity: '100g', category: 'Veg', calories: '41'),
    FoodItem(name: 'Tomato', protein: '0.9g', carbs: '3.9g', fat: '0.2g', quantity: '100g', category: 'Veg', calories: '18'),
    FoodItem(name: 'Cucumber', protein: '0.7g', carbs: '3.6g', fat: '0.1g', quantity: '100g', category: 'Veg', calories: '16'),
    FoodItem(name: 'Bell Pepper', protein: '1g', carbs: '6g', fat: '0.3g', quantity: '100g', category: 'Veg', calories: '31'),
    FoodItem(name: 'Mushrooms', protein: '3.1g', carbs: '3.3g', fat: '0.3g', quantity: '100g', category: 'Veg', calories: '22'),
  ];
}
