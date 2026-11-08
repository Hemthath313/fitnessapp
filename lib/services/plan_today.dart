/// Splits the weekday groups of the weekly plan into "today" and the days
/// that come next, so the plan can lead with today's workout.
class PlanDaySplit {
  const PlanDaySplit({required this.today, required this.later});

  /// Today's day name when it is part of the plan, otherwise null (rest day).
  final String? today;

  /// Remaining plan days, in the order they come up (starting tomorrow and
  /// wrapping past Sunday).
  final List<String> later;

  /// The next day to train: today's if planned, else the first of [later].
  String? get nextUp => today ?? (later.isEmpty ? null : later.first);
}

const List<String> kWeekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Day names in the plan that are not weekdays (e.g. body-part labels) are
/// appended after the weekdays, in their given order.
PlanDaySplit splitPlanDays(Iterable<String> planDays, DateTime now) {
  final set = planDays.toSet();
  final todayName = kWeekdayNames[now.weekday - 1];
  final later = <String>[];
  for (var i = 1; i <= 7; i++) {
    final name = kWeekdayNames[(now.weekday - 1 + i) % 7];
    if (name != todayName && set.contains(name)) later.add(name);
  }
  for (final d in planDays) {
    if (!kWeekdayNames.contains(d) && !later.contains(d)) later.add(d);
  }
  return PlanDaySplit(
    today: set.contains(todayName) ? todayName : null,
    later: later,
  );
}
