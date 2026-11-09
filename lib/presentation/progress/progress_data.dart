/// Pure (Flutter-free) helpers for the Progress tab: dated weight and
/// measurement entries, range filtering, deltas and input validation.
///
/// Weight and measurements used to be keyed by month number only, so two
/// weigh-ins in the same month (or the same month in two years) overwrote each
/// other and the charts had to invent data. Everything here works on real
/// dates instead.
library;

/// A single dated reading (weight in kg, or a body measurement in cm).
class TimedValue {
  final DateTime date;
  final double value;

  /// Firestore document id, when the reading came from the database.
  final String? id;

  const TimedValue(this.date, this.value, {this.id});

  @override
  String toString() => 'TimedValue($date, $value)';
}

/// Headline numbers for a window of weigh-ins.
class WeightSummary {
  final double start;
  final double latest;
  final double lowest;
  final double highest;
  final double change;

  /// Average change per week; null when the readings span less than a week
  /// (too short to say anything honest).
  final double? perWeek;

  const WeightSummary({
    required this.start,
    required this.latest,
    required this.lowest,
    required this.highest,
    required this.change,
    required this.perWeek,
  });
}

/// The time windows offered by the range selector on the Progress tab.
enum ProgressRange { week, month, threeMonths, year }

extension ProgressRangeX on ProgressRange {
  String get label {
    switch (this) {
      case ProgressRange.week:
        return 'Week';
      case ProgressRange.month:
        return 'Month';
      case ProgressRange.threeMonths:
        return '3 Months';
      case ProgressRange.year:
        return 'Year';
    }
  }

  /// Length of the window in days (the chart's x axis runs 0..days).
  int get days {
    switch (this) {
      case ProgressRange.week:
        return 7;
      case ProgressRange.month:
        return 30;
      case ProgressRange.threeMonths:
        return 90;
      case ProgressRange.year:
        return 365;
    }
  }

  /// Start of the window: midnight of the first day, so the window covers
  /// [days] calendar days including today.
  DateTime startFor(DateTime now) {
    // Calendar arithmetic (not Duration) so daylight-saving changes can't
    // shift the window start by an hour.
    return DateTime(now.year, now.month, now.day - (days - 1));
  }
}

class ProgressData {
  ProgressData._();

  /// yyyymmdd as an int (e.g. 20261109) - one entry per calendar day.
  static int dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  /// True when [date]'s day is the same as or after the newest entry's day
  /// (or there are no entries) - i.e. it would become the current weight.
  static bool isOnOrAfterLatest(List<TimedValue> entries, DateTime date) {
    if (entries.isEmpty) return true;
    final latest = sorted(entries).last.date;
    return dayKey(date) >= dayKey(latest);
  }

  /// Timestamp to store for a picked calendar day: today keeps the current
  /// time of day, a past day is stamped at noon so it stays on that day.
  static DateTime entryTimestamp(DateTime pickedDay, DateTime now) {
    if (dayKey(pickedDay) == dayKey(now)) return now;
    return DateTime(pickedDay.year, pickedDay.month, pickedDay.day, 12);
  }

