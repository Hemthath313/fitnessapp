import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/utils/transformation_equipment_adapter.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void _launchTransformationWorkout({
  required BuildContext context,
  required TransformationDayBlueprint day,
  required int dayNumber,
  required String planTitle,
  required String planId,
  required TransformationProvider provider,
}) {
  final activeState = provider.activeTransformation;
  final adaptedExerciseNames =
      TransformationEquipmentAdapter.adaptExercisesForEnvironment(
    exerciseNames: day.exerciseNames,
    workoutLocation: activeState?.workoutLocation,
    availableEquipment: activeState?.availableEquipment ?? const [],
    injuries: activeState?.injuries,
  );

  final resolvedExercises = <dynamic>[];
  for (final name in adaptedExerciseNames) {
    final catalogEx = ExerciseData.findByName(name);
    if (catalogEx != null) {
      resolvedExercises.add(catalogEx);
    } else {
      resolvedExercises.add({
        'name': name,
        'setNumber': day.targetSets,
        'repNumber': 10,
      });
    }
  }

  context.push(
    Routes.dayWorkoutSessionRoute,
    extra: {
      'dayName': '$planTitle • Day $dayNumber',
      'workouts': resolvedExercises,
      'planId': planId,
      'planDay': dayNumber,
    },
  );
}

  /// Priority 1 Hero Card: Active Transformation Programme
class TransformationHeroCard extends StatelessWidget {
  const TransformationHeroCard({super.key, required this.transformationProvider});

