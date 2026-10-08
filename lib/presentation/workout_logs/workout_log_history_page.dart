import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/workout_logs/workout_history_screen.dart';
import 'package:fitness_app/presentation/workout_tools/plate_calculator_sheet.dart';
import 'package:fitness_app/services/workout_export_service.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class WorkoutLogHistoryPage extends StatefulWidget {
  const WorkoutLogHistoryPage({super.key});

  @override
  State<WorkoutLogHistoryPage> createState() => _WorkoutLogHistoryPageState();
}

class _WorkoutLogHistoryPageState extends State<WorkoutLogHistoryPage> {
  final WorkoutLogService _logService = WorkoutLogService();
  late final Stream<List<WorkoutLog>> _logsStream;

  late DateTime _focusedDay;
  DateTime? _selectedDay;
  bool _isCalendarExpanded = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = null; // null means "show all"
    _logsStream = _logService.getLogs();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _exportLogs(BuildContext context) async {
    final logs = await _logService.getLogs().first;
    if (logs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No workout logs to export!')),
        );
      }
      return;
    }
    final csv = WorkoutExportService.generateCSV(logs);

    if (mounted) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: ColorManager.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Row(
            children: [
              Icon(Icons.download_done_rounded, color: ColorManager.primary, size: 24.sp),
              SizedBox(width: 8.w),
              Text('Export CSV', style: TextStyle(color: ColorManager.textPrimary)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CSV generated with ${logs.length} workouts. Copy and paste into Excel or Google Sheets.',
                style: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp),
              ),
              SizedBox(height: 12.h),
              Container(
                height: 120.h,
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: ColorManager.surfaceDark,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: ColorManager.divider),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    csv,
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontFamily: 'monospace',
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Close', style: TextStyle(color: ColorManager.textTertiary)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: csv));
                if (mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('CSV copied to clipboard!')),
                  );
                }
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy CSV'),
              style: ElevatedButton.styleFrom(backgroundColor: ColorManager.primary),
            ),
          ],
        ),
      );
    }
  }

  void _showProFeatureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorManager.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 24.sp),
            SizedBox(width: 8.w),
            Text('Pro Feature', style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Exporting workout history as CSV is a Premium feature. Upgrade to unlock full access!',
          style: TextStyle(color: ColorManager.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(Routes.premiumScreen);
            },
            style: ElevatedButton.styleFrom(backgroundColor: ColorManager.primary),
            child: const Text('Go Premium', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final stats = Provider.of<StatisticsProvider>(context);

    return Scaffold(
      backgroundColor: ColorManager.background,
      body: SafeArea(
        child: StreamBuilder<List<WorkoutLog>>(
          stream: _logsStream,
          builder: (context, snapshot) {
            final allLogs = snapshot.data ?? [];
            final isLoading = snapshot.connectionState == ConnectionState.waiting;

            // Group logs by Date for calendar dots
            final Map<DateTime, List<WorkoutLog>> logsByDate = {};
            for (var log in allLogs) {
              final normalized = _normalizeDate(log.date);
              logsByDate.putIfAbsent(normalized, () => []).add(log);
            }

            // Filtered logs based on selected calendar date
            List<WorkoutLog> displayedLogs = allLogs;
            if (_selectedDay != null) {
              final normalizedSelected = _normalizeDate(_selectedDay!);
              displayedLogs = logsByDate[normalizedSelected] ?? [];
            }

            return CustomScrollView(
              slivers: [
                // Top App Bar / Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
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
                                  'Workout Log',
                                  style: TextStyle(
                                    color: ColorManager.white,
                                    fontSize: 26.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Track consistency & review past lifts',
                                  style: TextStyle(
                                    color: ColorManager.textSecondary,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                // Barbell Plate Calculator Button
                                IconButton(
                                  tooltip: 'Barbell Plate Calculator',
                                  icon: Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: ColorManager.surfaceLight,
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(color: ColorManager.divider),
                                    ),
                                    child: Icon(Icons.fitness_center_rounded, color: Colors.amberAccent, size: 20.sp),
                                  ),
                                  onPressed: () {
                                    PlateCalculatorSheet.show(context);
                                  },
                                ),
                                SizedBox(width: 4.w),
                                // Export CSV Icon Button
                                IconButton(
                                  tooltip: 'Export CSV',
                                  icon: Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: ColorManager.surfaceLight,
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(color: ColorManager.divider),
                                    ),
                                    child: Icon(Icons.file_download_outlined, color: ColorManager.primary, size: 20.sp),
                                  ),
                                  onPressed: () {
                                    if (subProvider.isPremium) {
                                      _exportLogs(context);
                                    } else {
                                      _showProFeatureDialog(context);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),

                        // Prominent "+ Log Workout" CTA Card
                        InkWell(
                          onTap: () => context.push(Routes.workoutLogRoute),
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [ColorManager.primary, ColorManager.primary.withOpacity(0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: ColorManager.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.add_rounded, color: Colors.white, size: 22.sp),
                                ),
                                SizedBox(width: 14.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Record New Workout',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Log exercises, sets, reps & weight',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16.sp),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Stats Summary Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatBadge(
                                title: 'Total Workouts',
                                value: '${allLogs.isNotEmpty ? allLogs.length : stats.totalWorkouts}',
                                icon: Icons.fitness_center_rounded,
                                color: Colors.blueAccent,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildStatBadge(
                                title: 'Active Days',
                                value: '${logsByDate.length}',
                                icon: Icons.calendar_today_rounded,
                                color: Colors.greenAccent,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildStatBadge(
                                title: 'Streak',
                                value: '${stats.currentStreak}d',
                                icon: Icons.local_fire_department_rounded,
                                color: Colors.orangeAccent,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 18.h),

                        // Interactive Activity Calendar Section
                        Container(
                          decoration: BoxDecoration(
                            color: ColorManager.surface,
                            borderRadius: BorderRadius.circular(18.r),
                            border: Border.all(color: ColorManager.divider),
                          ),
                          padding: EdgeInsets.all(12.w),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_month_rounded, color: ColorManager.primary, size: 18.sp),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Activity Calendar',
                                        style: TextStyle(
                                          color: ColorManager.textPrimary,
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Expand / Collapse Calendar toggle
                                  IconButton(
                                    icon: Icon(
                                      _isCalendarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                      color: ColorManager.textTertiary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isCalendarExpanded = !_isCalendarExpanded;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (_isCalendarExpanded) ...[
                                TableCalendar(
                                  firstDay: DateTime.utc(2020, 1, 1),
                                  lastDay: DateTime.utc(2030, 12, 31),
                                  focusedDay: _focusedDay,
                                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                                  onDaySelected: (selectedDay, focusedDay) {
                                    setState(() {
                                      // Toggle selection (tapping already selected date deselects it)
                                      if (isSameDay(_selectedDay, selectedDay)) {
                                        _selectedDay = null;
                                      } else {
                                        _selectedDay = selectedDay;
                                      }
                                      _focusedDay = focusedDay;
                                    });
                                  },
                                  calendarFormat: CalendarFormat.month,
                                  headerStyle: HeaderStyle(
                                    formatButtonVisible: false,
                                    titleCentered: true,
                                    titleTextStyle: TextStyle(
                                      color: ColorManager.textPrimary,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    leftChevronIcon: Icon(Icons.chevron_left, color: ColorManager.textPrimary, size: 20.sp),
                                    rightChevronIcon: Icon(Icons.chevron_right, color: ColorManager.textPrimary, size: 20.sp),
                                  ),
                                  daysOfWeekStyle: DaysOfWeekStyle(
                                    weekdayStyle: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
                                    weekendStyle: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
                                  ),
                                  calendarStyle: CalendarStyle(
                                    defaultTextStyle: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp),
                                    weekendTextStyle: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp),
                                    outsideTextStyle: TextStyle(color: ColorManager.textTertiary.withOpacity(0.5)),
                                    selectedDecoration: BoxDecoration(
                                      color: ColorManager.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    todayDecoration: BoxDecoration(
                                      color: ColorManager.primary.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  calendarBuilders: CalendarBuilders(
                                    markerBuilder: (context, date, events) {
                                      final normalized = _normalizeDate(date);
                                      if (logsByDate.containsKey(normalized)) {
                                        return Positioned(
                                          bottom: 2,
                                          child: Container(
                                            width: 6.w,
                                            height: 6.w,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF4CAF50), // Green dot for workout day
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        );
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Feed Header Row (Shows active filter tag if a date is selected)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDay == null
                                  ? 'Recent Sessions (${allLogs.length})'
                                  : 'Workouts on ${DateFormat('MMM d').format(_selectedDay!)} (${displayedLogs.length})',
                              style: TextStyle(
                                color: ColorManager.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_selectedDay != null)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedDay = null;
                                  });
                                },
                                child: Text(
                                  'Clear Filter',
                                  style: TextStyle(color: ColorManager.primary, fontSize: 13.sp),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                      ],
                    ),
                  ),
                ),

                // History Feed / Empty States
                if (isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (displayedLogs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedDay == null ? Icons.fitness_center_outlined : Icons.event_busy_rounded,
                            size: 64.sp,
                            color: ColorManager.textTertiary,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            _selectedDay == null
                                ? 'No workouts logged yet'
                                : 'No workouts logged on ${DateFormat('MMM d, yyyy').format(_selectedDay!)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: ColorManager.textSecondary,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            _selectedDay == null
                                ? 'Hit "+ Record New Workout" above to start your journey!'
                                : 'Pick another date or tap "Clear Filter" to see all logs.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: ColorManager.textTertiary,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 40.h),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return WorkoutHistoryCard(
                            log: displayedLogs[index],
                            logService: _logService,
                          );
                        },
                        childCount: displayedLogs.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: ColorManager.surfaceLight,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              color: ColorManager.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: TextStyle(
              color: ColorManager.textTertiary,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}
