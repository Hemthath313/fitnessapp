import 'package:fitness_app/model/personal_record_model.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/services/strength_service.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class StrengthAnalyticsPage extends StatefulWidget {
  const StrengthAnalyticsPage({super.key});

  @override
  State<StrengthAnalyticsPage> createState() => _StrengthAnalyticsPageState();
}

class _StrengthAnalyticsPageState extends State<StrengthAnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WorkoutLogService _logService = WorkoutLogService();
  final StrengthService _strengthService = StrengthService();

  // PR Vault state
  bool _showEstimated1RM = false;
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Chest', 'Back', 'Legs', 'Shoulders', 'Arms'];

  // Progress Tab state
  String? _selectedExerciseName;
  bool _chartMetricIs1RM = false;

  // AI Suggestions cache
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

  Future<void> _getAISuggestion(ExerciseInsight insight) async {
    if (_aiSuggestions.containsKey(insight.exerciseName)) return;
    setState(() => _loadingAI[insight.exerciseName] = true);
    try {
      final gemini = Gemini.instance;
      final prompt =
          'I am a fitness user. My exercise "${insight.exerciseName}" has plateaued — '
          'I have been lifting ${insight.latestWeight.toStringAsFixed(1)} kg. '
          'Give me ONE specific, actionable suggestion (under 60 words) to break through this plateau. '
          'Be direct, practical, and motivating.';
      final response = await gemini.text(prompt);
      final suggestion = response?.output ??
          'Try deloading 20% this week, then push a new PR next week with high CNS recovery!';
      if (mounted) {
        setState(() {
          _aiSuggestions[insight.exerciseName] = suggestion;
          _loadingAI[insight.exerciseName] = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _aiSuggestions[insight.exerciseName] =
              'Deload by 20% this week for active recovery, then attempt a new PR next week with better CNS readiness.';
          _loadingAI[insight.exerciseName] = false;
        });
      }
    }
  }

  bool _matchesCategory(String exerciseName, String category) {
    if (category == 'All') return true;
    final lower = exerciseName.toLowerCase();
    switch (category) {
      case 'Chest':
        return lower.contains('bench') || lower.contains('chest') || lower.contains('pushup') || lower.contains('fly');
      case 'Back':
        return lower.contains('row') || lower.contains('pull') || lower.contains('lat') || lower.contains('deadlift');
      case 'Legs':
        return lower.contains('squat') || lower.contains('leg') || lower.contains('lunge') || lower.contains('calf');
      case 'Shoulders':
        return lower.contains('press') || lower.contains('shoulder') || lower.contains('raise') || lower.contains('arnold');
      case 'Arms':
        return lower.contains('curl') || lower.contains('tricep') || lower.contains('dip') || lower.contains('bicep');
      default:
        return true;
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
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ColorManager.primary,
          labelColor: ColorManager.primary,
          unselectedLabelColor: ColorManager.textTertiary,
          labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: '🏆 PR Vault'),
            Tab(text: '📈 Progress'),
            Tab(text: '⚡ Insights'),
          ],
        ),
      ),
      body: StreamBuilder<List<WorkoutSession>>(
        stream: _logService.getSessions(),
        builder: (context, sessionSnapshot) {
          return StreamBuilder<List<WorkoutLog>>(
            stream: _logService.getLogs(),
            builder: (context, logSnapshot) {
              final sessions = sessionSnapshot.data ?? [];
              final logs = logSnapshot.data ?? [];
              final isLoading = sessionSnapshot.connectionState == ConnectionState.waiting &&
                  logSnapshot.connectionState == ConnectionState.waiting;

              if (isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (sessions.isEmpty && logs.isEmpty) {
                return _buildEmptyState();
              }

              final allPRsMap = _strengthService.getAllTimePRs(
                sessions: sessions,
                legacyLogs: logs,
              );
              final prList = allPRsMap.values.toList();
              final insights = _strengthService.generateInsights(
                sessions: sessions,
                legacyLogs: logs,
              );

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildPRVaultTab(prList),
                  _buildProgressTab(sessions, logs, prList),
                  _buildInsightsTab(insights),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 1. PR Vault Tab
  // ─────────────────────────────────────────────────────────────
  Widget _buildPRVaultTab(List<PersonalRecord> prs) {
    if (prs.isEmpty) return _buildEmptyState();

    final filteredPRs = prs
        .where((pr) => _matchesCategory(pr.exerciseName, _selectedCategory))
        .toList();

    // Sort based on current view metric
    filteredPRs.sort((a, b) {
      if (_showEstimated1RM) {
        return b.estimated1RM.compareTo(a.estimated1RM);
      }
      return b.weight.compareTo(a.weight);
    });

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      children: [
        // Metric Toggle: Heaviest Weight vs Estimated 1RM
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: ColorManager.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: ColorManager.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showEstimated1RM = false),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: !_showEstimated1RM ? ColorManager.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                    child: Center(
                      child: Text(
                        'Heaviest Weight',
                        style: TextStyle(
                          color: !_showEstimated1RM ? Colors.white : ColorManager.textSecondary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showEstimated1RM = true),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: _showEstimated1RM ? ColorManager.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                    child: Center(
                      child: Text(
                        'Estimated 1RM',
                        style: TextStyle(
                          color: _showEstimated1RM ? Colors.white : ColorManager.textSecondary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Category Filter Chips
        SizedBox(
          height: 36.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, i) {
              final cat = _categories[i];
              final isSelected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isSelected ? ColorManager.surfaceLight : ColorManager.surface,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: isSelected ? ColorManager.primary : ColorManager.divider,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? ColorManager.primary : ColorManager.textSecondary,
                      fontSize: 12.sp,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16.h),

        // Subtitle note
        Text(
          _showEstimated1RM
              ? 'Calculated via Epley formula (reps 1-12) for completed working sets.'
              : 'Absolute heaviest load lifted for at least 1 clean repetition.',
          style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
        ),
        SizedBox(height: 12.h),

        // PR List Cards
        if (filteredPRs.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            child: Center(
              child: Text(
                'No PRs found in $_selectedCategory',
                style: TextStyle(color: ColorManager.textTertiary, fontSize: 14.sp),
              ),
            ),
          )
        else
          ...filteredPRs.asMap().entries.map((entry) => _buildPRCard(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildPRCard(int rank, PersonalRecord pr) {
    final medalIcons = ['🥇', '🥈', '🥉'];
    final medal = rank < 3 ? medalIcons[rank] : '${rank + 1}.';

    final displayVal = _showEstimated1RM ? pr.estimated1RM : pr.weight;
    final metricLabel = _showEstimated1RM ? 'Est. 1RM' : '${pr.reps} rep${pr.reps > 1 ? 's' : ''}';

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: rank < 3 ? Colors.amber.withValues(alpha: 0.4) : ColorManager.divider),
      ),
      child: InkWell(
        onTap: () => context.push(
          '${Routes.exerciseTracker}?exerciseName=${Uri.encodeComponent(pr.exerciseName)}',
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32.w,
              child: Text(
                medal,
                style: TextStyle(
                  fontSize: rank < 3 ? 20.sp : 14.sp,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.textSecondary,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pr.exerciseName,
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Achieved: ${DateFormat('MMM d, yyyy').format(pr.achievedAt)}',
                    style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${displayVal.toStringAsFixed(displayVal % 1 == 0 ? 0 : 1)} kg',
                  style: TextStyle(
                    color: rank == 0 ? Colors.amber : ColorManager.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                Text(
                  metricLabel,
                  style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                ),
              ],
            ),
            SizedBox(width: 8.w),
            Icon(Icons.chevron_right_rounded, color: ColorManager.textTertiary, size: 18.sp),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. Progress Tab
  // ─────────────────────────────────────────────────────────────
  Widget _buildProgressTab(
    List<WorkoutSession> sessions,
    List<WorkoutLog> logs,
    List<PersonalRecord> prs,
  ) {
    if (prs.isEmpty) return _buildEmptyState();

    // Pick first exercise if none selected
    _selectedExerciseName ??= prs.first.exerciseName;

    // Collect historical chronological data points for selected exercise
    final key = ExerciseIdentity.canonicalKey(_selectedExerciseName!);
    final List<_ProgressDataPoint> points = [];

    for (final s in sessions) {
      for (final ex in s.exercises) {
        if (ExerciseIdentity.canonicalKey(ex.exerciseName) == key) {
          final validSets = ex.sets.where((st) => st.isCompleted && st.type != SetType.warmup && st.weight > 0);
          if (validSets.isNotEmpty) {
            double maxWeight = 0;
            double max1RM = 0;
            for (final st in validSets) {
              if (st.weight > maxWeight) maxWeight = st.weight;
              final e1rm = StrengthService.calculateEstimated1RM(st);
              if (e1rm > max1RM) max1RM = e1rm;
            }
            points.add(_ProgressDataPoint(
              date: s.completedAt ?? s.startedAt,
              weight: maxWeight,
              estimated1RM: max1RM,
            ));
          }
        }
      }
    }

    // Merge legacy logs if session points are sparse
    if (points.length < 2) {
      for (final l in logs) {
        if (ExerciseIdentity.canonicalKey(l.exerciseName) == key) {
          final validSets = l.sets.where((st) => st.isCompleted && st.type != SetType.warmup && st.weight > 0);
          if (validSets.isNotEmpty) {
            double maxWeight = 0;
            double max1RM = 0;
            for (final st in validSets) {
              if (st.weight > maxWeight) maxWeight = st.weight;
              final e1rm = StrengthService.calculateEstimated1RM(st);
              if (e1rm > max1RM) max1RM = e1rm;
            }
            points.add(_ProgressDataPoint(
              date: l.date,
              weight: maxWeight,
              estimated1RM: max1RM,
            ));
          }
        }
      }
    }

    points.sort((a, b) => a.date.compareTo(b.date));

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      children: [
        // Exercise Selector Scroll Row
        SizedBox(
          height: 38.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: prs.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, i) {
              final ex = prs[i];
              final isSelected = ex.exerciseName == _selectedExerciseName;
              return GestureDetector(
                onTap: () => setState(() => _selectedExerciseName = ex.exerciseName),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected ? ColorManager.primary : ColorManager.surface,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected ? ColorManager.primary : ColorManager.divider,
                    ),
                  ),
                  child: Text(
                    ex.exerciseName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : ColorManager.textSecondary,
                      fontSize: 12.sp,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16.h),

        // Chart Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: ColorManager.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: ColorManager.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedExerciseName ?? '',
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _chartMetricIs1RM ? 'Progression (Estimated 1RM)' : 'Progression (Top Set Weight)',
                        style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                      ),
                    ],
                  ),
                  // Metric Toggle Icon
                  GestureDetector(
                    onTap: () => setState(() => _chartMetricIs1RM = !_chartMetricIs1RM),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: ColorManager.surfaceDark,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: ColorManager.divider),
                      ),
                      child: Text(
                        _chartMetricIs1RM ? 'Switch to Weight' : 'Switch to 1RM',
                        style: TextStyle(color: ColorManager.primary, fontSize: 11.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // fl_chart
              if (points.length < 2)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.h),
                  child: Center(
                    child: Text(
                      'Log at least 2 sessions to see the progression chart',
                      style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 180.h,
                  child: LineChart(
                    _buildChartData(points),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 20.h),

        // Full Progression Button
        ElevatedButton.icon(
          onPressed: () => context.push(
            '${Routes.exerciseTracker}?exerciseName=${Uri.encodeComponent(_selectedExerciseName ?? '')}',
          ),
          icon: const Icon(Icons.analytics_outlined, size: 18),
          label: Text('Open Full Tracker for ${_selectedExerciseName ?? ""}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorManager.surface,
            foregroundColor: ColorManager.primary,
            side: BorderSide(color: ColorManager.primary.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            padding: EdgeInsets.symmetric(vertical: 12.h),
          ),
        ),
      ],
    );
  }

  LineChartData _buildChartData(List<_ProgressDataPoint> points) {
    final spots = points.asMap().entries.map((e) {
      final val = _chartMetricIs1RM ? e.value.estimated1RM : e.value.weight;
      return FlSpot(e.key.toDouble(), val);
    }).toList();

    final values = spots.map((s) => s.y).toList();
    final minY = (values.reduce((a, b) => a < b ? a : b) - 5).clamp(0.0, double.infinity);
    final maxY = values.reduce((a, b) => a > b ? a : b) + 5;

    return LineChartData(
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
          color: ColorManager.divider.withValues(alpha: 0.4),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36.w,
            getTitlesWidget: (v, _) => Text(
              '${v.toInt()}kg',
              style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
            ),
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
            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
              radius: 3.5.r,
              color: ColorManager.primary,
              strokeColor: Colors.white,
              strokeWidth: 1.5,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: ColorManager.primary.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 3. Adaptive Insights Tab (Deterministic Rule-Based + Optional Gemini)
  // ─────────────────────────────────────────────────────────────
  Widget _buildInsightsTab(List<ExerciseInsight> insights) {
    if (insights.isEmpty) return _buildEmptyState();

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      children: [
        Text(
          'Adaptive Strength Insights',
          style: TextStyle(
            color: ColorManager.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Transparent, rule-based feedback analyzing your progressive overload.',
          style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp),
        ),
        SizedBox(height: 14.h),

        ...insights.map((insight) => _buildInsightCard(insight)),
      ],
    );
  }

  Widget _buildInsightCard(ExerciseInsight insight) {
    Color badgeColor;
    String badgeLabel;
    IconData badgeIcon;

    switch (insight.status) {
      case StrengthStatus.newPR:
        badgeColor = Colors.green;
        badgeLabel = 'New PR';
        badgeIcon = Icons.military_tech_rounded;
        break;
      case StrengthStatus.improving:
        badgeColor = Colors.blueAccent;
        badgeLabel = 'Improving';
        badgeIcon = Icons.trending_up_rounded;
        break;
      case StrengthStatus.stalled:
        badgeColor = Colors.orange;
        badgeLabel = 'Stalled';
        badgeIcon = Icons.pause_circle_outline_rounded;
        break;
      case StrengthStatus.stable:
        badgeColor = Colors.grey;
        badgeLabel = 'Stable';
        badgeIcon = Icons.check_circle_outline_rounded;
        break;
    }

    final hasAISuggestion = _aiSuggestions.containsKey(insight.exerciseName);
    final isLoadingAI = _loadingAI[insight.exerciseName] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: insight.status == StrengthStatus.stalled
              ? Colors.orange.withValues(alpha: 0.4)
              : ColorManager.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                insight.exerciseName,
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, color: badgeColor, size: 12.sp),
                    SizedBox(width: 4.w),
                    Text(
                      badgeLabel,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),

          // Message
          Text(
            insight.message,
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 12.sp,
              height: 1.3,
            ),
          ),
          SizedBox(height: 8.h),

          // Quick Specs: Latest Weight & Est 1RM
          Row(
            children: [
              Text(
                'Top Set: ${insight.latestWeight.toStringAsFixed(1)} kg',
                style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                'Estimated 1RM: ${insight.latestEstimated1RM.toStringAsFixed(1)} kg',
                style: TextStyle(color: ColorManager.primary, fontSize: 11.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          // Optional Gemini AI Coach button if stalled
          if (insight.status == StrengthStatus.stalled) ...[
            SizedBox(height: 10.h),
            const Divider(height: 1),
            SizedBox(height: 8.h),
            if (hasAISuggestion)
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: ColorManager.surfaceDark,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.amber, size: 16.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _aiSuggestions[insight.exerciseName]!,
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 11.sp,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: isLoadingAI ? null : () => _getAISuggestion(insight),
                  icon: isLoadingAI
                      ? SizedBox(width: 14.w, height: 14.w, child: const CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.auto_awesome, size: 14.sp, color: Colors.amber),
                  label: Text(
                    isLoadingAI ? 'Analyzing...' : 'Ask AI Coach for Tips',
                    style: TextStyle(color: Colors.amber, fontSize: 11.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center_outlined, size: 64.sp, color: ColorManager.textTertiary),
            SizedBox(height: 16.h),
            Text(
              'No Strength Data Yet',
              style: TextStyle(color: ColorManager.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              'Complete your workouts to automatically unlock your PR Vault, 1RM benchmarks, and progression analytics.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressDataPoint {
  final DateTime date;
  final double weight;
  final double estimated1RM;

  _ProgressDataPoint({
    required this.date,
    required this.weight,
    required this.estimated1RM,
  });
}
