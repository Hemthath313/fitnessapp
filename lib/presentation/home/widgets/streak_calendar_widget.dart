import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class StreakCalendarWidget extends StatelessWidget {
  const StreakCalendarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsProvider>(
      builder: (context, statsProvider, child) {
        final currentStreak = statsProvider.currentStreak;
        final completedDates = statsProvider.completedWorkoutDates;

        // Calculate start of current week (Monday)
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final currentDayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday
        final startOfWeek = today.subtract(Duration(days: currentDayOfWeek - 1));

        // Generate list of 7 days of this week
        final weekDays = List.generate(7, (index) {
          return startOfWeek.add(Duration(days: index));
        });

        // Determine next milestone
        String nextMilestoneName = '7 Day Streak';
        int targetDays = 7;
        if (currentStreak >= 7 && currentStreak < 30) {
          nextMilestoneName = 'Monthly Warrior';
          targetDays = 30;
        } else if (currentStreak >= 30) {
          nextMilestoneName = '90 Day Champion';
          targetDays = 90;
        }

        final double progress = (currentStreak / targetDays).clamp(0.0, 1.0);

        final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

        final completedToday = completedDates.any((d) =>
            d.year == today.year && d.month == today.month && d.day == today.day);

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: ColorManager.surface,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: ColorManager.divider.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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
                        Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.orange,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentStreak > 0
                                    ? '$currentStreak Day Streak!'
                                    : (!statsProvider.hasActiveSchedule &&
                                            !statsProvider.hasWorkoutHistory
                                        ? 'Start Your First Workout'
                                        : 'No Active Streak'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                completedToday
                                    ? 'Streak active for today!'
                                    : (currentStreak > 0 &&
                                            statsProvider.isRestDay(today)
                                        ? 'Planned rest day — streak preserved!'
                                        : (currentStreak > 0 &&
                                                statsProvider
                                                    .isPendingScheduledDay(today)
                                            ? 'Workout scheduled today — streak pending'
                                            : (!statsProvider.hasActiveSchedule &&
                                                    !statsProvider
                                                        .hasWorkoutHistory
                                                ? 'Complete your first workout to start a streak'
                                                : 'Log a workout to start a streak'))),
                                style: TextStyle(
                                  color: completedToday ||
                                          (currentStreak > 0 &&
                                              statsProvider.isRestDay(today))
                                      ? ColorManager.limerGreen2
                                      : ColorManager.textSecondary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'This Week',
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),

              // Calendar Strip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final day = weekDays[index];
                  final isCompleted = completedDates.any((d) =>
                      d.year == day.year &&
                      d.month == day.month &&
                      d.day == day.day);
                  final isToday = day.year == today.year &&
                      day.month == today.month &&
                      day.day == today.day;
                  final isFuture = day.isAfter(today);

                  return Column(
                    children: [
                      Text(
                        dayLabels[index],
                        style: TextStyle(
                          color: isToday
                              ? ColorManager.primary
                              : ColorManager.textSecondary,
                          fontSize: 12.sp,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: 38.w,
                        height: 38.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? ColorManager.primary
                              : isToday
                                  ? Colors.transparent
                                  : ColorManager.background,
                          border: isCompleted
                              ? null
                              : Border.all(
                                  color: isToday
                                      ? ColorManager.primary
                                      : ColorManager.divider,
                                  width: isToday ? 2.w : 1.w,
                                  style: isToday
                                      ? BorderStyle.solid
                                      : BorderStyle.solid,
                                ),
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 20.sp,
                                )
                              : Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: isToday
                                        ? ColorManager.primary
                                        : isFuture
                                            ? ColorManager.textSecondary
                                                .withOpacity(0.5)
                                            : ColorManager.textSecondary,
                                    fontSize: 13.sp,
                                    fontWeight: isToday
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              SizedBox(height: 20.h),

              // Divider
              Container(
                height: 1.h,
                color: ColorManager.divider.withOpacity(0.4),
              ),
              SizedBox(height: 16.h),

              // Milestone Target
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Next Milestone: $nextMilestoneName',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '$currentStreak/$targetDays Days',
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // Milestone Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8.h,
                  backgroundColor: ColorManager.background,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ColorManager.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
