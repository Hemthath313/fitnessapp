import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/presentation/workouts/widgets/workout_timer_widget.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:provider/provider.dart';

class DayWorkoutSessionPage extends StatefulWidget {
  final String dayName;
  final List<dynamic> workouts; // Using dynamic because existing code used dynamic for some reason, but essentially WorkoutModel

  const DayWorkoutSessionPage({
    super.key,
    required this.dayName,
    required this.workouts,
  });

  @override
  State<DayWorkoutSessionPage> createState() => _DayWorkoutSessionPageState();
}

class _DayWorkoutSessionPageState extends State<DayWorkoutSessionPage> {
  int _currentIndex = 0;
  bool _isResting = false;
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return _buildCompletionView();
    }

    final currentWorkout = widget.workouts[_currentIndex];
    
    // Clean up name for display
    String displayName = currentWorkout.name;
    final regex = RegExp(r'^\[\w+\]\s*');
    displayName = displayName.replaceAll(regex, '');

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: ColorManager.textPrimary),
          onPressed: () => _confirmExit(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.list, color: ColorManager.textPrimary),
            tooltip: 'Workout List',
            onPressed: _showWorkoutList,
          ),
          IconButton(
            icon: Icon(Icons.timer_outlined, color: ColorManager.textPrimary),
            tooltip: 'Manual Stopwatch',
            onPressed: () => _showManualStopwatch(context),
          ),
        ],
        centerTitle: true,
        title: Column(
          children: [
            Text(
              widget.dayName,
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
            Text(
              'Exercise ${_currentIndex + 1} of ${widget.workouts.length}',
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: _isResting
              ? _buildRestView()
              : _buildExerciseView(currentWorkout, displayName),
        ),
      ),
    );
  }

  void _showManualStopwatch(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ColorManager.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(Icons.timer, color: ColorManager.limerGreen2),
            SizedBox(width: 8.w),
            Text(
              'Manual Stopwatch',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontFamily: 'Roboto', // Assuming default font
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 300.w,
          child: const WorkoutTimerWidget(
            isRestTimer: false,
            initialMinutes: 0,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _showWorkoutList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorManager.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Overview',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: ListView.builder(
                itemCount: widget.workouts.length,
                itemBuilder: (context, index) {
                  final w = widget.workouts[index];
                  final isCurrent = index == _currentIndex;
                  final isDone = index < _currentIndex;
                  
                  String name = w.name.replaceAll(RegExp(r'^\[\w+\]\s*'), '');

                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: isCurrent 
                          ? ColorManager.primary.withOpacity(0.2) 
                          : ColorManager.surface,
                      borderRadius: BorderRadius.circular(12.r),
                      border: isCurrent 
                          ? Border.all(color: ColorManager.primary) 
                          : null,
                    ),
                    child: ListTile(
                      leading: Icon(
                        isDone ? Icons.check_circle : Icons.fitness_center,
                        color: isDone 
                            ? ColorManager.limerGreen2 
                            : (isCurrent ? ColorManager.primary : Colors.grey),
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          color: isDone ? Colors.white54 : Colors.white,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${w.setNumber} Sets × ${w.repNumber} Reps',
                        style: TextStyle(
                          color: ColorManager.textTertiary,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseView(dynamic workout, String displayName) {
      // Find exercise video logic
      final cleanName = displayName.trim();
      Exercise? foundExercise;
      try {
        final allExercises = [
          ...ExerciseData.chest,
          ...ExerciseData.back,
          // ExerciseData.cardio is problematic, removed for now, will add back correct one after checking
          ...ExerciseData.shoulders, 
          // ... other lists
        ];
        foundExercise = allExercises.firstWhere(
          (e) => e.name.toLowerCase() == cleanName.toLowerCase(),
        );
      } catch (_) {}

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          Container(
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
               color: ColorManager.surface,
               borderRadius: BorderRadius.circular(20.r),
               border: Border.all(color: ColorManager.primary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                 if (foundExercise != null && foundExercise.videoPath.isNotEmpty)
                   ClipRRect(
                     borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                     child: ExerciseVideoPlayer(
                       videoPath: foundExercise.videoPath,
                       height: 250.h,
                       autoPlay: true,
                     ),
                   )
                 else 
                   Padding(
                     padding: EdgeInsets.symmetric(vertical: 40.h),
                     child: Icon(Icons.fitness_center, size: 48.sp, color: ColorManager.primary),
                   ),
                 
                 Padding(
                   padding: EdgeInsets.all(24.w),
                   child: Column(
                     children: [
                        Text(
                          displayName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             _buildInfoChip('${workout.setNumber} Sets'),
                             SizedBox(width: 12.w),
                             _buildInfoChip('${workout.repNumber} Reps'),
                           ],
                        ),
                     ],
                   ),
                 ),
              ],
            ),
          ),
        
        SizedBox(height: 32.h),
        
        // Timer for the exercise (Stopwatch)
        WorkoutTimerWidget(
          isRestTimer: false,
          initialMinutes: 0,
        ),
        
        Spacer(),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _completeExercise,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Complete Exercise',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: ColorManager.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRestView() {
    dynamic nextWorkout;
    String nextName = '';
    
    if (_currentIndex + 1 < widget.workouts.length) {
      nextWorkout = widget.workouts[_currentIndex + 1];
      nextName = nextWorkout.name.replaceAll(RegExp(r'^\[\w+\]\s*'), '');
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Spacer(),
        Text(
          'REST TIME',
          style: TextStyle(
            color: ColorManager.limerGreen2,
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 24.h),
        
        // Rest Timer (Countdown)
        WorkoutTimerWidget(
          isRestTimer: true,
          initialMinutes: 1, // Default 1 min rest
        ),
        
        if (nextWorkout != null) ...[
          SizedBox(height: 32.h),
          Text(
            'Up Next:',
            style: TextStyle(color: ColorManager.textTertiary, fontSize: 14.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            nextName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ColorManager.textPrimary, 
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
             '${nextWorkout.setNumber} sets • ${nextWorkout.repNumber} reps',
             style: TextStyle(color: ColorManager.textSecondary, fontSize: 14.sp),
          ),
        ],
        Spacer(),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _isResting = false;
                _currentIndex++;
              });
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: ColorManager.primary),
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Skip Rest',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: ColorManager.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionView() {
    return Scaffold(
      backgroundColor: ColorManager.background,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(Icons.check_circle_outline, 
                 size: 100.sp, color: ColorManager.limerGreen2),
               SizedBox(height: 24.h),
               Text(
                 'Day Completed!',
                 style: TextStyle(
                   color: ColorManager.textPrimary,
                   fontSize: 28.sp,
                   fontWeight: FontWeight.bold,
                 ),
               ),
               SizedBox(height: 12.h),
               Text(
                 'You crushed ${widget.dayName} workout.',
                 textAlign: TextAlign.center,
                 style: TextStyle(color: ColorManager.textSecondary, fontSize: 16.sp),
               ),
               SizedBox(height: 48.h),
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: () {
                     // Optionally mark day as done in backend if needed
                     
                     // Update stats
                     Provider.of<WorkoutProvider>(context, listen: false).fetchAndSetWorkouts();
                     Navigator.of(context).pop();
                   },
                   style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                   ),
                   child: Text(
                     'Finish',
                     style: TextStyle(
                       fontSize: 18.sp,
                       fontWeight: FontWeight.bold,
                       color: ColorManager.textPrimary,
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

  Widget _buildInfoChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: ColorManager.divider,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: ColorManager.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 14.sp,
        ),
      ),
    );
  }
  
  void _completeExercise() {
    // If it's the last exercise, finish the day
    if (_currentIndex >= widget.workouts.length - 1) {
      _finishWorkoutForReal();
    } else {
      // Go to rest
      setState(() {
        _isResting = true;
      });
    }
  }

  void _finishWorkoutForReal() {
    setState(() {
      _isCompleted = true;
    });
  }

  void _confirmExit() async {
     final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ColorManager.background,
        title: Text('Exit Workout?', style: TextStyle(color: ColorManager.textPrimary)),
        content: const Text(
          'Your progress for this session will be lost.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.pop(context);
    }
  }
}
