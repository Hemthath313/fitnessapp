import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// Displays a "This Week" summary card showing workouts, calories, and water stats.
class WeeklySummaryWidget extends StatefulWidget {
  const WeeklySummaryWidget({super.key});

  @override
  State<WeeklySummaryWidget> createState() => _WeeklySummaryWidgetState();
}

class _WeeklySummaryWidgetState extends State<WeeklySummaryWidget> {
  Map<String, dynamic>? _weeklyStats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats =
        Provider.of<StatisticsProvider>(context, listen: false);
    final data = await stats.getWeeklyStats();
    if (mounted) {
      setState(() {
        _weeklyStats = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox.shrink();
    }

    final workouts = (_weeklyStats?['workouts'] ?? 0) as int;
    final calories = (_weeklyStats?['calories'] ?? 0) as int;
    final waterAvg = (_weeklyStats?['water'] ?? 0.0) as double;

    // Don't show if no data this week
    if (workouts == 0 && calories == 0) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'This Week',
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Past 7 days',
                  style: TextStyle(
                    color: ColorManager.primary,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.fitness_center_rounded,
                  value: '$workouts',
                  label: 'Workouts',
                  color: ColorManager.primary,
                  index: 0,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department_rounded,
                  value: '${calories}',
                  label: 'kcal eaten',
                  color: const Color(0xFFFF6B35),
                  index: 1,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _StatCard(
                  icon: Icons.water_drop_rounded,
                  value: waterAvg.toStringAsFixed(1),
                  label: 'L/day avg',
                  color: Colors.blue,
                  index: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 150.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final int index;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 80 * index)).fadeIn().scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          duration: 300.ms,
        );
  }
}
