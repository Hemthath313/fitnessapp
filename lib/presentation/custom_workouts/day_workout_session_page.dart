import 'dart:async';
import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/presentation/workouts/widgets/workout_timer_widget.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:provider/provider.dart';

class DayWorkoutSessionPage extends StatefulWidget {
  final String dayName;
  final List<dynamic> workouts; // WorkoutModel list

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
  bool _isRestingBetweenSets = false; // Tracks rest between sets of same exercise vs between exercises
  bool _isCompleted = false;
  int _completedSets = 0; // Track set-by-set progress

  Timer? _sessionTimer;
  int _elapsedSeconds = 0;

  final List<WorkoutLog> _sessionLogs = [];
  late List<TextEditingController> _weightControllers;
  late List<TextEditingController> _repControllers;
  late List<bool> _setCompletedStates;

  @override
  void initState() {
    super.initState();
    _startSessionTimer();
    _initializeCurrentExercise();
  }

  void _initializeCurrentExercise() {
    final currentWorkout = widget.workouts[_currentIndex];
    final totalSets = currentWorkout.setNumber;
    
    _weightControllers = List.generate(
      totalSets,
      (_) => TextEditingController(text: '12'), // Default to 12 kg
    );
    _repControllers = List.generate(
      totalSets,
      (_) => TextEditingController(text: '${currentWorkout.repNumber}'),
    );
    _setCompletedStates = List.generate(totalSets, (_) => false);
    _completedSets = 0;
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isResting && !_isCompleted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    for (var controller in _weightControllers) {
      controller.dispose();
    }
    for (var controller in _repControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatSessionTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

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
            tooltip: 'Workout Overview',
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
              : SingleChildScrollView(
                  child: _buildExerciseView(currentWorkout, displayName),
                ),
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
      ];
      foundExercise = allExercises.firstWhere(
        (e) => e.name.toLowerCase() == cleanName.toLowerCase(),
      );
    } catch (_) {}

