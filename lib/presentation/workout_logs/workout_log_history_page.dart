import 'dart:convert';

import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/workout_logs/widgets/legacy_workout_log_card.dart';
import 'package:fitness_app/presentation/workout_logs/widgets/repeat_workout_widgets.dart';
import 'package:fitness_app/presentation/widgets/skeleton.dart';
import 'package:fitness_app/presentation/workout_logs/widgets/workout_session_card.dart';
import 'package:fitness_app/presentation/workout_tools/plate_calculator_sheet.dart';
import 'package:fitness_app/services/strength_service.dart';
import 'package:fitness_app/services/workout_export_service.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/app_feedback.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
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

  /// True when pushed as its own screen (shortcuts from other pages) instead
  /// of living in the bottom-nav History tab: adds a back button.
  final bool showBackButton;

  const WorkoutLogHistoryPage({
    super.key,
    this.sessionsStream,
    this.logsStream,
    this.showBackButton = false,
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

  /// Narrows [feed] to entries whose workout name or any exercise name
  /// contains [query] (case-insensitive; every word must match somewhere).
  /// An empty query returns [feed] untouched.
  static WorkoutHistoryFeedData filterFeed(
    WorkoutHistoryFeedData feed,
    String query,
  ) {
    final words = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return feed;

    bool matches(String haystack) {
      final h = haystack.toLowerCase();
      return words.every(h.contains);
    }

    final sessions = feed.displayedSessions.where((s) {
      final text = [
        s.workoutName,
        s.dayName,
        ...s.exercises.map((e) => ExerciseIdentity.cleanDisplayName(e.exerciseName)),
      ].join(' ');
      return matches(text);
    }).toList();

    final logs = feed.displayedLegacyLogs
        .where((l) => matches(ExerciseIdentity.cleanDisplayName(l.exerciseName)))
        .toList();

    return WorkoutHistoryFeedData(
      displayedSessions: sessions,
      displayedLegacyLogs: logs,
      activeDates: feed.activeDates,
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
  bool _isCalendarExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  Future<void> _shareCsv(BuildContext boxContext, String csv) async {
    final box = boxContext.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(utf8.encode(csv)),
              mimeType: 'text/csv',
            ),
          ],
          fileNameOverrides: [WorkoutExportService.fileName(DateTime.now())],
          subject: 'Gym Buddy workout export',
          sharePositionOrigin:
              box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted) {
        AppFeedback.error(context, "Couldn't open the share sheet. Try Copy instead.");
      }
    }
  }

  void _exportLogs(BuildContext context) async {
    final logs = await _logService.getLogs().first;
    if (logs.isEmpty) {
      if (mounted) {
        AppFeedback.info(context, 'No workout logs to export!');
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
                'CSV ready with ${logs.length} workouts. Share it to Sheets, Drive or email, or copy it to paste into a spreadsheet.',
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
                      fontSize: 11.sp,
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
            OutlinedButton.icon(
              key: const Key('export_copy_button'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: csv));
                if (mounted) {
                  Navigator.pop(dialogCtx);
                  AppFeedback.success(context, 'CSV copied to clipboard!');
                }
              },
              icon: Icon(Icons.copy, size: 16, color: ColorManager.primary),
              label: Text('Copy', style: TextStyle(color: ColorManager.primary)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: ColorManager.primary.withValues(alpha: 0.5)),
              ),
            ),
            ElevatedButton.icon(
              key: const Key('export_share_button'),
              onPressed: () => _shareCsv(dialogCtx, csv),
              icon: Icon(Icons.ios_share_rounded, size: 16, color: ColorManager.onMint),
              label: Text('Share', style: TextStyle(color: ColorManager.onMint)),
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
            child: const Text('Go Premium', style: TextStyle(color: ColorManager.onMint)),
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
                final filteredFeed =
                    WorkoutLogHistoryPage.filterFeed(feedData, _query);
                final activeDates = feedData.activeDates;
                final displayedSessions = filteredFeed.displayedSessions;
                final displayedLegacyLogs = filteredFeed.displayedLegacyLogs;
                final totalDisplayCount = filteredFeed.totalDisplayCount;
                final isSearching = _query.trim().isNotEmpty;

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
                                Expanded(
                                  child: Row(
                                    children: [
                                      if (widget.showBackButton) ...[
                                        IconButton(
                                          tooltip: 'Back',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: Icon(Icons.arrow_back_rounded,
                                              color: ColorManager.textPrimary),
                                          onPressed: () => context.pop(),
                                        ),
                                        SizedBox(width: 12.w),
                                      ],
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Workout History',
                                      style: TextStyle(
                                        color: ColorManager.white,
                                        fontSize: 24.sp,
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
                                    ],
                                  ),
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

                            // Last workout strip: one-tap repeat of the latest session
                            LastWorkoutStrip(sessions: allSessions),
                            if (allSessions.isNotEmpty) SizedBox(height: 12.h),

                            // Secondary entry for sessions done off-app
                            InkWell(
                              key: const Key('log_past_workout_button'),
                              onTap: () => context.push(Routes.workoutLogRoute),
                              borderRadius: BorderRadius.circular(16.r),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: ColorManager.surface,
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(color: ColorManager.divider),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_note_rounded, color: ColorManager.primary, size: 22.sp),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Log a past workout',
                                            style: TextStyle(
                                              color: ColorManager.textPrimary,
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "Add sets you've already done",
                                            style: TextStyle(
                                              color: ColorManager.textTertiary,
                                              fontSize: 12.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios_rounded, color: ColorManager.textTertiary, size: 14.sp),
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
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        tooltip: _isCalendarExpanded ? 'Collapse calendar' : 'Expand calendar',
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
                                        outsideTextStyle: TextStyle(color: ColorManager.textTertiary.withValues(alpha: 0.5)),
                                        selectedDecoration: BoxDecoration(
                                          color: ColorManager.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        todayDecoration: BoxDecoration(
                                          color: ColorManager.primary.withValues(alpha: 0.3),
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

                            // Search by workout or exercise name
                            TextField(
                              key: const Key('history_search_field'),
                              controller: _searchController,
                              onChanged: (v) => setState(() => _query = v),
                              textInputAction: TextInputAction.search,
                              style: TextStyle(color: ColorManager.textPrimary, fontSize: 14.sp),
                              decoration: InputDecoration(
                                hintText: 'Search workouts or exercises',
                                hintStyle: TextStyle(color: ColorManager.textTertiary, fontSize: 14.sp),
                                prefixIcon: Icon(Icons.search_rounded, color: ColorManager.textTertiary, size: 20.sp),
                                suffixIcon: _query.isEmpty
                                    ? null
                                    : IconButton(
                                        key: const Key('history_search_clear'),
                                        tooltip: 'Clear search',
                                        icon: Icon(Icons.close_rounded, color: ColorManager.textTertiary, size: 18.sp),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _query = '');
                                        },
                                      ),
                                filled: true,
                                fillColor: ColorManager.surface,
                                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                  borderSide: BorderSide(color: ColorManager.divider),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                  borderSide: BorderSide(color: ColorManager.divider),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                  borderSide: BorderSide(color: ColorManager.primary),
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),

                            // Feed Header Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isSearching
                                      ? 'Matches ($totalDisplayCount)'
                                      : _selectedDay == null
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
                      const SliverToBoxAdapter(
                        child: SkeletonList(itemCount: 4),
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
                                isSearching
                                    ? Icons.search_off_rounded
                                    : (_selectedDay == null ? Icons.fitness_center_outlined : Icons.event_busy_rounded),
                                size: 64.sp,
                                color: ColorManager.textTertiary,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                isSearching
                                    ? 'No matches for "${_query.trim()}"'
                                    : _selectedDay == null
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
                                isSearching
                                    ? (_selectedDay == null
                                        ? 'Try a different word, like an exercise or workout name.'
                                        : 'Try a different word, or tap "Clear Filter" to search all days.')
                                    : _selectedDay == null
                                        ? 'Start a workout from the Workouts tab, or tap "Log a past workout".'
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
