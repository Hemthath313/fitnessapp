import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/achievements_widget.dart';
import 'package:fitness_app/services/badge_rules.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// How close the user is to the badge they will unlock next.
class BadgeProgress {
  const BadgeProgress({
    required this.def,
    required this.metric,
    required this.current,
    required this.target,
  });

  final AchievementDef def;
  final BadgeMetric metric;
  final int current;
  final int target;

  int get remaining => (target - current).clamp(0, target).toInt();
  double get fraction =>
      target == 0 ? 1 : (current / target).clamp(0.0, 1.0).toDouble();

  /// One line that says exactly what is left to do.
  String get message {
    final left = remaining;
    switch (metric) {
      case BadgeMetric.workouts:
        if (current == 0 && target == 1) {
          return 'Finish one workout to earn ${def.title}';
        }
        return '$left more workout${left == 1 ? '' : 's'} to unlock ${def.title}';
      case BadgeMetric.streakDays:
        return '$left more day${left == 1 ? '' : 's'} in a row to unlock ${def.title}';
    }
  }

  /// "3 / 10" style counter for the right-hand side of the bar.
  String get counter => '$current / $target';
}

/// Picks the locked badge the user is closest to (highest completed share,
/// then fewest steps left). Returns null when every badge is unlocked.
BadgeProgress? nextBadgeProgress({
  required Iterable<String> unlocked,
  required int totalWorkouts,
  required int currentStreak,
}) {
  final done = unlocked.toSet();
  BadgeProgress? best;
  for (final def in allAchievements) {
    if (done.contains(def.id)) continue;
    final rule = kBadgeRules[def.id];
    if (rule == null) continue;
    final value = badgeValue(rule.metric,
        totalWorkouts: totalWorkouts, currentStreak: currentStreak);
    // Already met but not yet recorded (it unlocks on the next sync): skip.
    if (value >= rule.target) continue;
    final candidate = BadgeProgress(
      def: def,
      metric: rule.metric,
      current: value.clamp(0, rule.target).toInt(),
      target: rule.target,
    );
    if (best == null ||
        candidate.fraction > best.fraction ||
        (candidate.fraction == best.fraction &&
            candidate.remaining < best.remaining)) {
      best = candidate;
    }
  }
  return best;
}

/// Compact dashboard card: "3 more workouts to unlock Strong Start" with a
/// progress bar. Near goals pull harder than locked grey icons.
class NextBadgeCard extends StatelessWidget {
  const NextBadgeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsProvider>(
      builder: (context, stats, _) {
        final progress = nextBadgeProgress(
          unlocked: stats.unlockedAchievements,
          totalWorkouts: stats.totalWorkouts,
          currentStreak: stats.currentStreak,
        );
        if (progress == null) return const SizedBox.shrink();
        return NextBadgeBar(progress: progress);
      },
    );
  }
}

/// The visual of [NextBadgeCard]; also used on the workout reward screen.
class NextBadgeBar extends StatelessWidget {
  const NextBadgeBar({super.key, required this.progress, this.padded = true});

  final BadgeProgress progress;

  /// Adds the dashboard's horizontal page padding.
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      key: const Key('next_badge_card'),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: progress.def.color.withValues(alpha: 0.16),
              border: Border.all(
                color: progress.def.color.withValues(alpha: 0.5),
              ),
            ),
            child: Text('🔒', style: TextStyle(fontSize: 18.sp)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT BADGE',
                  style: TextStyle(
                    color: ColorManager.textTertiary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  progress.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: progress.fraction,
                          minHeight: 6.h,
                          backgroundColor: ColorManager.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              ColorManager.primaryText),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      progress.counter,
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (!padded) return card;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      child: card,
    );
  }
}
