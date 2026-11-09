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

    String? phaseName;
    String? weekFocus;
    if (blueprint != null) {
      final weekIndex = (currentDay - 1) ~/ 7;
      int weekCounter = 0;
      for (final phase in blueprint.phases) {
        for (final week in phase.weeks) {
          if (weekCounter == weekIndex) {
            phaseName = phase.phaseName;
            weekFocus = week.focus;
            break;
          }
          weekCounter++;
        }
        if (phaseName != null) break;
      }
    }

    final todayBlueprint = transformationProvider.currentDayBlueprint ??
        blueprint?.getDayBlueprint(currentDay);
    final bool isRestDay = todayBlueprint?.isRestDay ?? false;
    final bool isActiveRecovery = todayBlueprint?.dayType == 'active_recovery';
    final bool isTodayCompleted =
        transformationProvider.isDayCompleted(currentDay);
    final bool isFinalDay = currentDay == totalDays;
    final double progress = active.completionPercentage;

    String sessionTitle;
    String sessionSubtitle;
    if (isRestDay) {
      if (isActiveRecovery) {
        sessionTitle = 'Active Recovery & Mobility';
        sessionSubtitle =
            'Light cardio, mobility, or stretching to accelerate muscular recovery.';
      } else {
        sessionTitle = 'Rest & Muscle Repair';
        sessionSubtitle =
            'Scheduled rest day for nervous system recovery and muscle tissue rebuilding.';
      }
    } else {
      final muscle = todayBlueprint?.muscleGroup;
      sessionTitle = muscle != null && muscle.isNotEmpty
          ? '$muscle Focus'
          : 'Day $currentDay Workout';
      final exCount = todayBlueprint?.exerciseNames.length ?? 0;
      final sets = todayBlueprint?.targetSets ?? 3;
      final reps = todayBlueprint?.targetReps ?? '8-12';
      sessionSubtitle = '$exCount Exercises · $sets sets ($reps) · ~45 min';
    }

    final exerciseNames = todayBlueprint != null && !isRestDay
        ? TransformationEquipmentAdapter.adaptExercisesForEnvironment(
            exerciseNames: todayBlueprint.exerciseNames,
            workoutLocation: active.workoutLocation,
            availableEquipment: active.availableEquipment,
            injuries: active.injuries,
          )
        : (isActiveRecovery
            ? const ['Dynamic Mobility', 'Foam Rolling', 'Light Walk']
            : const <String>[]);

    final Color accentColor = isTodayCompleted
        ? const Color(0xFF4CAF50)
        : (isRestDay ? Colors.blueAccent : Colors.white);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: (isTodayCompleted || isRestDay) ? ColorManager.surface : null,
          gradient: (isTodayCompleted || isRestDay)
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ColorManager.heroTealStart,
                    ColorManager.heroTealMid,
                    ColorManager.surface,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
          borderRadius: BorderRadius.circular(24.r),
          border: (isTodayCompleted || isRestDay)
              ? Border.all(
                  color: accentColor
                      .withValues(alpha: isTodayCompleted ? 0.7 : 0.4),
                  width: 1.4,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Status Badge & Roadmap Shortcut Link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isTodayCompleted
                            ? const Color(0xFF1E4331)
                            : (isRestDay
                                ? Colors.blueAccent.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.25)),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isTodayCompleted
                                ? Icons.check_circle_rounded
                                : (isRestDay
                                    ? (isActiveRecovery
                                        ? Icons.self_improvement_rounded
                                        : Icons.bedtime_rounded)
                                    : Icons.fitness_center_rounded),
                            size: 11.sp,
                            color: isTodayCompleted
                                ? const Color(0xFF4CAF50)
                                : accentColor,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            isTodayCompleted
                                ? 'DAY $currentDay COMPLETED ✓'
                                : (isActiveRecovery
                                    ? 'DAY $currentDay • ACTIVE RECOVERY'
                                    : (isRestDay
                                        ? 'DAY $currentDay • REST DAY'
                                        : 'DAY $currentDay OF $totalDays')),
                            style: TextStyle(
                              color: isTodayCompleted
                                  ? const Color(0xFF81C784)
                                  : accentColor,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                InkWell(
                  onTap: () => context.push(Routes.transformationRoadmapRoute),
                  borderRadius: BorderRadius.circular(6.r),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Roadmap',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                          size: 14.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // Programme Name
            Text(
              blueprint?.title ?? active.planTitle,
              style: TextStyle(
                color: ColorManager.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),

            // Week & Phase Context
            Text(
              'Week $currentWeek${phaseName != null ? ' • $phaseName' : ''}${weekFocus != null ? ' ($weekFocus)' : ''}',
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 11.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8.h),

            // Session Title & Focus
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: ColorManager.surfaceDark,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: ColorManager.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isRestDay
                            ? (isActiveRecovery
                                ? Icons.self_improvement_rounded
                                : Icons.spa_rounded)
                            : Icons.play_circle_outline_rounded,
                        color: accentColor,
                        size: 14.sp,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          sessionTitle,
                          style: TextStyle(
                            color: ColorManager.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    sessionSubtitle,
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontSize: 11.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Exercises Preview Pills (if workout or active recovery)
            if (exerciseNames.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Wrap(
                spacing: 5.w,
                runSpacing: 4.h,
                children: [
                  ...exerciseNames.take(3).map((name) => Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: isTodayCompleted
                              ? const Color(0xFF1E4331)
                              : ColorManager.surfaceDark,
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: ColorManager.divider),
                        ),
                        child: Text(
                          name,
                          style: TextStyle(
                            color: isTodayCompleted
                                ? const Color(0xFFE8F5E9)
                                : ColorManager.textSecondary,
                            fontSize: 11.sp,
                          ),
                        ),
                      )),
                  if (exerciseNames.length > 3)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: ColorManager.surfaceDark,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '+${exerciseNames.length - 3} more',
                        style: TextStyle(
                          color: ColorManager.primary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],

            // Progress Bar & Day Counter
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${(progress * 100).toInt()}% Complete',
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    '${active.completedDayIndices.length}/$totalDays Days Done',
                    style: TextStyle(
                      color: ColorManager.textTertiary,
                      fontSize: 11.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(3.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4.h,
                backgroundColor: ColorManager.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isTodayCompleted ? const Color(0xFF4CAF50) : ColorManager.primary,
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Bottom Action CTA
            SizedBox(
              width: double.infinity,
              height: 38.h,
              child: isFinalDay && isTodayCompleted
                  ? ElevatedButton.icon(
                      onPressed: () =>
                          context.push(Routes.transformationCompletionRoute),
                      icon: Icon(
                        Icons.emoji_events_rounded,
                        size: 16.sp,
                        color: Colors.black,
                      ),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'VIEW PROGRAMME GRADUATION',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button.r),
                        ),
                      ),
                    )
                  : (isRestDay && !isActiveRecovery
                      ? OutlinedButton.icon(
                          onPressed: () =>
                              context.push(Routes.transformationRoadmapRoute),
                          icon: Icon(
                            Icons.map_rounded,
                            size: 16.sp,
                            color: Colors.blueAccent,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'VIEW PROGRAMME ROADMAP',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.blueAccent.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.button.r),
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () {
                            if (!isPremium) {
                              context.push(Routes.premiumScreen);
                              return;
                            }

                            if (todayBlueprint != null) {
                              _launchTransformationWorkout(
                                context: context,
                                day: todayBlueprint,
                                dayNumber: currentDay,
                                planTitle:
                                    blueprint?.title ?? active.planTitle,
                                planId: active.planId,
                                provider: transformationProvider,
                              );
                            } else {
                              context.push(Routes.transformationRoadmapRoute);
                            }
                          },
                          icon: Icon(
                            isTodayCompleted
                                ? Icons.refresh_rounded
                                : (isActiveRecovery
                                    ? Icons.self_improvement_rounded
                                    : (!isPremium
                                        ? Icons.lock_outline_rounded
                                        : Icons.play_arrow_rounded)),
                            size: 16.sp,
                            color: isTodayCompleted
                                ? Colors.white
                                : Colors.black,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              isTodayCompleted
                                  ? 'REPEAT DAY $currentDay WORKOUT'
                                  : (isActiveRecovery
                                      ? 'START ACTIVE RECOVERY'
                                      : 'START DAY $currentDay WORKOUT'),
                              style: TextStyle(
                                color: isTodayCompleted
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isTodayCompleted
                                ? const Color(0xFF1E4331)
                                : ColorManager.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.button.r),
                              side: isTodayCompleted
                                  ? const BorderSide(color: Color(0xFF4CAF50))
                                  : BorderSide.none,
                            ),
                          ),
                        )),
            ),
          ],
        ),
      ),
    );
  }
}
