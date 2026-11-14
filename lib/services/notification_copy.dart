import 'package:shared_preferences/shared_preferences.dart';

/// Title/body pair for a local notification.
class NotificationText {
  final String title;
  final String body;
  const NotificationText(this.title, this.body);

  @override
  bool operator ==(Object other) =>
      other is NotificationText && other.title == title && other.body == body;

  @override
  int get hashCode => Object.hash(title, body);

  @override
  String toString() => '$title | $body';
}

/// Per-user facts cached in SharedPreferences so the (context-free)
/// notification service can personalise copy at schedule time.
class NotificationProfile {
  static const nameKey = 'notif_first_name';
  static const streakKey = 'notif_current_streak';
  static const longestStreakKey = 'notif_longest_streak';
  static const waterHourKey = 'notif_water_hour';
  static const waterMinuteKey = 'notif_water_minute';

  final String firstName;
  final int currentStreak;
  final int longestStreak;

  const NotificationProfile({
    this.firstName = '',
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  static Future<NotificationProfile> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return NotificationProfile(
        firstName: prefs.getString(nameKey) ?? '',
        currentStreak: prefs.getInt(streakKey) ?? 0,
        longestStreak: prefs.getInt(longestStreakKey) ?? 0,
      );
    } catch (_) {
      return const NotificationProfile();
    }
  }

  /// Cache the user's first name (takes the first word of [fullName]).
  static Future<void> saveName(String? fullName) async {
    final first = NotificationCopy.firstNameOf(fullName);
    if (first.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(nameKey, first);
    } catch (_) {}
  }

  static Future<void> saveStreak({
    required int current,
    required int longest,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(streakKey, current < 0 ? 0 : current);
      await prefs.setInt(longestStreakKey, longest < 0 ? 0 : longest);
    } catch (_) {}
  }
}

/// Pure, deterministic notification copy. Tone rules: encouraging and
/// progress-framed, never guilt ("we miss you", "don't lose", sad emoji).
class NotificationCopy {
  const NotificationCopy._();

  static String firstNameOf(String? fullName) {
    final trimmed = (fullName ?? '').trim();
    if (trimmed.isEmpty) return '';
    final first = trimmed.split(RegExp(r'\s+')).first;
    // Ignore placeholder values stored for guests/new accounts.
    final lower = first.toLowerCase();
    if (lower == 'user' || lower == 'guest' || lower == 'null') return '';
    return first[0].toUpperCase() + first.substring(1);
  }

  /// Prefixes [text] with "Name, " or capitalises it when there is no name.
  static String _say(String name, String text) {
    if (name.isEmpty) return text[0].toUpperCase() + text.substring(1);
    return '$name, $text';
  }

  /// 48h streak nudge. Scheduled after every workout so [streak] is current.
  static NotificationText streakReminder({
    required String name,
    required int streak,
    required int longest,
  }) {
    if (streak >= 2) {
      return NotificationText(
        '$streak-day streak, nice work 🔥',
        _say(name, "a quick session today keeps your $streak-day run going."),
      );
    }
    if (streak == 1) {
      return NotificationText(
        'Day 2 is where habits start 🔥',
        _say(name, "one more session and you've got a streak going."),
      );
    }
    return NotificationText(
      'Ready when you are 🔥',
      _say(name, 'a short workout today starts a fresh streak.'),
    );
  }

  /// Evening nudge on a workout day that is still open while a streak is
  /// running. [freezesLeft] tells the user a freeze would cover them.
  static NotificationText streakAtRisk({
    required String name,
    required int streak,
    required int freezesLeft,
  }) {
    final dayWord = streak == 1 ? 'day' : 'days';
    return NotificationText(
      'Keep your $streak-$dayWord streak 🔥',
      freezesLeft > 0
          ? _say(name, 'a 20-minute session tonight keeps it going. A freeze can cover today, but why spend it?')
          : _say(name, 'a 20-minute session tonight keeps your streak alive.'),
    );
  }

  /// Comeback nudges after [days] (3, 7 or 14) of silence. Frames what the
  /// user has already built instead of what they might lose.
  static NotificationText comeback({
    required int days,
    required String name,
    required int longest,
  }) {
    final hasBest = longest >= 3;
    switch (days) {
      case 3:
        return NotificationText(
          'A quick one today? 💪',
          hasBest
              ? _say(name,
                  'your $longest-day best is still on the board. A 15-minute session counts.')
              : _say(name, 'a 15-minute session is enough to get moving again.'),
        );
      case 7:
        return NotificationText(
          'Your plan is ready when you are',
          hasBest
              ? _say(name,
                  "you've hit a $longest-day streak before. Start small today and build back up.")
              : _say(name, 'even a 5-minute stretch gets you moving again.'),
        );
      default:
        return NotificationText(
          'Fresh start, light session 🌱',
          hasBest
              ? _say(name,
                  'your $longest-day best shows what you can do. Ease back in with a light workout.')
              : _say(name,
                  'pick a light workout and ease back in at your own pace.'),
        );
    }
  }

  /// Time-neutral water reminder (the user can pick the time).
  static NotificationText water({required String name}) {
    return NotificationText(
      '💧 Water check',
      _say(name, "how's your water today? Log a glass to stay on target."),
    );
  }

  /// Recurring weekly notification: a streak would go stale, so day/name only.
  static NotificationText workoutDay({
    required String day,
    required String name,
  }) {
    return NotificationText(
      '$day workout 💪',
      _say(name, 'your session is ready. Open Gym Buddy to track your lifts.'),
    );
  }

  /// One-shot Sunday evening recap, scheduled after a workout so the numbers
  /// are those of the week it fires in.
  static NotificationText weeklyRecap({
    required String name,
    required int workouts,
    required int target,
    required int streak,
  }) {
    final plural = workouts == 1 ? 'workout' : 'workouts';
    if (workouts >= target) {
      return NotificationText(
        'Week complete 🎉',
        _say(name, 'you hit $workouts of $target workouts. See your week in review.'),
      );
    }
    final streakBit = streak >= 2 ? ' $streak-day streak going.' : '';
    return NotificationText(
      'Your week in review',
      _say(name, '$workouts $plural this week.$streakBit Tap to see how it went.'),
    );
  }

  static NotificationText restDay({required String name}) {
    return NotificationText(
      'Rest day 🧘',
      _say(name, 'recovery is part of the plan. Stay hydrated and eat well.'),
    );
  }
}
