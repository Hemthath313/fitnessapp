import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:fitness_app/utils/router/router.dart';

import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/presentation/custom_workouts/day_workout_session_page.dart';
import 'package:intl/intl.dart';

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  void _handleLogLift(BuildContext context) {
    final transformationProvider =
        Provider.of<TransformationProvider?>(context, listen: false);

    // 1. Transformation Priority: When an active transformation exists, avoid
    // showing misleading AI-split prompts or conflicting rest-day messages.
    if (transformationProvider != null &&
        transformationProvider.hasActiveTransformation) {
      final active = transformationProvider.activeTransformation!;
      final todayBp = transformationProvider.currentDayBlueprint;
      final bool isRestDay = todayBp?.isRestDay ?? false;

      if (!isRestDay) {
        // Scheduled workout is already prominently featured in the unified hero card.
        // Route directly to manual/ad-hoc lift logging so user can record single lifts or PRs.
        context.push(Routes.workoutLogRoute);
        return;
      } else {
        // Today is a scheduled rest/recovery day in the active transformation programme.
        showModalBottomSheet(
          context: context,
          backgroundColor: ColorManager.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bedtime_rounded,
                          color: Colors.blueAccent, size: 22.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Today is a Rest Day (Day ${active.currentDay})',
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Your active programme (${active.planTitle}) has a recovery day scheduled today. You can view your roadmap or log an ad-hoc single lift.',
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontSize: 13.sp,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.primary,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push(Routes.transformationRoadmapRoute);
                      },
                      icon: const Icon(Icons.map_rounded, color: Colors.black),
                      label: const Text(
                        'View Programme Roadmap',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: ColorManager.textSecondary,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push(Routes.workoutLogRoute);
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Log a Single Ad-Hoc Lift'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return;
      }
    }

    // 2. Active AI Routine or Starter Split Fallback
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    final grouped = workoutProvider.groupedSplitWorkouts;
    final todayName = DateFormat('EEEE').format(DateTime.now());

    if (grouped.isNotEmpty) {
      if (grouped.containsKey(todayName)) {
        // When today's workout routine is already prominently displayed in HomeAiRoutineCard,
        // avoid presenting a confusing duplicate workout-start action through Log Lift.
        // Instead, route directly to manual/ad-hoc lift logging so the user can record
        // individual exercises, PRs, or extra work without duplicating the routine start.
        context.push(Routes.workoutLogRoute);
      } else {
        // Today is a rest day — find next scheduled day or offer to start next session early
        const weekDays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];
        final currentIndex = weekDays.indexOf(todayName);
        String nextWorkoutDay = '';
        if (currentIndex != -1) {
          for (int i = 1; i <= 6; i++) {
            final next = weekDays[(currentIndex + i) % 7];
            if (grouped.containsKey(next)) {
              nextWorkoutDay = next;
              break;
            }
          }
        }

        if (nextWorkoutDay.isNotEmpty && grouped.containsKey(nextWorkoutDay)) {
          showModalBottomSheet(
            context: context,
            backgroundColor: ColorManager.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            builder: (ctx) => SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bedtime_rounded,
                            color: Colors.blueAccent, size: 22.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'Today is a Rest Day ($todayName)',
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Your next scheduled workout is $nextWorkoutDay (${grouped[nextWorkoutDay]!.length} exercises). You can start it early or log a custom single lift.',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 13.sp,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.primary,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DayWorkoutSessionPage(
                                dayName: nextWorkoutDay,
                                workouts: grouped[nextWorkoutDay]!,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow_rounded,
                            color: Colors.black),
                        label: Text(
                          'Start $nextWorkoutDay Workout Early',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: ColorManager.textSecondary,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.push(Routes.workoutLogRoute);
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Log a Single Ad-Hoc Lift'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          context.push(Routes.workoutLogRoute);
        }
      }
    } else {
      // No active split yet -> prompt user to build plan or log single lift
      showModalBottomSheet(
        context: context,
        backgroundColor: ColorManager.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.fitness_center_rounded,
                        color: ColorManager.primary, size: 22.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Ready to Train?',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'Build an Adaptive AI Split with previous weights and automatic progression, or log a single custom exercise.',
                  style: TextStyle(
                    color: ColorManager.textSecondary,
                    fontSize: 13.sp,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push(Routes.workoutGeneratorRoute);
                    },
                    icon: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.black),
                    label: const Text(
                      'Build My Adaptive Plan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: ColorManager.textSecondary,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push(Routes.workoutLogRoute);
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Log a Single Exercise Manually'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector2<ConsumptionProvider, StatisticsProvider,
        ({bool waterDoneToday, bool workoutDoneToday})>(
      selector: (_, consumption, stats) => (
        waterDoneToday: consumption.waterADay > 0,
        workoutDoneToday: stats.hasWorkoutToday,
      ),
      builder: (context, data, _) {
        final bool waterDoneToday = data.waterDoneToday;
        final bool workoutDoneToday = data.workoutDoneToday;

        final List<Map<String, dynamic>> actions = [
          {
            'icon': Icons.water_drop_rounded,
            'label': 'Water',
            'color': Colors.blue,
            'isCompleted': waterDoneToday,
            'onTap': () => context.push(Routes.addWaterRoute),
          },
          {
            'icon': Icons.fitness_center_rounded,
            'label': 'Log Lift',
            'color': Colors.orange,
            'isCompleted': workoutDoneToday,
            'onTap': () => _handleLogLift(context),
          },
      {
        'icon': Icons.restaurant_menu_rounded,
        'label': 'Diet Plans',
        'color': Colors.green,
        'isCompleted': false,
        'onTap': () {
          context.push(Routes.dietRoute);
        },
      },
      {
        'icon': Icons.auto_awesome_rounded,
        'label': 'AI Routine',
        'color': Colors.purpleAccent,
        'isCompleted': false,
        'onTap': () {
          context.push(Routes.workoutGeneratorRoute);
        },
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
            decoration: BoxDecoration(
              color: ColorManager.surfaceLight,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: ColorManager.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: actions.map((act) {
                final Color baseColor = act['color'] as Color;
                final bool isCompleted = act['isCompleted'] as bool? ?? false;
                return Expanded(
                  child: GestureDetector(
                    onTap: act['onTap'] as VoidCallback,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                    children: [
                      // Circular Icon wrapper with optional completion badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 52.w,
                            height: 52.w,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                                  : baseColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isCompleted
                                    ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                                    : baseColor.withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              act['icon'] as IconData,
                              color: isCompleted ? const Color(0xFF4CAF50) : baseColor,
                              size: 24.sp,
                            ),
                          ),
                          if (isCompleted)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 10.sp,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        act['label'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}
