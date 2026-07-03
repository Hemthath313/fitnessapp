import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────
// Data helpers
// ─────────────────────────────────────────────────────────────

class _ExerciseStat {
  final String name;
  final double allTimePR;
  final double firstWeight;
  final double latestWeight;
  final DateTime latestDate;
  final List<WorkoutLog> history;

  _ExerciseStat({
    required this.name,
    required this.allTimePR,
    required this.firstWeight,
    required this.latestWeight,
    required this.latestDate,
    required this.history,
  });

  double get improvement => latestWeight - firstWeight;

  bool get isStagnating {
    if (history.length < 2) return false;
    final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
    final recent = history.where((l) => l.date.isAfter(twoWeeksAgo)).toList();
    if (recent.length < 2) return false;
    final recentMax = recent
        .map((l) => l.sets.isEmpty ? 0.0 : l.sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b))
        .reduce((a, b) => a > b ? a : b);
    final olderMax = history
        .where((l) => l.date.isBefore(twoWeeksAgo))
        .map((l) => l.sets.isEmpty ? 0.0 : l.sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b))
        .fold(0.0, (a, b) => a > b ? a : b);
    return recentMax <= olderMax && olderMax > 0;
  }
}

List<_ExerciseStat> _buildStats(List<WorkoutLog> logs) {
  final Map<String, List<WorkoutLog>> grouped = {};
  for (final log in logs) {
    final key = log.exerciseName.trim();
    grouped.putIfAbsent(key, () => []).add(log);
  }

  final stats = <_ExerciseStat>[];
  for (final entry in grouped.entries) {
    final exerciseLogs = List<WorkoutLog>.from(entry.value)
      ..sort((a, b) => a.date.compareTo(b.date));

    double pr = 0;
    double firstWeight = 0;
    double latestWeight = 0;

    for (int i = 0; i < exerciseLogs.length; i++) {
      final log = exerciseLogs[i];
      if (log.sets.isEmpty) continue;
      final maxWeight = log.sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
      if (maxWeight > pr) pr = maxWeight;
      if (i == 0) firstWeight = maxWeight;
      latestWeight = maxWeight;
    }

    if (pr == 0) continue;

    stats.add(_ExerciseStat(
      name: entry.key,
      allTimePR: pr,
      firstWeight: firstWeight,
      latestWeight: latestWeight,
      latestDate: exerciseLogs.last.date,
      history: exerciseLogs,
    ));
  }

  return stats;
}

// ─────────────────────────────────────────────────────────────
// Main page
// ─────────────────────────────────────────────────────────────

class StrengthAnalyticsPage extends StatefulWidget {
  const StrengthAnalyticsPage({super.key});

  @override
  State<StrengthAnalyticsPage> createState() => _StrengthAnalyticsPageState();
}

