import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/presentation/workouts/widgets/exercise_widget.dart';
import 'package:fitness_app/presentation/workouts/widgets/new_exercise_button.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/interstitial_ads/interstitial_ad_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:provider/provider.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  bool _isLoading = false;
  int _workoutCount = 0;

  @override
  void initState() {
    super.initState();
    InterstitialAdService.loadInterstitialAd();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() => _isLoading = true);
    await Provider.of<WorkoutProvider>(context, listen: false)
        .fetchAndSetWorkouts();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleRefresh() async {
    await Provider.of<WorkoutProvider>(context, listen: false)
        .fetchAndSetWorkouts();
  }

  void _showInterstitialAd() {
    _workoutCount++;
    if (_workoutCount % 3 == 0) {
      final sub = Provider.of<SubscriptionProvider>(context, listen: false);
      if (!sub.isPremium) {
        InterstitialAdService.showWorkoutCompletionAd();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, workoutsProvider, _) {
        return SafeArea(
          bottom: true,
          child: LiquidPullToRefresh(
            height: SizeManager.s250.h,
            color: ColorManager.darkGrey,
            animSpeedFactor: 2,
            backgroundColor: ColorManager.white2,
            onRefresh: _handleRefresh,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: ColorManager.primary,
                    ),
                  )
                : Column(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: NewExerciseButton(
                          onTap: () => context.push(Routes.addNewExerciseRoute),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: workoutsProvider.workouts.length,
                          itemBuilder: (context, index) {
                            final workout = workoutsProvider.workouts[index];
                            final allWorkout =
                                workoutsProvider.allWorkouts[index];

                            return ExerciseWidget(
                              name: workout.name,
                              repNumber: workout.repNumber,
                              setNumber: workout.setNumber,
                              id: workout.id,
                              onTap: () => _handleExerciseTap(workout.name),
                              onDeleted: (_) {
                                workoutsProvider.deleteWorkout(
                                  workoutID: workout.id,
                                );
                                workoutsProvider.deleteAllWorkout(
                                  allWorkoutID: allWorkout.id,
                                );
                              },
                              onFinished: (_) async {
                                workoutsProvider.finishWorkout(
                                  workoutID: workout.id,
                                  name: workout.name,
                                  repNumber: workout.repNumber,
                                  setNumber: workout.setNumber,
                                  dateTime: workout.dateTime,
                                );

                                workoutsProvider.deleteWorkout(
                                  workoutID: workout.id,
                                );

                                await WorkoutProvider
                                    .updateStatisticsAfterWorkout(context);

                                _showInterstitialAd();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // ===================== EXERCISE VIDEO HANDLING =====================

  void _handleExerciseTap(String savedName) {
    String cleanName = savedName;
    
    // Try to remove bracketed info from start or end
    if (savedName.contains(']')) {
      final parts = savedName.split(']');
      // Case: [Day 1] Push Up
      if (savedName.trim().startsWith('[')) {
         if (parts.length > 1) {
           cleanName = parts[1].trim();
         }
      } 
      // Case: Push Up [Day 1]
      else {
         cleanName = parts.first.trim();
      }
    }

    final allExercises = [
      ...ExerciseData.chest,
      ...ExerciseData.back,
      ...ExerciseData.legs,
      ...ExerciseData.shoulders,
      ...ExerciseData.arms,
    ];

    try {
      final exercise = allExercises.firstWhere(
        (e) => e.name.toLowerCase() == cleanName.toLowerCase(),
      );
      _showExerciseDetails(context, exercise);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video detail not available for this exercise'),
        ),
      );
    }
  }

  void _showExerciseDetails(BuildContext context, Exercise exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: ColorManager.black,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVideo(exercise),
                      SizedBox(height: 24.h),
                      _buildTitle(exercise.name),
                      SizedBox(height: 16.h),
                      _buildDescription(exercise.description),
                      SizedBox(height: 20.h),
                      _buildInfoRow(exercise),
                      SizedBox(height: 24.h),
                      _buildInstructions(exercise),
                    ],
                  ),
                ),
              ),
              _buildCloseButton(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideo(Exercise exercise) {
    return Container(
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
          autoPlay: true,
        ),
      ),
    );
  }

  Widget _buildTitle(String name) => Text(
        name,
        style: TextStyle(
          color: Colors.white,
          fontSize: 28.sp,
          fontWeight: FontWeight.bold,
        ),
      );

  Widget _buildDescription(String desc) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          desc,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16.sp,
            height: 1.6,
          ),
        ),
      );

  Widget _buildInfoRow(Exercise exercise) => Row(
        children: [
          Expanded(
            child: _buildDetailCard(
                'Target', exercise.target, Icons.center_focus_strong),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildDetailCard(
                'Equipment', exercise.equipment, Icons.sports_gymnastics),
          ),
        ],
      );

  Widget _buildInstructions(Exercise exercise) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instructions',
            style: TextStyle(
              color: ColorManager.primary,
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          ...exercise.instructions.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child:
                  Text('• $i', style: const TextStyle(color: Colors.white70)),
            ),
          ),
        ],
      );

  Widget _buildCloseButton(BuildContext context) => SafeArea(
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
      );

  Widget _buildDetailCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ColorManager.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ColorManager.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text(label,
                  style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
