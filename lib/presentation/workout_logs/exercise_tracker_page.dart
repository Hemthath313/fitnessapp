import 'package:fitness_app/utils/managers/layout_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/services/strength_service.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class ExerciseTrackerPage extends StatefulWidget {
  final String exerciseName;

  const ExerciseTrackerPage({super.key, required this.exerciseName});

  @override
  State<ExerciseTrackerPage> createState() => _ExerciseTrackerPageState();
}

class _ExerciseTrackerPageState extends State<ExerciseTrackerPage> {
  int _activeTab = 0; // 0: Top Weight, 1: Estimated 1RM, 2: Volume, 3: Reps
  final _logService = WorkoutLogService();

  @override
  Widget build(BuildContext context) {
    final cleanTitle = ExerciseIdentity.cleanDisplayName(widget.exerciseName);
    final targetKey = ExerciseIdentity.canonicalKey(widget.exerciseName);

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text(cleanTitle, style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: ColorManager.background,
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
        elevation: 0,
      ),
      body: StreamBuilder<List<WorkoutLog>>(
        stream: _logService.getLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data ?? [];
          final filteredLogs = logs
              .where((l) => ExerciseIdentity.canonicalKey(l.exerciseName) == targetKey)
              .toList();

          if (filteredLogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 64.sp, color: ColorManager.textTertiary),
                  SizedBox(height: 16.h),
                  Text(
                    'No tracking logs found for $cleanTitle',
                    style: TextStyle(color: ColorManager.textTertiary, fontSize: 16.sp),
                  ),
                ],
              ),
            );
          }

          // Chronological logs for graph
          final graphLogs = List<WorkoutLog>.from(filteredLogs)
            ..sort((a, b) => a.date.compareTo(b.date));

          // List logs for history (descending)
          final historyLogs = List<WorkoutLog>.from(filteredLogs)
            ..sort((a, b) => b.date.compareTo(a.date));

          return Column(
            children: [
              // 1. Selector Segment Tabs
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  children: [
                    _buildTabButton(0, 'Weight'),
                    SizedBox(width: 6.w),
                    _buildTabButton(1, 'Est. 1RM'),
                    SizedBox(width: 6.w),
                    _buildTabButton(2, 'Volume'),
                    SizedBox(width: 6.w),
                    _buildTabButton(3, 'Reps'),
                  ],
                ),
              ),

              // 2. Chart Section
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                padding: EdgeInsets.all(16.w),
                height: 220.h,
                decoration: BoxDecoration(
                  color: ColorManager.surface,
                  boxShadow: ColorManager.cardShadow,
                  borderRadius: BorderRadius.circular(AppRadius.tile.r),
                  border: Border.all(color: ColorManager.divider),
                ),
                child: _buildChart(graphLogs),
              ),

              // 3. Header title for history
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 4.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Session History (${historyLogs.length})',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    Text(
                      _activeTab == 1 ? 'Epley 1RM Guardrails Active' : '',
                      style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                    ),
                  ],
                ),
              ),

              // 4. Log History list
              Expanded(
                child: ListView.builder(
                  itemCount: historyLogs.length,
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.gutter, vertical: 16.h),
                  itemBuilder: (context, index) {
                    final log = historyLogs[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Date Badge
                          Container(
                            width: 80.w,
                            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
                            decoration: BoxDecoration(
                              color: ColorManager.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: ColorManager.accent.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('MMM d').format(log.date),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: ColorManager.accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.sp,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  DateFormat('yyyy').format(log.date),
                                  style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10.w),

                          // Right sets log block
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: ColorManager.surface,
                                boxShadow: ColorManager.cardShadow,
                                borderRadius: BorderRadius.circular(AppRadius.small.r),
                                border: Border.all(color: ColorManager.divider),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildLogHeaderCell('Set'),
                                      _buildLogHeaderCell('Weight'),
                                      _buildLogHeaderCell('Reps'),
                                      _buildLogHeaderCell('Est. 1RM'),
                                    ],
                                  ),
                                  const Divider(height: 12),
                                  ...log.sets.asMap().entries.map((entry) {
                                    final setIdx = entry.key + 1;
                                    final setVal = entry.value;
                                    final est1RM = StrengthService.calculateEstimated1RM(setVal);

                                    return Padding(
                                      padding: EdgeInsets.symmetric(vertical: 4.h),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildLogDataCell('$setIdx'),
                                          _buildLogDataCell('${setVal.weight.toStringAsFixed(setVal.weight % 1 == 0 ? 0 : 1)} kg'),
                                          _buildLogDataCell('${setVal.reps}'),
                                          _buildLogDataCell(
                                            est1RM > 0 ? '${est1RM.toStringAsFixed(1)} kg' : '—',
                                            color: est1RM > 0 ? ColorManager.primary : ColorManager.textTertiary,
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? ColorManager.accent : ColorManager.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? ColorManager.accent : ColorManager.divider,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : ColorManager.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 11.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogHeaderCell(String label) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: ColorManager.textTertiary,
          fontWeight: FontWeight.bold,
          fontSize: 11.sp,
        ),
      ),
    );
  }

  Widget _buildLogDataCell(String value, {Color? color}) {
    return Expanded(
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color ?? ColorManager.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 12.sp,
        ),
      ),
    );
  }

  Widget _buildChart(List<WorkoutLog> graphLogs) {
    final List<FlSpot> spots = [];
    final Map<int, String> dateLabels = {};

    for (int i = 0; i < graphLogs.length; i++) {
      final log = graphLogs[i];
      final workingSets = log.sets.where((s) => s.isCompleted && s.type != SetType.warmup && s.weight > 0).toList();
      double val = 0.0;

      if (_activeTab == 0) {
        // Max weight in working sets
        val = workingSets.isEmpty ? 0.0 : workingSets.map((s) => s.weight).fold(0.0, math.max);
      } else if (_activeTab == 1) {
        // Estimated 1RM
        val = workingSets.isEmpty
            ? 0.0
            : workingSets.map((s) => StrengthService.calculateEstimated1RM(s)).fold(0.0, math.max);
      } else if (_activeTab == 2) {
        // Total Volume
        val = workingSets.isEmpty
            ? 0.0
            : workingSets.map((s) => s.weight * s.reps).fold(0.0, (sum, item) => sum + item);
      } else {
        // Max reps
        val = workingSets.isEmpty ? 0.0 : workingSets.map((s) => s.reps).fold(0, math.max).toDouble();
      }

      spots.add(FlSpot(i.toDouble(), val));
      dateLabels[i] = DateFormat('M/d').format(log.date);
    }

    if (spots.isEmpty || spots.every((s) => s.y == 0)) {
      return Center(
        child: Text(
          'No working sets data available yet',
          style: TextStyle(color: ColorManager.textTertiary, fontSize: 13.sp),
        ),
      );
    }

    final double minY = spots.map((s) => s.y).reduce(math.min);
    final double maxY = spots.map((s) => s.y).reduce(math.max);
    final double paddingY = (maxY - minY) == 0 ? 5.0 : (maxY - minY) * 0.15;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (spots.length - 1).toDouble() + 0.1,
        minY: math.max(0.0, minY - paddingY),
        maxY: maxY + paddingY,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22.h,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (dateLabels.containsKey(idx)) {
                  return Text(
                    dateLabels[idx]!,
                    style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35.w,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: ColorManager.divider,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: spots.length > 1,
            dotData: FlDotData(show: true),
            color: ColorManager.accent,
            barWidth: 3.w,
            belowBarData: BarAreaData(
              show: true,
              color: ColorManager.accent.withValues(alpha: 0.1),
            ),
          )
        ],
      ),
    );
  }
}
