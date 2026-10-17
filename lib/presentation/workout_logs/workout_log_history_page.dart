import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/workout_logs/widgets/legacy_workout_log_card.dart';
import 'package:fitness_app/presentation/workout_logs/widgets/workout_session_card.dart';
import 'package:fitness_app/presentation/workout_tools/plate_calculator_sheet.dart';
import 'package:fitness_app/services/strength_service.dart';
import 'package:fitness_app/services/workout_export_service.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class WorkoutHistoryFeedData {
  final List<WorkoutSession> displayedSessions;
  final List<WorkoutLog> displayedLegacyLogs;
  final Set<DateTime> activeDates;

  const WorkoutHistoryFeedData({
    required this.displayedSessions,
    required this.displayedLegacyLogs,
    required this.activeDates,
  });

  int get totalDisplayCount =>
      displayedSessions.length + displayedLegacyLogs.length;
}

class WorkoutLogHistoryPage extends StatefulWidget {
  final Stream<List<WorkoutSession>>? sessionsStream;
  final Stream<List<WorkoutLog>>? logsStream;

  const WorkoutLogHistoryPage({
    super.key,
    this.sessionsStream,
    this.logsStream,
  });

  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Returns true if [log] is already represented within [session]
  /// (e.g. written by WorkoutLogService.saveWorkoutSession for backward compatibility).
  static bool isLogRepresentedInSession(
    WorkoutLog log,
    WorkoutSession session,
  ) {
    final sessionDate = session.completedAt ?? session.startedAt;
    final sameDay = normalizeDate(log.date) == normalizeDate(sessionDate);
    final withinSessionWindow = !log.date.isBefore(
          session.startedAt.subtract(const Duration(minutes: 1)),
        ) &&
        !log.date.isAfter(
          sessionDate.add(const Duration(minutes: 1)),
        );

    if (!sameDay && !withinSessionWindow) {
      return false;
    }

    final logKey = ExerciseIdentity.canonicalKey(log.exerciseName);
    if (session.exercises.isNotEmpty) {
      final matchesSessionExercise = session.exercises.any(
        (ex) => ExerciseIdentity.canonicalKey(ex.exerciseName) == logKey,
      );
      if (matchesSessionExercise) {
        return true;
      }
    } else if (withinSessionWindow) {
      return true;
    }

    return false;
  }

  /// Merges canonical [WorkoutSession] entries and standalone [WorkoutLog] entries
  /// for both the default "All" feed ([selectedDay] == null) and calendar day filtering.
  static WorkoutHistoryFeedData buildFeedData({
    required List<WorkoutSession> allSessions,
    required List<WorkoutLog> allLogs,
    DateTime? selectedDay,
  }) {
    final Map<DateTime, List<WorkoutSession>> sessionsByDate = {};
    for (final s in allSessions) {
      final date = s.completedAt ?? s.startedAt;
      final normalized = normalizeDate(date);
      sessionsByDate.putIfAbsent(normalized, () => []).add(s);
    }

    final Map<DateTime, List<WorkoutLog>> allLogsByDate = {};
    for (final l in allLogs) {
      final normalized = normalizeDate(l.date);
      allLogsByDate.putIfAbsent(normalized, () => []).add(l);
    }

    final Set<DateTime> activeDates = {
      ...sessionsByDate.keys,
      ...allLogsByDate.keys,
    };

    // Standalone logs are those not already represented inside any canonical session
    final List<WorkoutLog> standaloneLogs = allLogs
        .where(
          (log) => !allSessions.any(
            (session) => isLogRepresentedInSession(log, session),
          ),
        )
        .toList();

    List<WorkoutSession> displayedSessions;
    List<WorkoutLog> displayedLegacyLogs;

    if (selectedDay != null) {
      final normalizedSelected = normalizeDate(selectedDay);
      displayedSessions = sessionsByDate[normalizedSelected] ?? [];
      if (displayedSessions.isEmpty) {
        displayedLegacyLogs = allLogsByDate[normalizedSelected] ?? [];
      } else {
        displayedLegacyLogs = standaloneLogs
            .where((l) => normalizeDate(l.date) == normalizedSelected)
            .toList();
      }
    } else {
      displayedSessions = allSessions;
      displayedLegacyLogs = standaloneLogs;
    }

    return WorkoutHistoryFeedData(
      displayedSessions: displayedSessions,
      displayedLegacyLogs: displayedLegacyLogs,
      activeDates: activeDates,
    );
  }

