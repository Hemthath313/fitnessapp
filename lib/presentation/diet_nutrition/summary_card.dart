import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SummaryCard extends StatelessWidget {
  final int totalCalories;
  final int totalProtein;
  final int totalCarbs;
  final int totalFats;
  final int remainingCalories;
  final int remainingProtein;
  final int remainingCarbs;
  final int remainingFats;

  /// What has actually been eaten. When provided these are used as-is, so
  /// eating more than the target is shown honestly (the remaining values can
  /// only reach 0). When null they are derived from total - remaining.
  final int? consumedCalories;
  final int? consumedProtein;
  final int? consumedCarbs;
  final int? consumedFats;

  const SummaryCard({
    Key? key,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFats,
    required this.remainingCalories,
    required this.remainingProtein,
    required this.remainingCarbs,
    required this.remainingFats,
    this.consumedCalories,
    this.consumedProtein,
    this.consumedCarbs,
    this.consumedFats,
  }) : super(key: key);

  // Macro arcs: protein blue, carbs amber, fats violet (coral is calories).
  static const Color _carbsColor = ColorManager.ringAmber;
  static const Color _fatsColor = Color(0xFF8B5CF6);

  /// Shared with the Nutrition Hub estimator so both use the same macro colours.
  static const Color carbsColor = _carbsColor;
  static const Color fatsColor = _fatsColor;

  static double _progress(int consumed, int total) =>
      total <= 0 ? 0.0 : (consumed / total).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
      ),
      child: Column(
        children: [
          _buildMainCalorieCircle(totalCalories, remainingCalories, consumedCalories),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: _buildMacroItem('Protein', totalProtein, remainingProtein,
                    ColorManager.primary, consumedProtein),
              ),
              Expanded(
                child: _buildMacroItem('Carbs', totalCarbs, remainingCarbs, _carbsColor,
                    consumedCarbs),
              ),
              Expanded(
                child: _buildMacroItem(
                    'Fats', totalFats, remainingFats, _fatsColor, consumedFats),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainCalorieCircle(int total, int remaining, int? eaten) {
    final int consumed = eaten ??
        (total - remaining).clamp(0, total < 0 ? 0 : total).toInt();
    final double progress = _progress(consumed, total);
    final int left = total - consumed < 0 ? 0 : total - consumed;
    final int over = consumed - total > 0 ? consumed - total : 0;

    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 76.w,
              width: 76.w,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                // Calories are coral everywhere (snapshot, diet, streak).
                backgroundColor: ColorManager.calorie.withValues(alpha: 0.18),
                color: ColorManager.calorieText,
              ),
            ),
            Icon(Icons.local_fire_department_rounded, color: ColorManager.calorieText, size: 26.w),
          ],
        ),
        SizedBox(width: 18.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Calories',
                style: TextStyle(
                  color: ColorManager.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 2.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$consumed / $total kcal',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: ColorManager.calorie.withValues(alpha: 0.18),
                  color: ColorManager.calorieText,
                  minHeight: 6.h,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                over > 0 ? '$over kcal over' : '$left kcal left',
                key: const Key('summary_calories_status'),
                style: TextStyle(
                  color: over > 0
                      ? ColorManager.warningText
                      : ColorManager.textSecondary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacroItem(
      String label, int total, int remaining, Color color, int? eaten) {
    final int consumed =
        eaten ?? (total - remaining).clamp(0, total < 0 ? 0 : total).toInt();
    final double progress = _progress(consumed, total);

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: ColorManager.textSecondary,
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 54.w,
              width: 54.w,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                backgroundColor: ColorManager.chipBackground,
                color: color,
              ),
            ),
            Text(
              '${consumed}g',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          'Target: $total g',
          style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
        ),
      ],
    );
  }
}
