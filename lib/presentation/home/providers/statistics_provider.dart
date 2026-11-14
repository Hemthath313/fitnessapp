import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fitness_app/services/badge_rules.dart';
import 'package:fitness_app/services/notification_copy.dart';
import 'package:fitness_app/services/notification_service.dart';
import 'package:fitness_app/services/review_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsProvider with ChangeNotifier {
  int _currentStreak = 0;

  // ── Streak freeze ──
  // A freeze covers one missed workout day so the streak survives.
  // Free: 1 per calendar month. Pro: 3 per month. Used automatically.
  static const String _freezePrefsKey = 'streak_freeze_dates';
  Set<DateTime> _frozenDates = {};
  int _monthlyFreezeAllowance = 1;
  DateTime? _freezeNoticeDate;

  /// Freezes still available this calendar month.
  int get freezesLeftThisMonth {
    final now = _referenceNow ?? DateTime.now();
    final usedThisMonth = _frozenDates
        .where((d) => d.year == now.year && d.month == now.month)
        .length;
    final left = _monthlyFreezeAllowance - usedThisMonth;
    return left < 0 ? 0 : left;
  }

  int get monthlyFreezeAllowance => _monthlyFreezeAllowance;

  /// Pro members get 3 freezes a month instead of 1.
  void setPremiumForStreakFreeze(bool isPremium) {
    final next = isPremium ? 3 : 1;
    if (next == _monthlyFreezeAllowance) return;
    _monthlyFreezeAllowance = next;
    notifyListeners();
  }

  /// Returns (once) the day a freeze was just used, so the UI can say so.
  DateTime? consumeFreezeNotice() {
    final d = _freezeNoticeDate;
    _freezeNoticeDate = null;
    return d;
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadFrozenDates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _frozenDates = (prefs.getStringList(_freezePrefsKey) ?? [])
          .map(DateTime.tryParse)
          .whereType<DateTime>()
          .map(normalizeLocalDate)
          .toSet();
    } catch (_) {}
  }

  Future<void> _saveFrozenDates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _freezePrefsKey, _frozenDates.map(_dayKey).toList()..sort());
    } catch (_) {}
  }

  /// Missed workout days between the last workout and yesterday that are
  /// not already covered by a freeze.
  List<DateTime> _uncoveredMissedDays(Set<DateTime> dates, DateTime today) {
    if (dates.isEmpty) return const [];
    final last = (dates.toList()..sort()).last;
    final missed = <DateTime>[];
    var d = DateTime(last.year, last.month, last.day + 1);
    while (d.isBefore(today)) {
      final scheduled = _scheduledWeekdays.isEmpty ||
          _scheduledWeekdays.contains(d.weekday);
      if (scheduled && !_frozenDates.contains(d)) missed.add(d);
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return missed;
  }

  /// Uses freezes automatically when they would save a running streak.
  /// Returns true when a freeze was applied.
  Future<bool> _applyStreakFreezeIfNeeded(
      Set<DateTime> dates, int storedStreak) async {
    if (storedStreak <= 0 || dates.isEmpty) return false;
    final today = normalizeLocalDate(_referenceNow ?? DateTime.now());
    final missed = _uncoveredMissedDays(dates, today);
    if (missed.isEmpty) return false;
    // Freezes are counted in the month of the missed day.
    final byMonth = <String, int>{};
    for (final m in missed) {
      byMonth['${m.year}-${m.month}'] = (byMonth['${m.year}-${m.month}'] ?? 0) + 1;
    }
    for (final entry in byMonth.entries) {
      final parts = entry.key.split('-');
      final y = int.parse(parts[0]);
      final mo = int.parse(parts[1]);
      final used = _frozenDates.where((d) => d.year == y && d.month == mo).length;
      if (used + entry.value > _monthlyFreezeAllowance) return false;
    }
    _frozenDates = {..._frozenDates, ...missed};
    _freezeNoticeDate = missed.last;
    await _saveFrozenDates();
    return true;
  }
  int _longestStreak = 0;
  DateTime? _lastWorkoutDate;
  int _totalWorkouts = 0;
  List<String> _unlockedAchievements = [];
  List<DateTime> _completedWorkoutDates = [];
  int _dynamicWeeklyTarget = 3;

  Set<int> _scheduledWeekdays = {};
  Set<int> _previousScheduledWeekdays = {};
  DateTime? _scheduleEffectiveDate;
  int _streakAtScheduleChange = 0;
  DateTime? _referenceNow;

  /// When the full workout-date history was last read from Firestore
  /// successfully. Null until the first complete read this session.
  DateTime? _datesFetchedAt;

  /// How long the in-memory workout dates are trusted before [updateStreak]
  /// re-reads the history. Within this window finishing a workout just adds
  /// today's date instead of re-downloading every collection.
  static const Duration datesRefreshInterval = Duration(minutes: 30);

  static const Map<String, int> _weekdayMap = {
    'monday': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'friday': DateTime.friday,
    'saturday': DateTime.saturday,
    'sunday': DateTime.sunday,
  };

  static const List<String> _orderedDayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Holds newly unlocked achievement IDs since last read (for showing celebration dialog)
  List<String> _newlyUnlockedAchievements = [];

  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  DateTime? get lastWorkoutDate => _lastWorkoutDate;
  int get totalWorkouts => _totalWorkouts;
  List<String> get unlockedAchievements => [..._unlockedAchievements];
  List<DateTime> get completedWorkoutDates => [..._completedWorkoutDates];
  Set<int> get scheduledWeekdays => {..._scheduledWeekdays};

  List<String> get scheduledDayNames {
    final sorted = _scheduledWeekdays.toList()..sort();
    return sorted.map((w) => _orderedDayNames[w - 1]).toList();
  }

  bool get hasActiveSchedule => _scheduledWeekdays.isNotEmpty;

  bool get hasWorkoutHistory =>
      _completedWorkoutDates.isNotEmpty ||
      _totalWorkouts > 0 ||
      _lastWorkoutDate != null;

  bool get hasWorkoutToday => hasWorkoutOnDate(_referenceNow ?? DateTime.now());

  bool hasWorkoutOnDate(DateTime date) {
    final target = normalizeLocalDate(date);
    if (_completedWorkoutDates.any((d) =>
        d.year == target.year &&
        d.month == target.month &&
        d.day == target.day)) {
      return true;
    }
    if (_lastWorkoutDate == null) return false;
    final lastNorm = normalizeLocalDate(_lastWorkoutDate!);
    return lastNorm.year == target.year &&
        lastNorm.month == target.month &&
        lastNorm.day == target.day;
  }

  /// True when the user has a configured schedule and [date] (defaults to today) is not a scheduled training day
  bool isRestDay([DateTime? date]) {
    if (_scheduledWeekdays.isEmpty) return false;
    final target = normalizeLocalDate(date ?? _referenceNow ?? DateTime.now());
    return !_scheduledWeekdays.contains(target.weekday);
  }

  /// True when [date] (defaults to today) is a scheduled training day that has not been completed yet
  bool isPendingScheduledDay([DateTime? date]) {
    if (_scheduledWeekdays.isEmpty) return false;
    final target = normalizeLocalDate(date ?? _referenceNow ?? DateTime.now());
    if (!_scheduledWeekdays.contains(target.weekday)) return false;
    return !hasWorkoutOnDate(target);
  }

  /// Normalizes any DateTime (UTC or local) to local calendar midnight DateTime(year, month, day)
  static DateTime normalizeLocalDate(DateTime date) {
    final local = date.isUtc ? date.toLocal() : date;
    return DateTime(local.year, local.month, local.day);
  }

  /// Deduplicates a collection of timestamps into unique local calendar dates
  static Set<DateTime> normalizeAndDeduplicateDates(
      Iterable<DateTime> rawDates) {
    return rawDates.map(normalizeLocalDate).toSet();
  }

  /// Parses weekday names (e.g. 'Monday', '[Wednesday]') into DateTime weekday ints (1..7)
  static Set<int> parseWeekdayNames(Iterable<String> dayNames) {
    final result = <int>{};
    for (final raw in dayNames) {
      final clean =
          raw.replaceAll(RegExp(r'[\[\]]'), '').trim().toLowerCase();
      final weekday = _weekdayMap[clean];
      if (weekday != null) {
        result.add(weekday);
      }
    }
    return result;
  }

  /// Returns and clears newly unlocked achievements (consume once to show dialog)
  List<String> consumeNewlyUnlocked() {
    final result = [..._newlyUnlockedAchievements];
    _newlyUnlockedAchievements.clear();
    return result;
  }

  int get workoutsCompletedThisWeek {
    final today = normalizeLocalDate(_referenceNow ?? DateTime.now());
    final startOfWeek =
        DateTime(today.year, today.month, today.day - (today.weekday - 1));
    final endOfWeek =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + 7);
    final uniqueDates = normalizeAndDeduplicateDates(_completedWorkoutDates);
    return uniqueDates
        .where((d) => !d.isBefore(startOfWeek) && d.isBefore(endOfWeek))
        .length;
  }

  int get weeklyTarget => _dynamicWeeklyTarget > 0 ? _dynamicWeeklyTarget : 3;

  /// Restores any saved schedule selections from SharedPreferences without requiring Firestore
  Future<void> restoreSavedScheduleFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedScheduledDays = prefs.getStringList('scheduled_workout_days');
    if (savedScheduledDays != null && savedScheduledDays.isNotEmpty) {
      final parsed = parseWeekdayNames(savedScheduledDays);
      if (parsed.isNotEmpty) {
        _scheduledWeekdays = parsed;
        _dynamicWeeklyTarget = parsed.length;
        await prefs.setInt('weekly_target_count', _dynamicWeeklyTarget);
      } else {
        _scheduledWeekdays = {};
        _dynamicWeeklyTarget = 3;
        await prefs.remove('weekly_target_count');
      }
    } else {
      _scheduledWeekdays = {};
      _dynamicWeeklyTarget = 3;
      await prefs.remove('weekly_target_count');
    }
    final savedPrevDays =
        prefs.getStringList('previous_scheduled_workout_days');
    if (savedPrevDays != null && savedPrevDays.isNotEmpty) {
      _previousScheduledWeekdays = parseWeekdayNames(savedPrevDays);
    } else {
      _previousScheduledWeekdays = {};
    }
    final savedEffectiveIso = prefs.getString('schedule_effective_date');
    if (savedEffectiveIso != null) {
      final parsedDate = DateTime.tryParse(savedEffectiveIso);
      if (parsedDate != null) {
        _scheduleEffectiveDate = normalizeLocalDate(parsedDate);
      }
    } else {
      _scheduleEffectiveDate = null;
    }
    final savedStreakAtChange = prefs.getInt('streak_at_schedule_change');
    if (savedStreakAtChange != null && savedStreakAtChange > 0) {
      _streakAtScheduleChange = savedStreakAtChange;
    } else {
      _streakAtScheduleChange = 0;
    }
    _reconcileInMemoryStreak(referenceNow: _referenceNow);
    notifyListeners();
  }

  /// Syncs split workout days when an active split is present, while preserving
  /// any free-user scheduled_workout_days when the split is empty.
  Future<void> syncSplitSchedule(
    Iterable<String> splitDays, {
    DateTime? effectiveDate,
  }) async {
    final parsed = parseWeekdayNames(splitDays);
    if (parsed.isNotEmpty) {
      await updateScheduledDays(splitDays, effectiveDate: effectiveDate);
    } else {
      await resetWeeklyTarget();
    }
  }

  /// Updates the active scheduled workout days and weekly target, then recalculates streak.
  /// Preserves verified streak up to the schedule change and applies the new schedule prospectively.
  Future<void> updateScheduledDays(
    Iterable<String> dayNames, {
    DateTime? effectiveDate,
  }) async {
    final parsed = parseWeekdayNames(dayNames);
    if (parsed.isEmpty) {
      // Do not erase existing free-user schedule when passed an empty iterable
      return;
    }

    final bool scheduleChanged =
        parsed.length != _scheduledWeekdays.length ||
            !parsed.containsAll(_scheduledWeekdays);
    final bool targetChanged = _dynamicWeeklyTarget != parsed.length;

    final effectiveNow = effectiveDate ?? _referenceNow ?? DateTime.now();

    if (scheduleChanged &&
        (_completedWorkoutDates.isNotEmpty || _lastWorkoutDate != null)) {
      // Reconcile verified streak under the prior schedule before switching
      _reconcileInMemoryStreak(referenceNow: effectiveNow);
      if (_currentStreak > 0) {
        _previousScheduledWeekdays = {..._scheduledWeekdays};
        _scheduleEffectiveDate = normalizeLocalDate(effectiveNow);
        _streakAtScheduleChange = _currentStreak;
      }
    }

    _scheduledWeekdays = parsed;
    _dynamicWeeklyTarget = parsed.length;

    final canonicalNames = scheduledDayNames;
    final prevNames = (_previousScheduledWeekdays.toList()..sort())
        .map((w) => _orderedDayNames[w - 1])
        .toList();
    final effectiveIso = _scheduleEffectiveDate?.toIso8601String();
    final streakSnapshot = _streakAtScheduleChange;

    _reconcileInMemoryStreak(referenceNow: effectiveNow);
    if (scheduleChanged || targetChanged) {
      notifyListeners();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('scheduled_workout_days', canonicalNames);
    await prefs.setInt('weekly_target_count', _dynamicWeeklyTarget);
    if (prevNames.isNotEmpty) {
      await prefs.setStringList('previous_scheduled_workout_days', prevNames);
    }
    if (effectiveIso != null) {
      await prefs.setString('schedule_effective_date', effectiveIso);
      await prefs.setInt('streak_at_schedule_change', streakSnapshot);
    }
  }

  /// Updates the weekly adherence target to match the user's active split schedule
  void updateWeeklyTarget(int target, {Iterable<String>? scheduledDays}) {
    if (scheduledDays != null && scheduledDays.isNotEmpty) {
      updateScheduledDays(scheduledDays);
      return;
    }
    if (target <= 0) {
      resetWeeklyTarget();
      return;
    }
    if (target != _dynamicWeeklyTarget) {
      _dynamicWeeklyTarget = target;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('weekly_target_count', target);
      });
      notifyListeners();
    }
  }

  /// Resets the weekly adherence target without erasing the user's selected training days
  Future<void> resetWeeklyTarget() async {
    final nextTarget =
        _scheduledWeekdays.isNotEmpty ? _scheduledWeekdays.length : 3;
    final changed = _dynamicWeeklyTarget != nextTarget;
    _dynamicWeeklyTarget = nextTarget;
    _reconcileInMemoryStreak(referenceNow: _referenceNow);
    if (changed) {
      notifyListeners();
    }
    final prefs = await SharedPreferences.getInstance();
    if (_scheduledWeekdays.isNotEmpty) {
      await prefs.setInt('weekly_target_count', nextTarget);
    } else {
      await prefs.remove('weekly_target_count');
    }
  }

  /// Explicitly clears the user's selected training schedule and resets the weekly target to default (3)
  Future<void> clearScheduledDays() async {
    final hadSchedule =
        _scheduledWeekdays.isNotEmpty || _dynamicWeeklyTarget != 3;
    _dynamicWeeklyTarget = 3;
    _scheduledWeekdays = {};
    _previousScheduledWeekdays = {};
    _scheduleEffectiveDate = null;
    _streakAtScheduleChange = 0;
    _reconcileInMemoryStreak(referenceNow: _referenceNow);
    if (hadSchedule) {
      notifyListeners();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('weekly_target_count');
    await prefs.remove('scheduled_workout_days');
    await prefs.remove('previous_scheduled_workout_days');
    await prefs.remove('schedule_effective_date');
    await prefs.remove('streak_at_schedule_change');
  }

  void _reconcileInMemoryStreak({DateTime? referenceNow}) {
    final normalizedDates =
        normalizeAndDeduplicateDates(_completedWorkoutDates);
    if (normalizedDates.isEmpty && _lastWorkoutDate == null) {
      _currentStreak = 0;
      _totalWorkouts = 0;
      return;
    }
    final calculated = calculateCurrentStreak(
      completedDates: normalizedDates,
      scheduledWeekdays: _scheduledWeekdays,
      referenceNow: referenceNow ?? _referenceNow,
      storedStreak: _currentStreak,
      lastWorkoutDate: _lastWorkoutDate,
      previousScheduledWeekdays: _previousScheduledWeekdays,
      scheduleEffectiveDate: _scheduleEffectiveDate,
      streakAtScheduleChange: _streakAtScheduleChange,
      frozenDates: _frozenDates,
    );
    final longest = calculateLongestStreak(
      completedDates: normalizedDates,
      scheduledWeekdays: _scheduledWeekdays,
    );
    _currentStreak = calculated;
    if (longest > _longestStreak) {
      _longestStreak = longest;
    }
    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }
  }

  /// Configures provider state directly for deterministic testing without Firestore
  @visibleForTesting
  void configureStreakStateForTesting({
    required Iterable<DateTime> completedDates,
    Iterable<String> scheduledDays = const [],
    int storedStreak = 0,
    int storedLongestStreak = 0,
    DateTime? lastWorkoutDate,
    DateTime? referenceNow,
  }) {
    _referenceNow = referenceNow;
    _previousScheduledWeekdays = {};
    _scheduleEffectiveDate = null;
    _streakAtScheduleChange = 0;
    _scheduledWeekdays = parseWeekdayNames(scheduledDays);
    if (_scheduledWeekdays.isNotEmpty) {
      _dynamicWeeklyTarget = _scheduledWeekdays.length;
      final canonicalNames = scheduledDayNames;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setStringList('scheduled_workout_days', canonicalNames);
        prefs.setInt('weekly_target_count', _dynamicWeeklyTarget);
      });
    } else {
      _dynamicWeeklyTarget = 3;
    }
    _lastWorkoutDate = lastWorkoutDate;
    final deduped = normalizeAndDeduplicateDates(completedDates);
    if (lastWorkoutDate != null) {
      deduped.add(normalizeLocalDate(lastWorkoutDate));
    }
    final sorted = deduped.toList()..sort();
    _completedWorkoutDates = sorted;
    _totalWorkouts = sorted.length;

    if (sorted.isEmpty) {
      _currentStreak = 0;
      _lastWorkoutDate = null;
      _longestStreak = storedLongestStreak;
      notifyListeners();
      return;
    }

    _currentStreak = calculateCurrentStreak(
      completedDates: sorted,
      scheduledWeekdays: _scheduledWeekdays,
      referenceNow: referenceNow,
      storedStreak: storedStreak,
      lastWorkoutDate: lastWorkoutDate,
    );
    _lastWorkoutDate ??= sorted.last;
    final calcLongest = calculateLongestStreak(
      completedDates: sorted,
      scheduledWeekdays: _scheduledWeekdays,
    );
    _longestStreak = [
      storedLongestStreak,
      calcLongest,
      _currentStreak,
    ].reduce((a, b) => a > b ? a : b);
    notifyListeners();
  }

  /// Pure schedule-aware current streak calculation:
  /// - Deduplicates completed workout dates by local calendar day.
  /// - Counts completed workout sessions (AI, predefined, or manual).
  /// - Planned rest days preserve the streak without incrementing it.
  /// - A scheduled workout day today that has not finished yet remains pending (does not reset streak).
  /// - Past scheduled workout days with no completed session break the streak.
  /// - Schedule changes apply prospectively from [scheduleEffectiveDate], preserving verified streaks prior to the change.
  /// - Stored streak is preserved only when verified by prior workout history (< today) and no missed scheduled days.
  static int calculateCurrentStreak({
    required Iterable<DateTime> completedDates,
    Set<int> scheduledWeekdays = const {},
    DateTime? referenceNow,
    int storedStreak = 0,
    DateTime? lastWorkoutDate,
    Set<int> previousScheduledWeekdays = const {},
    DateTime? scheduleEffectiveDate,
    int streakAtScheduleChange = 0,
    Set<DateTime> frozenDates = const {},
  }) {
    final today = normalizeLocalDate(referenceNow ?? DateTime.now());
    final normalizedDates = normalizeAndDeduplicateDates(completedDates)
      ..removeWhere((d) => d.isAfter(today));

    final DateTime? previousLast = lastWorkoutDate != null
        ? normalizeLocalDate(lastWorkoutDate)
        : null;
    if (previousLast != null && !previousLast.isAfter(today)) {
      normalizedDates.add(previousLast);
    }

    if (normalizedDates.isEmpty) {
      return 0;
    }

    final sortedDates = normalizedDates.toList()..sort();
    final earliestDate = sortedDates.first;
    final latestWorkoutDate = sortedDates.last;
    final DateTime? effectiveDay = scheduleEffectiveDate != null
        ? normalizeLocalDate(scheduleEffectiveDate)
        : null;

    int streak = 0;
    int workoutsAfterEffectiveDay = 0;

    // 1. Evaluate today:
    // If a workout was completed today, count it.
    // Otherwise today is either a pending scheduled workout day or a rest day — do not break!
    if (normalizedDates.contains(today)) {
      streak = 1;
      if (effectiveDay != null && today.isAfter(effectiveDay)) {
        workoutsAfterEffectiveDay = 1;
      }
    }

    // 2. Step backwards calendar day by calendar day starting from yesterday
    DateTime cursor = DateTime(today.year, today.month, today.day - 1);
    bool brokeAfterLatestWorkout = false;
    bool brokeInHistory = false;
    bool brokeAfterEffectiveDay = false;

    while (!cursor.isBefore(earliestDate)) {
      final bool isAfterEffective =
          effectiveDay == null || cursor.isAfter(effectiveDay);

      if (normalizedDates.contains(cursor)) {
        streak++;
        if (effectiveDay != null && cursor.isAfter(effectiveDay)) {
          workoutsAfterEffectiveDay++;
        }
      } else {
        final bool isMissedDay;
        if (isAfterEffective) {
          isMissedDay = scheduledWeekdays.isNotEmpty
              ? scheduledWeekdays.contains(cursor.weekday)
              : true;
        } else if (previousScheduledWeekdays.isNotEmpty) {
          isMissedDay = previousScheduledWeekdays.contains(cursor.weekday);
        } else if (streakAtScheduleChange > 0) {
          isMissedDay = false;
        } else {
          isMissedDay = scheduledWeekdays.isNotEmpty
              ? scheduledWeekdays.contains(cursor.weekday)
              : true;
        }

        // A streak freeze covers a missed day like a planned rest day.
        if (isMissedDay && !frozenDates.contains(cursor)) {
          if (isAfterEffective) {
            brokeAfterEffectiveDay = true;
          }
          if (cursor.isAfter(latestWorkoutDate)) {
            brokeAfterLatestWorkout = true;
          } else {
            brokeInHistory = true;
          }
          break;
        }
        // Else: cursor is a planned rest day -> preserve streak without incrementing
      }
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }

    // 3. Apply prospective schedule-change preservation when no scheduled day was missed after the change
    if (effectiveDay != null &&
        streakAtScheduleChange > 0 &&
        !brokeAfterEffectiveDay &&
        !brokeAfterLatestWorkout) {
      int candidateFromChange =
          streakAtScheduleChange + workoutsAfterEffectiveDay;
      if (today == effectiveDay &&
          normalizedDates.contains(today) &&
          previousLast != null &&
          previousLast.isBefore(today)) {
        candidateFromChange += 1;
      }
      if (candidateFromChange > streak) {
        streak = candidateFromChange;
      }
    }

    // 4. Preserve valid stored streak ONLY when anchored by verified workout history prior to today
    //    and no required workout day was missed.
    final bool hasVerifiedPriorHistory =
        previousLast != null && earliestDate.isBefore(today);

    if (storedStreak > streak &&
        hasVerifiedPriorHistory &&
        !brokeAfterLatestWorkout &&
        !brokeInHistory) {
      if (normalizedDates.contains(today) && previousLast.isBefore(today)) {
        return storedStreak + 1;
      }
      return storedStreak;
    }

    return streak;
  }

  /// Pure schedule-aware longest streak calculation across historical dates
  static int calculateLongestStreak({
    required Iterable<DateTime> completedDates,
    Set<int> scheduledWeekdays = const {},
  }) {
    final normalizedDates = normalizeAndDeduplicateDates(completedDates);
    if (normalizedDates.isEmpty) return 0;

    final sortedDates = normalizedDates.toList()..sort();
    final firstDate = sortedDates.first;
    final lastDate = sortedDates.last;

    int maxStreak = 0;
    int currentRun = 0;

    DateTime cursor = firstDate;
    while (!cursor.isAfter(lastDate)) {
      if (normalizedDates.contains(cursor)) {
        currentRun++;
        if (currentRun > maxStreak) {
          maxStreak = currentRun;
        }
      } else {
        final bool isMissedDay = scheduledWeekdays.isNotEmpty
            ? scheduledWeekdays.contains(cursor.weekday)
            : true;
        if (isMissedDay) {
          currentRun = 0;
        }
      }
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }

    return maxStreak;
  }

  int _calculateCurrentStreak(
    Set<DateTime> normalizedDates, {
    int storedStreak = 0,
  }) {
    return calculateCurrentStreak(
      completedDates: normalizedDates,
      scheduledWeekdays: _scheduledWeekdays,
      referenceNow: _referenceNow,
      storedStreak: storedStreak,
      lastWorkoutDate: _lastWorkoutDate,
      previousScheduledWeekdays: _previousScheduledWeekdays,
      scheduleEffectiveDate: _scheduleEffectiveDate,
      streakAtScheduleChange: _streakAtScheduleChange,
      frozenDates: _frozenDates,
    );
  }

  int _calculateLongestStreak(Set<DateTime> normalizedDates) {
    return calculateLongestStreak(
      completedDates: normalizedDates,
      scheduledWeekdays: _scheduledWeekdays,
    );
  }

  Future<void> loadStreakData() async {
    try {
      await restoreSavedScheduleFromPrefs();

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Read existing doc to get achievements and stored streak
      final doc = await FirebaseFirestore.instance
          .collection('statistics')
          .doc(user.uid)
          .get();

      int storedStreak = 0;
      if (doc.exists) {
        storedStreak = doc.data()?['currentStreak'] ?? 0;
        _longestStreak = doc.data()?['longestStreak'] ?? 0;
        _totalWorkouts = doc.data()?['totalWorkouts'] ?? 0;
        _unlockedAchievements =
            List<String>.from(doc.data()?['achievements'] ?? []);

        if (doc.data()?['lastWorkoutDate'] != null) {
          _lastWorkoutDate =
              (doc.data()!['lastWorkoutDate'] as Timestamp).toDate();
        } else {
          _lastWorkoutDate = null;
        }
      } else {
        _lastWorkoutDate = null;
      }

      // 2. Fetch all actual workout dates across canonical & legacy sources + schedule
      await fetchCompletedWorkoutDates();

      // 3. Recalculate streak dynamically from the deduplicated dates
      final normalizedDates =
          normalizeAndDeduplicateDates(_completedWorkoutDates);
      await _loadFrozenDates();
      await _applyStreakFreezeIfNeeded(normalizedDates, storedStreak);
      if (normalizedDates.isNotEmpty) {
        final calculatedStreak = _calculateCurrentStreak(
          normalizedDates,
          storedStreak: storedStreak,
        );
        final calculatedLongest = _calculateLongestStreak(normalizedDates);

        _currentStreak = calculatedStreak;
        if (calculatedLongest > _longestStreak) {
          _longestStreak = calculatedLongest;
        }
        if (_currentStreak > _longestStreak) {
          _longestStreak = _currentStreak;
        }

        final sortedDates = normalizedDates.toList()..sort();
        if (sortedDates.isNotEmpty) {
          _lastWorkoutDate = sortedDates.last;
        }
        _totalWorkouts = [
          _totalWorkouts,
          normalizedDates.length
        ].reduce((a, b) => a > b ? a : b);

        // Sync reconciled statistics back to Firestore
        await FirebaseFirestore.instance
            .collection('statistics')
            .doc(user.uid)
            .set({
          'currentStreak': _currentStreak,
          'longestStreak': _longestStreak,
          'lastWorkoutDate': _lastWorkoutDate != null
              ? Timestamp.fromDate(_lastWorkoutDate!)
              : null,
          'totalWorkouts': _totalWorkouts,
          'achievements': _unlockedAchievements,
        }, SetOptions(merge: true));
      } else {
        // Explicitly clear stale in-memory streak when no workout history exists
        _currentStreak = 0;
        _lastWorkoutDate = null;
        _totalWorkouts = 0;
        if (doc.exists && storedStreak != 0) {
          await FirebaseFirestore.instance
              .collection('statistics')
              .doc(user.uid)
              .set({
            'currentStreak': 0,
            'lastWorkoutDate': null,
            'totalWorkouts': 0,
          }, SetOptions(merge: true));
        }
      }

      // 4. Evening "streak at risk" nudge when today is an open workout day.
      try {
        final now = _referenceNow ?? DateTime.now();
        final isWorkoutDay = _scheduledWeekdays.isEmpty ||
            _scheduledWeekdays.contains(now.weekday);
        if (_currentStreak > 0 && isWorkoutDay && !hasWorkoutOnDate(now)) {
          await NotificationService().scheduleStreakAtRiskReminder(
            streak: _currentStreak,
            freezesLeft: freezesLeftThisMonth,
          );
        } else {
          await NotificationService().cancelStreakAtRiskReminder();
        }
      } catch (_) {}

      // 5. Update home widget
      await HomeWidget.saveWidgetData<int>('streak', _currentStreak);
      await HomeWidget.updateWidget(androidName: 'FitnessWidgetProvider');

      notifyListeners();
    } catch (e) {
      print('Error loading streak data: $e');
    }
  }

  /// True when the in-memory workout dates are missing or older than
  /// [datesRefreshInterval] and must be re-read before recalculating a streak.
  bool shouldRefetchDates(DateTime now) {
    final fetchedAt = _datesFetchedAt;
    if (fetchedAt == null) return true;
    return now.difference(fetchedAt) > datesRefreshInterval;
  }

  @visibleForTesting
  void markDatesFetchedForTesting(DateTime? at) => _datesFetchedAt = at;

  Future<void> updateStreak() async {
    try {
      User? user;
      try {
        user = FirebaseAuth.instance.currentUser;
      } catch (_) {}

      final now = _referenceNow ?? DateTime.now();
      final todayDate = normalizeLocalDate(now);
      final previousStreak = _currentStreak;
      final previousLastWorkoutDate = _lastWorkoutDate;
      final alreadyCompletedToday = hasWorkoutOnDate(todayDate);

      if (user != null && shouldRefetchDates(now)) {
        // Re-read history from canonical & legacy sources only when we have
        // not done so recently; otherwise today is simply added below.
        await fetchCompletedWorkoutDates();
      }
      final normalizedDates =
          normalizeAndDeduplicateDates(_completedWorkoutDates)..add(todayDate);
      final sortedDates = normalizedDates.toList()..sort();
      _completedWorkoutDates = sortedDates;

      _currentStreak = calculateCurrentStreak(
        completedDates: normalizedDates,
        scheduledWeekdays: _scheduledWeekdays,
        referenceNow: now,
        storedStreak: previousStreak,
        lastWorkoutDate: previousLastWorkoutDate ?? todayDate,
        previousScheduledWeekdays: _previousScheduledWeekdays,
        scheduleEffectiveDate: _scheduleEffectiveDate,
        streakAtScheduleChange: _streakAtScheduleChange,
        frozenDates: _frozenDates,
      );

      final calculatedLongest = _calculateLongestStreak(normalizedDates);
      if (calculatedLongest > _longestStreak) {
        _longestStreak = calculatedLongest;
      }
      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
      }

      _lastWorkoutDate = now;
      final nextCount =
          alreadyCompletedToday ? _totalWorkouts : _totalWorkouts + 1;
      _totalWorkouts = [
        nextCount,
        normalizedDates.length
      ].reduce((a, b) => a > b ? a : b);

      if (user == null) {
        notifyListeners();
        return;
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('statistics')
          .doc(user.uid)
          .set({
        'currentStreak': _currentStreak,
        'longestStreak': _longestStreak,
        'lastWorkoutDate': Timestamp.fromDate(now),
        'totalWorkouts': _totalWorkouts,
        'achievements': _unlockedAchievements,
      }, SetOptions(merge: true));

      // Check for new achievements
      await _checkAchievements();

      // Everything below is bookkeeping the user never waits for.
      unawaited(_runPostWorkoutSideEffects());

      notifyListeners();
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  /// Reminders, widget refresh and the review prompt. Runs detached so it
  /// never blocks (or fails) the workout flow.
  Future<void> _runPostWorkoutSideEffects() async {
    final currentStreak = _currentStreak;
    final longestStreak = _longestStreak;
    final weeklyDone = workoutsCompletedThisWeek;
    final target = weeklyTarget;
    final scheduledNames =
        _scheduledWeekdays.isNotEmpty ? scheduledDayNames : null;
    final notifications = NotificationService();

    Future<void> safely(String label, Future<void> Function() task) async {
      try {
        await task();
      } catch (e) {
        print('Post-workout task "$label" failed: $e');
      }
    }

    // Notification calls stay in their original order (they share the
    // notification plugin); only the home widget runs alongside them.
    await Future.wait([
      safely('notifications', () async {
        await NotificationProfile.saveStreak(
            current: currentStreak, longest: longestStreak);
        await notifications.scheduleStreakReminder();
        // Today's workout is done: no "streak at risk" nudge tonight.
        await notifications.cancelStreakAtRiskReminder();
        await notifications.scheduleWeeklyRecapNotification(
          workoutsThisWeek: weeklyDone,
          target: target,
          streak: currentStreak,
        );
        await notifications.advanceTodayWorkoutReminderIfScheduled(
            scheduledDays: scheduledNames);
        await notifications.scheduleWaterReminder();
        await notifications.scheduleReEngagementNotifications();
      }),
      safely('home widget', () async {
        await HomeWidget.saveWidgetData<int>('streak', currentStreak);
        await HomeWidget.updateWidget(androidName: 'FitnessWidgetProvider');
      }),
    ]);

    // In-app review at key milestones. Give the celebration UI a moment to
    // appear first so the system prompt doesn't land on top of the save.
    await safely('review prompt', () async {
      final shouldReview = await ReviewService().incrementWorkoutsLogged();
      if (shouldReview) {
        await Future<void>.delayed(const Duration(seconds: 2));
        await ReviewService().requestNativeReview();
        await ReviewService().markAsPrompted();
      }
    });
  }

  static DateTime? _extractDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  Future<void> fetchCompletedWorkoutDates() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final Set<DateTime> dates = {};
      var anyReadFailed = false;
      final db = FirebaseFirestore.instance;

      Future<QuerySnapshot<Map<String, dynamic>>?> read(
        String label,
        Query<Map<String, dynamic>> query,
      ) async {
        try {
          return await query.get();
        } catch (e) {
          anyReadFailed = true;
          print('Error fetching $label: $e');
          return null;
        }
      }

      // The four sources are independent, so read them at the same time.
      final results = await Future.wait([
        // 1. canonical users/{uid}/workout_sessions
        read('workout_sessions dates',
            db.collection('users').doc(user.uid).collection('workout_sessions')),
        // 2. finishedWorkouts (legacy & challenge/session workouts)
        read(
            'finishedWorkouts dates',
            db
                .collection('finishedWorkouts')
                .doc(user.uid)
                .collection('finishedWorkoutsData')),
        // 3. users/{uid}/workout_logs (manual lifts & exercise trackers)
        read('workout_logs dates',
            db.collection('users').doc(user.uid).collection('workout_logs')),
        // 4. active weekly plan in allWorkouts (scheduled training days)
        read(
            'allWorkouts plan days',
            db
                .collection('allWorkouts')
                .doc(user.uid)
                .collection('allWorkoutsData')),
      ]);
      final sessionsSnap = results[0];
      final finishedSnap = results[1];
      final logsSnap = results[2];
      final allWorkoutsSnap = results[3];

      if (sessionsSnap != null) {
        for (var doc in sessionsSnap.docs) {
          final data = doc.data();
          final status = data['status']?.toString().toLowerCase();
          if (status != null && status != 'completed' && status != 'partial') {
            continue;
          }
          final rawDate = data['completedAt'] ?? data['startedAt'];
          final date = _extractDateTime(rawDate);
          if (date != null) {
            dates.add(normalizeLocalDate(date));
          }
        }
      }

      if (finishedSnap != null) {
        for (var doc in finishedSnap.docs) {
          final date = _extractDateTime(doc.data()['dateTime']);
          if (date != null) {
            dates.add(normalizeLocalDate(date));
          }
        }
      }

      if (logsSnap != null) {
        for (var doc in logsSnap.docs) {
          final date = _extractDateTime(doc.data()['date']);
          if (date != null) {
            dates.add(normalizeLocalDate(date));
          }
        }
      }

      if (allWorkoutsSnap != null) {
        try {
          final Set<String> planDays = {};
          for (var doc in allWorkoutsSnap.docs) {
            final name = doc.data()['name']?.toString() ?? '';
            final match = RegExp(r'^\[(\w+)\]').firstMatch(name);
            if (match != null) {
              planDays.add(match.group(1)!);
            }
          }
          if (planDays.isNotEmpty) {
            _scheduledWeekdays = parseWeekdayNames(planDays);
            _dynamicWeeklyTarget = _scheduledWeekdays.length;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList(
                'scheduled_workout_days', scheduledDayNames);
            await prefs.setInt('weekly_target_count', _dynamicWeeklyTarget);
          }
        } catch (e) {
          print('Error syncing scheduled workout days: $e');
        }
      }

      // Only trust the cache when every source answered.
      _datesFetchedAt = anyReadFailed ? null : (_referenceNow ?? DateTime.now());

      if (_lastWorkoutDate != null) {
        dates.add(normalizeLocalDate(_lastWorkoutDate!));
      }

      final sorted = dates.toList()..sort();
      _completedWorkoutDates = sorted;
      notifyListeners();
    } catch (e) {
      print('Error fetching completed workout dates: $e');
    }
  }

  Future<void> _checkAchievements() async {
    // Rules live in badge_rules.dart (shared with the next-badge UI)
    final newAchievements = badgesToUnlock(
      alreadyUnlocked: _unlockedAchievements,
      totalWorkouts: _totalWorkouts,
      currentStreak: _currentStreak,
    );

    if (newAchievements.isNotEmpty) {
      _unlockedAchievements.addAll(newAchievements);
      _newlyUnlockedAchievements.addAll(newAchievements); // expose to UI
      notifyListeners();
      // Store updated achievements
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('statistics')
              .doc(user.uid)
              .update({
            'achievements': _unlockedAchievements,
          });
        }
      } catch (e) {
        print('Error saving achievements: $e');
      }
    }
  }

  Future<List<String>> getRecentlyUnlockedAchievements() async {
    return _unlockedAchievements;
  }

  // Weekly statistics
  Future<Map<String, dynamic>> getWeeklyStats() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return {'workouts': 0, 'calories': 0, 'water': 0};

      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      // Get workouts from last 7 days
      final workoutsSnapshot = await FirebaseFirestore.instance
          .collection('finishedWorkouts')
          .doc(user.uid)
          .collection('finishedWorkoutsData')
          .where('dateTime', isGreaterThan: Timestamp.fromDate(weekAgo))
          .get();

      // Get meals for calories
      final mealsSnapshot = await FirebaseFirestore.instance
          .collection('meals')
          .doc(user.uid)
          .collection('mealData')
          .where('dateTime', isGreaterThan: Timestamp.fromDate(weekAgo))
          .get();

      double totalCalories = 0;
      for (var doc in mealsSnapshot.docs) {
        final calories = doc.data()['calories'];
        if (calories != null) {
          totalCalories += (calories is int) ? calories.toDouble() : calories;
        }
      }

      // Get water data
      final waterSnapshot = await FirebaseFirestore.instance
          .collection('meals')
          .doc(user.uid)
          .collection('waterData')
          .where('dateTime', isGreaterThan: Timestamp.fromDate(weekAgo))
          .get();

      double totalWater = 0;
      for (var doc in waterSnapshot.docs) {
        final amount = doc.data()['amount'];
        if (amount != null) {
          totalWater += (amount is int) ? amount.toDouble() : amount;
        }
      }

      return {
        'workouts': workoutsSnapshot.docs.length,
        'calories': totalCalories.round(),
        'water': totalWater / 7, // Average per day
      };
    } catch (e) {
      print('Error getting weekly stats: $e');
      return {'workouts': 0, 'calories': 0, 'water': 0};
    }
  }

  bool get isMaintainingStreak => _currentStreak > 0;
}
