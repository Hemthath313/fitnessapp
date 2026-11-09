# Product rules

Rules about what the app does that are decided by the product owner and must not
be changed by accident. Update this file when a rule changes.

## Meal logging and tracking is Pro-only

- Only Pro (premium) users can **log meals** and **track meals** (tick plan meals
  off, add custom meals, manual "Add Meal", the calorie/macro progress that
  results from them).
- Free users can still see informational content: the Nutrition Hub, the
  calorie/macro estimator, the Food Library and their calorie target.
- Enforced in the UI by `ProFeatureGate`
  (`lib/presentation/diet_nutrition/widgets/pro_feature_gate.dart`), which wraps
  the Bulking / Cutting / Maintain plan screens and the manual Add Meal page.
  Any new screen that logs or tracks meals must be wrapped in it too.
- The Nutrition Hub locks the meal-plan card for free users (`_handlePlanTap`).
  The "Today's Food Log" card is hidden from free users entirely (no locked
  teaser), so it never nudges them toward Pro.
- Today's calories on Home = plan meals ticked off + meals logged by hand
  (`ConsumptionProvider.consumedCalories`). Both are Pro-only to create.
- Water tracking is NOT Pro-only.

## One calorie / macro target everywhere

- All screens read targets from `NutritionTargets`
  (`lib/presentation/diet_nutrition/nutrition_targets.dart`).
- The goal adjustment (deficit / surplus) is applied once. The profile's stored
  `bmr` field already includes it: never treat it as maintenance and never add
  another surplus or deficit on top.

## Units

- Water is stored and displayed in **liters** (`waterADay`, quick add 0.2 / 0.5 /
  1.0). Convert before comparing with millilitre values.
