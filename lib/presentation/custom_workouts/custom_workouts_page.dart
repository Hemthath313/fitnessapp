import 'package:fitness_app/presentation/banner_ads/banner_ad_service.dart';
import 'package:fitness_app/presentation/custom_workouts/day_workout_session_page.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/presentation/workouts/widgets/workout_timer_widget.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
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
      final aiWorkouts = provider.allWorkouts.where((w) => w.name.startsWith('[')).toList();
      for (var w in aiWorkouts) {
        // Assuming provider has a way to delete by ID, specifically for allWorkouts
        // The current provider method deleteWorkout checks 'workouts' collection, may need verify
        // But for now we stick to what we have or just recreate the logic if needed
        // The provider has `deleteAllWorkout` for "allWorkouts" collection usage
        await provider.deleteAllWorkout(allWorkoutID: w.id);
      }
      provider.fetchAndSetWorkouts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                          icon: Icon(Icons.auto_awesome, color: ColorManager.textPrimary),
                          label: Text('AI Build', style: TextStyle(color: ColorManager.textPrimary)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
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
                    // Check for [Day] pattern
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
                    return ListView.builder(
                      itemCount: otherWorkouts.length,
                      itemBuilder: (context, index) => _buildWorkoutCard(
                          workout: otherWorkouts[index],
                          onStart: () => _showWorkoutTimerDialog(context, otherWorkouts[index]),
                          onEdit: () {}, 
                          isGrouped: false),
                    );
                  }

                  // Sort Days
                  final sortedDays = groupedMap.keys.toList()
                    ..sort((a, b) => (_dayOrder[a] ?? 99).compareTo(_dayOrder[b] ?? 99));

                  return ListView(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    children: [
                      ...sortedDays.map((day) {
                        final workouts = groupedMap[day]!;
                        return Container(
                          margin: EdgeInsets.only(bottom: 16.h),
                          decoration: BoxDecoration(
                            color: ColorManager.surface,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: ColorManager.divider),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: true,
                              title: Row(
                                children: [
                                  Text(
                                    day,
                                    style: TextStyle(
                                      color: ColorManager.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18.sp,
                                    ),
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
                                    icon: Icon(Icons.play_arrow, size: 16.sp, color: ColorManager.textPrimary),
                                    label: Text(
                                      'Start Day', 
                                      style: TextStyle(fontSize: 12.sp, color: ColorManager.textPrimary, fontWeight: FontWeight.bold)
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: ColorManager.gradientStart,
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
                        )),
                      ]
                    ],
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
          Icon(Icons.calendar_month_rounded, size: 80.sp, color: Colors.purple.withOpacity(0.5)),
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
            icon: Icon(Icons.auto_awesome, color: ColorManager.textPrimary),
            label: Text('Generate Plan', style: TextStyle(color: ColorManager.textPrimary)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
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

  Widget _buildWorkoutCard({
    required dynamic workout,
    required VoidCallback onStart,
    required VoidCallback onEdit,
    required bool isGrouped,
  }) {
    // If grouped, remove the [Day] prefix from display name
    String displayName = workout.name;
    if (isGrouped) {
      final regex = RegExp(r'^\[\w+\]\s*');
      displayName = displayName.replaceAll(regex, '');
    }

    return Container(
      margin:
          EdgeInsets.symmetric(vertical: 4.h, horizontal: isGrouped ? 0 : 0),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: isGrouped
          ? null
          : BoxDecoration(
              color: ColorManager.surfaceDark,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: ColorManager.divider),
            ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
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
                    context: context, // Use the page context, since this method is in the State
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
                    await Provider.of<WorkoutProvider>(context, listen: false)
                        .deleteAllWorkout(allWorkoutID: workout.id);
                        
                    // Manually trigger fetch to update UI immediately
                    if (context.mounted) {
                      Provider.of<WorkoutProvider>(context, listen: false).fetchAndSetWorkouts();
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
     // Same implementation as before
     showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Find exercise video logic
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

        return AlertDialog(
          backgroundColor: ColorManager.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SizeManager.s20.r),
          ),
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Icon(Icons.timer, color: ColorManager.limerGreen2),
              SizedBox(width: SizeManager.s8.w),
              Expanded(
                child: Text(
                  '${workout.name} Timer',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: SizeManager.s20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            width: SizeManager.s300.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (foundExercise != null && foundExercise.videoPath.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(SizeManager.s20.r)),
                    child: ExerciseVideoPlayer(
                      videoPath: foundExercise.videoPath,
                      height: 200.h,
                      autoPlay: true,
                    ),
                  )
                else 
                   Padding(
                     padding: EdgeInsets.symmetric(vertical: 20.h),
                     child: Icon(Icons.fitness_center, size: 40.sp, color: ColorManager.primary),
                   ),
                
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: WorkoutTimerWidget(
                    isRestTimer: false,
                    initialMinutes: 0, 
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: ColorManager.white70),
              ),
            ),
          ],
        );
      }
    );

  }
}
