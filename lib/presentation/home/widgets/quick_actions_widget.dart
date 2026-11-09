import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:fitness_app/utils/router/router.dart';

import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/presentation/custom_workouts/day_workout_session_page.dart';
import 'package:intl/intl.dart';

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  /// The one label for the "just log something" escape hatch, used by every
  /// Log Lift sheet so the wording never drifts between cases.
  static const String _logSingleLiftLabel = 'Log a Single Lift';

  /// Shared bottom sheet for every Log Lift case that needs a prompt: a title
  /// with icon, one line of context, a primary action and the single-lift
  /// fallback.
  void _showTrainSheet(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required IconData primaryIcon,
    required String primaryLabel,
    required VoidCallback onPrimary,
  }) {
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
                  Icon(icon, color: iconColor, size: 22.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      title,
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
                message,
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
                    foregroundColor: ColorManager.onMint,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button.r),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onPrimary();
                  },
                  icon: Icon(primaryIcon, color: ColorManager.onMint),
                  label: Text(
                    primaryLabel,
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
                  label: const Text(_logSingleLiftLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      }

      // Today is a scheduled rest/recovery day in the active transformation programme.
      _showTrainSheet(
        context,
        icon: Icons.bedtime_rounded,
        iconColor: Colors.blueAccent,
        title: 'Today is a Rest Day (Day ${active.currentDay})',
        message:
            'Your active programme (${active.planTitle}) has a recovery day scheduled today. You can view your roadmap or log a single lift.',
        primaryIcon: Icons.map_rounded,
        primaryLabel: 'View Programme Roadmap',
        onPrimary: () => context.push(Routes.transformationRoadmapRoute),
      );
      return;
    }

    // 2. Active AI Routine or Starter Split Fallback
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    final grouped = workoutProvider.groupedSplitWorkouts;
    final todayName = DateFormat('EEEE').format(DateTime.now());

    if (grouped.isEmpty) {
      // No active split yet -> prompt user to build plan or log single lift
      _showTrainSheet(
        context,
        icon: Icons.fitness_center_rounded,
        iconColor: ColorManager.primary,
        title: 'Ready to Train?',
        message:
            'Build an adaptive split with previous weights and automatic progression, or log a single lift.',
        primaryIcon: Icons.auto_awesome_rounded,
        primaryLabel: 'Build My Adaptive Plan',
        onPrimary: () => context.push(Routes.workoutGeneratorRoute),
      );
      return;
    }

    if (grouped.containsKey(todayName)) {
      // When today's workout routine is already prominently displayed in HomeAiRoutineCard,
      // avoid presenting a confusing duplicate workout-start action through Log Lift.
      // Instead, route directly to manual/ad-hoc lift logging so the user can record
      // individual exercises, PRs, or extra work without duplicating the routine start.
      context.push(Routes.workoutLogRoute);
      return;
    }

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

    if (nextWorkoutDay.isEmpty || !grouped.containsKey(nextWorkoutDay)) {
      context.push(Routes.workoutLogRoute);
      return;
    }

    final nextWorkouts = grouped[nextWorkoutDay]!;
    _showTrainSheet(
      context,
      icon: Icons.bedtime_rounded,
      iconColor: Colors.blueAccent,
      title: 'Today is a Rest Day ($todayName)',
      message:
          'Your next scheduled workout is $nextWorkoutDay (${nextWorkouts.length} exercises). You can start it early or log a single lift.',
      primaryIcon: Icons.play_arrow_rounded,
      primaryLabel: 'Start $nextWorkoutDay Workout Early',
      onPrimary: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DayWorkoutSessionPage(
            dayName: nextWorkoutDay,
            workouts: nextWorkouts,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Water logging lives on the Today's Snapshot water card, so it is not
    // repeated here.
    return Selector<StatisticsProvider, bool>(
      selector: (_, stats) => stats.hasWorkoutToday,
      builder: (context, workoutDoneToday, _) {
        final List<Map<String, dynamic>> actions = [
          {
            'icon': Icons.restaurant_menu_rounded,
            'label': 'Log Meal',
            'alias': 'Diet Plans',
            'isCompleted': false,
            'onTap': () {
              final transformationProvider =
                  Provider.of<TransformationProvider?>(context, listen: false);
              if (transformationProvider != null &&
                  transformationProvider.hasActiveTransformation) {
                context.push(Routes.transformationNutritionRoute);
              } else {
                context.push(Routes.dietRoute);
              }
            },
          },
          {
            'icon': Icons.fitness_center_rounded,
            'label': 'Log Lift',
            'isCompleted': workoutDoneToday,
            'onTap': () => _handleLogLift(context),
          },
          {
            'icon': Icons.auto_awesome_rounded,
            'label': 'Plan Builder',
            'alias': 'Routine Builder',
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
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) SizedBox(width: 10.w),
                    Expanded(child: _buildActionTile(actions[i])),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// One quick-action tile: its own surface card with a ringed icon chip.
  Widget _buildActionTile(Map<String, dynamic> act) {
    final bool isCompleted = act['isCompleted'] as bool? ?? false;
    final String? alias = act['alias'] as String?;
    final String label = act['label'] as String;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: act['onTap'] as VoidCallback,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: BoxConstraints(minHeight: 96.h),
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 6.w),
          decoration: BoxDecoration(
            color: ColorManager.surface,
            borderRadius: BorderRadius.circular(AppRadius.card.r),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: BoxDecoration(
                          color: ColorManager.iconChip,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted
                                ? ColorManager.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          act['icon'] as IconData,
                          color: ColorManager.primary,
                          size: 22.sp,
                        ),
                      ),
                      if (isCompleted)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: ColorManager.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: const Color(0xFF06201B),
                              size: 10.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (alias != null)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.0,
                    child: Center(
                      child: Text(
                        alias,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
