import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:fitness_app/presentation/in_app_purchases/premimum_screen.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/model/workout_model.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dart:math';

class WorkoutGeneratorScreen extends StatefulWidget {
  const WorkoutGeneratorScreen({super.key});

  @override
  State<WorkoutGeneratorScreen> createState() => _WorkoutGeneratorScreenState();
}

class _WorkoutGeneratorScreenState extends State<WorkoutGeneratorScreen> {
  bool _isLoading = false;
  
  // Weekly Schedule Structure: 
  // [ { "day": "Monday", "focus": "Chest", "exercises": [...] }, ... ]
  List<Map<String, dynamic>> _generatedWeek = [];

  // Selections
  String _target = 'Full Body';
  String _level = 'Beginner';
  String _equipment = 'Gym (Full Equipment)';
  int _daysPerWeek = 3;

  final List<String> _targets = [
    'Full Body',
    'Muscle Build (Hypertrophy)',
    'Strength',
    'Fat Loss'
  ];
  final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _equipments = [
    'Gym (Full Equipment)',
    'Home (Dumbbells)',
  ];
  final List<int> _daysOptions = [3, 4, 5, 6];

  @override
  void initState() {
    super.initState();
  }


  Future<void> _generateWorkout() async {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    if (!subscriptionProvider.isPremium) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedWeek = [];
    });

    // Simulate "Thinking" delay for UX
    await Future.delayed(const Duration(milliseconds: 1500));

    List<Map<String, dynamic>> plan = [];

    // Generation Logic
    if (_daysPerWeek == 3) {
      // 3 Day Full Body Split
      plan = [
        _createDayPlan('Monday', 'Full Body A', _mixAllGroups(5)),
        _createDayPlan('Wednesday', 'Full Body B', _mixAllGroups(5)),
        _createDayPlan('Friday', 'Full Body C', _mixAllGroups(5)),
      ];
    } else if (_daysPerWeek == 4) {
      // 4 Day Upper / Lower
      plan = [
        _createDayPlan('Monday', 'Upper Body', _getUpperBody(6)),
        _createDayPlan('Tuesday', 'Lower Body', _getRandomExercises(ExerciseData.legs, 5)),
        _createDayPlan('Thursday', 'Upper Body', _getUpperBody(6)),
        _createDayPlan('Friday', 'Lower Body', _getRandomExercises(ExerciseData.legs, 5)),
      ];
    } else if (_daysPerWeek == 5) {
      // 5 Day Bro Split
      plan = [
        _createDayPlan('Monday', 'Chest', _getRandomExercises(ExerciseData.chest, 4)),
        _createDayPlan('Tuesday', 'Back', _getRandomExercises(ExerciseData.back, 4)),
        _createDayPlan('Wednesday', 'Legs', _getRandomExercises(ExerciseData.legs, 5)),
        _createDayPlan('Thursday', 'Shoulders', _getRandomExercises(ExerciseData.shoulders, 4)),
        _createDayPlan('Friday', 'Arms', _getRandomExercises(ExerciseData.arms, 4)),
      ];
    } else {
      // 6 Day PPL
      plan = [
        _createDayPlan('Monday', 'Push', _getPush(5)),
        _createDayPlan('Tuesday', 'Pull', _getPull(5)),
        _createDayPlan('Wednesday', 'Legs', _getRandomExercises(ExerciseData.legs, 5)),
        _createDayPlan('Thursday', 'Push', _getPush(5)),
        _createDayPlan('Friday', 'Pull', _getPull(5)),
        _createDayPlan('Saturday', 'Legs', _getRandomExercises(ExerciseData.legs, 5)),
      ];
    }

    setState(() {
      _generatedWeek = plan;
      _isLoading = false;
    });
  }

  Map<String, dynamic> _createDayPlan(String day, String focus, List<Exercise> exercises) {
    return {
      'day': day,
      'focus': focus,
      'exercises': exercises.map((e) => {
        'name': e.name,
        'sets': 3, // Default sets
        'reps': e.setsReps.contains('x') ? e.setsReps.split('x').last.trim() : '10-12 reps',
        'videoPath': e.videoPath,
        'description': e.description,
        'target': e.target,
        'equipment': e.equipment,
        'difficulty': e.difficulty,
        'instructions': e.instructions,
        'setsReps': e.setsReps,
      }).toList(),
    };
  }

  // Helper Randomizers
  List<Exercise> _getRandomExercises(List<Exercise> source, int count) {
    if (source.isEmpty) return [];
    var list = List<Exercise>.from(source)..shuffle();
    return list.take(min(count, list.length)).toList();
  }

  List<Exercise> _mixAllGroups(int countPerGroup) {
    // Full Body: 1 chest, 1 back, 1 legs, 1 shoulder, 1 arms
    return [
      ..._getRandomExercises(ExerciseData.chest, 1),
      ..._getRandomExercises(ExerciseData.back, 1),
      ..._getRandomExercises(ExerciseData.legs, 1),
      ..._getRandomExercises(ExerciseData.shoulders, 1),
      ..._getRandomExercises(ExerciseData.arms, 1),
    ];
  }

  List<Exercise> _getUpperBody(int count) {
    return [
      ..._getRandomExercises(ExerciseData.chest, 2),
      ..._getRandomExercises(ExerciseData.back, 2),
      ..._getRandomExercises(ExerciseData.shoulders, 1),
      ..._getRandomExercises(ExerciseData.arms, 1),
    ];
  }
  
  List<Exercise> _getPush(int count) {
    return [
      ..._getRandomExercises(ExerciseData.chest, 2),
      ..._getRandomExercises(ExerciseData.shoulders, 2),
      ..._getRandomExercises(ExerciseData.arms.where((e) => e.target.contains('Triceps')).toList(), 1),
    ];
  }

  List<Exercise> _getPull(int count) {
    return [
      ..._getRandomExercises(ExerciseData.back, 3),
      ..._getRandomExercises(ExerciseData.arms.where((e) => e.target.contains('Biceps')).toList(), 2),
    ];
  }

  bool _isSaving = false;

  Future<void> _saveAllWorkouts() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final provider = Provider.of<WorkoutProvider>(context, listen: false);
    final now = DateTime.now();
    int count = 0;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      final List<WorkoutModel> workoutsToSave = [];

      for (var dayPlan in _generatedWeek) {
        final dayName = dayPlan['day'] ?? 'Day';
        final exercises = dayPlan['exercises'] as List<dynamic>? ?? [];

        for (var exercise in exercises) {
          final rawName = exercise['name'] ?? 'Exercise';
          final savedName = '[$dayName] $rawName'; 

          // Try to parse reps
          String reps = exercise['reps'].toString().replaceAll(RegExp(r'[^0-9]'), '');
          if (reps.isEmpty) reps = "10";
          if (reps.length > 2) reps = reps.substring(0,2); // handle "10-12" -> "10"

          workoutsToSave.add(
            WorkoutModel(
              id: '',
              name: savedName,
              repNumber: int.tryParse(reps) ?? 10,
              setNumber: int.tryParse(exercise['sets'].toString()) ?? 3,
              dateTime: now,
            ),
          );
          count++;
        }
      }

      if (workoutsToSave.isNotEmpty) {
        await provider.addNewWorkouts(workoutsToSave);
      }

      await provider.fetchAndSetWorkouts();

      if (mounted) {
        Navigator.pop(context); // Pop dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saved $count exercises to My Workouts!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: ColorManager.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            margin: EdgeInsets.all(16.w),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving: $e',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: ColorManager.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            margin: EdgeInsets.all(16.w),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Weekly Split',
              style: TextStyle(color: ColorManager.textPrimary, fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _isSaving ? null : _saveAllWorkouts,
              icon: Icon(Icons.save_alt, color: _isSaving ? Colors.grey : ColorManager.gradientStart),
              label: Text('Save Plan', style: TextStyle(color: _isSaving ? Colors.grey : ColorManager.limerGreen2)),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        ..._generatedWeek.map((dayPlan) => _buildDayCard(dayPlan)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text('AI Weekly Coach', style: TextStyle(color: ColorManager.textPrimary)),
        backgroundColor: ColorManager.background,
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeManager.s16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSelectionSection(),
            SizedBox(height: 24.h),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _generateWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'GENERATE WEEKLY PLAN',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            SizedBox(height: 24.h),
            
            if (_generatedWeek.isNotEmpty) _buildResultsSection(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSelectionSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorManager.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
           _buildDropdown('Days per Week', '$_daysPerWeek Days', _daysOptions.map((e) => '$e Days').toList(), 
            (val) => setState(() => _daysPerWeek = int.parse(val!.split(' ')[0]))),
           SizedBox(height: 16.h),
          _buildDropdown('Goal', _target, _targets, (val) => setState(() => _target = val!)),
          SizedBox(height: 16.h),
          _buildDropdown('Level', _level, _levels, (val) => setState(() => _level = val!)),
          SizedBox(height: 16.h),
          _buildDropdown('Equipment', _equipment, _equipments, (val) => setState(() => _equipment = val!)),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: ColorManager.textSecondary, fontSize: 14.sp),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: ColorManager.surfaceDark,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: ColorManager.surface,
              iconEnabledColor: ColorManager.textPrimary,
              style: TextStyle(color: ColorManager.textPrimary, fontSize: 16.sp),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(Map<String, dynamic> dayPlan) {
    final exercises = dayPlan['exercises'] as List<dynamic>? ?? [];
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: ExpansionTile(
        backgroundColor: ColorManager.surface,
        collapsedBackgroundColor: ColorManager.surface,
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Text(
          dayPlan['day'] ?? 'Day',
          style: TextStyle(color: ColorManager.primary, fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
        subtitle: Text(
          dayPlan['focus'] ?? 'Workout',
          style: TextStyle(color: ColorManager.textSecondary, fontSize: 14.sp),
        ),
        children: exercises.map((e) => ListTile(
          dense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          leading: Icon(Icons.play_circle_fill, color: ColorManager.primary, size: 24.sp),
          title: Text(
            e['name'],
            style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            e['description'] ?? '',
             maxLines: 1,
             overflow: TextOverflow.ellipsis,
             style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
          ),
          trailing: Text(
            '${e['sets']}x${e['reps']}',
            style: TextStyle(color: ColorManager.textSecondary),
          ),
          onTap: () {
            // Reconstruct Exercise object for details view
            final exerciseObj = Exercise(
              name: e['name'],
              videoPath: e['videoPath'],
              description: e['description'],
              target: e['target'] ?? 'General',
              equipment: e['equipment'] ?? 'None',
              difficulty: e['difficulty'] ?? 'All Levels',
              instructions: List<String>.from(e['instructions'] ?? []),
              setsReps: e['setsReps'] ?? '${e['sets']}x${e['reps']}',
            );
            _showExerciseDetails(context, exerciseObj);
          },
        )).toList(),
      ),
    );
  }

  void _showExerciseDetails(BuildContext context, Exercise exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: ColorManager.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorManager.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Player
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: ColorManager.primary.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: ExerciseVideoPlayer(
                          videoPath: exercise.videoPath,
                          height: 300,
                          autoPlay: true, // Auto-play in detail view
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Exercise Name
                    Text(
                      exercise.name,
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Description
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ColorManager.surface,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        exercise.description,
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 16.sp,
                          height: 1.6,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Info Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            'Target',
                            exercise.target,
                            Icons.center_focus_strong,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildDetailCard(
                            'Equipment',
                            exercise.equipment,
                            Icons.sports_gymnastics,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            'Difficulty',
                            exercise.difficulty,
                            Icons.trending_up,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildDetailCard(
                            'Sets & Reps',
                            exercise.setsReps,
                            Icons.repeat,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Instructions
                    Text(
                      'How to Perform',
                      style: TextStyle(
                        color: ColorManager.primary,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ...exercise.instructions.asMap().entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ColorManager.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ColorManager.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: ColorManager.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  color: ColorManager.textPrimary,
                                  fontSize: 15.sp,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),

            // Close Button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: ColorManager.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ColorManager.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: ColorManager.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
