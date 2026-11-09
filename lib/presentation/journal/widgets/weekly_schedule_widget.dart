import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/utils/managers/card_size_manager.dart';
import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/presentation/home/widgets/gradient_hero_card.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/utils/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/services/notification_service.dart';
import 'package:fitness_app/services/plan_today.dart';
import 'package:fitness_app/services/progression_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class WeeklyScheduleWidget extends StatefulWidget {
  const WeeklyScheduleWidget({super.key});

  @override
  State<WeeklyScheduleWidget> createState() => _WeeklyScheduleWidgetState();
}

class _WeeklyScheduleWidgetState extends State<WeeklyScheduleWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
      workoutProvider.fetchAndSetWorkouts();
    });
  }

  void _deleteWeeklyPlan(WorkoutProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ColorManager.background,
        title: Text('Reset Weekly Plan?', style: TextStyle(color: ColorManager.textPrimary)),
        content: Text(
          'This will delete all generated exercises from your schedule.',
          style: TextStyle(color: ColorManager.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Reset', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      LoadingOverlay.show(context, message: 'Resetting weekly plan...');
      try {
        await provider.deleteWeeklyPlan();
        if (!mounted) return;
        await provider.fetchAndSetWorkouts();
        if (mounted) {
          final statsProvider =
              Provider.of<StatisticsProvider>(context, listen: false);
          await statsProvider.clearScheduledDays();
          await statsProvider.resetWeeklyTarget();
        }
        try {
          await NotificationService().cancelWorkoutDayReminders();
          await NotificationService().cancelRestDayReminders();
        } catch (_) {}
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) LoadingOverlay.hide(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, workoutProvider, _) {
        final hasWeeklyPlan = workoutProvider.allWorkouts.any((w) => w.name.startsWith('['));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Plan',
                      style: TextStyle(
                        color: ColorManager.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hasWeeklyPlan)
                      Text('Your generated schedule', style: TextStyle(color: ColorManager.gradientStart, fontSize: 12.sp)),
                  ],
                ),
                if (hasWeeklyPlan)
                  IconButton(
                    onPressed: () => _deleteWeeklyPlan(workoutProvider),
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    tooltip: 'Reset Plan',
                  )
                else 
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: ColorManager.mintGradient,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(Routes.workoutGeneratorRoute),
                      icon: Icon(Icons.auto_awesome, size: 16.sp, color: ColorManager.onMint),
                      label: Text(
                        'AI Build',
                        style: TextStyle(
                          color: ColorManager.onMint,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        minimumSize: Size(0, 36.h),
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            
            // Content
            if (workoutProvider.allWorkouts.isEmpty)
              _buildEmptyState(context)
            else
              _buildScheduleContent(workoutProvider),
          ],
        );
      }
    );
  }

  Widget _buildScheduleContent(WorkoutProvider workoutProvider) {
    final Map<String, List<dynamic>> groupedMap = {};
    final List<dynamic> otherWorkouts = [];

    for (var w in workoutProvider.allWorkouts) {
      final regex = RegExp(r'^\[(\w+)\]');
      final match = regex.firstMatch(w.name);
      if (match != null) {
        final day = match.group(1)!;
        if (!groupedMap.containsKey(day)) groupedMap[day] = [];
        groupedMap[day]!.add(w);
      } else {
        otherWorkouts.add(w);
      }
    }

    if (groupedMap.isEmpty) {
      if (otherWorkouts.isEmpty) {
        return _buildEmptyState(context);
      }
      return StreamBuilder<List<WorkoutLog>>(
        stream: WorkoutLogService().getLogs(),
        builder: (context, snap) {
          final logs = snap.data ?? [];
          final latestLogMap = _buildLatestLogMap(logs);
          return Column(
            children: otherWorkouts.map((w) => _buildWorkoutCard(
              workout: w,
              onStart: () => _startSingleExercise(context, w),
              isGrouped: false,
              latestLogMap: latestLogMap,
            )).toList(),
          );
        },
      );
    }

    final split = splitPlanDays(groupedMap.keys, DateTime.now());
    final hasWeekdayGroup = groupedMap.keys.any(kWeekdayNames.contains);

    return StreamBuilder<List<WorkoutLog>>(
      stream: WorkoutLogService().getLogs(),
      builder: (context, snap) {
        final logs = snap.data ?? [];
        final latestLogMap = _buildLatestLogMap(logs);
        final today = split.today;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (today != null)
              _buildDayCard(today, groupedMap[today]!, latestLogMap, isToday: true)
            else if (hasWeekdayGroup && split.nextUp != null)
              _buildRestDayBanner(split.nextUp!, groupedMap[split.nextUp!]!),
            if (split.later.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.only(top: 4.h, bottom: 10.h),
                child: Text(
                  'Coming up',
                  style: TextStyle(
                    color: ColorManager.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              ...split.later.map((day) =>
                  _buildDayCard(day, groupedMap[day]!, latestLogMap, isToday: false)),
            ],
            if (otherWorkouts.isNotEmpty) ...[
              Padding(padding: EdgeInsets.symmetric(vertical: 12.h), child: Text('Other Workouts', style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold))),
              ...otherWorkouts.map((w) => _buildWorkoutCard(workout: w, onStart: () => _startSingleExercise(context, w), isGrouped: false, latestLogMap: latestLogMap)),
            ],
          ],
        );
      },
    );
  }

  /// Opens the guided day session through the router (same entry as Home).
  void _startDay(String day, List<dynamic> workouts) {
    context.push(
      Routes.dayWorkoutSessionRoute,
      extra: {'dayName': day, 'workouts': workouts},
    );
  }

  bool _doneToday(BuildContext context) {
    try {
      return Provider.of<StatisticsProvider>(context).hasWorkoutToday;
    } catch (_) {
      return false;
    }
  }

  Widget _buildRestDayBanner(String nextDay, List<dynamic> nextWorkouts) {
    return Container(
      key: const Key('rest_day_banner'),
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.small.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.self_improvement, color: ColorManager.primary, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rest day today',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Next up: $nextDay',
                  style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          OutlinedButton(
            key: const Key('rest_day_start_button'),
            onPressed: () => _startDay(nextDay, nextWorkouts),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorManager.primary,
              side: BorderSide(color: ColorManager.primary),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Train anyway', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(
    String day,
    List<dynamic> workouts,
    Map<String, WorkoutLog> latestLogMap, {
    required bool isToday,
  }) {
    final done = isToday && _doneToday(context);
    final subtitle = done
        ? '${workouts.length} Exercises · Done today'
        : '${workouts.length} Exercises';

    return Card(
      key: isToday ? const Key('today_plan_card') : null,
      margin: EdgeInsets.only(bottom: 16.h),
      color: ColorManager.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: isToday ? ColorManager.primary : ColorManager.divider,
          width: isToday ? 1.5 : 1,
        ),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: isToday,
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isToday)
                          Text(
                            'TODAY',
                            style: TextStyle(
                              color: ColorManager.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.sp,
                              letterSpacing: 1,
                            ),
                          ),
                        Text(
                          day,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: ColorManager.primary, fontWeight: FontWeight.bold, fontSize: 18.sp),
                        ),
                      ],
                    ),
                  ),
                  if (!isToday) ...[
                    SizedBox(width: 8.w),
                    ElevatedButton.icon(
                      onPressed: () => _startDay(day, workouts),
                      icon: Icon(Icons.play_arrow, size: 16.sp, color: ColorManager.onMint),
                      label: Text('Start Day', style: TextStyle(fontSize: 12.sp, color: ColorManager.onMint, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.gradientStart,
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Text(subtitle, style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp)),
              children: workouts.map((w) => _buildWorkoutCard(workout: w, onStart: () => _startSingleExercise(context, w), isGrouped: true, latestLogMap: latestLogMap)).toList(),
            ),
          ),
          if (isToday)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
              child: SizedBox(
                width: double.infinity,
                height: 44.h,
                child: ElevatedButton.icon(
                  key: const Key('today_start_button'),
                  onPressed: () => _startDay(day, workouts),
                  icon: Icon(Icons.play_arrow, size: 18.sp, color: ColorManager.onMint),
                  label: Text(
                    done ? 'Train again' : "Start today's workout",
                    style: TextStyle(fontSize: 14.sp, color: ColorManager.onMint, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.gradientStart,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isPremium =
        Provider.of<SubscriptionProvider?>(context)?.isPremium ?? false;
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    final statsProvider =
        Provider.of<StatisticsProvider>(context, listen: false);

    return GradientHeroCard(
      key: const Key('no_plan_active_hero'),
      imageAsset: HeroImages.forKey('chest'),
      imageSize: AppCardSize.heroImageSize,
      padding: EdgeInsets.all(AppCardSize.heroPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(right: GradientHeroCard.textInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HeroBadge(
                  text: 'WEEKLY PLAN',
                  icon: Icons.calendar_month_rounded,
                ),
                SizedBox(height: 12.h),
                Text(
                  'No Plan Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  isPremium
                      ? 'Use AI to generate a full weekly schedule instantly.'
                      : 'Activate your free 3-day starter routine (Mon, Wed, Fri) or upgrade to Pro for custom splits.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 14.sp,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton.icon(
              onPressed: () => context.push(Routes.workoutGeneratorRoute),
              icon: Icon(Icons.auto_awesome, size: 18.sp, color: ColorManager.onMint),
              label: Text(
                'Build a Plan',
                style: TextStyle(
                  color: ColorManager.onMint,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
              ),
            ),
          ),
          if (!isPremium) ...[
            SizedBox(height: 6.h),
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  try {
                    await workoutProvider.restoreDefaultThreeDaySplit();
                    await statsProvider.updateScheduledDays(
                      const ['Monday', 'Wednesday', 'Friday'],
                      effectiveDate: DateTime.now(),
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
                },
                icon: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 16),
                label: const Text(
                  'Or Activate Free 3-Day Starter Routine',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, WorkoutLog> _buildLatestLogMap(List<WorkoutLog> logs) {
    final Map<String, WorkoutLog> map = {};
    for (final log in logs) {
      final key = log.exerciseName.trim().toLowerCase();
      if (!map.containsKey(key) || log.date.isAfter(map[key]!.date)) {
        map[key] = log;
      }
    }
    return map;
  }

  Widget _buildWorkoutCard({required dynamic workout, required VoidCallback onStart, required bool isGrouped, Map<String, WorkoutLog>? latestLogMap}) {
    String displayName = workout.name;
    if (isGrouped) {
      final regex = RegExp(r'^\[\w+\]\s*');
      displayName = displayName.replaceAll(regex, '');
    }

    final cleanKey = displayName.trim().toLowerCase();
    final prevLog = latestLogMap?[cleanKey];
    String? lastSessionText;
    String? nudgeText;
    if (prevLog != null && prevLog.sets.isNotEmpty) {
      final date = DateFormat('MMM d').format(prevLog.date);
      final topSet = prevLog.sets.reduce((a, b) => a.weight >= b.weight ? a : b);
      lastSessionText = '${prevLog.sets.length} sets · ${topSet.weight.toInt()}kg × ${topSet.reps} reps · $date';
      nudgeText = ProgressionService.nudgeFor(displayName, prevLog);
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: isGrouped ? null : BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.small.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.fitness_center, color: Colors.blue, size: 16.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.w600, fontSize: 16.sp)),
                Text('${workout.setNumber} sets × ${workout.repNumber} reps', style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp)),
                if (lastSessionText != null) ...[
                  SizedBox(height: 5.h),
                  Row(
                    children: [
                      Icon(Icons.history, size: 11.sp, color: Colors.teal),
                      SizedBox(width: 4.w),
                      Flexible(child: Text(lastSessionText, style: TextStyle(color: Colors.teal, fontSize: 11.sp), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  if (nudgeText != null)
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Text(nudgeText, style: TextStyle(color: Colors.orange, fontSize: 11.sp, fontWeight: FontWeight.w500)),
                    ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(tooltip: 'Start workout', onPressed: onStart, icon: const Icon(Icons.play_circle_fill, color: ColorManager.gradientStart), iconSize: 32.sp, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              SizedBox(width: 4.w),
              PopupMenuButton<String>(
                tooltip: 'More options',
                padding: EdgeInsets.zero,
                color: ColorManager.surface,
                icon: Icon(Icons.more_vert, color: ColorManager.textTertiary, size: 20.sp),
                onSelected: (value) {
                  if (value == 'delete') _confirmDeleteWorkout(workout, displayName);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete exercise', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteWorkout(dynamic workout, String displayName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ColorManager.background,
        title: Text('Delete Workout?', style: TextStyle(color: ColorManager.textPrimary)),
        content: Text('Delete "$displayName"?', style: TextStyle(color: ColorManager.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      if (!mounted) return;
      LoadingOverlay.show(context, message: 'Deleting...');
      try {
        await Provider.of<WorkoutProvider>(context, listen: false).deleteWorkoutByNameAndAllWorkoutId(name: workout.name, allWorkoutId: workout.id);
        if (!mounted) return;
        await Provider.of<WorkoutProvider>(context, listen: false).fetchAndSetWorkouts();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) LoadingOverlay.hide(context);
      }
    }
  }

  /// The play button on a single exercise starts a one-exercise guided
  /// session (rest timer, last-time values, reward screen, History entry)
  /// instead of opening the loose-log sheet.
  void _startSingleExercise(BuildContext context, dynamic workout) {
    final cleanName = ExerciseData.normalizeExerciseName(workout.name);
    // The exercise name stands in for the day name, so finishing it never
    // marks a weekday of the plan as done.
    _startDay(cleanName, [workout]);
  }
}