  /// "9 Nov 2026"
  static String formatDay(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  /// Old entries only stored a month number (1-12). Treat them as the 1st of
  /// that month; a month that is still in the future this year must belong to
  /// last year.
  static DateTime legacyMonthToDate(int month, DateTime now) {
    final m = month < 1 ? 1 : (month > 12 ? 12 : month);
    final year = m > now.month ? now.year - 1 : now.year;
    return DateTime(year, m, 1);
  }

  /// Entries sorted oldest -> newest.
  static List<TimedValue> sorted(Iterable<TimedValue> entries) {
    final list = List<TimedValue>.from(entries);
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// Entries that fall inside [range] ending today, oldest -> newest.
  static List<TimedValue> inRange(
    Iterable<TimedValue> entries,
    ProgressRange range,
    DateTime now,
  ) {
    final start = range.startFor(now);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return sorted(
      entries.where((e) => !e.date.isBefore(start) && !e.date.isAfter(end)),
    );
  }

  /// Summary of [entries] (already limited to one window), or null when there
  /// are fewer than two readings.
  static WeightSummary? summarize(Iterable<TimedValue> entries) {
    final list = sorted(entries);
    if (list.length < 2) return null;
    var lowest = list.first.value;
    var highest = list.first.value;
    for (final e in list) {
      if (e.value < lowest) lowest = e.value;
      if (e.value > highest) highest = e.value;
    }
    final change = list.last.value - list.first.value;
    final spanDays = list.last.date.difference(list.first.date).inMinutes / (60 * 24);
    return WeightSummary(
      start: list.first.value,
      latest: list.last.value,
      lowest: lowest,
      highest: highest,
      change: change,
      perWeek: spanDays >= 7 ? change / (spanDays / 7) : null,
    );
  }

  /// Change from the first to the last entry in the window, or null when there
  /// are fewer than two readings (no honest delta can be computed).
  static double? deltaInRange(
    Iterable<TimedValue> entries,
    ProgressRange range,
    DateTime now,
  ) {
    final list = inRange(entries, range, now);
    if (list.length < 2) return null;
    return list.last.value - list.first.value;
  }

  /// Chart x position: whole + fractional days since the window start.
  static double xFor(DateTime date, ProgressRange range, DateTime now) {
    final start = range.startFor(now);
    // Compare as UTC so a DST change between the two dates adds no extra hour.
    final a = DateTime.utc(date.year, date.month, date.day, date.hour, date.minute);
    final b = DateTime.utc(start.year, start.month, start.day);
    return a.difference(b).inMinutes / (60 * 24);
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// X-axis label for a chart position.
  static String axisLabel(double x, ProgressRange range, DateTime now) {
    final start = range.startFor(now);
    final date = DateTime(start.year, start.month, start.day + x.round());
    switch (range) {
      case ProgressRange.week:
        return _weekdays[date.weekday - 1];
      case ProgressRange.month:
        return '${date.day} ${_months[date.month - 1]}';
      case ProgressRange.threeMonths:
      case ProgressRange.year:
        return _months[date.month - 1];
    }
  }

  /// Distance between x-axis labels, in days.
  static double axisInterval(ProgressRange range) {
    switch (range) {
      case ProgressRange.week:
        return 1;
      case ProgressRange.month:
        return 10;
      case ProgressRange.threeMonths:
        return 30;
      case ProgressRange.year:
        return 60;
    }
  }

  // ---------------------------------------------------------------- input

  static const double minWeightKg = 20;
  static const double maxWeightKg = 400;
  static const double minMeasurementCm = 5;
  static const double maxMeasurementCm = 300;

  /// Parses user text into a number; accepts a decimal comma.
  static double? parseNumber(String? raw) {
    if (raw == null) return null;
    final text = raw.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null || value.isNaN || value.isInfinite) return null;
    return value;
  }

  /// Like [validateWeight] but worded for the optional goal weight.
  static String? validateGoalWeight(String? raw) {
    final v = parseNumber(raw);
    if (v == null) return 'Enter your goal weight in kg, e.g. 70';
    if (v < minWeightKg || v > maxWeightKg) {
      return 'Goal weight must be between ${minWeightKg.toInt()} and '
          '${maxWeightKg.toInt()} kg';
    }
    return null;
  }

  /// "5.0 kg to lose", "2.5 kg to gain" or "Goal reached".
  static String goalProgressText(double current, double goal) {
    final diff = current - goal;
    if (diff.abs() < 0.05) return 'Goal reached';
    return diff > 0
        ? '${diff.toStringAsFixed(1)} kg to lose'
        : '${(-diff).toStringAsFixed(1)} kg to gain';
  }

  /// Returns an error message, or null when [raw] is a valid weight in kg.
  static String? validateWeight(String? raw) {
    final v = parseNumber(raw);
    if (v == null) return 'Enter your weight in kg, e.g. 72.5';
    if (v < minWeightKg || v > maxWeightKg) {
      return 'Weight must be between ${minWeightKg.toInt()} and '
          '${maxWeightKg.toInt()} kg';
    }
    return null;
  }

  /// Returns an error message, or null when [raw] is a valid measurement in
  /// cm. A blank field is valid when [allowBlank] is true (keep the old value).
  static String? validateMeasurement(
    String? raw,
    String name, {
    bool allowBlank = false,
  }) {
    final blank = raw == null || raw.trim().isEmpty;
    if (blank) return allowBlank ? null : 'Enter your $name in cm';
    final v = parseNumber(raw);
    if (v == null) return 'Enter a valid number for $name';
    if (v < minMeasurementCm || v > maxMeasurementCm) {
      return '$name must be between ${minMeasurementCm.toInt()} and '
          '${maxMeasurementCm.toInt()} cm';
    }
    return null;
  }

  /// Text to prefill into a numeric field: empty when there is no real value.
  static String prefill(dynamic value) {
    if (value is num && value > 0) {
      return value == value.roundToDouble()
          ? value.toStringAsFixed(0)
          : value.toString();
    }
    return '';
  }
}
