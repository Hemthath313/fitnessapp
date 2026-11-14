import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/utils/haptics.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// All possible achievements in the app
class AchievementDef {
  final String id;
  final String emoji;
  final String title;
  final String desc;
  final Color color;

  const AchievementDef({
    required this.id,
    required this.emoji,
    required this.title,
    required this.desc,
    required this.color,
  });
}

/// All possible achievements in the app (public for use in other widgets)
const List<AchievementDef> allAchievements = [
  AchievementDef(
    id: 'First Workout',
    emoji: '🔥',
    title: 'First Flame',
    desc: 'Log your first workout',
    color: Color(0xFFFF6B35),
  ),
  AchievementDef(
    id: 'Hat Trick',
    emoji: '🎯',
    title: 'Hat Trick',
    desc: 'Log 3 workouts',
    color: Color(0xFF26C6DA),
  ),
  AchievementDef(
    id: '3 Day Streak',
    emoji: '☀️',
    title: 'Warming Up',
    desc: '3 active days in a row',
    color: Color(0xFFFFB300),
  ),
  AchievementDef(
    id: 'Strong Start',
    emoji: '💪',
    title: 'Strong Start',
    desc: 'Log 10 workouts total',
    color: ColorManager.success,
  ),
  AchievementDef(
    id: '7 Day Streak',
    emoji: '⚡',
    title: '7-Day Warrior',
    desc: '7 consecutive active days',
    color: Color(0xFFFFD700),
  ),
  AchievementDef(
    id: '14 Day Streak',
    emoji: '🥊',
    title: 'Fortnight Fighter',
    desc: '14-day streak',
    color: Color(0xFFEF5350),
  ),
  AchievementDef(
    id: '21 Day Streak',
    emoji: '🧱',
    title: 'Habit Builder',
    desc: '21-day streak',
    color: Color(0xFF8D6E63),
  ),
  AchievementDef(
    id: '25 Workouts',
    emoji: '🥉',
    title: '25 Club',
    desc: 'Log 25 workouts',
    color: Color(0xFFCD7F32),
  ),
  AchievementDef(
    id: 'Half Century',
    emoji: '🥈',
    title: 'Half Century',
    desc: 'Log 50 workouts',
    color: Color(0xFFB0BEC5),
  ),
  AchievementDef(
    id: 'Monthly Warrior',
    emoji: '🏆',
    title: 'Monthly Warrior',
    desc: '30-day streak',
    color: Color(0xFFE91E63),
  ),
  AchievementDef(
    id: '60 Day Streak',
    emoji: '🚀',
    title: 'Unstoppable',
    desc: '60-day streak',
    color: Color(0xFF42A5F5),
  ),
  AchievementDef(
    id: 'Centurion',
    emoji: '👑',
    title: 'Centurion',
    desc: '100 workouts logged',
    color: Color(0xFF9C27B0),
  ),
  AchievementDef(
    id: '100 Day Streak',
    emoji: '🌟',
    title: 'Legend',
    desc: '100-day streak',
    color: Color(0xFFFFC107),
  ),
  AchievementDef(
    id: 'Double Century',
    emoji: '🥇',
    title: 'Double Century',
    desc: 'Log 200 workouts',
    color: Color(0xFFFFD54F),
  ),
  AchievementDef(
    id: 'Iron Year',
    emoji: '🦾',
    title: 'Iron Year',
    desc: 'Log 365 workouts',
    color: Color(0xFF7E57C2),
  ),
];

/// Widget that shows earned badges on the home screen.
/// Locked badges are shown as greyed-out teasers.
class AchievementsWidget extends StatelessWidget {
  const AchievementsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsProvider>(
      builder: (context, stats, _) {
        final unlocked = stats.unlockedAchievements;
        final hasAny = unlocked.isNotEmpty;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Achievements',
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (hasAny)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: ColorManager.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        '${unlocked.length}/${allAchievements.length}',
                        style: TextStyle(
                          color: ColorManager.primaryText,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12.h),
              SizedBox(
                height: 90.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
              itemCount: allAchievements.length,
                  separatorBuilder: (_, __) => SizedBox(width: 10.w),
                  itemBuilder: (context, i) {
                    final def = allAchievements[i];
                    final isUnlocked = unlocked.contains(def.id);
                    return _AchievementBadge(
                      def: def,
                      isUnlocked: isUnlocked,
                      index: i,
                    );
                  },
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms, delay: 200.ms)
            .slideY(begin: 0.05, end: 0);
      },
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final AchievementDef def;
  final bool isUnlocked;
  final int index;

  const _AchievementBadge({
    required this.def,
    required this.isUnlocked,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isUnlocked ? def.desc : 'Locked: ${def.desc}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 72.w,
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
        decoration: BoxDecoration(
          color: isUnlocked
              ? def.color.withValues(alpha: 0.12)
              : ColorManager.surfaceLight,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isUnlocked
                ? def.color.withValues(alpha: 0.4)
                : ColorManager.divider,
            width: 1.5,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: def.color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge icon / emoji
            ColorFiltered(
              colorFilter: isUnlocked
                  ? const ColorFilter.mode(
                      Colors.transparent, BlendMode.multiply)
                  : const ColorFilter.matrix([
                      0.2126, 0.7152, 0.0722, 0, 0, //
                      0.2126, 0.7152, 0.0722, 0, 0, //
                      0.2126, 0.7152, 0.0722, 0, 0, //
                      0, 0, 0, 0.4, 0, //
                    ]),
              child: Text(
                isUnlocked ? def.emoji : '🔒',
                style: TextStyle(fontSize: 24.sp),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              def.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isUnlocked
                    ? ColorManager.textPrimary
                    : ColorManager.textTertiary,
                fontSize: 12.sp,
                fontWeight:
                    isUnlocked ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: 100 * index)).fadeIn().scale(
            begin: const Offset(0.85, 0.85),
            end: const Offset(1.0, 1.0),
            duration: 300.ms,
          ),
    );
  }
}

/// Shows a full-screen celebration dialog when a new achievement is unlocked.
void showAchievementUnlockDialog(
    BuildContext context, AchievementDef achievement) {
  Haptics.heavy();
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      // Solid card underneath so the tinted gradient reads the same in
      // light and dark mode.
      backgroundColor: ColorManager.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              achievement.color.withValues(alpha: 0.15),
              ColorManager.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
              color: achievement.color.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: achievement.color.withValues(alpha: 0.3),
              blurRadius: 24,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              achievement.emoji,
              style: TextStyle(fontSize: 64.sp),
              textAlign: TextAlign.center,
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.9, end: 1.1, duration: 800.ms),
            SizedBox(height: 16.h),
            Text(
              '🎉 Achievement Unlocked!',
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 14.sp,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              achievement.desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: achievement.color,
                foregroundColor: Colors.white,
                padding:
                    EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button.r)),
              ),
              child: Text(
                'Awesome!',
                style:
                    TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      )
          .animate()
          .scale(
            begin: const Offset(0.7, 0.7),
            end: const Offset(1.0, 1.0),
            duration: 400.ms,
            curve: Curves.elasticOut,
          )
          .fadeIn(duration: 250.ms),
    ),
  );
}
