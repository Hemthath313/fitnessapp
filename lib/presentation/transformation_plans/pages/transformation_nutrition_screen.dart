import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/data/transformation_food_library.dart';
import 'package:fitness_app/presentation/transformation_plans/models/transformation_meal_plan_model.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/transformation_log_meal_dialog.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';

/// Screen displaying the complete, personalized daily meal plan for any programme day,
/// with exact food quantities, raw/cooked indications, macro breakdown, ingredient substitutions,
/// and direct integration with the canonical ConsumptionProvider food tracker.
class TransformationNutritionScreen extends StatefulWidget {
  final int? initialDayNumber;

  const TransformationNutritionScreen({
    super.key,
    this.initialDayNumber,
  });

  @override
  State<TransformationNutritionScreen> createState() =>
      _TransformationNutritionScreenState();
}

class _TransformationNutritionScreenState
    extends State<TransformationNutritionScreen> {
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TransformationProvider>(context, listen: false);
    _selectedDay = widget.initialDayNumber ?? provider.activeTransformation?.currentDay ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransformationProvider>(context);
    final consumption = Provider.of<ConsumptionProvider?>(context);
    final active = provider.activeTransformation;

    if (active == null) {
      return Scaffold(
        backgroundColor: ColorManager.background,
        appBar: AppBar(
          title: const Text('Daily Meal Plan'),
          backgroundColor: ColorManager.surface,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'No active transformation plan found.\nEnroll in a programme to generate daily meal plans.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ColorManager.textSecondary, fontSize: 14.sp),
          ),
        ),
      );
    }

    final blueprint = provider.activeBlueprint;
    final primaryColor = blueprint != null
        ? Color(int.parse(blueprint.gradientColorHex))
        : ColorManager.primary;

    final mealPlan = provider.getMealPlanForDay(_selectedDay);

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Meal Plan',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${active.planTitle} • Day $_selectedDay',
              style: TextStyle(
                color: primaryColor,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: ColorManager.surface,
        elevation: 0,
        leading: IconButton(tooltip: 'Back', 
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: ColorManager.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Day Selector Carousel
            _buildDaySelector(active.totalDays, active.currentDay, primaryColor),
            SizedBox(height: 16.h),

            // 2. Clinical Review / Safety Alert Banner (if flagged)
            if (mealPlan != null && mealPlan.flaggedForReview) ...[
              _buildReviewBanner(mealPlan.reviewMessage),
              SizedBox(height: 16.h),
            ],

            // 3. Planned vs. Actual Consumed Nutrition Card
            if (mealPlan != null)
              _buildNutritionSummaryCard(mealPlan, consumption, primaryColor),
            SizedBox(height: 20.h),

            // 4. Meals Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Scheduled Daily Meals (5)',
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    active.dietaryPreference ?? 'Personalized',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // 5. 5 Meal Cards
            if (mealPlan != null && mealPlan.meals.isNotEmpty)
              ...mealPlan.meals.map((meal) => _buildMealCard(
                    meal: meal,
                    dayNumber: _selectedDay,
                    provider: provider,
                    primaryColor: primaryColor,
                    userAllergies: active.allergies,
                    dietaryPreference: active.dietaryPreference,
                  ))
            else
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: ColorManager.surface,
                  boxShadow: ColorManager.cardShadow,
                  borderRadius: BorderRadius.circular(AppRadius.tile.r),
                ),
                child: Text(
                  'No meal plan available for this day. Please check allergy settings.',
                  style: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp),
                ),
              ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector(int totalDays, int currentDay, Color primaryColor) {
    return SizedBox(
      height: 48.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalDays,
        itemBuilder: (context, idx) {
          final dayNum = idx + 1;
          final isSelected = dayNum == _selectedDay;
          final isToday = dayNum == currentDay;

          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: InkWell(
              key: Key('nutrition_day_tab_$dayNum'),
              onTap: () => setState(() => _selectedDay = dayNum),
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : ColorManager.surface,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected
                        ? primaryColor
                        : (isToday ? primaryColor.withValues(alpha: 0.5) : ColorManager.divider),
                    width: isToday ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  isToday ? 'Day $dayNum (Today)' : 'Day $dayNum',
                  style: TextStyle(
                    color: isSelected ? ColorManager.onColor(primaryColor) : ColorManager.textPrimary,
                    fontSize: 12.sp,
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewBanner(String? message) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA500).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFFFA500).withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFFFA500), size: 20),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nutritional Review Note',
                  style: TextStyle(
                    color: const Color(0xFFFFA500),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  message ??
                      'Target caloric intake is below standard baseline. Clinical or dietician consultation is advised.',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummaryCard(
    TransformationDailyMealPlan plan,
    ConsumptionProvider? consumption,
    Color primaryColor,
  ) {
    final actualCalories = consumption?.consumedCalories ?? 0;
    final plannedCalories = plan.plannedCalories.round();
    final pct = plannedCalories > 0 ? (actualCalories / plannedCalories).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Daily Target Breakdown',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'Plan Sum: ${plan.actualTotalCalories.round()} kcal',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Calorie progress (Actual logged vs planned)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Logged Today: $actualCalories / $plannedCalories kcal',
                  style: TextStyle(
                    color: ColorManager.textSecondary,
                    fontSize: 12.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '${(pct * 100).toInt()}%',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6.h,
              backgroundColor: ColorManager.surfaceDark,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
          SizedBox(height: 14.h),

          // Macro distribution targets
          Row(
            children: [
              Expanded(
                child: _buildMacroTargetPill(
                  'Protein',
                  '${plan.plannedProtein.round()}g',
                  ColorManager.secondary,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildMacroTargetPill(
                  'Carbs',
                  '${plan.plannedCarbs.round()}g',
                  primaryColor,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildMacroTargetPill(
                  'Fats',
                  '${plan.plannedFat.round()}g',
                  const Color(0xFFFFA500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroTargetPill(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard({
    required TransformationMeal meal,
    required int dayNumber,
    required TransformationProvider provider,
    required Color primaryColor,
    required List<String> userAllergies,
    required String? dietaryPreference,
  }) {
    final mealKey = 'day_${dayNumber}_meal_${meal.id}';
    final isLogged = provider.isMealLoggedToday(mealKey) || meal.isLogged;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(
          color: isLogged ? ColorManager.success.withValues(alpha: 0.5) : ColorManager.divider,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.restaurant_rounded, color: primaryColor, size: 16),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meal.name,
                              style: TextStyle(
                                color: ColorManager.textPrimary,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              meal.timeGuidance,
                              style: TextStyle(
                                color: ColorManager.textSecondary,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: ColorManager.surfaceDark,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '${meal.totalCalories.round()} kcal',
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Foods List
            ...meal.foods.asMap().entries.map((entry) {
              final idx = entry.key;
              final food = entry.value;
              final subKey = 'day_${dayNumber}_meal_${meal.id}_food_$idx';

              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: ColorManager.surfaceDark,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  food.name,
                                  style: TextStyle(
                                    color: ColorManager.textPrimary,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                                decoration: BoxDecoration(
                                  color: food.isRawWeight
                                      ? Colors.amber.withValues(alpha: 0.15)
                                      : Colors.blue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  food.preparationNote,
                                  style: TextStyle(
                                    color: food.isRawWeight ? Colors.amber[800] : Colors.blue[300],
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            '${food.quantity} ${food.unit} • ${food.calories.round()} kcal | ${food.protein}g P | ${food.carbs}g C | ${food.fat}g F',
                            style: TextStyle(
                              color: ColorManager.textSecondary,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Swap / Substitute Button
                    IconButton(
                      key: Key('swap_${meal.id}_food_$idx'),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      color: primaryColor,
                      tooltip: 'Swap food',
                      onPressed: () => _showSubstituteModal(
                        context: context,
                        food: food,
                        subKey: subKey,
                        provider: provider,
                        userAllergies: userAllergies,
                        dietaryPreference: dietaryPreference,
                      ),
                    ),
                  ],
                ),
              );
            }),

            SizedBox(height: 8.h),

            // Log Meal Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: Key('log_meal_${meal.id}_button'),
                onPressed: isLogged
                    ? null
                    : () => TransformationLogMealDialog.show(
                          context: context,
                          meal: meal,
                          dayNumber: dayNumber,
                          provider: provider,
                        ),
                icon: Icon(
                  isLogged ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                  size: 16.sp,
                  color: isLogged ? ColorManager.success : primaryColor,
                ),
                label: Text(
                  isLogged ? '✓ Logged to Food Tracker' : 'Log ${meal.name} to Tracker',
                  style: TextStyle(
                    color: isLogged ? ColorManager.success : primaryColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isLogged
                        ? ColorManager.success.withValues(alpha: 0.5)
                        : primaryColor.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button.r)),
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubstituteModal({
    required BuildContext context,
    required TransformationFoodItem food,
    required String subKey,
    required TransformationProvider provider,
    required List<String> userAllergies,
    required String? dietaryPreference,
  }) {
    final substitutes = TransformationFoodLibrary.getSafeSubstitutes(
      foodId: food.id,
      userAllergies: userAllergies,
      dietaryPreference: dietaryPreference,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: ColorManager.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(18.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Substitute ${food.name}',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Select a nutritionally similar alternative:',
              style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
            ),
            SizedBox(height: 14.h),

            if (substitutes.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Text(
                  'No allergen-safe substitutes available for this ingredient.',
                  style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
                ),
              )
            else
              ...substitutes.map((sub) => Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    decoration: BoxDecoration(
                      color: ColorManager.surfaceDark,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: ListTile(
                      title: Text(
                        sub.name,
                        style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp),
                      ),
                      subtitle: Text(
                        '${sub.quantity} ${sub.unit} (${sub.preparationNote}) • ${sub.calories.round()} kcal | ${sub.protein}g P',
                        style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
                      ),
                      trailing: Icon(Icons.check_circle_outline_rounded, color: ColorManager.primaryText),
                      onTap: () async {
                        await provider.updateMealSubstitution(
                          substitutionKey: subKey,
                          foodId: sub.id,
                        );
                        if (context.mounted) {
                          Navigator.of(ctx).pop();
                          setState(() {});
                        }
                      },
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
