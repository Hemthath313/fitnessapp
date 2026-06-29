import 'package:fitness_app/model/workout_log.dart';
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
  int _activeTab = 0; // 0: Weights, 1: Repetitions, 2: Performance
  final _logService = WorkoutLogService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text(widget.exerciseName, style: TextStyle(color: ColorManager.textPrimary)),
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
              .where((l) => l.exerciseName.toLowerCase() == widget.exerciseName.toLowerCase())
              .toList();

          if (filteredLogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 64.sp, color: ColorManager.textTertiary),
                  SizedBox(height: 16.h),
                  Text(
                    'No tracking logs found for this exercise',
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTabButton(0, 'Weights'),
                    _buildTabButton(1, 'Repetitions'),
                    _buildTabButton(2, 'Performance'),
                  ],
                ),
              ),

              // 2. Chart Section
              Container(
                margin: EdgeInsets.all(16.w),
                padding: EdgeInsets.all(16.w),
                height: 220.h,
                decoration: BoxDecoration(
                  color: ColorManager.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: ColorManager.divider),
                ),
                child: _buildChart(graphLogs),
              ),

              // 3. Header title for history
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'History Logs',
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),

              // 4. Log History list
              Expanded(
                child: ListView.builder(
                  itemCount: historyLogs.length,
                  padding: EdgeInsets.all(16.w),
                  itemBuilder: (context, index) {
                    final log = historyLogs[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 16.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Date Badge
                          Container(
                            width: 85.w,
                            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
                            decoration: BoxDecoration(
                              color: ColorManager.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: ColorManager.accent.withOpacity(0.3)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('M/d/yy').format(log.date),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: ColorManager.accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          // Right sets log block
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: ColorManager.surface,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: ColorManager.divider),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildLogHeaderCell('Set'),
                                      _buildLogHeaderCell('Weight (kg)'),
                                      _buildLogHeaderCell('Reps'),
                                    ],
                                  ),
                                  const Divider(),
                                  ...log.sets.asMap().entries.map((entry) {
                                    final setIdx = entry.key + 1;
                                    final setVal = entry.value;
                                    return Padding(
                                      padding: EdgeInsets.symmetric(vertical: 4.h),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildLogDataCell('$setIdx'),
                                          _buildLogDataCell('${setVal.weight}'),
                                          _buildLogDataCell('${setVal.reps}'),
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
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? ColorManager.accent : ColorManager.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? ColorManager.accent : ColorManager.divider,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ColorManager.accent.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : ColorManager.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
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

  Widget _buildLogDataCell(String value) {
    return Expanded(
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: ColorManager.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 13.sp,
        ),
      ),
    );
  }

  Widget _buildChart(List<WorkoutLog> graphLogs) {
    final List<FlSpot> spots = [];
    final Map<int, String> dateLabels = {};

    for (int i = 0; i < graphLogs.length; i++) {
      final log = graphLogs[i];
      double val = 0.0;

      if (_activeTab == 0) {
        // Max weight in sets
        val = log.sets.map((s) => s.weight).fold(0.0, math.max);
      } else if (_activeTab == 1) {
        // Max reps in sets
        val = log.sets.map((s) => s.reps).fold(0, math.max).toDouble();
      } else {
        // Total Volume (Performance)
        val = log.sets.map((s) => s.weight * s.reps).fold(0.0, (sum, item) => sum + item);
      }

      spots.add(FlSpot(i.toDouble(), val));
      dateLabels[i] = DateFormat('M/d').format(log.date);
    }

    if (spots.isEmpty) {
      return Center(
        child: Text(
          'No chart data available',
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
                    style: TextStyle(color: ColorManager.textTertiary, fontSize: 9.sp),
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
                  style: TextStyle(color: ColorManager.textTertiary, fontSize: 9.sp),
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
              color: ColorManager.accent.withOpacity(0.1),
            ),
          )
        ],
      ),
    );
  }
}
