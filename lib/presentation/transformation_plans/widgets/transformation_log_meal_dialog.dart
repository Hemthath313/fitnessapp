import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/presentation/transformation_plans/models/transformation_meal_plan_model.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';

/// Modal bottom sheet allowing users to review, adjust portion scale,
/// and log a recommended meal directly into the canonical ConsumptionProvider tracker.
class TransformationLogMealDialog extends StatefulWidget {
  final TransformationMeal meal;
  final int dayNumber;
  final TransformationProvider provider;

  const TransformationLogMealDialog({
    super.key,
    required this.meal,
    required this.dayNumber,
    required this.provider,
  });

  static Future<void> show({
    required BuildContext context,
    required TransformationMeal meal,
    required int dayNumber,
    required TransformationProvider provider,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransformationLogMealDialog(
        meal: meal,
        dayNumber: dayNumber,
        provider: provider,
      ),
    );
  }

  @override
  State<TransformationLogMealDialog> createState() =>
      _TransformationLogMealDialogState();
}

class _TransformationLogMealDialogState
    extends State<TransformationLogMealDialog> {
  double _portionScale = 1.0;
  bool _isLogging = false;

  @override
  Widget build(BuildContext context) {
    final scaledCalories = (widget.meal.totalCalories * _portionScale).round();
    final scaledProtein = (widget.meal.totalProtein * _portionScale).toStringAsFixed(1);
    final scaledCarbs = (widget.meal.totalCarbs * _portionScale).toStringAsFixed(1);
    final scaledFat = (widget.meal.totalFat * _portionScale).toStringAsFixed(1);

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: ColorManager.divider,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 14.h),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log ${widget.meal.name}',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Day ${widget.dayNumber} • Planned Nutrition',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(tooltip: 'Close', 
                icon: Icon(Icons.close_rounded, color: ColorManager.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Food items summary
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: ColorManager.surfaceDark,
              borderRadius: BorderRadius.circular(AppRadius.small.r),
            ),
            child: Column(
              children: widget.meal.foods.map((food) {
                final foodQty = (food.quantity * _portionScale).toStringAsFixed(food.unit == 'piece' || food.unit == 'slice' ? 0 : 1);
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${food.name} ($foodQty ${food.unit})',
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 12.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${(food.calories * _portionScale).round()} kcal',
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 14.h),

          // Portion Scale Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Portion Eaten: ${(_portionScale * 100).toInt()}%',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [0.75, 1.0, 1.25].map((preset) {
                  final isSelected = (_portionScale - preset).abs() < 0.05;
                  return Padding(
                    padding: EdgeInsets.only(left: 6.w),
                    child: InkWell(
                      onTap: () => setState(() => _portionScale = preset),
                      borderRadius: BorderRadius.circular(6.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: isSelected ? ColorManager.primary : ColorManager.surfaceDark,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          '${(preset * 100).toInt()}%',
                          style: TextStyle(
                            color: isSelected ? ColorManager.onMint : ColorManager.textSecondary,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Slider(
            value: _portionScale,
            min: 0.5,
            max: 1.5,
            divisions: 10,
            activeColor: ColorManager.primary,
            inactiveColor: ColorManager.surfaceDark,
            onChanged: (val) => setState(() => _portionScale = val),
          ),
          SizedBox(height: 10.h),

          // Scaled Nutrition Totals
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: ColorManager.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: ColorManager.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(child: _buildMacroStat('Calories', '$scaledCalories', 'kcal')),
                Expanded(child: _buildMacroStat('Protein', '${scaledProtein}g', 'P')),
                Expanded(child: _buildMacroStat('Carbs', '${scaledCarbs}g', 'C')),
                Expanded(child: _buildMacroStat('Fats', '${scaledFat}g', 'F')),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('confirm_log_meal_button'),
              onPressed: _isLogging
                  ? null
                  : () async {
                      final nav = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => _isLogging = true);
                      try {
                        await widget.provider.logMealToConsumptionTracker(
                          context: context,
                          meal: widget.meal,
                          dayNumber: widget.dayNumber,
                          portionMultiplier: _portionScale,
                        );
                        if (mounted) {
                          nav.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                  '✓ ${widget.meal.name} ($scaledCalories kcal) logged to Food Tracker!'),
                              backgroundColor: ColorManager.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() => _isLogging = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Failed to log meal: $e'),
                              backgroundColor: ColorManager.error,
                            ),
                          );
                        }
                      }
                    },
              icon: _isLogging
                  ? SizedBox(
                      width: 18.w,
                      height: 18.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, color: ColorManager.onMint),
              label: Text(
                _isLogging ? 'Logging...' : 'Log to Gym Buddy Food Tracker',
                style: TextStyle(
                  color: ColorManager.onMint,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button.r),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroStat(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: 14.sp,
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
    );
  }
}
