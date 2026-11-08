import 'package:fitness_app/model/personal_record_model.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/home/widgets/achievements_widget.dart';
import 'package:fitness_app/presentation/home/widgets/next_badge_card.dart';
import 'package:fitness_app/presentation/widgets/reminder_opt_in_card.dart';
import 'package:fitness_app/services/session_reward_service.dart';
import 'package:fitness_app/utils/haptics.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Everything the reward screen shows besides the saved session itself.
class WorkoutRewardData {
  const WorkoutRewardData({
    this.streakBefore = 0,
    this.streakAfter = 0,
    this.longestStreak = 0,
    this.newPRs = const [],
    this.unlockedBadges = const [],
    this.workoutsThisWeek = 0,
    this.weeklyTarget = 3,
    this.nextBadge,
  });

  final int streakBefore;
  final int streakAfter;
  final int longestStreak;
  final List<PersonalRecord> newPRs;
  final List<AchievementDef> unlockedBadges;
  final int workoutsThisWeek;
  final int weeklyTarget;
  final BadgeProgress? nextBadge;
}

/// Finish-line screen shown after a workout is saved: a streak count-up, new
/// PRs, weekly goal, badge progress and a one-time reminder opt-in. The
/// "Back to Home" button stays pinned below the scrolling content.
class WorkoutRewardView extends StatefulWidget {
  const WorkoutRewardView({
    super.key,
    required this.session,
    required this.dayName,
    required this.data,
    required this.onDone,
    this.reminderCard = const ReminderOptInCard(),
    this.playHaptic = true,
  });

  final WorkoutSession session;
  final String dayName;
  final WorkoutRewardData data;
  final VoidCallback onDone;

  /// Replaceable so tests do not touch notification plugins.
  final Widget reminderCard;
  final bool playHaptic;

  @override
  State<WorkoutRewardView> createState() => _WorkoutRewardViewState();
}

class _WorkoutRewardViewState extends State<WorkoutRewardView> {
  @override
  void initState() {
    super.initState();
    if (widget.playHaptic) {
      // A felt "you did it" beat; stronger when a record was broken.
      if (widget.data.newPRs.isNotEmpty ||
          widget.data.unlockedBadges.isNotEmpty) {
        Haptics.heavy();
      } else {
        Haptics.medium();
      }
    }
  }

  static String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String _kg(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final data = widget.data;
    final isPartial = session.isPartial;

    return Scaffold(
      backgroundColor: ColorManager.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                key: const Key('reward_scroll'),
                padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _hero(isPartial),
                    SizedBox(height: 20.h),
                    _streakCard(data),
                    SizedBox(height: 12.h),
                    _statsCard(session),
                    if (data.newPRs.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      _prCard(data.newPRs),
                    ],
                    SizedBox(height: 12.h),
                    _weeklyCard(data),
                    SizedBox(height: 12.h),
                    if (data.unlockedBadges.isNotEmpty)
                      ...data.unlockedBadges.map(_unlockedBadgeCard)
                    else if (data.nextBadge != null)
                      NextBadgeBar(progress: data.nextBadge!, padded: false),
                    SizedBox(height: 12.h),
                    widget.reminderCard,
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 16.h),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.primary,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Back to Home',
                    style: TextStyle(
                      color: ColorManager.onMint,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
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

  Widget _hero(bool isPartial) {
    final color = isPartial ? Colors.amber : ColorManager.primary;
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isPartial
                  ? Icons.check_circle_outline_rounded
                  : Icons.emoji_events_rounded,
              size: 56.sp,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          isPartial ? 'Workout Saved Early!' : 'Workout Complete! 🔥',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ColorManager.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          isPartial
              ? 'All completed sets and volume have been saved to your logbook.'
              : 'Crushed every set on ${widget.dayName}.',
          textAlign: TextAlign.center,
          style: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp),
        ),
      ],
    );
  }

  Widget _streakCard(WorkoutRewardData data) {
    final caption = SessionRewards.streakCaption(
      before: data.streakBefore,
      after: data.streakAfter,
    );
    return Container(
      key: const Key('reward_streak_card'),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department_rounded,
              color: Colors.orange, size: 40.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    TweenAnimationBuilder<int>(
                      tween: IntTween(
                        begin: data.streakBefore,
                        end: data.streakAfter,
                      ),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => Text(
                        '$value',
                        key: const Key('reward_streak_value'),
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'day streak',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  caption,
                  style: TextStyle(
                    color: ColorManager.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          if (data.longestStreak > 0)
            Column(
              children: [
                Text('Best',
                    style: TextStyle(
                        color: ColorManager.textTertiary, fontSize: 11.sp)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events_rounded,
                        color: Colors.amber, size: 14.sp),
                    SizedBox(width: 2.w),
                    Text(
                      '${data.longestStreak}',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _statsCard(WorkoutSession session) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _metric('Total Volume', '${session.totalVolume.toStringAsFixed(0)} kg',
              Icons.fitness_center),
          _metric('Time', _formatTimer(session.durationSeconds), Icons.timer),
          _metric('Exercises', '${session.exercises.length}',
              Icons.format_list_bulleted),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: ColorManager.primary, size: 20.sp),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: ColorManager.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
        ),
      ],
    );
  }

  Widget _prCard(List<PersonalRecord> prs) {
    final shown = prs.take(3).toList();
    final extra = prs.length - shown.length;
    return Container(
      key: const Key('reward_pr_card'),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                prs.length == 1 ? 'New personal record!' : 'New personal records!',
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final pr in shown)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '${pr.exerciseName}  ${_kg(pr.weight)} kg × ${pr.reps}',
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (extra > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  child: Text(
                    '+$extra more',
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weeklyCard(WorkoutRewardData data) {
    final target = data.weeklyTarget.clamp(1, 7).toInt();
    final done = data.workoutsThisWeek;
    final hit = done >= target;
    return Container(
      key: const Key('reward_weekly_card'),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THIS WEEK',
                  style: TextStyle(
                    color: ColorManager.textTertiary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  hit
                      ? 'Weekly goal hit: $done of $target workouts'
                      : '$done of $target workouts. ${target - done} to go',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(target, (i) {
              final filled = i < done;
              return Container(
                width: 14.w,
                height: 14.w,
                margin: EdgeInsets.only(left: 5.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? ColorManager.primary : Colors.transparent,
                  border: Border.all(
                    color: filled ? ColorManager.primary : ColorManager.divider,
                    width: 2,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _unlockedBadgeCard(AchievementDef def) {
    return Container(
      key: Key('reward_badge_${def.id}'),
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [def.color.withValues(alpha: 0.2), ColorManager.surface],
        ),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: def.color.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        children: [
          Text(def.emoji, style: TextStyle(fontSize: 32.sp)),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BADGE UNLOCKED',
                  style: TextStyle(
                    color: def.color,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  def.title,
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  def.desc,
                  style: TextStyle(
                    color: ColorManager.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