  final TransformationProvider transformationProvider;
  @override
  Widget build(BuildContext context) {
    final active = transformationProvider.activeTransformation;
    if (active == null) return const SizedBox.shrink();

    final subscriptionProvider = Provider.of<SubscriptionProvider?>(context);
    final bool isPremium = subscriptionProvider?.isPremium ?? false;

    final blueprint = transformationProvider.activeBlueprint ??
        TransformationPlansData.getById(active.planId);

    final int currentDay = active.currentDay;
    final int totalDays = active.totalDays;
    final int currentWeek = active.currentWeekNumber;

    final todayBlueprint = transformationProvider.currentDayBlueprint ??
        blueprint?.getDayBlueprint(currentDay);
    final bool isRestDay = todayBlueprint?.isRestDay ?? false;
    final bool isActiveRecovery = todayBlueprint?.dayType == 'active_recovery';
    final bool isTodayCompleted =
        transformationProvider.isDayCompleted(currentDay);
    final bool isFinalDay = currentDay == totalDays;
    final double progress = active.completionPercentage;

    // ── What the card says (kept short: 5 pieces of information) ──
    final String sessionTitle;
    if (isRestDay) {
      sessionTitle =
          isActiveRecovery ? 'Active Recovery & Mobility' : 'Rest & Muscle Repair';
    } else {
      final muscle = todayBlueprint?.muscleGroup;
      sessionTitle = muscle != null && muscle.isNotEmpty
          ? muscle
          : 'Day $currentDay Workout';
    }

    final String statusLabel = isTodayCompleted
        ? 'DAY $currentDay DONE'
        : (isActiveRecovery
            ? 'DAY $currentDay • ACTIVE RECOVERY'
            : (isRestDay
                ? 'DAY $currentDay • REST DAY'
                : 'DAY $currentDay OF $totalDays'));

    final Color statusColor = isTodayCompleted
        ? ColorManager.successText
        : (isRestDay ? ColorManager.infoText : ColorManager.primaryText);

    // Meta line: when done, point at tomorrow instead of repeating today.
    String metaLine;
    if (isTodayCompleted && !isFinalDay) {
      final nextBp = blueprint?.getDayBlueprint(currentDay + 1);
      final nextName = nextBp == null
          ? 'Day ${currentDay + 1}'
          : (nextBp.isRestDay
              ? 'Rest day'
              : (nextBp.muscleGroup ?? 'Day ${currentDay + 1}'));
      metaLine = 'Up next tomorrow · $nextName';
    } else if (isRestDay) {
      metaLine = isActiveRecovery
          ? 'Week $currentWeek · Light mobility, ~20 min'
          : 'Week $currentWeek · Recovery builds muscle';
    } else {
      final exCount = todayBlueprint?.exerciseNames.length ?? 0;
      final minutes = active.workoutDurationMinutes;
      metaLine = 'Week $currentWeek · $exCount exercises · ~$minutes min';
    }

    final bool useHeroGradient = !isTodayCompleted && !isRestDay;

    // This week's workout days (rest days excluded) and how many are done.
    final int weekStart = ((currentDay - 1) ~/ 7) * 7 + 1;
    final List<int> weekWorkoutDays = [
      for (var d = weekStart; d < weekStart + 7 && d <= totalDays; d++)
        if (!(blueprint?.getDayBlueprint(d)?.isRestDay ?? false)) d,
    ];
    final int weekDone =
        weekWorkoutDays.where(transformationProvider.isDayCompleted).length;

    // Result of today's workout, saved when the session finished.
    final Map<String, int>? todaySummary =
        isTodayCompleted ? active.completedDaySummaries[currentDay] : null;

    void startToday() {
      if (!isPremium) {
        context.push(Routes.premiumScreen);
        return;
      }
      if (todayBlueprint != null) {
        _launchTransformationWorkout(
          context: context,
          day: todayBlueprint,
          dayNumber: currentDay,
          planTitle: blueprint?.title ?? active.planTitle,
          planId: active.planId,
          provider: transformationProvider,
        );
      } else {
        context.push(Routes.transformationRoadmapRoute);
      }
    }

    // On the blue hero gradient text is always light; on the plain card it
    // follows the theme.
    final Color titleColor =
        useHeroGradient ? Colors.white : ColorManager.textPrimary;
    final Color mutedColor =
        useHeroGradient ? Colors.white70 : ColorManager.textSecondary;

    Widget cta;
    if (isFinalDay && isTodayCompleted) {
      cta = SizedBox(
        width: double.infinity,
        height: 44.h,
        child: ElevatedButton.icon(
          onPressed: () => context.push(Routes.transformationCompletionRoute),
          icon: Icon(Icons.emoji_events_rounded,
              size: 16.sp, color: ColorManager.inkOnLight),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'View programme graduation',
              style: TextStyle(
                color: ColorManager.inkOnLight,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorManager.premium,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button.r),
            ),
          ),
        ),
      );
    } else if (isTodayCompleted) {
      // Done for today: the repeat option is a quiet link, not a big button.
      cta = Center(
        child: TextButton.icon(
          key: const Key('transformation_repeat_today_link'),
          onPressed: startToday,
          icon: Icon(Icons.refresh_rounded,
              size: 16.sp, color: ColorManager.textSecondary),
          label: Text(
            "Repeat today's workout",
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } else if (isRestDay && !isActiveRecovery) {
      cta = SizedBox(
        width: double.infinity,
        height: 44.h,
        child: OutlinedButton.icon(
          onPressed: () => context.push(Routes.transformationRoadmapRoute),
          icon: Icon(Icons.map_rounded, size: 16.sp, color: ColorManager.infoText),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'View programme roadmap',
              style: TextStyle(
                color: ColorManager.infoText,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: ColorManager.divider),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button.r),
            ),
          ),
        ),
      );
    } else {
      final Color fill = useHeroGradient ? Colors.white : ColorManager.primary;
      final Color ink =
          useHeroGradient ? ColorManager.inkOnLight : ColorManager.onMint;
      cta = SizedBox(
        width: double.infinity,
        height: 44.h,
        child: ElevatedButton.icon(
          onPressed: startToday,
          icon: Icon(
            isActiveRecovery
                ? Icons.self_improvement_rounded
                : (!isPremium
                    ? Icons.lock_outline_rounded
                    : Icons.play_arrow_rounded),
            size: 18.sp,
            color: ink,
          ),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              isActiveRecovery
                  ? 'Start active recovery'
                  : 'Start Day $currentDay workout',
              style: TextStyle(
                color: ink,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: fill,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button.r),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: useHeroGradient ? null : ColorManager.surface,
          gradient: useHeroGradient
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ColorManager.heroTealStart,
                    ColorManager.heroTealMid,
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(24.r),
          border: useHeroGradient
              ? null
              : Border.all(color: ColorManager.divider, width: 1),
          boxShadow: ColorManager.cardShadow,
        ),
        padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 14.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Plan name + roadmap link
            Row(
              children: [
                Expanded(
                  child: Text(
                    blueprint?.title ?? active.planTitle,
                    style: TextStyle(color: mutedColor, fontSize: 12.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () => context.push(Routes.transformationRoadmapRoute),
                  borderRadius: BorderRadius.circular(6.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Roadmap',
                          style: TextStyle(
                            color: useHeroGradient
                                ? Colors.white
                                : ColorManager.primaryText,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16.sp,
                          color: useHeroGradient
                              ? Colors.white
                              : ColorManager.primaryText,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // 2. Day status
            Row(
              children: [
                if (isTodayCompleted) ...[
                  Icon(Icons.check_circle_rounded,
                      size: 14.sp, color: ColorManager.successText),
                  SizedBox(width: 5.w),
                ],
                Flexible(
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: useHeroGradient ? Colors.white : statusColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),

            // 3. Today's workout
            Text(
              sessionTitle,
              style: TextStyle(
                color: titleColor,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),

            // 4. One meta line
            Text(
              metaLine,
              key: const Key('transformation_meta_line'),
              style: TextStyle(color: mutedColor, fontSize: 12.sp),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 14.h),

            // Workout result (only once today is done and a summary exists).
            if (todaySummary != null) ...[
              Row(
                key: const Key('transformation_done_summary'),
                children: [
                  _SummaryStat(value: '${todaySummary['sets'] ?? 0}', label: 'sets'),
                  SizedBox(width: 8.w),
                  _SummaryStat(value: '${todaySummary['minutes'] ?? 0}m', label: 'time'),
                  SizedBox(width: 8.w),
                  _SummaryStat(
                    value: '${todaySummary['prs'] ?? 0}',
                    label: (todaySummary['prs'] ?? 0) == 1 ? 'new PR' : 'new PRs',
                    highlight: (todaySummary['prs'] ?? 0) > 0,
                  ),
                ],
              ),
              SizedBox(height: 14.h),
            ],

            // 5. This week's progress: one segment per workout day.
            if (weekWorkoutDays.isNotEmpty) ...[
              Row(
                key: const Key('transformation_week_segments'),
                children: [
                  for (var i = 0; i < weekWorkoutDays.length; i++) ...[
                    if (i > 0) SizedBox(width: 4.w),
                    Expanded(
                      child: Container(
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: transformationProvider
                                  .isDayCompleted(weekWorkoutDays[i])
                              ? (useHeroGradient
                                  ? Colors.white
                                  : ColorManager.primary)
                              : (useHeroGradient
                                  ? Colors.white24
                                  : ColorManager.divider),
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 6.h),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$weekDone of ${weekWorkoutDays.length} workouts this week',
                    style: TextStyle(color: mutedColor, fontSize: 12.sp),
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% Complete',
                  style: TextStyle(color: mutedColor, fontSize: 12.sp),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            cta,
          ],
        ),
      ),
    );
  }
}

/// Small stat tile on the finished-day card (e.g. "15 sets").
class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: ColorManager.surfaceDark,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: highlight ? ColorManager.warningText : ColorManager.textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }
}
