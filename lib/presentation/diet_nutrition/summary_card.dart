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
  }) : super(key: key);

  // Macro arcs: one mint family plus warm accents (functional, not decorative).
  static const Color _carbsColor = Color(0xFFF4B03E);
  static const Color _fatsColor = Color(0xFFE58B6E);

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
          _buildMainCalorieCircle(totalCalories, remainingCalories),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: _buildMacroItem(
                    'Protein', totalProtein, remainingProtein, ColorManager.primary),
              ),
              Expanded(
                child: _buildMacroItem(
                    'Carbs', totalCarbs, remainingCarbs, _carbsColor),
              ),
              Expanded(
                child: _buildMacroItem(
                    'Fats', totalFats, remainingFats, _fatsColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainCalorieCircle(int total, int remaining) {
    final int consumed =
        (total - remaining).clamp(0, total < 0 ? 0 : total).toInt();
    final double progress = _progress(consumed, total);
    final int left = remaining < 0 ? 0 : remaining;

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
                backgroundColor: ColorManager.iconChip,
                color: ColorManager.primary,
              ),
            ),
            Icon(Icons.bolt_rounded, color: ColorManager.primary, size: 26.w),
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
                  backgroundColor: ColorManager.iconChip,
                  color: ColorManager.primary,
                  minHeight: 6.h,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                '$left kcal left',
                style: TextStyle(
                  color: ColorManager.primary,
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

  Widget _buildMacroItem(String label, int total, int remaining, Color color) {
    final int consumed =
        (total - remaining).clamp(0, total < 0 ? 0 : total).toInt();
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
                backgroundColor: ColorManager.iconChip,
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
          style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
        ),
      ],
    );
  }
}
