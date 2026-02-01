import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';

class SummaryCard extends StatelessWidget {
  final int remainingCalories;
  final int remainingProtein;
  final int remainingCarbs;
  final int remainingFats;

  const SummaryCard({
    Key? key,
    required this.remainingCalories,
    required this.remainingProtein,
    required this.remainingCarbs,
    required this.remainingFats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);
    final userData = homeProvider.userData;

    double storedBMR = userData['bmr'] ?? 0.0;
    double storedBMI = userData['bmi'] ?? 0.0;
    double weight = userData['weight'] ?? 70.0;

    int totalCalories = (storedBMR > 0) ? storedBMR.toInt() : (storedBMI * 30).toInt();
    if (totalCalories == 0) totalCalories = 2000; // Default fallback

    int totalProtein = (weight * 2.0).toInt();
    int totalCarbs = (weight * 3.5).toInt();
    int totalFats = (weight * 0.8).toInt();

    return Container(
      padding: EdgeInsets.all(SizeManager.s16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(SizeManager.s20.r),
        border: Border.all(color: ColorManager.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildMainCalorieCircle(totalCalories, remainingCalories),
          SizedBox(height: SizeManager.s20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroItem('Protein', totalProtein, remainingProtein, Colors.orangeAccent),
              _buildMacroItem('Carbs', totalCarbs, remainingCarbs, Colors.blueAccent),
              _buildMacroItem('Fats', totalFats, remainingFats, Colors.pinkAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainCalorieCircle(int total, int remaining) {
    int consumed = total - remaining;
    double progress = (consumed / total).clamp(0.0, 1.0);

    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 70.w,
              width: 70.w,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: ColorManager.background,
                color: ColorManager.primary,
              ),
            ),
            Icon(Icons.bolt, color: ColorManager.primary, size: 24.w),
          ],
        ),
        SizedBox(width: SizeManager.s20.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Calories',
                style: TextStyle(
                  color: ColorManager.white70,
                  fontSize: SizeManager.s14.sp,
                ),
              ),
              Text(
                '${consumed.clamp(0, total)} / $total kcal',
                style: TextStyle(
                  color: ColorManager.white,
                  fontSize: SizeManager.s20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: SizeManager.s4.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: ColorManager.background,
                  color: ColorManager.primary,
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacroItem(String label, int total, int remaining, Color color) {
    int consumed = total - remaining;
    double progress = (consumed / total).clamp(0.0, 1.0);

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: ColorManager.white70, fontSize: SizeManager.s12.sp),
        ),
        SizedBox(height: SizeManager.s8.h),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 45.w,
              width: 45.w,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                backgroundColor: ColorManager.background,
                color: color,
              ),
            ),
            Text(
              '${consumed.clamp(0, total)}g',
              style: TextStyle(
                color: ColorManager.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: SizeManager.s4.h),
        Text(
          'Target: $total g',
          style: TextStyle(color: color.withOpacity(0.7), fontSize: 8.sp),
        ),
      ],
    );
  }
}
