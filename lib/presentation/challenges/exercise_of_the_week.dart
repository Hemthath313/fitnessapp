import 'package:fitness_app/data/challenge_data.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExerciseOfTheWeekScreen extends StatelessWidget {
  const ExerciseOfTheWeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exercise = ChallengeData.weeklyFeaturedExercise;

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text('Exercise of the Week',
            style: TextStyle(color: ColorManager.textPrimary)),
        backgroundColor: ColorManager.background,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildVideoHeader(exercise),
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleSection(exercise),
                  SizedBox(height: 24.h),
                  _buildProTipsSection(),
                  SizedBox(height: 24.h),
                  _buildMistakesSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoHeader(ChallengeExercise exercise) {
    return Container(
      width: double.infinity,
      height: 350.h,
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: ColorManager.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ExerciseVideoPlayer(
        videoPath: exercise.videoPath,
        height: 350.h,
        fit: BoxFit.contain,
        autoPlay: true,
      ),
    );
  }

  Widget _buildTitleSection(ChallengeExercise exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: ColorManager.primary,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'FEATURED',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
            Icon(Icons.star, color: ColorManager.primary, size: 20.sp),
          ],
        ),
        SizedBox(height: 12.h),
        Text(
          exercise.name,
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Target: ${exercise.target} • ${exercise.setsReps}',
          style: TextStyle(
            color: ColorManager.primary,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRO TIPS',
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        _buildBulletPoint('Squeeze at the peak of the movement for 1 second.'),
        _buildBulletPoint('Maintain a slow, controlled negative phase (3 seconds).'),
        _buildBulletPoint('Keep your neck neutral to avoid strain.'),
      ],
    );
  }

  Widget _buildMistakesSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'COMMON MISTAKES',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            '• Using momentum rather than core strength.\n• Arching the lower back excessively during the eccentric phase.',
            style: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: ColorManager.primary, size: 18.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: ColorManager.textSecondary, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }
}
