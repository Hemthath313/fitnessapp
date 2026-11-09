import 'package:fitness_app/utils/managers/layout_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
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

enum HistoryTypeFilter { all, strength, cardio, partial }

String historyTypeLabel(HistoryTypeFilter f) {
  switch (f) {
    case HistoryTypeFilter.all:
      return 'All';
    case HistoryTypeFilter.strength:
      return 'Strength';
    case HistoryTypeFilter.cardio:
      return 'Cardio';
    case HistoryTypeFilter.partial:
      return 'Partial';
  }
}

/// One row of the History feed: a group header or a workout entry.
class HistoryFeedItem {
  final String? header;
  final WorkoutSession? session;
  final WorkoutLog? log;

  const HistoryFeedItem.header(String this.header)
      : session = null,
        log = null;
  const HistoryFeedItem.session(WorkoutSession this.session)
      : header = null,
        log = null;
  const HistoryFeedItem.log(WorkoutLog this.log)
      : header = null,
        session = null;
}

class WorkoutLogHistoryPage extends StatefulWidget {
  final Stream<List<WorkoutSession>>? sessionsStream;
  final Stream<List<WorkoutLog>>? logsStream;

  /// True when pushed as its own screen (shortcuts from other pages) instead
  /// of living in the bottom-nav History tab: adds a back button.
  final bool showBackButton;

  /// Called by the empty-state "Start a workout" button, e.g. to switch to
  /// the Workouts tab. Falls back to the main screen when not given.
  final VoidCallback? onStartWorkout;

  const WorkoutLogHistoryPage({
    super.key,
    this.sessionsStream,
    this.logsStream,
    this.showBackButton = false,
    this.onStartWorkout,
  });

  /// Narrows [feed] to one kind of workout. Strength keeps sessions and
  /// strength quick logs, Cardio keeps cardio quick logs, Partial keeps
  /// unfinished sessions.
  static WorkoutHistoryFeedData filterByType(
    WorkoutHistoryFeedData feed,
    HistoryTypeFilter type,
  ) {
    List<WorkoutSession> sessions;
    List<WorkoutLog> logs;
    switch (type) {
      case HistoryTypeFilter.all:
        return feed;
      case HistoryTypeFilter.strength:
        sessions = feed.displayedSessions;
        logs = feed.displayedLegacyLogs.where((l) => l.category == 'Strength').toList();
        break;
      case HistoryTypeFilter.cardio:
        sessions = const [];
        logs = feed.displayedLegacyLogs.where((l) => l.category == 'Cardio').toList();
        break;
      case HistoryTypeFilter.partial:
        sessions = feed.displayedSessions.where((s) => s.isPartial).toList();
        logs = const [];
        break;
    }
    return WorkoutHistoryFeedData(
      displayedSessions: sessions,
      displayedLegacyLogs: logs,
      activeDates: feed.activeDates,
    );
  }

  /// When [query] matches exactly one distinct exercise across all history,
  /// returns its clean name (to offer a "View progress" link). Otherwise null.
  static String? singleMatchingExercise(
    List<WorkoutSession> sessions,
    List<WorkoutLog> logs,
    String query,
  ) {
    final words = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return null;
    final matches = <String, String>{};
    void consider(String raw) {
      final name = ExerciseIdentity.cleanDisplayName(raw);
      final lower = name.toLowerCase();
      if (words.every(lower.contains)) matches.putIfAbsent(lower, () => name);
    }
    for (final s in sessions) {
      for (final e in s.exercises) {
        consider(e.exerciseName);
      }
    }
    for (final l in logs) {
      consider(l.exerciseName);
    }
    return matches.length == 1 ? matches.values.first : null;
  }

  static DateTime _weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  /// "This week", "Last week", then one group per month.
  static String groupLabel(DateTime date, DateTime now) {
    final d = DateTime(date.year, date.month, date.day);
    final thisWeek = _weekStart(now);
    if (!d.isBefore(thisWeek)) return 'This week';
    if (!d.isBefore(thisWeek.subtract(const Duration(days: 7)))) return 'Last week';
    return DateFormat(d.year == now.year ? 'MMMM' : 'MMMM yyyy').format(d);
  }

