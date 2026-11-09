import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/services/weekly_recap.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// Sunday/Monday "your week in review" card. Renders nothing on other days or
/// when the recapped week was empty, so it never shows as a scolding.
class WeeklyRecapCard extends StatelessWidget {
  const WeeklyRecapCard({super.key, this.now});

  /// Overrides the clock (tests).
  final DateTime? now;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final clock = now ?? DateTime.now();
    // Cheap exit first: don't even listen to stats on non-recap days.
    if (!WeeklyRecap.isRecapDay(clock)) return const SizedBox.shrink();

    return Consumer<StatisticsProvider>(
      builder: (context, stats, _) {
        WeeklyRecap? recap;
        try {
          recap = WeeklyRecap.build(
            now: clock,
            hasWorkoutOn: stats.hasWorkoutOnDate,
            target: stats.weeklyTarget,
            streak: stats.currentStreak,
          );
        } catch (_) {
          recap = null;
        }
        if (recap == null) return const SizedBox.shrink();
        return WeeklyRecapView(recap: recap);
      },
    );
  }
}

/// Visual for a [WeeklyRecap].
class WeeklyRecapView extends StatelessWidget {
  const WeeklyRecapView({super.key, required this.recap});

  final WeeklyRecap recap;

  @override
  Widget build(BuildContext context) {
    final accent = recap.goalHit ? ColorManager.primaryText : ColorManager.textSecondary;
    final chips = <String>[
      if (recap.deltaText != null) recap.deltaText!,
      if (recap.streakText != null) recap.streakText!,
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      child: Container(
        key: const Key('weekly_recap_card'),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: ColorManager.surface,
          boxShadow: ColorManager.cardShadow,
          borderRadius: BorderRadius.circular(AppRadius.card.r),
          border: recap.goalHit
              ? Border.all(color: ColorManager.primary.withValues(alpha: 0.4))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recap.title.toUpperCase(),
              style: TextStyle(
                color: ColorManager.textTertiary,
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              recap.headline,
              key: const Key('weekly_recap_headline'),
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 7; i++)
                  _DayDot(
                    label: WeeklyRecapCard._labels[i],
                    done: recap.activeDays[i],
                    accent: accent,
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              recap.message,
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 13.sp,
              ),
            ),
            if (chips.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                children: [for (final c in chips) _Chip(text: c)],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.label, required this.done, required this.accent});

  final String label;
  final bool done;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28.w,
          height: 28.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? ColorManager.primary : ColorManager.surfaceLight,
          ),
          child: done
              ? Icon(Icons.check_rounded, size: 16.sp, color: Colors.black)
              : null,
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            color: done ? accent : ColorManager.textTertiary,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: ColorManager.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: ColorManager.primaryText,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
