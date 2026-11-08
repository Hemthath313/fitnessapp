import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';

/// Widget displaying rolling weekly adherence scores and habit consistency breakdown.
class TransformationWeeklyAdherenceSummary extends StatelessWidget {
  final DateTime? referenceDate;
  final int daysCount;

  const TransformationWeeklyAdherenceSummary({
    super.key,
    this.referenceDate,
    this.daysCount = 7,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransformationProvider, ConsumptionProvider?>(
      builder: (context, transformationProvider, consumptionProvider, _) {
        final summary = transformationProvider.getWeeklyAdherenceSummary(
          referenceDate: referenceDate,
          daysCount: daysCount,
          consumptionProvider: consumptionProvider,
        );

        final blueprint = transformationProvider.activeBlueprint;
        final primaryColor = blueprint != null
            ? Color(int.parse(blueprint.gradientColorHex.replaceFirst('0x', ''), radix: 16))
            : ColorManager.primary;

        return Container(
          key: const Key('weekly_adherence_summary_card'),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: ColorManager.surface,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.insights_rounded, color: primaryColor, size: 20.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Weekly Habit Consistency',
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (summary.hasEnoughData) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '${summary.averageAdherenceScore.round()}% Avg',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                ],
              ),
              SizedBox(height: 12.h),

              if (!summary.hasEnoughData) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: ColorManager.surfaceDark,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'No historical data recorded yet. Complete daily workouts and nutrition check-ins to build your weekly consistency score.',
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontSize: 12.sp,
                      height: 1.4,
                    ),
                  ),
                ),
              ] else ...[
                // Daily scores chips row
                SizedBox(
                  height: 52.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _buildDayScoreChips(summary, primaryColor),
                  ),
                ),
                SizedBox(height: 14.h),

                // Consistency Metrics Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.fitness_center_rounded,
                        color: primaryColor,
                        label: 'Workouts',
                        value: '${summary.workoutsCompletedCount} done',
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.local_fire_department_rounded,
                        color: ColorManager.accent,
                        label: 'Calories',
                        value: '${summary.calorieConsistencyCount} on target',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.egg_alt_rounded,
                        color: ColorManager.secondary,
                        label: 'Protein',
                        value: '${summary.proteinConsistencyCount} hit target',
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.water_drop_rounded,
                        color: Colors.blue,
                        label: 'Hydration',
                        value: '${summary.waterGoalConsistencyCount} hit goal',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildDayScoreChips(
    TransformationWeeklyAdherenceSummaryData summary,
    Color primaryColor,
  ) {
    final ref = referenceDate ?? DateTime.now();
    final chips = <Widget>[];

    for (int i = daysCount - 1; i >= 0; i--) {
      final date = ref.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayLetter = DateFormat('E').format(date).substring(0, 1);
      final score = summary.dailyScores[dateStr];

      chips.add(
        Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: Container(
            width: 44.w,
            padding: EdgeInsets.symmetric(vertical: 6.h),
            decoration: BoxDecoration(
              color: score != null
                  ? primaryColor.withValues(alpha: 0.12)
                  : ColorManager.surfaceDark,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: score != null
                    ? primaryColor.withValues(alpha: 0.4)
                    : ColorManager.divider,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayLetter,
                  style: TextStyle(
                    color: ColorManager.textSecondary,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  score != null ? '${score.round()}%' : '—',
                  style: TextStyle(
                    color: score != null ? primaryColor : ColorManager.textTertiary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return chips;
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: ColorManager.textSecondary, fontSize: 10.sp),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
