import 'package:fitness_app/utils/managers/layout_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/widgets/streak_calendar_widget.dart';
import 'package:fitness_app/presentation/progress/progress_data.dart';
import 'package:fitness_app/presentation/progress/widgets/adaptive_strength_summary_card.dart';
import 'package:fitness_app/presentation/profile/providers/profile_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const List<ProgressRange> _ranges = ProgressRange.values;
  int _selectedTabIndex = 1; // Default to 'Month'
  bool _loading = true;

  ProgressRange get _range => _ranges[_selectedTabIndex];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _ranges.length, vsync: this, initialIndex: _selectedTabIndex);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      await Future.wait([
        profileProvider.fetchAndSetFlSpots(),
        profileProvider.loadMeasurementHistory(),
      ]);
    } catch (e) {
      debugPrint('Error loading progress data: $e');
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);

    final userData = homeProvider.userData;
    final chest = (userData['chest'] ?? 0.0).toDouble();
    final waist = (userData['waist'] ?? 0.0).toDouble();
    final biceps = (userData['biceps'] ?? 0.0).toDouble();

    // Real, dated readings only - nothing is invented or gap-filled.
    final now = DateTime.now();
    final range = _range;
    final allWeights = profileProvider.weightEntries;
    final rangeWeights = ProgressData.inRange(allWeights, range, now);
    final spots = [
      for (final e in rangeWeights) FlSpot(ProgressData.xFor(e.date, range, now), e.value),
    ];
    final double? weightDelta = ProgressData.deltaInRange(allWeights, range, now);
    final profileWeight = (userData['weight'] as num?)?.toDouble();
    final double? displayWeight = allWeights.isNotEmpty
        ? allWeights.last.value
        : (profileWeight != null && profileWeight > 0 ? profileWeight : null);
    final history = profileProvider.measurementHistory;
    final WeightSummary? summary = ProgressData.summarize(rangeWeights);
    final goalRaw = userData['goalWeight'];
    final double? goalWeight = goalRaw is num && goalRaw > 0 ? goalRaw.toDouble() : null;

    return Scaffold(
      backgroundColor: ColorManager.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Subtitle
              Text(
                'Progress',
                style: TextStyle(
                  color: ColorManager.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Visualize your transformation and celebrate every win.',
                style: TextStyle(
                  color: ColorManager.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 24.h),

              // First-run guidance: nothing logged yet
              if (!_loading &&
                  allWeights.isEmpty &&
                  history.values.every((list) => list.isEmpty)) ...[
                _buildGetStartedCard(),
                SizedBox(height: 20.h),
              ],

              // 5-Second Rule: Adaptive Strength Snapshot (What did I do? Am I getting stronger? What should I do next?)
              const AdaptiveStrengthSummaryCard(),
              SizedBox(height: 20.h),

              // Weekly Consistency & Streak Calendar
              const StreakCalendarWidget(),
              SizedBox(height: 20.h),

              // Timeframe Tabs selector
              Container(
                height: 46.h,
                decoration: BoxDecoration(
                  color: ColorManager.surface,
                  boxShadow: ColorManager.cardShadow,
                  borderRadius: BorderRadius.circular(AppRadius.card.r),
                  border: Border.all(color: ColorManager.divider),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: ColorManager.mintGradient,
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: ColorManager.onMint,
                  unselectedLabelColor: ColorManager.textSecondary,
                  labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                  tabs: _ranges.map((r) => Tab(text: r.label)).toList(),
                  dividerColor: Colors.transparent,
                ),
              ),
              SizedBox(height: 28.h),

              // Weight Card (Stats & Graph)
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: ColorManager.surface,
                  boxShadow: ColorManager.cardShadow,
                  borderRadius: BorderRadius.circular(AppRadius.card.r),
                  border: Border.all(color: ColorManager.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weight Values Header
                     Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weight',
                              style: TextStyle(
                                color: ColorManager.textSecondary,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  displayWeight != null ? displayWeight.toStringAsFixed(1) : '—',
                                  style: TextStyle(
                                    color: ColorManager.white,
                                    fontSize: 32.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'kg',
                                  style: TextStyle(
                                    color: ColorManager.textSecondary,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              children: [
                                if (weightDelta != null) ...[
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                  decoration: BoxDecoration(
                                    color: weightDelta <= 0
                                        ? ColorManager.primary.withValues(alpha: 0.12)
                                        : Colors.orange.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: weightDelta <= 0 ? ColorManager.primary.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '${weightDelta >= 0 ? '+' : ''}${weightDelta.toStringAsFixed(1)} kg',
                                    style: TextStyle(
                                      color: weightDelta <= 0 ? ColorManager.primaryText : Colors.orange,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                ],
                                GestureDetector(
                                  onTap: () => context.push(Routes.changeWeightRoute),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      color: ColorManager.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: ColorManager.primary.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.add_rounded,
                                          color: ColorManager.primaryText,
                                          size: 16.sp,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'Log',
                                          style: TextStyle(
                                            color: ColorManager.primaryText,
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    if (displayWeight != null) _buildGoalRow(displayWeight, goalWeight),
                    SizedBox(height: 14.h),

                    // Weight Line Chart (real readings only)
                    if (_loading)
                      SizedBox(
                        height: 180.h,
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    else if (spots.length < 2)
                      _buildWeightEmptyState(allWeights.isEmpty, spots.length)
                    else
                      SizedBox(
                        height: 180.h,
                        child: LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: range.days.toDouble(),
                            minY: _chartMin(spots, goalWeight),
                            maxY: _chartMax(spots, goalWeight),
                            extraLinesData: ExtraLinesData(
                              horizontalLines: [
                                if (goalWeight != null)
                                  HorizontalLine(
                                    y: goalWeight,
                                    color: ColorManager.primaryText.withValues(alpha: 0.7),
                                    strokeWidth: 1.5,
                                    dashArray: [6, 4],
                                    label: HorizontalLineLabel(
                                      show: true,
                                      alignment: Alignment.topRight,
                                      style: TextStyle(
                                        color: ColorManager.primaryText,
                                        fontSize: AppText.caption,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      labelResolver: (line) => 'Goal ${line.y.toStringAsFixed(1)}',
                                    ),
                                  ),
                              ],
                            ),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22.h,
                                  interval: ProgressData.axisInterval(range),
                                  getTitlesWidget: (value, meta) {
                                    // Only label real days inside the window.
                                    if (value < 0 ||
                                        value > range.days - 1 ||
                                        value != value.roundToDouble()) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      ProgressData.axisLabel(value, range, now),
                                      style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: spots.length > 2,
                                preventCurveOverShooting: true,
                                color: ColorManager.primary,
                                barWidth: 3.w,
                                dotData: FlDotData(
                                  show: spots.length <= 31,
                                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                    radius: 4.r,
                                    color: ColorManager.primary,
                                    strokeWidth: 2.w,
                                    strokeColor: ColorManager.surface,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      ColorManager.primary.withValues(alpha: 0.25),
                                      ColorManager.primary.withValues(alpha: 0.0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!_loading && summary != null) ...[
                      SizedBox(height: 16.h),
                      _buildSummaryRow(summary),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 28.h),

              // Body Measurements Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Body Measurements',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ColorManager.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () => context.push(Routes.monthlyComparisonRoute),
                    child: Text(
                      'Compare',
                      style: TextStyle(
                        color: ColorManager.primaryText,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  GestureDetector(
                    onTap: () => context.push(Routes.changeMeasurementsRoute),
                    child: Text(
                      'Update',
                      style: TextStyle(
                        color: ColorManager.primaryText,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                'Change over the selected period (${range.label.toLowerCase()})',
                style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
              ),
              SizedBox(height: 12.h),

              // Measurements checklist items
              _loading
                  ? Center(child: Padding(padding: EdgeInsets.all(12.w), child: const CircularProgressIndicator()))
                  : Container(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: ColorManager.surface,
                        boxShadow: ColorManager.cardShadow,
                        borderRadius: BorderRadius.circular(AppRadius.card.r),
                        border: Border.all(color: ColorManager.divider),
                      ),
                      child: Column(
                        children: [
                          _buildMeasurementRow(Icons.all_inbox_rounded, 'Chest', chest, ProgressData.deltaInRange(history['chest'] ?? const [], range, now)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: const Divider(height: 1),
                          ),
                          _buildMeasurementRow(Icons.calendar_view_week_rounded, 'Waist', waist, ProgressData.deltaInRange(history['waist'] ?? const [], range, now)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: const Divider(height: 1),
                          ),
                          _buildMeasurementRow(Icons.fitness_center_rounded, 'Biceps', biceps, ProgressData.deltaInRange(history['biceps'] ?? const [], range, now)),
                        ],
                      ),
                    ),
              SizedBox(height: 24.h),

              // Deep Dive Analytics Section
              Text(
                'Analytics',
                style: TextStyle(
                  color: ColorManager.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    child: _buildDeepDiveCard(
                      title: 'Strength',
                      icon: Icons.bar_chart_rounded,
                      color: Colors.deepPurple,
                      onTap: () => context.push(Routes.strengthAnalyticsRoute),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildDeepDiveCard(
                      title: 'Muscle Stats',
                      icon: Icons.pie_chart_rounded,
                      color: Colors.pink,
                      onTap: () => context.push(Routes.muscleAnalyticsRoute),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 80.h), // Safe spacing for bottom navigation
            ],
          ),
        ),
      ),
    );
  }

  double _chartMin(List<FlSpot> spots, double? goal) {
    var lo = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    if (goal != null && goal < lo) lo = goal;
    return lo - 2.0;
  }

  double _chartMax(List<FlSpot> spots, double? goal) {
    var hi = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    if (goal != null && goal > hi) hi = goal;
    return hi + 2.0;
  }

  /// "Goal 70.0 kg · 5.0 kg to lose", or a link to set a goal.
  Widget _buildGoalRow(double current, double? goal) {
    return GestureDetector(
      onTap: () => context.push(Routes.changeWeightRoute),
      child: Row(
        children: [
          Icon(Icons.flag_rounded, color: ColorManager.primaryText, size: 16.sp),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              goal == null
                  ? 'Set a goal weight'
                  : 'Goal ${goal.toStringAsFixed(1)} kg · ${ProgressData.goalProgressText(current, goal)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: goal == null ? ColorManager.primaryText : ColorManager.textSecondary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(WeightSummary summary) {
    final perWeek = summary.perWeek;
    return Row(
      children: [
        Expanded(child: _buildStatTile('Start', '${summary.start.toStringAsFixed(1)} kg')),
        SizedBox(width: 10.w),
        Expanded(child: _buildStatTile('Lowest', '${summary.lowest.toStringAsFixed(1)} kg')),
        SizedBox(width: 10.w),
        Expanded(
          child: _buildStatTile(
            'Per week',
            perWeek == null
                ? '—'
                : '${perWeek >= 0 ? '+' : ''}${perWeek.toStringAsFixed(1)} kg',
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.small.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp)),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetStartedCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start tracking your progress',
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Log your weight and body measurements to see your trend here. '
            'Your workouts are tracked automatically.',
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 13.sp,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push(Routes.changeWeightRoute),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: ColorManager.mintGradient,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Text(
                      'Log weight',
                      style: TextStyle(
                        color: ColorManager.onMint,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push(Routes.changeMeasurementsRoute),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: ColorManager.divider),
                    ),
                    child: Text(
                      'Add measurements',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightEmptyState(bool noWeighIns, int pointsInRange) {
    return SizedBox(
      height: 180.h,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart_rounded, color: ColorManager.textTertiary, size: 36.sp),
            SizedBox(height: 10.h),
            Text(
              noWeighIns
                  ? 'No weigh-ins yet'
                  : (pointsInRange == 1
                      ? 'Only one weigh-in in this period'
                      : 'No weigh-ins in this period'),
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Log your weight on different days to see your trend.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
            ),
            SizedBox(height: 12.h),
            GestureDetector(
              onTap: () => context.push(Routes.changeWeightRoute),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  gradient: ColorManager.mintGradient,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Log weight',
                  style: TextStyle(
                    color: ColorManager.onMint,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementRow(IconData icon, String name, double value, double? delta) {
    String deltaText = '';
    Color deltaColor = ColorManager.textSecondary;
    if (delta != null && delta.abs() >= 0.05) {
      if (delta > 0) {
        deltaText = '+${delta.toStringAsFixed(1)} cm';
        deltaColor = Colors.orange;
      } else {
        deltaText = '${delta.toStringAsFixed(1)} cm';
        deltaColor = ColorManager.primaryText;
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: ColorManager.background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: ColorManager.primaryText, size: 20.sp),
          ),
          SizedBox(width: 16.w),
          Text(
            name,
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            value > 0 ? '${value.toStringAsFixed(1)} cm' : 'N/A',
            style: TextStyle(
              color: ColorManager.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (deltaText.isNotEmpty) ...[
            SizedBox(width: 12.w),
            Text(
              deltaText,
              style: TextStyle(
                color: deltaColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeepDiveCard({required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: ColorManager.surface,
          boxShadow: ColorManager.cardShadow,
          borderRadius: BorderRadius.circular(AppRadius.tile.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(height: 10.h),
            Text(
              title,
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
