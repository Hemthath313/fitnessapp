import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/utils/router/router.dart';

/// Mon–Sun "workout duration" style card for the Daily Companion dashboard.
///
/// Matches the reference design: icon chip + title on the left, summary on the
/// right, then seven rounded bars. Today is bright mint, completed past days
/// are dim teal, everything else is muted grey. Data comes only from
/// [StatisticsProvider].
class WeeklyActivityBars extends StatelessWidget {
  const WeeklyActivityBars({super.key});

  static const List<String> _labels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsProvider>(
      builder: (context, stats, _) {
        final now = DateTime.now();
        final todayIndex = now.weekday - 1; // Monday = 0
        final monday = DateTime(now.year, now.month, now.day - todayIndex);

        final done = List<bool>.generate(7, (i) {
          if (i > todayIndex) return false; // future days can't be done yet
          final day = DateTime(monday.year, monday.month, monday.day + i);
          return stats.hasWorkoutOnDate(day);
        });
        final completed = done.where((d) => d).length;
        final target = stats.weeklyTarget;
        final scheduled = stats.scheduledWeekdays; // 1 = Monday
        final isEmptyWeek = completed == 0;

        // An empty week uses short bars so the card doesn't look dead/blank.
        final double barMax = isEmptyWeek ? 46.h : 80.h;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
          child: Container(
            key: const Key('weekly_activity_bars'),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 14.h),
            decoration: BoxDecoration(
              color: ColorManager.surface,
              boxShadow: ColorManager.cardShadow,
              borderRadius: BorderRadius.circular(AppRadius.card.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34.w,
                      height: 34.w,
                      decoration: const BoxDecoration(
                        color: ColorManager.iconChip,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.fitness_center_rounded,
                        size: 16.sp,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'This Week',
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '$completed/$target workouts',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  height: barMax + 28.h,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final isToday = i == todayIndex;
                      final isDone = done[i];

                      final bool isPlanned = !isDone && scheduled.contains(i + 1);
                      final double heightFactor =
                          isDone ? 1.0 : (isPlanned ? 0.6 : 0.38);
                      final Color barColor = isDone
                          ? (isToday
                              ? ColorManager.primary
                              : ColorManager.barDim)
                          : (isPlanned
                              ? ColorManager.primary.withValues(alpha: 0.22)
                              : ColorManager.barMuted);
                      // Today (not done yet) gets a mint outline as a "start here" cue.
                      final bool showTodayRing = isToday && !isDone;

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 3.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: barMax * heightFactor,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: showTodayRing
                                      ? Border.all(
                                          color: ColorManager.primary,
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _labels[i],
                                  style: TextStyle(
                                    color: isToday
                                        ? ColorManager.textPrimary
                                        : ColorManager.textTertiary,
                                    fontSize: 11.sp,
                                    fontWeight: isToday
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                if (isEmptyWeek) ...[
                  SizedBox(height: 10.h),
                  InkWell(
                    key: const Key('weekly_activity_empty_hint'),
                    borderRadius: BorderRadius.circular(8.r),
                    onTap: () => context.push(Routes.workoutLogRoute),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Complete a workout to light up your week.',
                              style: TextStyle(
                                color: ColorManager.textMuted,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                          Text(
                            'Start',
                            style: TextStyle(
                              color: ColorManager.primaryText,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: ColorManager.primaryText,
                            size: 16.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
