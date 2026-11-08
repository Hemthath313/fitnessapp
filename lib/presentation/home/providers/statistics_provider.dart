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

        if (isMissedDay) {
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

      // 4. Update home widget
      await HomeWidget.saveWidgetData<int>('streak', _currentStreak);
      await HomeWidget.updateWidget(androidName: 'FitnessWidgetProvider');

      notifyListeners();
    } catch (e) {
      print('Error loading streak data: $e');
    }
  }

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

      if (user != null) {
        // Re-fetch all dates from canonical & legacy sources and ensure today is included
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

      // Cache streak values so reminder copy reflects the current run
      await NotificationProfile.saveStreak(
          current: _currentStreak, longest: _longestStreak);

      // Schedule notification reminder to maintain streak
      await NotificationService().scheduleStreakReminder();

      // Sunday 7 PM "week in review" with this week's real numbers
      await NotificationService().scheduleWeeklyRecapNotification(
        workoutsThisWeek: workoutsCompletedThisWeek,
        target: weeklyTarget,
        streak: _currentStreak,
      );

      // Advance today's workout day reminder by 7 days if scheduled (without canceling other days)
      await NotificationService().advanceTodayWorkoutReminderIfScheduled(
        scheduledDays: _scheduledWeekdays.isNotEmpty ? scheduledDayNames : null,
      );

      // Schedule water reminder (user-chosen time, default 6 PM)
      await NotificationService().scheduleWaterReminder();

      // Reset re-engagement timers (3, 7, 14 days)
      await NotificationService().scheduleReEngagementNotifications();

      // Update Home Screen Widget
      await HomeWidget.saveWidgetData<int>('streak', _currentStreak);
      await HomeWidget.updateWidget(androidName: 'FitnessWidgetProvider');

      // Trigger in-app review at key milestones
      try {
        final shouldReview = await ReviewService().incrementWorkoutsLogged();
        if (shouldReview) {
          await ReviewService().requestNativeReview();
          await ReviewService().markAsPrompted();
        }
      } catch (e) {
        print('Error handling review prompt in StatisticsProvider: $e');
      }

      notifyListeners();
    } catch (e) {
      print('Error updating streak: $e');
    }
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

      // 1. Fetch from canonical users/{uid}/workout_sessions
      try {
        final sessionsSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workout_sessions')
            .get();

        for (var doc in sessionsSnap.docs) {
          final data = doc.data();
          final status = data['status']?.toString().toLowerCase();
          if (status != null &&
              status != 'completed' &&
              status != 'partial') {
            continue;
          }
          final rawDate = data['completedAt'] ?? data['startedAt'];
          final date = _extractDateTime(rawDate);
          if (date != null) {
            dates.add(normalizeLocalDate(date));
          }
        }
      } catch (e) {
        print('Error fetching workout_sessions dates: $e');
      }

      // 2. Fetch from finishedWorkouts (legacy & challenge/session workouts)
      try {
        final finishedSnap = await FirebaseFirestore.instance
            .collection('finishedWorkouts')
            .doc(user.uid)
            .collection('finishedWorkoutsData')
            .get();

        for (var doc in finishedSnap.docs) {
          final date = _extractDateTime(doc.data()['dateTime']);
          if (date != null) {
            dates.add(normalizeLocalDate(date));
          }
        }
      } catch (e) {
        print('Error fetching finishedWorkouts dates: $e');
      }

      // 3. Fetch from users/{uid}/workout_logs (manual lifts & exercise trackers)
      try {
        final logsSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workout_logs')
            .get();

        for (var doc in logsSnap.docs) {
          final date = _extractDateTime(doc.data()['date']);
          if (date != null) {
            dates.add(normalizeLocalDate(date));
          }
        }
      } catch (e) {
        print('Error fetching workout_logs dates: $e');
      }

      // 4. Sync scheduled training days from active weekly plan in allWorkouts if present
      try {
        final allWorkoutsSnap = await FirebaseFirestore.instance
            .collection('allWorkouts')
            .doc(user.uid)
            .collection('allWorkoutsData')
            .get();

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