  /// Merges sessions and quick logs into one list ordered newest first, so a
  /// quick log lands on its own date instead of at the bottom. With
  /// [withHeaders] the list gets a header at the start of each group.
  static List<HistoryFeedItem> buildTimeline(
    WorkoutHistoryFeedData feed, {
    DateTime? now,
    bool withHeaders = true,
  }) {
    final entries = <({DateTime date, HistoryFeedItem item})>[
      for (final s in feed.displayedSessions)
        (date: s.completedAt ?? s.startedAt, item: HistoryFeedItem.session(s)),
      for (final l in feed.displayedLegacyLogs)
        (date: l.date, item: HistoryFeedItem.log(l)),
    ];
    // Stable newest-first order (List.sort is not stable on its own).
    final order = <int, int>{for (var i = 0; i < entries.length; i++) i: i};
    final indexed = List.generate(entries.length, (i) => i)
      ..sort((a, b) {
        final c = entries[b].date.compareTo(entries[a].date);
        return c != 0 ? c : order[a]!.compareTo(order[b]!);
      });

    final reference = now ?? DateTime.now();
    final out = <HistoryFeedItem>[];
    String? lastGroup;
    for (final i in indexed) {
      if (withHeaders) {
        final group = groupLabel(entries[i].date, reference);
        if (group != lastGroup) {
          out.add(HistoryFeedItem.header(group));
          lastGroup = group;
        }
      }
      out.add(entries[i].item);
    }
    return out;
  }

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
  HistoryTypeFilter _typeFilter = HistoryTypeFilter.all;
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
                final hasCardio = allLogs.any((l) => l.category == 'Cardio');
                final hasPartial = allSessions.any((x) => x.isPartial);
                final showTypeChips = hasCardio || hasPartial;
                final effectiveType = showTypeChips ? _typeFilter : HistoryTypeFilter.all;
                final isTypeFiltered = effectiveType != HistoryTypeFilter.all;
                final typedFeed =
                    WorkoutLogHistoryPage.filterByType(filteredFeed, effectiveType);
                final totalDisplayCount = typedFeed.totalDisplayCount;
                final timeline = WorkoutLogHistoryPage.buildTimeline(
                  typedFeed,
                  withHeaders: _selectedDay == null,
                );
                final isSearching = _query.trim().isNotEmpty;
                final progressExercise = isSearching
                    ? WorkoutLogHistoryPage.singleMatchingExercise(
                        allSessions, allLogs, _query)
                    : null;

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
                                  ],
                                ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    // Log a workout (today, or a past day)
                                    IconButton(
                                      key: const Key('log_past_workout_button'),
                                      tooltip: 'Log a workout',
                                      icon: Container(
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: ColorManager.primary,
                                          borderRadius: BorderRadius.circular(12.r),
                                        ),
                                        child: Icon(Icons.add_rounded, color: ColorManager.onMint, size: 20.sp),
                                      ),
                                      onPressed: () => context.push(Routes.workoutLogRoute),
                                    ),
                                    SizedBox(width: 4.w),
                                    // Less-used tools live in one menu
                                    PopupMenuButton<String>(
                                      key: const Key('history_more_menu'),
                                      tooltip: 'More',
                                      color: ColorManager.surface,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14.r),
                                      ),
                                      icon: Container(
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: ColorManager.surfaceLight,
                                          borderRadius: BorderRadius.circular(AppRadius.small.r),
                                          border: Border.all(color: ColorManager.divider),
                                        ),
                                        child: Icon(Icons.more_horiz_rounded,
                                            color: ColorManager.textPrimary, size: 20.sp),
                                      ),
                                      onSelected: (value) {
                                        if (value == 'plate') {
                                          PlateCalculatorSheet.show(context);
                                        } else if (value == 'export') {
                                          if (subProvider.isPremium) {
                                            _exportLogs(context);
                                          } else {
                                            _showProFeatureDialog(context);
                                          }
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        PopupMenuItem<String>(
                                          key: const Key('history_menu_plate'),
                                          value: 'plate',
                                          child: Row(
                                            children: [
                                              Icon(Icons.fitness_center_rounded,
                                                  color: Colors.amberAccent, size: 18.sp),
                                              SizedBox(width: 10.w),
                                              Text('Plate calculator',
                                                  style: TextStyle(color: ColorManager.textPrimary, fontSize: 14.sp)),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem<String>(
                                          key: const Key('history_menu_export'),
                                          value: 'export',
                                          child: Row(
                                            children: [
                                              Icon(Icons.file_download_outlined,
                                                  color: ColorManager.primary, size: 18.sp),
                                              SizedBox(width: 10.w),
                                              Text('Export CSV',
                                                  style: TextStyle(color: ColorManager.textPrimary, fontSize: 14.sp)),
                                              if (!subProvider.isPremium) ...[
                                                SizedBox(width: 8.w),
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                                  decoration: BoxDecoration(
                                                    color: ColorManager.primary.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6.r),
                                                  ),
                                                  child: Text('PRO',
                                                      style: TextStyle(
                                                        color: ColorManager.primary,
                                                        fontSize: AppText.caption,
                                                        fontWeight: FontWeight.bold,
                                                      )),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),

                            // Last workout strip: one-tap repeat of the latest session
                            LastWorkoutStrip(sessions: allSessions),
                            if (allSessions.isNotEmpty) SizedBox(height: 12.h),

                            // Stats as one quiet line
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: _buildStatsLine(
                                    sessions: allSessions.isNotEmpty ? allSessions.length : stats.totalWorkouts,
                                    activeDays: activeDates.length,
                                    streak: stats.currentStreak,
                                  ),
                                ),
                                TextButton(
                                  key: const Key('history_progress_link'),
                                  onPressed: () => context.push(Routes.strengthAnalyticsRoute),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                                    minimumSize: Size(0, 36.h),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Progress',
                                        style: TextStyle(
                                          color: ColorManager.primary,
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Icon(Icons.chevron_right_rounded,
                                          color: ColorManager.primary, size: 18.sp),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 14.h),

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
                            SizedBox(height: 12.h),

                            if (showTypeChips) ...[
                              SingleChildScrollView(
                                key: const Key('history_type_chips'),
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    for (final t in [
                                      HistoryTypeFilter.all,
                                      HistoryTypeFilter.strength,
                                      if (hasCardio) HistoryTypeFilter.cardio,
                                      if (hasPartial) HistoryTypeFilter.partial,
                                    ])
                                      Padding(
                                        padding: EdgeInsets.only(right: 8.w),
                                        child: ChoiceChip(
                                          key: Key('history_filter_${t.name}'),
                                          label: Text(historyTypeLabel(t)),
                                          selected: effectiveType == t,
                                          showCheckmark: false,
                                          selectedColor: ColorManager.primary,
                                          backgroundColor: ColorManager.surface,
                                          side: BorderSide(color: ColorManager.divider),
                                          labelStyle: TextStyle(
                                            color: effectiveType == t
                                                ? ColorManager.onMint
                                                : ColorManager.textSecondary,
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          onSelected: (_) => setState(() => _typeFilter = t),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12.h),
                            ],

                            // Week strip (tap a day to filter). Month view on demand.
                            Container(
                              key: const Key('history_calendar_card'),
                              decoration: BoxDecoration(
                                color: ColorManager.surface,
                                boxShadow: ColorManager.cardShadow,
                                borderRadius: BorderRadius.circular(AppRadius.card.r),
                                border: Border.all(color: ColorManager.divider),
                              ),
                              padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 10.h),
                              child: Column(
                                children: [
                                  if (_isCalendarExpanded)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: _buildCalendarToggle(),
                                    )
                                  else
                                    _buildWeekHeader(),
                                  if (_isCalendarExpanded) ...[
                                    TableCalendar(
                                      firstDay: DateTime.utc(2020, 1, 1),
                                      lastDay: DateTime.utc(2030, 12, 31),
                                      startingDayOfWeek: StartingDayOfWeek.monday,
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
                                  ] else
                                    _buildWeekStrip(activeDates),
                                ],
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
                                          ? 'Workouts ($totalDisplayCount)'
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
                            if (progressExercise != null) ...[
                              SizedBox(height: 8.h),
                              InkWell(
                                key: const Key('history_search_progress_link'),
                                borderRadius: BorderRadius.circular(12.r),
                                onTap: () => context.push(
                                  '${Routes.exerciseTracker}?exerciseName=${Uri.encodeComponent(progressExercise)}',
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                                  decoration: BoxDecoration(
                                    color: ColorManager.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(color: ColorManager.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.analytics_outlined, color: ColorManager.primary, size: 18.sp),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          'View progress for $progressExercise',
                                          style: TextStyle(
                                            color: ColorManager.primary,
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.chevron_right_rounded, color: ColorManager.primary, size: 18.sp),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
                                    : isTypeFiltered
                                        ? 'No ${historyTypeLabel(effectiveType).toLowerCase()} workouts'
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
                                    : isTypeFiltered
                                        ? 'Pick "All" to see every workout again.'
                                    : _selectedDay == null
                                        ? 'Start a workout, or log one you already did.'
                                        : 'Pick another date or tap "Clear Filter" to view all.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ColorManager.textTertiary,
                                  fontSize: 13.sp,
                                ),
                              ),
                              if (!isSearching && !isTypeFiltered && _selectedDay == null) ...[
                                SizedBox(height: 20.h),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    key: const Key('history_empty_start_button'),
                                    onPressed: widget.onStartWorkout ??
                                        () => context.go(Routes.mainRoute),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: ColorManager.primary,
                                      foregroundColor: ColorManager.onMint,
                                      padding: EdgeInsets.symmetric(vertical: 14.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppRadius.button.r),
                                      ),
                                    ),
                                    child: Text(
                                      'Start a workout',
                                      style: TextStyle(fontSize: AppText.body, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  key: const Key('history_empty_log_button'),
                                  onPressed: () => context.push(Routes.workoutLogRoute),
                                  child: Text(
                                    'Log one you already did',
                                    style: TextStyle(color: ColorManager.primary, fontSize: 13.sp),
                                  ),
                                ),
                              ],
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
                              final item = timeline[index];
                              if (item.header != null) {
                                return Padding(
                                  padding: EdgeInsets.only(top: index == 0 ? 0 : 10.h, bottom: 8.h),
                                  child: Text(
                                    item.header!,
                                    key: Key('history_group_${item.header}'),
                                    style: TextStyle(
                                      color: ColorManager.textTertiary,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                );
                              }
                              if (item.session != null) {
                                return WorkoutSessionCard(session: item.session!);
                              }
                              return LegacyWorkoutLogCard(log: item.log!);
                            },
                            childCount: timeline.length,
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

  Widget _buildStatsLine({
    required int sessions,
    required int activeDays,
    required int streak,
  }) {
    Widget item(IconData icon, Color color, String value, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15.sp),
          SizedBox(width: 5.w),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: ColorManager.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: ' $label',
                  style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Wrap(
      key: const Key('history_stats_line'),
      spacing: 16.w,
      runSpacing: 6.h,
      children: [
        item(Icons.fitness_center_rounded, Colors.blueAccent, '$sessions', 'sessions'),
        item(Icons.calendar_today_rounded, Colors.greenAccent, '$activeDays', 'active days'),
        item(Icons.local_fire_department_rounded, Colors.orangeAccent, '$streak', 'day streak'),
      ],
    );
  }

  DateTime _weekStartOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  Widget _buildCalendarToggle() {
    return TextButton.icon(
      key: const Key('history_calendar_toggle'),
      onPressed: () => setState(() => _isCalendarExpanded = !_isCalendarExpanded),
      icon: Icon(
        _isCalendarExpanded ? Icons.view_week_rounded : Icons.calendar_month_rounded,
        color: ColorManager.primaryText,
        size: 18.sp,
      ),
      label: Text(
        _isCalendarExpanded ? 'Week' : 'Month',
        style: TextStyle(
          color: ColorManager.primaryText,
          fontSize: 13.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildWeekHeader() {
    final start = _weekStartOf(_focusedDay);
    final end = start.add(const Duration(days: 6));
    final today = DateTime.now();
    final thisWeekStart = _weekStartOf(today);
    final isThisWeek = start == thisWeekStart;
    final label = isThisWeek
        ? 'This week'
        : (start.month == end.month
            ? '${DateFormat('MMM d').format(start)} – ${end.day}'
            : '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d').format(end)}');
    return Row(
      children: [
        IconButton(
          key: const Key('history_week_prev'),
          tooltip: 'Previous week',
          icon: Icon(Icons.chevron_left, color: ColorManager.textPrimary, size: 22.sp),
          onPressed: () => setState(
              () => _focusedDay = _focusedDay.subtract(const Duration(days: 7))),
        ),
        Text(
          label,
          key: const Key('history_week_label'),
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          key: const Key('history_week_next'),
          tooltip: 'Next week',
          icon: Icon(
            Icons.chevron_right,
            color: isThisWeek ? ColorManager.textTertiary.withValues(alpha: 0.4) : ColorManager.textPrimary,
            size: 22.sp,
          ),
          onPressed: isThisWeek
              ? null
              : () => setState(
                  () => _focusedDay = _focusedDay.add(const Duration(days: 7))),
        ),
        const Spacer(),
        _buildCalendarToggle(),
      ],
    );
  }

  Widget _buildWeekStrip(Set<DateTime> activeDates) {
    final start = _weekStartOf(_focusedDay);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      key: const Key('history_week_strip'),
      children: List.generate(7, (i) {
        final day = start.add(Duration(days: i));
        final isFuture = day.isAfter(todayDate);
        final isSelected = _selectedDay != null && isSameDay(_selectedDay, day);
        final isToday = isSameDay(day, todayDate);
        final hasWorkout = activeDates.contains(_normalizeDate(day));
        return Expanded(
          child: InkWell(
            key: Key('history_week_day_${DateFormat('yyyyMMdd').format(day)}'),
            borderRadius: BorderRadius.circular(12.r),
            onTap: isFuture
                ? null
                : () => setState(() {
                      _selectedDay = isSelected ? null : day;
                      _focusedDay = day;
                    }),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    letters[i],
                    style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    width: 34.w,
                    height: 34.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? ColorManager.primary : Colors.transparent,
                      border: isToday && !isSelected
                          ? Border.all(color: ColorManager.primary, width: 1.5)
                          : null,
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isSelected
                            ? ColorManager.onMint
                            : (isFuture ? ColorManager.textTertiary.withValues(alpha: 0.4) : ColorManager.textPrimary),
                        fontSize: 13.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasWorkout ? const Color(0xFF4CAF50) : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
