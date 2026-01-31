import 'package:fitness_app/presentation/banner_ads/banner_ad_service.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/presentation/workouts/widgets/workout_timer_widget.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
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
  @override
  void initState() {
    super.initState();
    // Fetch workouts when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      workoutProvider.fetchAndSetWorkouts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Column(
        children: [
          // Header with Add Button
          Padding(
            padding: EdgeInsets.all(SizeManager.s16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Workouts',
                  style: TextStyle(
                    color: ColorManager.white,
                    fontSize: SizeManager.s24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push(Routes.addNewExerciseRoute),
                  icon: Icon(Icons.add, color: ColorManager.darkGrey),
                  label: Text(
                    'Add',
                    style: TextStyle(
                      color: ColorManager.darkGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.limerGreen2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SizeManager.s12.r),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quick Access Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeManager.s16.w),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    icon: Icons.fitness_center,
                    label: 'Exercises',
                    color: Colors.blue,
                    onTap: () => context.push(Routes.bodypartsPage),
                  ),
                ),
                SizedBox(width: SizeManager.s12.w),
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Splits',
                    color: Colors.purple,
                    onTap: () {
                      final sub = Provider.of<SubscriptionProvider>(context,
                          listen: false);
                      if (sub.isPremium) {
                        context.push(Routes.workoutSplitsRoute);
                      } else {
                        context.push(Routes.premiumScreen);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: SizeManager.s24.h),

          // Custom Workouts List
          Expanded(
            child: Consumer<WorkoutProvider>(
              builder: (context, workoutProvider, _) {
                if (workoutProvider.allWorkouts.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.builder(
                  itemCount: workoutProvider.allWorkouts.length,
                  itemBuilder: (context, index) {
                    final workout = workoutProvider.allWorkouts[index];
                    return _buildWorkoutCard(
                      workout: workout,
                      onStart: () {
                        _showWorkoutTimerDialog(context, workout);
                      },
                      onEdit: () {
                        // TODO: Navigate to edit workout
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Banner Ad at the bottom
          PremiumAwareBannerAd(pageName: 'workout'),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SizeManager.s16.r),
      child: Container(
        padding: EdgeInsets.all(SizeManager.s16.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(SizeManager.s16.r),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: SizeManager.s40.sp),
            SizedBox(height: SizeManager.s8.h),
            Text(
              label,
              style: TextStyle(
                color: ColorManager.white,
                fontSize: SizeManager.s14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
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
          Icon(
            Icons.fitness_center,
            size: SizeManager.s100.sp,
            color: ColorManager.grey3,
          ),
          SizedBox(height: SizeManager.s20.h),
          Text(
            'No Custom Workouts Yet',
            style: TextStyle(
              color: ColorManager.white,
              fontSize: SizeManager.s20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: SizeManager.s8.h),
          Text(
            'Create your first workout routine',
            style: TextStyle(
              color: ColorManager.white70,
              fontSize: SizeManager.s14.sp,
            ),
          ),
          SizedBox(height: SizeManager.s24.h),
          ElevatedButton.icon(
            onPressed: () => context.push(Routes.addNewExerciseRoute),
            icon: Icon(Icons.add, color: ColorManager.darkGrey),
            label: Text(
              'Create Workout',
              style: TextStyle(
                color: ColorManager.darkGrey,
                fontSize: SizeManager.s16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.limerGreen2,
              padding: EdgeInsets.symmetric(
                horizontal: SizeManager.s24.w,
                vertical: SizeManager.s16.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SizeManager.s12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard({
    required dynamic workout,
    required VoidCallback onStart,
    required VoidCallback onEdit,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: SizeManager.s16.w,
        vertical: SizeManager.s8.h,
      ),
      padding: EdgeInsets.all(SizeManager.s16.w),
      decoration: BoxDecoration(
        color: ColorManager.black87,
        borderRadius: BorderRadius.circular(SizeManager.s16.r),
        border: Border.all(
          color: ColorManager.grey3.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  workout.name,
                  style: TextStyle(
                    color: ColorManager.white,
                    fontSize: SizeManager.s18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: ColorManager.white70),
                onPressed: onEdit,
              ),
            ],
          ),
          SizedBox(height: SizeManager.s12.h),
          Row(
            children: [
              Icon(
                Icons.fitness_center,
                color: ColorManager.limerGreen2,
                size: SizeManager.s16.sp,
              ),
              SizedBox(width: SizeManager.s8.w),
              Text(
                '${workout.setNumber} sets × ${workout.repNumber} reps',
                style: TextStyle(
                  color: ColorManager.white70,
                  fontSize: SizeManager.s14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeManager.s16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onStart,
              icon: Icon(Icons.play_arrow, color: ColorManager.darkGrey),
              label: Text(
                'Start Workout',
                style: TextStyle(
                  color: ColorManager.darkGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.limerGreen2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SizeManager.s12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWorkoutTimerDialog(BuildContext context, dynamic workout) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ColorManager.darkGrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SizeManager.s20.r),
        ),
        title: Row(
          children: [
            Icon(Icons.timer, color: ColorManager.limerGreen2),
            SizedBox(width: SizeManager.s8.w),
            Expanded(
              child: Text(
                '${workout.name} Timer',
                style: TextStyle(
                  color: ColorManager.white,
                  fontSize: SizeManager.s20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: SizeManager.s300.w,
          child: WorkoutTimerWidget(
            isRestTimer: false,
            initialMinutes: 0, // Stopwatch mode - starts at 0:00
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
      ),
    );
  }
}
