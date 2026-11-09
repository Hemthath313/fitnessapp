import 'dart:math' as math;

import 'package:fitness_app/data/challenge_data.dart';
import 'package:fitness_app/utils/managers/app_font.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// The weekly technique guide: a demo, form cues, common mistakes and a way to
/// keep going (browse the rest of the abs exercises).
class ExerciseOfTheWeekScreen extends StatefulWidget {
  const ExerciseOfTheWeekScreen({super.key, this.exercise, this.today});

  /// Overrides the weekly pick (tests / previews).
  final ChallengeExercise? exercise;

  /// Overrides "now" when working out the next rotation (tests).
  final DateTime? today;

  /// Cues shown when an exercise has none of its own.
  static const List<String> genericTips = [
    'Squeeze at the peak of the movement for 1 second.',
    'Keep the lowering phase slow and controlled (about 3 seconds).',
    'Keep your neck neutral to avoid strain.',
  ];

  static const List<String> genericMistakes = [
    'Using momentum rather than core strength.',
    'Arching the lower back excessively while lowering.',
  ];

  @override
  State<ExerciseOfTheWeekScreen> createState() =>
      _ExerciseOfTheWeekScreenState();
}

class _ExerciseOfTheWeekScreenState extends State<ExerciseOfTheWeekScreen> {
  bool _playing = true;

  @override
  Widget build(BuildContext context) {
    final today = widget.today ?? DateTime.now();
    final exercise = widget.exercise ?? ChallengeData.weeklyFeaturedExerciseFor(today);
    final tips = exercise.tips.isNotEmpty
        ? exercise.tips
        : ExerciseOfTheWeekScreen.genericTips;
    final mistakes = exercise.mistakes.isNotEmpty
        ? exercise.mistakes
        : ExerciseOfTheWeekScreen.genericMistakes;
    final daysLeft = ChallengeData.daysUntilNextFeatured(today);

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
            _buildHero(context, exercise),
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleSection(exercise),
                  SizedBox(height: 24.h),
                  _buildTipsSection(tips),
                  SizedBox(height: 24.h),
                  _buildMistakesSection(mistakes),
                  SizedBox(height: 24.h),
                  _buildNextSteps(context, daysLeft),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, ChallengeExercise exercise) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final height = math.min(math.max(screenHeight * 0.38, 240.0), 380.0);

    if (!exercise.hasVideo) {
      return Container(
        key: const Key('weekly_no_video'),
        width: double.infinity,
        height: height * 0.7,
        color: ColorManager.surface,
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.self_improvement,
                size: 56.sp, color: ColorManager.primary),
            SizedBox(height: 12.h),
            Text(
              'Hold-and-brace exercise',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: AppType.title,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'There is no demo clip for this one yet. Follow the form cues '
              'below and keep a straight line from head to heels.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: AppType.small,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: height,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExerciseVideoPlayer(
            videoPath: exercise.videoPath,
            height: height,
            fit: BoxFit.contain,
            autoPlay: _playing,
            holdFrameOnPause: true,
          ),
          Positioned(
            right: 12.w,
            bottom: 12.h,
            child: Semantics(
              button: true,
              label: _playing ? 'Pause demo' : 'Play demo',
              child: Material(
                color: Colors.black.withValues(alpha: 0.6),
                shape: const CircleBorder(),
                child: InkWell(
                  key: const Key('weekly_play_pause'),
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _playing = !_playing),
                  child: Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Icon(
                      _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 26.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
                borderRadius: BorderRadius.circular(AppRadius.small.r),
              ),
              child: Text(
                'FEATURED',
                style: TextStyle(
                    color: ColorManager.onMint,
                    fontSize: AppType.micro,
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
            fontSize: AppType.display,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Target: ${exercise.target} • ${exercise.setsReps}',
          style: TextStyle(
            color: ColorManager.primaryText,
            fontSize: AppType.body,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Equipment: ${exercise.equipment}',
          style: TextStyle(
            color: ColorManager.textSecondary,
            fontSize: AppType.small,
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection(List<String> tips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FORM CUES',
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: AppType.title,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        for (final tip in tips) _buildBulletPoint(tip),
      ],
    );
  }

  Widget _buildMistakesSection(List<String> mistakes) {
    final accent = ColorManager.warningText;
    return Container(
      key: const Key('weekly_mistakes'),
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ColorManager.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(color: ColorManager.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: accent, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'COMMON MISTAKES',
                style: TextStyle(
                  color: accent,
                  fontSize: AppType.bodyLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          for (final mistake in mistakes)
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Text(
                '• $mistake',
                style: TextStyle(
                  color: ColorManager.textSecondary,
                  fontSize: AppType.small,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNextSteps(BuildContext context, int daysLeft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const Key('weekly_explore_abs'),
            onPressed: () => context.push(Routes.absRoute),
            icon: const Icon(Icons.fitness_center),
            label: const Text('Explore more abs exercises'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
              foregroundColor: ColorManager.onMint,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button.r),
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Center(
          child: Text(
            key: const Key('weekly_next_rotation'),
            daysLeft == 1
                ? 'A new featured exercise arrives tomorrow.'
                : 'A new featured exercise arrives in $daysLeft days.',
            style: TextStyle(
              color: ColorManager.textTertiary,
              fontSize: AppType.caption,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline,
              color: ColorManager.primaryText, size: 18.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  color: ColorManager.textSecondary, fontSize: AppType.body),
            ),
          ),
        ],
      ),
    );
  }
}
