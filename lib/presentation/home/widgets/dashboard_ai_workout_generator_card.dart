import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/model/workout_model.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Companion card displayed on the Dashboard to ensure the AI Workout Generator
/// remains fully visible and accessible when an active Transformation Programme
/// is the primary hero card.
class DashboardAiWorkoutGeneratorCard extends StatelessWidget {
  const DashboardAiWorkoutGeneratorCard({super.key});

  static const List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final transformationProvider =
        Provider.of<TransformationProvider?>(context);

    // Only render when an active transformation programme is running.
    // When no transformation is active, HomeAiRoutineCard itself acts as the
    // primary AI routine hero, avoiding duplicate cards.
    if (transformationProvider == null ||
        !transformationProvider.hasActiveTransformation) {
      return const SizedBox.shrink();
    }

    return Consumer<WorkoutProvider>(
      builder: (context, workoutProvider, _) {
        final planWorkouts = workoutProvider.allWorkouts
            .where((w) => w.name.startsWith('['))
            .toList();

        final Map<String, List<WorkoutModel>> grouped = {};
        for (final w in planWorkouts) {
          final match = RegExp(r'^\[(.*?)\]').firstMatch(w.name);
          if (match != null) {
            final day = match.group(1)!;
            grouped.putIfAbsent(day, () => []).add(w);
          }
        }

        final subscriptionProvider =
            Provider.of<SubscriptionProvider?>(context);
        final isPremium = subscriptionProvider?.isPremium ?? false;

        if (grouped.isEmpty) {
          return _buildNoRoutineCard(context, isPremium);
        }

        return _buildActiveRoutineCompanionCard(
          context: context,
          grouped: grouped,
          workoutProvider: workoutProvider,
        );
      },
    );
  }

  /// Card rendered when user has an active transformation but no AI routine yet.
  Widget _buildNoRoutineCard(BuildContext context, bool isPremium) {
    return Padding(
      padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 12.h),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(AppRadius.card.r),
          border: Border.all(
            color: ColorManager.primary.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorManager.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: ColorManager.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            color: ColorManager.primary, size: 13.sp),
                        SizedBox(width: 5.w),
                        Flexible(
                          child: Text(
                            'PLAN BUILDER',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ColorManager.primary,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    '3–6 Day Custom Splits',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: ColorManager.textTertiary,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'Build Your Workout Routine',
              style: TextStyle(
                color: ColorManager.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Generate an adaptive weekly routine by selecting your preferred number of workout days (3 to 6 days/week) with targeted exercises and rest timers.',
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 12.sp,
                height: 1.4,
              ),
            ),
            SizedBox(height: 14.h),
            // Days selection preview pills
            Row(
              children: [3, 4, 5, 6].map((days) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3.w),
                    child: InkWell(
                      onTap: () =>
                          context.push(Routes.workoutGeneratorRoute),
                      borderRadius: BorderRadius.circular(10.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 7.h),
                        decoration: BoxDecoration(
                          color: ColorManager.surfaceDark,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: ColorManager.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$days Days',
                            style: TextStyle(
                              color: ColorManager.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(Routes.workoutGeneratorRoute),
                icon: const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: ColorManager.onMint,
                ),
                label: Text(
                  'Build My Routine',
                  style: TextStyle(
                    color: ColorManager.onMint,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button.r),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            if (!isPremium) ...[
              SizedBox(height: 8.h),
              Center(
                child: TextButton.icon(
                  onPressed: () => _activateFreeStarterPlan(context),
                  icon: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  label: Text(
                    'Or tap to activate Free 3-Day Starter Plan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Card rendered when user has an active transformation AND an existing AI routine.
  Widget _buildActiveRoutineCompanionCard({
    required BuildContext context,
    required Map<String, List<WorkoutModel>> grouped,
    required WorkoutProvider workoutProvider,
  }) {
    final sortedDays = grouped.keys.toList()
      ..sort((a, b) => _weekDays.indexOf(a).compareTo(_weekDays.indexOf(b)));
    final todayName = DateFormat('EEEE').format(workoutProvider.currentNow);
    final bool isTodayWorkout = grouped.containsKey(todayName);
    final bool isCompletedToday = isTodayWorkout &&
        (workoutProvider.isDayWorkoutCompletedToday(todayName) ||
            workoutProvider.isDayWorkoutCompletedThisWeek(todayName));

    return Padding(
      padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 12.h),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(AppRadius.card.r),
          border: Border.all(
            color: ColorManager.primary.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorManager.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: ColorManager.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            color: ColorManager.primary, size: 13.sp),
                        SizedBox(width: 5.w),
                        Flexible(
                          child: Text(
                            'WORKOUT ROUTINE',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ColorManager.primary,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    '${sortedDays.length}-Day Split (${sortedDays.join(' · ')})',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ColorManager.textTertiary,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'Your Custom Routine',
              style: TextStyle(
                color: ColorManager.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Active schedule running alongside your transformation programme. Tap below to launch today\'s workout or re-plan days.',
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 12.sp,
                height: 1.4,
              ),
            ),
            SizedBox(height: 12.h),
            // Days split chips
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: sortedDays.map((day) {
                final bool isDayToday = day == todayName;
                final bool isCompleted =
                    workoutProvider.isDayWorkoutCompletedThisWeek(day);
                return Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: isDayToday
                        ? ColorManager.primary.withValues(alpha: 0.2)
                        : ColorManager.surfaceDark,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isDayToday
                          ? ColorManager.primary
                          : ColorManager.divider,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCompleted) ...[
                        Icon(Icons.check_circle_rounded,
                            color: ColorManager.success, size: 12.sp),
                        SizedBox(width: 4.w),
                      ],
                      Text(
                        day,
                        style: TextStyle(
                          color: isDayToday
                              ? ColorManager.primary
                              : ColorManager.textSecondary,
                          fontSize: 11.sp,
                          fontWeight: isDayToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                if (isTodayWorkout) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final todaysWorkouts = grouped[todayName]!;
                        final resolvedExercises = <dynamic>[];
                        for (final w in todaysWorkouts) {
                          final cleanName =
                              w.name.replaceAll(RegExp(r'^\[.*?\]\s*'), '');
                          final catalogEx = ExerciseData.findByName(cleanName);
                          if (catalogEx != null) {
                            resolvedExercises.add(catalogEx);
                          } else {
                            resolvedExercises.add({
                              'name': cleanName,
                              'setNumber': w.setNumber,
                              'repNumber': w.repNumber,
                            });
                          }
                        }

                        context.push(
                          Routes.dayWorkoutSessionRoute,
                          extra: {
                            'dayName': '$todayName Workout',
                            'workouts': resolvedExercises,
                          },
                        );
                      },
                      icon: Icon(
                        isCompletedToday
                            ? Icons.refresh_rounded
                            : Icons.play_arrow_rounded,
                        size: 16.sp,
                        color: Colors.white,
                      ),
                      label: Text(
                        isCompletedToday
                            ? 'Repeat Routine'
                            : 'Start Routine',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompletedToday
                            ? const Color(0xFF1E4331)
                            : ColorManager.primary,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push(Routes.workoutGeneratorRoute),
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 16.sp,
                      color: ColorManager.primary,
                    ),
                    label: Text(
                      'Re-plan Split',
                      style: TextStyle(
                        color: ColorManager.primary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: ColorManager.primary),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _activateFreeStarterPlan(BuildContext context) async {
    try {
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      final statsProvider =
          Provider.of<StatisticsProvider>(context, listen: false);
      await workoutProvider.restoreDefaultThreeDaySplit();
      final now = workoutProvider.currentNow;
      await statsProvider.updateScheduledDays(
        const ['Monday', 'Wednesday', 'Friday'],
        effectiveDate: now,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '3-Day Starter Routine activated! Ready for your workout.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: ColorManager.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to activate starter plan: $e'),
            backgroundColor: ColorManager.error,
          ),
        );
      }
    }
  }
}
