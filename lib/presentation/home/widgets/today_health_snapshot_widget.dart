import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/fitness_data_widget.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Compact Today's Health Snapshot for Option A (Focused Daily Companion).
///
/// Combines:
/// 1. Calories consumed vs valid calorie target (never BMR).
/// 2. Water consumed vs user's configured dynamic water goal.
/// 3. Compact 7-day workout consistency indicator.
class TodayHealthSnapshotWidget extends StatefulWidget {
  const TodayHealthSnapshotWidget({super.key});

  @override
  State<TodayHealthSnapshotWidget> createState() =>
      _TodayHealthSnapshotWidgetState();
}

class _TodayHealthSnapshotWidgetState extends State<TodayHealthSnapshotWidget> {
  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    _userDataFuture = homeProvider.fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<ConsumptionProvider, StatisticsProvider>(
      builder: (context, consumptionProvider, statsProvider, _) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _userDataFuture,
          builder: (context, snapshot) {
            final homeProvider =
                Provider.of<HomeProvider>(context, listen: false);
            final cachedData = homeProvider.userData;
            final effectiveData =
                (snapshot.hasData && snapshot.data!.isNotEmpty)
                    ? snapshot.data!
                    : (cachedData.isNotEmpty ? cachedData : <String, dynamic>{});

            final calorieInfo = FitnessDataWidget.resolveCalorieGoal(
              context: context,
              userData: effectiveData,
            );
            final hasTarget = calorieInfo.hasValidTarget;
            final targetCalories = calorieInfo.targetCalories ?? 0.0;
            final consumedCalories = consumptionProvider.consumedCalories;
            final remainingCalories = hasTarget
                ? (targetCalories - consumedCalories).clamp(0.0, double.infinity)
                : 0.0;
            final caloriePercent = (hasTarget && targetCalories > 0
                    ? (consumedCalories / targetCalories)
                    : 0.0)
                .clamp(0.0, 1.0);

            final waterGoal = FitnessDataWidget.resolveWaterGoal(
              context: context,
              consumptionProvider: consumptionProvider,
              userData: effectiveData,
            );
            final consumedWater = consumptionProvider.waterADay;
            final waterPercent = (waterGoal > 0 ? (consumedWater / waterGoal) : 0.0)
                .clamp(0.0, 1.0);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: ColorManager.surfaceLight,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: ColorManager.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Section title + compact weekly consistency dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.insights_rounded,
                                color: ColorManager.primary,
                                size: 16.sp,
                              ),
                              SizedBox(width: 6.w),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Today's Snapshot",
                                    style: TextStyle(
                                      color: ColorManager.textPrimary,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 6.w),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _buildWeeklyConsistencyDots(statsProvider),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Metrics: Side-by-Side Calories & Water compact cards
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left: Calorie Tracker Card
                          Expanded(
                            child: GestureDetector(
                              key: const Key('snapshot_calorie_card'),
                              onTap: () {
                                if (hasTarget) {
                                  context.push(Routes.newMealRoute);
                                } else {
                                  context.push(Routes.changeWeightRoute);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: ColorManager.surface,
                                  borderRadius: BorderRadius.circular(14.r),
                                  border: Border.all(
                                    color: ColorManager.divider.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.local_fire_department_rounded,
                                          color: Colors.orange,
                                          size: 15.sp,
                                        ),
                                        SizedBox(width: 4.w),
                                        Flexible(
                                          child: Text(
                                            'Calories',
                                            style: TextStyle(
                                              color: ColorManager.textSecondary,
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: ColorManager.textSecondary
                                              .withValues(alpha: 0.4),
                                          size: 14.sp,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '$consumedCalories kcal',
                                        style: TextStyle(
                                          color: ColorManager.textPrimary,
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        hasTarget
                                            ? '/ ${targetCalories.toStringAsFixed(0)} kcal'
                                            : 'Not Set',
                                        style: TextStyle(
                                          color: ColorManager.textSecondary,
                                          fontSize: 10.sp,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4.r),
                                      child: LinearProgressIndicator(
                                        value: caloriePercent,
                                        backgroundColor: isDarkMode
                                            ? Colors.white10
                                            : Colors.black12,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                          Colors.orange,
                                        ),
                                        minHeight: 5.h,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        hasTarget
                                            ? '${remainingCalories.toStringAsFixed(0)} left'
                                            : 'Set in profile',
                                        style: TextStyle(
                                          color: hasTarget
                                              ? (remainingCalories > 0
                                                  ? ColorManager.primary
                                                  : Colors.green)
                                              : Colors.orange,
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),

                          // Right: Water Tracker Card
                          Expanded(
                            child: GestureDetector(
                              key: const Key('snapshot_water_card'),
                              onTap: () => context.push(Routes.addWaterRoute),
                              child: Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: ColorManager.surface,
                                  borderRadius: BorderRadius.circular(14.r),
                                  border: Border.all(
                                    color: ColorManager.divider.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.water_drop_rounded,
                                          color: Colors.blue,
                                          size: 15.sp,
                                        ),
                                        SizedBox(width: 4.w),
                                        Flexible(
                                          child: Text(
                                            'Water',
                                            style: TextStyle(
                                              color: ColorManager.textSecondary,
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: ColorManager.textSecondary
                                              .withValues(alpha: 0.4),
                                          size: 14.sp,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            consumedWater.toStringAsFixed(1),
                                            style: TextStyle(
                                              color: ColorManager.textPrimary,
                                              fontSize: 15.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 2.w),
                                          Text(
                                            'L',
                                            style: TextStyle(
                                              color: ColorManager.textPrimary,
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            '/ ${waterGoal.toStringAsFixed(1)} L',
                                            style: TextStyle(
                                              color: ColorManager.textSecondary,
                                              fontSize: 10.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4.r),
                                      child: LinearProgressIndicator(
                                        value: waterPercent,
                                        backgroundColor: isDarkMode
                                            ? Colors.white10
                                            : Colors.black12,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                          Colors.blue,
                                        ),
                                        minHeight: 5.h,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '${(waterPercent * 100).toInt()}% of goal',
                                        style: TextStyle(
                                          color: waterPercent >= 1.0
                                              ? Colors.green
                                              : Colors.blue,
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Compact 7-day indicator showing workout consistency for the current week.
  Widget _buildWeeklyConsistencyDots(StatisticsProvider statsProvider) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    final currentWeekday = now.weekday;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (index) {
        final dayIndex = index + 1;
        final isPastOrToday = dayIndex <= currentWeekday;
        final isToday = dayIndex == currentWeekday;

        bool isDone = false;
        if (dayIndex == currentWeekday) {
          isDone = statsProvider.hasWorkoutToday;
        } else if (dayIndex < currentWeekday) {
          final targetDate = now.subtract(Duration(days: currentWeekday - dayIndex));
          isDone = statsProvider.completedWorkoutDates.any((d) =>
              d.year == targetDate.year &&
              d.month == targetDate.month &&
              d.day == targetDate.day);
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 1.w),
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? const Color(0xFF4CAF50)
                : (isToday
                    ? ColorManager.primary.withValues(alpha: 0.3)
                    : (isPastOrToday
                        ? ColorManager.surface
                        : ColorManager.surface.withValues(alpha: 0.4))),
            border: Border.all(
              color: isToday
                  ? ColorManager.primary
                  : (isDone ? const Color(0xFF4CAF50) : ColorManager.divider),
              width: isToday ? 1.0 : 0.8,
            ),
          ),
          child: Center(
            child: isDone
                ? Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 7.sp,
                  )
                : Text(
                    days[index],
                    style: TextStyle(
                      color: isToday
                          ? ColorManager.primary
                          : ColorManager.textSecondary,
                      fontSize: 6.5.sp,
                      fontWeight:
                          isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
          ),
        );
      }),
    );
  }
}
