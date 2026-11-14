import 'dart:ui' show ImageFilter;

import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/utils/router/router.dart';

class MuscleActivationChart extends StatefulWidget {
  const MuscleActivationChart({super.key});

  @override
  State<MuscleActivationChart> createState() => _MuscleActivationChartState();
}

class _MuscleActivationChartState extends State<MuscleActivationChart> {
  final _logService = WorkoutLogService();

  String _getMuscleGroup(String exerciseName, String category) {
    final name = exerciseName.toLowerCase();
    if (name.contains('bench press') || name.contains('chest') || name.contains('pushup') || name.contains('fly') || name.contains('pec')) {
      return 'Chest';
    } else if (name.contains('squat') || name.contains('lunge') || name.contains('leg press') || name.contains('leg extension') || name.contains('leg curl') || name.contains('calf') || name.contains('thigh') || name.contains('quad') || name.contains('glute')) {
      return 'Legs';
    } else if (name.contains('pull up') || name.contains('row') || name.contains('pulldown') || name.contains('deadlift') || name.contains('lats') || name.contains('back') || name.contains('chin up')) {
      return 'Back';
    } else if (name.contains('military press') || name.contains('shoulder press') || name.contains('lateral raise') || name.contains('arnold press') || name.contains('delt') || name.contains('shoulder')) {
      return 'Shoulders';
    } else if (name.contains('curl') || name.contains('pushdown') || name.contains('skull crusher') || name.contains('bicep') || name.contains('tricep') || name.contains('arm') || name.contains('forearm')) {
      return 'Arms';
    } else if (name.contains('crunch') || name.contains('sit up') || name.contains('plank') || name.contains('abs') || name.contains('core') || name.contains('leg raise')) {
      return 'Core';
    }
    
    // Fallback to category
    if (category.toLowerCase() == 'cardio') return 'Cardio';
    if (category.toLowerCase() == 'strength') return 'Strength';
    return 'Other';
  }

  Color _getMuscleColor(String muscle) {
    switch (muscle) {
      case 'Chest':
        return ColorManager.info;
      case 'Back':
        return ColorManager.success;
      case 'Legs':
        return ColorManager.warning;
      case 'Shoulders':
        return ColorManager.violetText;
      case 'Arms':
        return ColorManager.error;
      case 'Core':
        return ColorManager.waterText;
      default:
        return ColorManager.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = Provider.of<SubscriptionProvider>(context).isPremium;
    final deviceWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8.w, bottom: 8.h),
            child: Text(
              'Training Distribution (Muscle Groups)',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          StreamBuilder<List<WorkoutLog>>(
            stream: _logService.getLogs(),
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];

              if (logs.isEmpty) {
                return Container(
                  height: 180.h,
                  width: deviceWidth,
                  decoration: BoxDecoration(
                    color: ColorManager.surface,
                    boxShadow: ColorManager.cardShadow,
                    borderRadius: BorderRadius.circular(AppRadius.tile.r),
                    border: Border.all(color: ColorManager.divider),
                  ),
                  child: Center(
                    child: Text(
                      'No workout logs found.\nLog your first workout to see analytics.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ColorManager.textTertiary, fontSize: 13.sp),
                    ),
                  ),
                );
              }

              // Calculate muscle activations (count sets per muscle group)
              final Map<String, int> muscleCounts = {};
              int totalSets = 0;

              for (var log in logs) {
                final group = _getMuscleGroup(log.exerciseName, log.category);
                final setQuantity = log.sets.length;
                muscleCounts[group] = (muscleCounts[group] ?? 0) + setQuantity;
                totalSets += setQuantity;
              }

              final sortedEntries = muscleCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              // Map to PieChartSections
              final sections = sortedEntries.map((entry) {
                final double percentage = (entry.value / totalSets) * 100;
                return PieChartSectionData(
                  color: _getMuscleColor(entry.key),
                  value: entry.value.toDouble(),
                  radius: 30.r,
                  showTitle: false,
                );
              }).toList();

              return Stack(
                children: [
                  // Main Content Card
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: ColorManager.surface,
                      boxShadow: ColorManager.cardShadow,
                      borderRadius: BorderRadius.circular(AppRadius.tile.r),
                      border: Border.all(color: ColorManager.divider),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // 1. Donut Chart
                            SizedBox(
                              height: 130.h,
                              width: 130.w,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 35.r,
                                  startDegreeOffset: -90,
                                  sections: sections.isEmpty
                                      ? [
                                          PieChartSectionData(
                                            color: ColorManager.textTertiary.withValues(alpha: 0.2),
                                            value: 1,
                                            radius: 30.r,
                                            showTitle: false,
                                          )
                                        ]
                                      : sections,
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            // 2. Legend
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: sortedEntries.take(4).map((entry) {
                                  final percentage = (entry.value / totalSets) * 100;
                                  final color = _getMuscleColor(entry.key);
                                  return Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4.h),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 10.w,
                                          height: 10.h,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
                                        Expanded(
                                          child: Text(
                                            entry.key,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: ColorManager.textPrimary,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${percentage.toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            color: ColorManager.textSecondary,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        if (sortedEntries.length > 4) ...[
                          const Divider(),
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Wrap(
                              spacing: 12.w,
                              runSpacing: 4.h,
                              children: sortedEntries.skip(4).map((entry) {
                                final color = _getMuscleColor(entry.key);
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8.w,
                                      height: 8.h,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      '${entry.key} (${((entry.value / totalSets) * 100).toStringAsFixed(0)}%)',
                                      style: TextStyle(
                                        color: ColorManager.textTertiary,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Free users: the real chart blurred, with an unlock button.
                  if (!isPremium)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            color: ColorManager.surface.withValues(alpha: 0.55),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_rounded, color: ColorManager.warningText, size: 26.sp),
                                SizedBox(height: 8.h),
                                Text(
                                  'Muscle Training Breakdown',
                                  style: TextStyle(
                                    color: ColorManager.textPrimary,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'See which muscles you train most',
                                  style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
                                ),
                                SizedBox(height: 12.h),
                                ElevatedButton(
                                  onPressed: () => context.push(Routes.premiumScreen),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorManager.primary,
                                    foregroundColor: ColorManager.onMint,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                                  ),
                                  child: Text('Unlock with Pro',
                                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
