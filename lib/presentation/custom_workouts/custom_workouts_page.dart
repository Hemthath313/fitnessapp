import 'package:fitness_app/presentation/banner_ads/banner_ad_service.dart';
import 'package:fitness_app/utils/widgets/loading_overlay.dart';
import 'package:fitness_app/presentation/custom_workouts/day_workout_session_page.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/presentation/workouts/widgets/workout_timer_widget.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:fitness_app/presentation/widgets/interactive_exercise_detail.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CustomWorkoutsPage extends StatefulWidget {
  const CustomWorkoutsPage({super.key});

  @override
  State<CustomWorkoutsPage> createState() => _CustomWorkoutsPageState();
}

class _CustomWorkoutsPageState extends State<CustomWorkoutsPage> {
  // Map to order days correctly
  final Map<String, int> _dayOrder = {
    'Monday': 1,
    'Tuesday': 2,
    'Wednesday': 3,
    'Thursday': 4,
    'Friday': 5,
    'Saturday': 6,
    'Sunday': 7,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      workoutProvider.fetchAndSetWorkouts();
    });
  }

  void _deleteWeeklyPlan(WorkoutProvider provider) async {
    // Show confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ColorManager.background,
        title: Text('Reset Weekly Plan?', style: TextStyle(color: ColorManager.textPrimary)),
        content: Text(
          'This will delete all AI-generated exercises from your schedule. Grouped workouts (e.g. [Monday]...) will be removed.',
          style: TextStyle(color: ColorManager.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
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
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error resetting weekly plan: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: ColorManager.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        );
      } finally {
        if (mounted) {
          LoadingOverlay.hide(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(SizeManager.s16.w),
              child: Consumer<WorkoutProvider>(
                builder: (context, provider, _) {
                  final hasWeeklyPlan = provider.allWorkouts.any((w) => w.name.startsWith('['));
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                            hasWeeklyPlan ? 'Weekly Schedule' : 'My Workouts',
                            style: TextStyle(
                              color: ColorManager.white,
                              fontSize: SizeManager.s24.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (hasWeeklyPlan)
                            Text(
                              'AI Generated Plan',
                              style: TextStyle(
                                color: ColorManager.gradientStart,
                                fontSize: 12.sp,
                              ),
                            ),
                         ],
                       ),
                      if (hasWeeklyPlan)
                        IconButton(
                          onPressed: () => _deleteWeeklyPlan(provider),
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          tooltip: 'Reset Plan',
                        )
                      else 
                        ElevatedButton.icon(
                          onPressed: () => context.push(Routes.workoutGeneratorRoute),
                          icon: const Icon(Icons.auto_awesome, color: Colors.white),
                          label: const Text('AI Build', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: ColorManager.primary),
                        ),
                    ],
                  );
                }
              ),
            ),

            // Main Listing
            Expanded(
              child: Consumer<WorkoutProvider>(
                builder: (context, workoutProvider, _) {
                  if (workoutProvider.allWorkouts.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  // Group by Day
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

                  // If no groups, just show list
                  if (groupedMap.isEmpty) {
                    return StreamBuilder<List<WorkoutLog>>(
                      stream: WorkoutLogService().getLogs(),
                      builder: (context, snap) {
                        final logs = snap.data ?? [];
                        final latestLogMap = _buildLatestLogMap(logs);
                        return ListView.builder(
                          padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 80.h),
                          itemCount: otherWorkouts.length,
                          itemBuilder: (context, index) => _buildWorkoutCard(
                            workout: otherWorkouts[index],
                            onStart: () => _showWorkoutTimerDialog(context, otherWorkouts[index]),
                            onEdit: () {},
                            isGrouped: false,
                            latestLogMap: latestLogMap,
                          ),
                        );
                      },
                    );
                  }

                  // Sort Days
                  final sortedDays = groupedMap.keys.toList()
                    ..sort((a, b) => (_dayOrder[a] ?? 99).compareTo(_dayOrder[b] ?? 99));

                  return StreamBuilder<List<WorkoutLog>>(
                    stream: WorkoutLogService().getLogs(),
                    builder: (context, snap) {
                      final logs = snap.data ?? [];
                      final latestLogMap = _buildLatestLogMap(logs);

                      return ListView(
                        padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 80.h),
                        children: [
                          ...sortedDays.map((day) {
                            final workouts = groupedMap[day]!;

                            // Find last date any exercise from this day was logged THIS WEEK
                            // so "Start Day" resets each new week
                            final now = DateTime.now();
                            final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
                            final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

                            DateTime? lastDone;
                            for (var w in workouts) {
                              final cleanName = w.name.replaceAll(RegExp(r'^\[\w+\]\s*'), '').trim().toLowerCase();
                              final log = latestLogMap[cleanName];
                              if (log != null && log.date.isAfter(weekStart)) {
                                if (lastDone == null || log.date.isAfter(lastDone)) {
                                  lastDone = log.date;
                                }
                              }
                            }

                            return Card(
                              margin: EdgeInsets.only(bottom: 16.h),
                              color: ColorManager.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                side: BorderSide(
                                  color: lastDone != null ? ColorManager.primary.withValues(alpha: 0.4) : ColorManager.divider,
                                ),
                              ),
                              elevation: 0,
                              clipBehavior: Clip.antiAlias,
                              child: Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  initiallyExpanded: true,
                                  title: Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            day,
                                            style: TextStyle(
                                              color: ColorManager.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18.sp,
                                            ),
                                          ),
                                          if (lastDone != null)
                                            Text(
                                              'Last done: ${DateFormat('MMM d').format(lastDone)}',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const Spacer(),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                DayWorkoutSessionPage(
                                                  dayName: day,
                                                  workouts: workouts,
                                                ),
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.play_arrow, size: 16.sp, color: Colors.white),
                                        label: Text(
                                          lastDone != null ? 'Redo' : 'Start Day',
                                          style: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: lastDone != null ? Colors.green : ColorManager.gradientStart,
                                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    '${workouts.length} Exercises',
                                    style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp),
                                  ),
                                  children: workouts.map((w) => _buildWorkoutCard(
                                    workout: w,
                                    onStart: () => _showWorkoutTimerDialog(context, w),
                                    onEdit: () {},
                                    isGrouped: true,
                                    latestLogMap: latestLogMap,
                                  )).toList(),
                                ),
                              ),
                            );
                          }),
                          if (otherWorkouts.isNotEmpty) ...[
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              child: Text('Other Workouts', style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold)),
                            ),
                            ...otherWorkouts.map((w) => _buildWorkoutCard(
                              workout: w,
                              onStart: () => _showWorkoutTimerDialog(context, w),
                              onEdit: () {},
                              isGrouped: false,
                              latestLogMap: latestLogMap,
                            )),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            
            const PremiumAwareBannerAd(pageName: 'workout', bottomMargin: 60.0),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_rounded, size: 80.sp, color: ColorManager.primary.withOpacity(0.2)),
          SizedBox(height: 20.h),
          Text(
            'No Weekly Plan',
            style: TextStyle(color: ColorManager.textPrimary, fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Text(
              'Use AI to generate a full weekly schedule instantly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ColorManager.textSecondary),
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () => context.push(Routes.workoutGeneratorRoute),
            icon: Icon(Icons.auto_awesome, color: Colors.white),
            label: Text('Generate Plan', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
            ),
          ),
          TextButton.icon(
             onPressed: () => context.push(Routes.addNewExerciseRoute),
             icon: const Icon(Icons.add, color: Colors.grey),
             label: const Text('Manual Entry', style: TextStyle(color: Colors.grey)),
          )
        ],
      ),
    );
  }

  /// Builds a map of exercise name (lowercase) -> most recent WorkoutLog
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

  Widget _buildWorkoutCard({
    required dynamic workout,
    required VoidCallback onStart,
    required VoidCallback onEdit,
    required bool isGrouped,
    Map<String, WorkoutLog>? latestLogMap,
  }) {
    // If grouped, remove the [Day] prefix from display name
    String displayName = workout.name;
    if (isGrouped) {
      final regex = RegExp(r'^\[\w+\]\s*');
      displayName = displayName.replaceAll(regex, '');
    }

    // Lookup previous log for this exercise
    final cleanKey = displayName.trim().toLowerCase();
    final prevLog = latestLogMap?[cleanKey];

    // Build last session summary string
    String? lastSessionText;
    String? nudgeText;
    if (prevLog != null && prevLog.sets.isNotEmpty) {
      final date = DateFormat('MMM d').format(prevLog.date);
      final topSet = prevLog.sets.reduce((a, b) => a.weight >= b.weight ? a : b);
      lastSessionText = '${prevLog.sets.length} sets · ${topSet.weight.toInt()}kg × ${topSet.reps} reps · $date';
      // Progressive overload nudge: suggest +2.5kg
      final suggestedWeight = topSet.weight + 2.5;
      nudgeText = '🔺 Try ${suggestedWeight.toStringAsFixed(1)}kg today';
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: isGrouped
          ? null
          : BoxDecoration(
              color: ColorManager.surfaceDark,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: ColorManager.divider),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.fitness_center, color: Colors.blue, size: 16.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp),
                ),
                Text(
                  '${workout.setNumber} sets × ${workout.repNumber} reps',
                  style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp),
                ),
                if (lastSessionText != null) ...[
                  SizedBox(height: 5.h),
                  Row(
                    children: [
                      Icon(Icons.history, size: 11.sp, color: Colors.teal),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          lastSessionText,
                          style: TextStyle(color: Colors.teal, fontSize: 11.sp),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (nudgeText != null)
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Text(
                        nudgeText,
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          // Actions: Play and Delete
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onStart,
                icon: const Icon(Icons.play_circle_fill,
                    color: ColorManager.gradientStart),
                iconSize: 32.sp,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(width: 12.w),
              IconButton(
                onPressed: () async {
                   final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      backgroundColor: ColorManager.background,
                      title: Text('Delete Workout?', style: TextStyle(color: ColorManager.textPrimary)),
                      content: Text('Delete "$displayName"?', style: TextStyle(color: ColorManager.textSecondary)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true) {
                    if (!mounted) return;
                    LoadingOverlay.show(context, message: 'Deleting workout...');
                    try {
                      await Provider.of<WorkoutProvider>(context, listen: false)
                          .deleteWorkoutByNameAndAllWorkoutId(
                            name: workout.name,
                            allWorkoutId: workout.id,
                          );
                      
                      if (!mounted) return;
                      await Provider.of<WorkoutProvider>(context, listen: false).fetchAndSetWorkouts();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error deleting workout: $e',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: ColorManager.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      );
                    } finally {
                      if (mounted) {
                        LoadingOverlay.hide(context);
                      }
                    }
                  }
                },
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                iconSize: 20.sp,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showWorkoutTimerDialog(BuildContext context, dynamic workout) {
    String displayName = workout.name;
    final regex = RegExp(r'^\[\w+\]\s*');
    displayName = displayName.replaceAll(regex, '');
    final cleanName = displayName.trim();
    
    Exercise? foundExercise;
    try {
      final allExercises = [
        ...ExerciseData.chest,
        ...ExerciseData.back,
        ...ExerciseData.shoulders,
        ...ExerciseData.biceps,
        ...ExerciseData.triceps,
        ...ExerciseData.legs,
        ...ExerciseData.abs,
        ...ExerciseData.cardio,
      ];
      foundExercise = allExercises.firstWhere(
        (e) => e.name.toLowerCase() == cleanName.toLowerCase(),
      );
    } catch (_) {}

    String category = 'Chest';
    if (foundExercise != null) {
      if (ExerciseData.chest.any((e) => e.name == foundExercise!.name)) {
        category = 'Chest';
      } else if (ExerciseData.biceps.any((e) => e.name == foundExercise!.name)) {
        category = 'Biceps';
      } else if (ExerciseData.back.any((e) => e.name == foundExercise!.name)) {
        category = 'Lats';
      } else if (ExerciseData.triceps.any((e) => e.name == foundExercise!.name)) {
        category = 'Triceps';
      } else if (ExerciseData.legs.any((e) => e.name == foundExercise!.name)) {
        category = 'Legs';
      } else if (ExerciseData.abs.any((e) => e.name == foundExercise!.name)) {
        category = 'Abs';
      } else if (ExerciseData.shoulders.any((e) => e.name == foundExercise!.name)) {
        category = 'Shoulder';
      } else if (ExerciseData.cardio.any((e) => e.name == foundExercise!.name)) {
        category = 'Cardio';
      }
    }

    final exerciseToUse = foundExercise ?? Exercise(
      name: cleanName,
      videoPath: '',
      description: 'Custom exercise routine.',
      target: 'N/A',
      equipment: 'N/A',
      instructions: const ['Perform the custom exercise as scheduled.'],
      difficulty: 'Intermediate',
      setsReps: '${workout.setNumber} sets x ${workout.repNumber} reps',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => InteractiveExerciseDetailWidget(
        name: exerciseToUse.name,
        videoPath: exerciseToUse.videoPath,
        description: exerciseToUse.description,
        target: exerciseToUse.target,
        equipment: exerciseToUse.equipment,
        instructions: exerciseToUse.instructions,
        difficulty: exerciseToUse.difficulty,
        setsReps: exerciseToUse.setsReps,
        category: category,
      ),
    );
  }
}
