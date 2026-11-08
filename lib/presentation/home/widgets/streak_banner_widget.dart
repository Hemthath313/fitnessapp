import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// Displays a streak hero banner with milestones and motivational messages.
/// Shows on home screen between greeting and quick actions.
class StreakBannerWidget extends StatelessWidget {
  const StreakBannerWidget({super.key});

  String _getMotivation(StatisticsProvider stats) {
    final streak = stats.currentStreak;
    if (streak == 0) {
      if (!stats.hasActiveSchedule && !stats.hasWorkoutHistory) {
        return 'Complete your first workout to start your streak! 💪';
      }
      return 'Log a workout today to start your streak! 💪';
    }
    if (stats.isRestDay()) {
      return 'Rest day — your $streak-day streak is safe and active! 🛡️';
    }
    if (streak == 1) return 'Great start! Day 1 is the hardest. 🌟';
    if (streak < 3) return 'You\'re building momentum. Keep it up!';
    if (streak < 7) return 'Impressive! You\'re on fire. Don\'t stop now! 🔥';
    if (streak == 7) return '🏆 7-Day Warrior! One full week of crushing it!';
    if (streak < 14) return 'You\'re unstoppable! 2-week mark in sight!';
    if (streak == 14) return '💎 2-Week Legend! Elite consistency!';
    if (streak < 30) return 'You\'re in the top 1% of consistency. Respect!';
    return '🏆 MONTHLY CHAMPION! Absolute legend status!';
  }

  Color _getStreakColor(int streak) {
    if (streak == 0) return ColorManager.textTertiary;
    if (streak < 3) return const Color(0xFF4CAF50);
    if (streak < 7) return Colors.orange.shade600;
    if (streak < 14) return const Color(0xFFFF6B35);
    if (streak < 30) return const Color(0xFFE53935);
    return const Color(0xFFFFD700); // gold for 30+
  }

  List<Color> _getGradientColors(int streak) {
    if (streak == 0) {
      return [ColorManager.surfaceLight, ColorManager.surface];
    }
    if (streak < 7) {
      return [const Color(0xFF1A2A1A), const Color(0xFF0F1F0F)];
    }
    if (streak < 14) {
      return [const Color(0xFF2A1A0F), const Color(0xFF1A0F00)];
    }
    if (streak < 30) {
      return [const Color(0xFF2A0F0F), const Color(0xFF1A0000)];
    }
    return [const Color(0xFF2A2000), const Color(0xFF1A1500)];
  }

  List<_MilestoneItem> _getMilestones(int streak) {
    return [
      _MilestoneItem(days: 1, label: '1D', reached: streak >= 1),
      _MilestoneItem(days: 3, label: '3D', reached: streak >= 3),
      _MilestoneItem(days: 7, label: '7D', reached: streak >= 7),
      _MilestoneItem(days: 14, label: '14D', reached: streak >= 14),
      _MilestoneItem(days: 30, label: '30D', reached: streak >= 30),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsProvider>(
      builder: (context, stats, _) {
        final streak = stats.currentStreak;
        final longest = stats.longestStreak;
        final color = _getStreakColor(streak);
        final gradientColors = _getGradientColors(streak);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: streak > 0
                  ? LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: streak == 0 ? ColorManager.surfaceLight : null,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: streak > 0
                    ? color.withValues(alpha: 0.5)
                    : ColorManager.divider,
                width: 1.5,
              ),
              boxShadow: streak > 0
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: flame count + longest
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Big flame + number
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: streak > 0 ? color : ColorManager.textTertiary,
                          size: 36.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '$streak',
                          style: TextStyle(
                            color: streak > 0
                                ? Colors.white
                                : ColorManager.textTertiary,
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: Text(
                            'day streak',
                            style: TextStyle(
                              color: streak > 0
                                  ? Colors.white60
                                  : ColorManager.textSecondary,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Best streak pill
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: streak > 0
                            ? Colors.white.withValues(alpha: 0.1)
                            : ColorManager.surfaceDark,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Best',
                            style: TextStyle(
                              color: streak > 0
                                  ? Colors.white54
                                  : ColorManager.textTertiary,
                              fontSize: 11.sp,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.emoji_events_rounded,
                                color: Colors.amber,
                                size: 12.sp,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                '$longest',
                                style: TextStyle(
                                  color: streak > 0
                                      ? Colors.white
                                      : ColorManager.textSecondary,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                // Motivation text
                Text(
                  _getMotivation(stats),
                  style: TextStyle(
                    color: streak > 0
                        ? Colors.white70
                        : ColorManager.textSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 14.h),
                // Milestone progress dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _getMilestones(streak).map((m) {
                    return _MilestoneDot(item: m, activeColor: color);
                  }).toList(),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 100.ms)
              .slideY(begin: 0.05, end: 0),
        );
      },
    );
  }
}

class _MilestoneItem {
  final int days;
  final String label;
  final bool reached;
  const _MilestoneItem(
      {required this.days, required this.label, required this.reached});
}

class _MilestoneDot extends StatelessWidget {
  final _MilestoneItem item;
  final Color activeColor;
  const _MilestoneDot({required this.item, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: item.reached
                ? activeColor.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: item.reached ? activeColor : Colors.white12,
              width: 2,
            ),
          ),
          child: Center(
            child: item.reached
                ? Icon(Icons.check_rounded,
                    color: activeColor, size: 16.sp)
                : Text(
                    item.label,
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          item.label,
          style: TextStyle(
            color: item.reached ? activeColor : Colors.white30,
            fontSize: 11.sp,
            fontWeight:
                item.reached ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
