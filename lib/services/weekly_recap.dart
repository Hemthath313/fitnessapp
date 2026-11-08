/// Pure weekly-recap computation (no Flutter, no providers) so it is easy to
/// unit test. The recap covers Mon–Sun and is shown on Sunday (the week that
/// is ending) and Monday (the week that just ended).
class WeeklyRecap {
  const WeeklyRecap({
    required this.weekStart,
    required this.title,
    required this.activeDays,
    required this.workouts,
    required this.target,
    required this.previousWorkouts,
    required this.streak,
    required this.goalHit,
    required this.headline,
    required this.message,
    this.deltaText,
    this.streakText,
  });

  /// Monday (local midnight) of the recapped week.
  final DateTime weekStart;
  final String title;

  /// Mon..Sun, true when a workout was logged that day.
  final List<bool> activeDays;
  final int workouts;
  final int target;
  final int previousWorkouts;
  final int streak;
  final bool goalHit;
  final String headline;
  final String message;

  /// "+2 vs the week before" / "Same as the week before"; null when there is
  /// nothing positive to say (we never show a drop).
  final String? deltaText;
  final String? streakText;

  /// Sunday and Monday are recap days.
  static bool isRecapDay(DateTime now) =>
      now.weekday == DateTime.sunday || now.weekday == DateTime.monday;

  /// Monday of the week to recap for [now], or null when it is not a recap day.
  static DateTime? recapWeekStart(DateTime now) {
    if (!isRecapDay(now)) return null;
    final today = DateTime(now.year, now.month, now.day);
    final thisMonday = DateTime(today.year, today.month, today.day - (today.weekday - 1));
    return now.weekday == DateTime.sunday
        ? thisMonday
        : DateTime(thisMonday.year, thisMonday.month, thisMonday.day - 7);
  }

  /// Builds the recap, or returns null when it is not a recap day or the user
  /// logged nothing that week (an empty recap would only feel like a scolding).
  static WeeklyRecap? build({
    required DateTime now,
    required bool Function(DateTime day) hasWorkoutOn,
    required int target,
    required int streak,
  }) {
    final start = recapWeekStart(now);
    if (start == null) return null;

    List<bool> week(DateTime monday) => List<bool>.generate(
          7,
          (i) => hasWorkoutOn(DateTime(monday.year, monday.month, monday.day + i)),
        );

    final days = week(start);
    final workouts = days.where((d) => d).length;
    if (workouts == 0) return null;

    final prevStart = DateTime(start.year, start.month, start.day - 7);
    final prev = week(prevStart).where((d) => d).length;

    final safeTarget = target > 0 ? target : 3;
    final goalHit = workouts >= safeTarget;
    final endingToday = now.weekday == DateTime.sunday;

    final String headline = goalHit
        ? 'Goal hit: $workouts of $safeTarget workouts'
        : '$workouts of $safeTarget workouts';

    final String message;
    if (goalHit) {
      message = 'Nice work. Rest up and go again.';
    } else if (endingToday) {
      final left = safeTarget - workouts;
      message = left == 1
          ? 'One more session today would complete your week.'
          : 'A fresh week starts tomorrow.';
    } else {
      message = 'A fresh week starts today.';
    }

    String? delta;
    if (prev > 0 && workouts > prev) {
      delta = '+${workouts - prev} vs the week before';
    } else if (prev > 0 && workouts == prev) {
      delta = 'Same as the week before';
    }

    return WeeklyRecap(
      weekStart: start,
      title: endingToday ? 'Your week in review' : 'Last week in review',
      activeDays: days,
      workouts: workouts,
      target: safeTarget,
      previousWorkouts: prev,
      streak: streak,
      goalHit: goalHit,
      headline: headline,
      message: message,
      deltaText: delta,
      streakText: streak >= 2 ? '$streak-day streak' : null,
    );
  }
}