class _StrengthAnalyticsPageState extends State<StrengthAnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  _ExerciseStat? _selectedExercise;
  final Map<String, String> _aiSuggestions = {};
  final Map<String, bool> _loadingAI = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getAISuggestion(_ExerciseStat stat) async {
    if (_aiSuggestions.containsKey(stat.name)) return;
    setState(() => _loadingAI[stat.name] = true);
    try {
      final gemini = Gemini.instance;
      final prompt =
          'I am a fitness user. My exercise "${stat.name}" has been stagnating — '
          'I have been lifting ${stat.latestWeight.toInt()}kg for the past 2+ weeks with no improvement. '
          'My all-time PR is ${stat.allTimePR.toInt()}kg. '
          'Give me ONE specific, actionable suggestion (under 60 words) to break through this plateau. '
          'Be direct, practical, and motivating.';
      final response = await gemini.text(prompt);
      final suggestion = response?.output ?? 'Try deloading 20% this week, then push a new PR next week!';
      if (mounted) {
        setState(() {
          _aiSuggestions[stat.name] = suggestion;
          _loadingAI[stat.name] = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _aiSuggestions[stat.name] =
              'Deload by 20% this week for active recovery, then attempt a new PR next week with better CNS readiness.';
          _loadingAI[stat.name] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        backgroundColor: ColorManager.background,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
        title: Text(
          'Strength Analytics',
          style: TextStyle(color: ColorManager.textPrimary, fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ColorManager.primary,
          labelColor: ColorManager.primary,
          unselectedLabelColor: ColorManager.textTertiary,
          labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: '🏆 PRs'),
            Tab(text: '📈 Progress'),
            Tab(text: '⚠️ Stagnating'),
          ],
        ),
      ),
      body: StreamBuilder<List<WorkoutLog>>(
        stream: WorkoutLogService().getLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) return _buildEmptyState();
          final stats = _buildStats(logs);
          if (stats.isEmpty) return _buildEmptyState();
          return TabBarView(
            controller: _tabController,
            children: [
              _buildPRTab(stats),
              _buildProgressTab(stats),
              _buildStagnatingTab(stats),
            ],
          );
        },
      ),
    );
  }

  // ──────── PR Tab ────────
  Widget _buildPRTab(List<_ExerciseStat> stats) {
    final sorted = List<_ExerciseStat>.from(stats)
      ..sort((a, b) => b.allTimePR.compareTo(a.allTimePR));
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _sectionHeader('🏆 All-Time Personal Records', 'Your heaviest lifts ever'),
        SizedBox(height: 12.h),
        ...sorted.asMap().entries.map((e) => _buildPRCard(e.key, e.value)),
      ],
    );
  }

  Widget _buildPRCard(int rank, _ExerciseStat stat) {
    final medalIcons = ['🥇', '🥈', '🥉'];
    final medalColors = [Colors.amber, Colors.grey.shade400, Colors.brown.shade300];
    final medal = rank < 3 ? medalIcons[rank] : '${rank + 1}.';
    final borderColor = rank < 3 ? medalColors[rank] : ColorManager.divider;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor, width: rank < 3 ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Text(medal, style: TextStyle(fontSize: 22.sp)),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.name, style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold, fontSize: 15.sp)),
                SizedBox(height: 2.h),
                Text('Last: ${DateFormat('MMM d, yyyy').format(stat.latestDate)}', style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${stat.allTimePR.toInt()} kg', style: TextStyle(color: rank == 0 ? Colors.amber : ColorManager.primary, fontWeight: FontWeight.bold, fontSize: 18.sp)),
              if (stat.improvement > 0)
                Text('+${stat.improvement.toInt()}kg overall', style: TextStyle(color: Colors.green, fontSize: 10.sp)),
            ],
          ),
        ],
      ),
    );
  }

  // ──────── Progress Tab ────────
  Widget _buildProgressTab(List<_ExerciseStat> stats) {
    final improved = List<_ExerciseStat>.from(stats.where((s) => s.improvement > 0))
      ..sort((a, b) => b.improvement.compareTo(a.improvement));
    final selected = _selectedExercise ?? (stats.isNotEmpty ? stats.first : null);
    if (selected == null) return _buildEmptyState();
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _sectionHeader('📈 Weight Progression', 'Tap an exercise to see its chart'),
        SizedBox(height: 12.h),
        SizedBox(
          height: 40.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stats.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (_, i) {
              final stat = stats[i];
              final isSelected = selected.name == stat.name;
              return GestureDetector(
                onTap: () => setState(() => _selectedExercise = stat),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected ? ColorManager.primary : ColorManager.surface,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: isSelected ? ColorManager.primary : ColorManager.divider),
                  ),
                  child: Text(
                    stat.name,
                    style: TextStyle(color: isSelected ? Colors.white : ColorManager.textSecondary, fontSize: 12.sp, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 20.h),
        _buildLineChart(selected),
        SizedBox(height: 20.h),
        _sectionHeader('💪 Most Improved', 'Biggest weight gains overall'),
        SizedBox(height: 12.h),
        if (improved.isEmpty)
          _emptyCard('Complete more sessions to track improvement.')
        else
          ...improved.take(5).map((s) => _buildImprovedCard(s)),
      ],
    );
  }

  Widget _buildLineChart(_ExerciseStat stat) {
    final data = stat.history
        .where((l) => l.sets.isNotEmpty)
        .map((l) => l.sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b))
        .toList();

    if (data.length < 2) return _emptyCard('Need at least 2 sessions to show the chart.');

    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    final minY = (data.reduce((a, b) => a < b ? a : b) - 5).clamp(0, double.infinity).toDouble();
    final maxY = data.reduce((a, b) => a > b ? a : b) + 5;

    return Container(
      height: 200.h,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: ColorManager.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stat.name, style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.sp)),
          SizedBox(height: 4.h),
          Text('PR: ${stat.allTimePR.toInt()}kg  ·  Start: ${stat.firstWeight.toInt()}kg  →  Now: ${stat.latestWeight.toInt()}kg', style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp)),
          SizedBox(height: 12.h),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(color: ColorManager.divider.withValues(alpha: 0.5), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36.w,
                      getTitlesWidget: (v, m) => Text('${v.toInt()}', style: TextStyle(color: ColorManager.textTertiary, fontSize: 9.sp)),
                    ),
                  ),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: ColorManager.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(radius: 3.r, color: ColorManager.primary, strokeColor: Colors.white, strokeWidth: 1.5),
                    ),
                    belowBarData: BarAreaData(show: true, color: ColorManager.primary.withValues(alpha: 0.08)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovedCard(_ExerciseStat stat) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.trending_up, color: Colors.green, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(child: Text(stat.name, style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.w600, fontSize: 14.sp))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${stat.improvement.toInt()} kg', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16.sp)),
              Text('${stat.firstWeight.toInt()} → ${stat.latestWeight.toInt()}kg', style: TextStyle(color: ColorManager.textTertiary, fontSize: 10.sp)),
            ],
          ),
        ],
      ),
    );
  }

  // ──────── Stagnating Tab ────────
  Widget _buildStagnatingTab(List<_ExerciseStat> stats) {
    final stagnating = stats.where((s) => s.isStagnating).toList();
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _sectionHeader('⚠️ Plateau Detected', 'No improvement in 2+ weeks'),
        SizedBox(height: 12.h),
        if (stagnating.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 40.h),
            child: Column(
              children: [
                Icon(Icons.emoji_events, size: 64.sp, color: Colors.amber),
                SizedBox(height: 16.h),
                Text('No plateaus detected! 🎉', style: TextStyle(color: ColorManager.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 8.h),
                Text("Keep pushing — you're making consistent progress.", textAlign: TextAlign.center, style: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp)),
              ],
            ),
          )
        else ...[
          Text('${stagnating.length} exercise${stagnating.length > 1 ? 's' : ''} need attention', style: TextStyle(color: Colors.orange, fontSize: 13.sp, fontWeight: FontWeight.w500)),
          SizedBox(height: 12.h),
          ...stagnating.map((s) => _buildStagnatingCard(s)),
        ],
      ],
    );
  }

  Widget _buildStagnatingCard(_ExerciseStat stat) {
    final suggestion = _aiSuggestions[stat.name];
    final isLoading = _loadingAI[stat.name] ?? false;
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stat.name, style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold, fontSize: 15.sp)),
                      Text('Stuck at ${stat.latestWeight.toInt()}kg  ·  PR: ${stat.allTimePR.toInt()}kg', style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: suggestion != null
                ? Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: ColorManager.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: ColorManager.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('✨', style: TextStyle(fontSize: 14.sp)),
                        SizedBox(width: 8.w),
                        Expanded(child: Text(suggestion, style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, height: 1.4))),
                      ],
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : () => _getAISuggestion(stat),
                      icon: isLoading
                          ? SizedBox(width: 14.w, height: 14.h, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(Icons.auto_awesome, size: 16.sp),
                      label: Text(isLoading ? 'Getting AI suggestion...' : 'Get AI Suggestion', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ──────── Helpers ────────
  Widget _sectionHeader(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: ColorManager.textPrimary, fontSize: 17.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 2.h),
          Text(subtitle, style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp)),
        ],
      );

  Widget _emptyCard(String message) => Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(color: ColorManager.surface, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: ColorManager.divider)),
        child: Text(message, style: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp)),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 72.sp, color: ColorManager.primary.withValues(alpha: 0.2)),
            SizedBox(height: 20.h),
            Text('No workout data yet', style: TextStyle(color: ColorManager.textPrimary, fontSize: 20.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 10.h),
            Text('Complete a workout session to start\nseeing your strength analytics.', textAlign: TextAlign.center, style: TextStyle(color: ColorManager.textSecondary, fontSize: 14.sp)),
          ],
        ),
      );
}