  @override
  State<WorkoutLogHistoryPage> createState() => _WorkoutLogHistoryPageState();
}

class _WorkoutLogHistoryPageState extends State<WorkoutLogHistoryPage> {
  WorkoutLogService? _lazyLogService;
  WorkoutLogService get _logService => _lazyLogService ??= WorkoutLogService();

  late final Stream<List<WorkoutSession>> _sessionsStream;
  late final Stream<List<WorkoutLog>> _logsStream;

  late DateTime _focusedDay;
  DateTime? _selectedDay;
  bool _isCalendarExpanded = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = null; // null means "show all"
    _sessionsStream = widget.sessionsStream ?? _logService.getSessions();
    _logsStream = widget.logsStream ?? _logService.getLogs();
  }

  DateTime _normalizeDate(DateTime date) =>
      WorkoutLogHistoryPage.normalizeDate(date);

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
        child: StreamBuilder<List<WorkoutSession>>(
          stream: _sessionsStream,
          builder: (context, sessionSnapshot) {
            return StreamBuilder<List<WorkoutLog>>(
              stream: _logsStream,
              builder: (context, logSnapshot) {
                final allSessions = sessionSnapshot.data ?? [];
                final allLogs = logSnapshot.data ?? [];
                final isLoading = sessionSnapshot.connectionState == ConnectionState.waiting &&
                    logSnapshot.connectionState == ConnectionState.waiting;

                final feedData = WorkoutLogHistoryPage.buildFeedData(
                  allSessions: allSessions,
                  allLogs: allLogs,
                  selectedDay: _selectedDay,
                );
                final activeDates = feedData.activeDates;
                final displayedSessions = feedData.displayedSessions;
                final displayedLegacyLogs = feedData.displayedLegacyLogs;
                final totalDisplayCount = feedData.totalDisplayCount;

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
                                      'Workout History',
                                      style: TextStyle(
                                        color: ColorManager.white,
                                        fontSize: 26.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'Sessions, strength trends & past lifts',
                                      style: TextStyle(
                                        color: ColorManager.textSecondary,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    // Plate Calculator Button
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
                                    // Export CSV Button
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

                            // Record New Workout CTA Card
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
                                    title: 'Sessions',
                                    value: '${allSessions.isNotEmpty ? allSessions.length : stats.totalWorkouts}',
                                    icon: Icons.fitness_center_rounded,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: _buildStatBadge(
                                    title: 'Active Days',
                                    value: '${activeDates.length}',
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
                                          if (activeDates.contains(normalized)) {
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

                            // Feed Header Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedDay == null
                                      ? 'Recent Sessions ($totalDisplayCount)'
                                      : 'Workouts on ${DateFormat('MMM d').format(_selectedDay!)} ($totalDisplayCount)',
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
                    else if (totalDisplayCount == 0)
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
                                    ? 'No workout sessions yet'
                                    : 'No workouts found on ${DateFormat('MMM d, yyyy').format(_selectedDay!)}',
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
                                    ? 'Hit "+ Record New Workout" above to start logging!'
                                    : 'Pick another date or tap "Clear Filter" to view all.',
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
                              if (index < displayedSessions.length) {
                                return WorkoutSessionCard(
                                  session: displayedSessions[index],
                                );
                              } else {
                                final legacyIndex = index - displayedSessions.length;
                                return LegacyWorkoutLogCard(
                                  log: displayedLegacyLogs[legacyIndex],
                                );
                              }
                            },
                            childCount: totalDisplayCount,
                          ),
                        ),
                      ),
                  ],
                );
              },
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