    return Column(
      children: [
        // 1. Video / Illustration Section
        Container(
          height: 220.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: ColorManager.surface,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: ColorManager.divider),
          ),
          child: Column(
            children: [
              Expanded(
                child: foundExercise != null && foundExercise.videoPath.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                        child: ExerciseVideoPlayer(
                          videoPath: foundExercise.videoPath,
                          height: double.infinity,
                          autoPlay: true,
                        ),
                      )
                    : Center(
                        child: Icon(Icons.fitness_center, size: 64.sp, color: ColorManager.primary),
                      ),
              ),
              Padding(
                padding: EdgeInsets.all(12.w),
                child: Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // 2. Target Info Chip
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: ColorManager.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: ColorManager.primary, size: 16.sp),
              SizedBox(width: 8.w),
              Text(
                'Recommended Target: ${workout.repNumber} reps',
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // 3. Metric Circles Row (Matching Mockup)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildMetricCircle('${workout.repNumber}', 'Repeats required'),
            _buildMetricCircle(_formatSessionTime(_elapsedSeconds), 'Active timer'),
            _buildMetricCircle('$_completedSets / ${workout.setNumber}', 'Sets made'),
          ],
        ),
        SizedBox(height: 16.h),

        // 4. Sets Table (Weight, Reps Input Form matching mockup)
        Card(
          color: ColorManager.surface,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTableHeaderCell('Set'),
                    _buildTableHeaderCell('Weight (kg)'),
                    _buildTableHeaderCell('Reps'),
                    _buildTableHeaderCell('Log'),
                  ],
                ),
                const Divider(),
                ...List.generate(workout.setNumber, (index) {
                  final isDone = _setCompletedStates[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Set Number Badge
                        Expanded(
                          child: Center(
                            child: CircleAvatar(
                              radius: 12.r,
                              backgroundColor: isDone ? ColorManager.success : ColorManager.primary.withOpacity(0.15),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isDone ? Colors.white : ColorManager.primary,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Weight input field
                        Expanded(
                          child: Center(
                            child: SizedBox(
                              width: 65.w,
                              height: 32.h,
                              child: TextField(
                                controller: _weightControllers[index],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                enabled: !isDone,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.zero,
                                  filled: true,
                                  fillColor: isDone ? ColorManager.background : ColorManager.divider.withOpacity(0.3),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Reps input field
                        Expanded(
                          child: Center(
                            child: SizedBox(
                              width: 65.w,
                              height: 32.h,
                              child: TextField(
                                controller: _repControllers[index],
                                keyboardType: TextInputType.number,
                                enabled: !isDone,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.zero,
                                  filled: true,
                                  fillColor: isDone ? ColorManager.background : ColorManager.divider.withOpacity(0.3),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Log Status Checkbox Icon
                        Expanded(
                          child: Center(
                            child: IconButton(
                              icon: Icon(
                                isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: isDone ? ColorManager.success : ColorManager.textTertiary,
                              ),
                              onPressed: () => _toggleSetCompletion(index, workout),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // 5. Primary Button to Complete Set or Exercise
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final firstIncomplete = _setCompletedStates.indexOf(false);
              if (firstIncomplete != -1) {
                _toggleSetCompletion(firstIncomplete, workout);
              } else {
                _completeExercise();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 4,
            ),
            child: Text(
              _completedSets >= workout.setNumber ? 'Complete Exercise' : 'Log Set ${_completedSets + 1}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeaderCell(String label) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: ColorManager.textTertiary,
          fontWeight: FontWeight.bold,
          fontSize: 11.sp,
        ),
      ),
    );
  }

  Widget _buildMetricCircle(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80.w,
          height: 80.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorManager.surface,
            border: Border.all(
              color: ColorManager.primary.withOpacity(0.4),
              width: 2.w,
            ),
            boxShadow: [
              BoxShadow(
                color: ColorManager.primary.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorManager.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ColorManager.textSecondary,
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRestView() {
    dynamic nextWorkout;
    String nextName = '';
    
    if (!_isRestingBetweenSets && _currentIndex + 1 < widget.workouts.length) {
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
        const WorkoutTimerWidget(
          isRestTimer: true,
          initialMinutes: 1, // Default 1 min rest
        ),
        
        if (!_isRestingBetweenSets && nextWorkout != null) ...[
          SizedBox(height: 32.h),
          Text(
            'Up Next:',
            style: TextStyle(color: ColorManager.textSecondary, fontSize: 14.sp),
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
             style: TextStyle(color: ColorManager.textTertiary, fontSize: 14.sp),
          ),
        ] else if (_isRestingBetweenSets) ...[
          SizedBox(height: 32.h),
          Text(
            'Get Ready for Set ${_completedSets + 1}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        Spacer(),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _skipRest,
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

  void _skipRest() {
    if (_isRestingBetweenSets) {
      setState(() {
        _isResting = false;
        _isRestingBetweenSets = false;
      });
    } else {
      setState(() {
        _isResting = false;
        _currentIndex++;
        _initializeCurrentExercise();
      });
    }
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
                     Provider.of<WorkoutProvider>(context, listen: false).fetchAndSetWorkouts();
                     Navigator.of(context).pop();
                   },
                   style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      foregroundColor: Colors.black,
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

  void _toggleSetCompletion(int index, dynamic workout) {
    if (_setCompletedStates[index]) {
      setState(() {
        _setCompletedStates[index] = false;
        _completedSets--;
      });
    } else {
      setState(() {
        _setCompletedStates[index] = true;
        _completedSets++;
      });
      
      if (_completedSets < workout.setNumber) {
        setState(() {
          _isResting = true;
          _isRestingBetweenSets = true;
        });
      }
    }
  }
  
  void _completeExercise() {
    final currentWorkout = widget.workouts[_currentIndex];
    
    // Package sets into WorkoutSet list
    final List<WorkoutSet> completedSets = [];
    for (int i = 0; i < currentWorkout.setNumber; i++) {
      final weight = double.tryParse(_weightControllers[i].text) ?? 12.0;
      final reps = int.tryParse(_repControllers[i].text) ?? currentWorkout.repNumber;
      completedSets.add(WorkoutSet(weight: weight, reps: reps));
    }
    
    // Save to session logs list
    _sessionLogs.add(WorkoutLog(
      id: '',
      exerciseName: currentWorkout.name.replaceAll(RegExp(r'^\[\w+\]\s*'), '').trim(),
      date: DateTime.now(),
      sets: completedSets,
      category: 'Strength',
    ));

    if (_currentIndex >= widget.workouts.length - 1) {
      _finishWorkoutForReal();
    } else {
      setState(() {
        _isResting = true;
        _isRestingBetweenSets = false;
      });
    }
  }

  Future<void> _finishWorkoutForReal() async {
    final logService = WorkoutLogService();
    try {
      // Save all session logs to Firestore!
      for (var log in _sessionLogs) {
        await logService.addLog(log);
      }
      
      // Update streak statistics!
      if (mounted) {
        final statisticsProvider = Provider.of<StatisticsProvider>(context, listen: false);
        await statisticsProvider.updateStreak();
      }
    } catch (e) {
      print('Error saving workout logs or updating streak: $e');
    }
    
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
        content: Text(
          'Your progress for this session will be lost.',
          style: TextStyle(color: ColorManager.textSecondary),
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
