import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';

/// Card displaying weekly scheduling breakdown and advisory insights
class TransformationWeeklyScheduleCard extends StatelessWidget {
  final int? weekNumber;

  const TransformationWeeklyScheduleCard({
    super.key,
    this.weekNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TransformationProvider>(
      builder: (context, provider, _) {
        final state = provider.activeTransformation;
        if (state == null) return const SizedBox.shrink();

        final summary = provider.getWeeklyScheduleSummary(weekNumber: weekNumber);
        final currentWeek = summary.weekNumber;

        return Container(
          key: const Key('transformation_weekly_schedule_card'),
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: ColorManager.surface,
            boxShadow: ColorManager.cardShadow,
            borderRadius: BorderRadius.circular(AppRadius.tile.r),
            border: Border.all(color: ColorManager.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, color: ColorManager.primaryText, size: 18.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Week $currentWeek Schedule Insights',
                            style: TextStyle(
                              color: ColorManager.textPrimary,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: ColorManager.surfaceDark,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '${summary.completedWorkouts} / ${summary.plannedWorkouts} Done',
                      style: TextStyle(
                        color: summary.completedWorkouts == summary.plannedWorkouts && summary.plannedWorkouts > 0
                            ? ColorManager.successText
                            : ColorManager.textSecondary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // 4 Stat Counters in a Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatChip(
                      label: 'Planned',
                      value: '${summary.plannedWorkouts}',
                      color: ColorManager.textPrimary,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: _buildStatChip(
                      label: 'Completed',
                      value: '${summary.completedWorkouts}',
                      color: ColorManager.success,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: _buildStatChip(
                      label: 'Rescheduled',
                      value: '${summary.rescheduledWorkouts}',
                      color: ColorManager.secondary,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: _buildStatChip(
                      label: 'Skipped',
                      value: '${summary.skippedWorkouts}',
                      color: ColorManager.accent,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),

              // Advisory Recommendation Message
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: ColorManager.surfaceDark,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: summary.skippedWorkouts >= 2
                        ? ColorManager.accent.withValues(alpha: 0.3)
                        : ColorManager.divider,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      summary.skippedWorkouts >= 2
                          ? Icons.info_outline_rounded
                          : Icons.lightbulb_outline_rounded,
                      size: 14.sp,
                      color: summary.skippedWorkouts >= 2 ? ColorManager.accentText : ColorManager.primaryText,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        summary.advisoryInsights.join(' '),
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 12.sp,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              color: ColorManager.textTertiary,
              fontSize: 12.sp,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
