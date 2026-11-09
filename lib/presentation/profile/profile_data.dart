/// Pure (Flutter-free) helpers for the Profile tab: input validation for the
/// personal details a user can edit, and display helpers.
library;

class ProfileData {
  ProfileData._();

  static const int minAge = 13;
  static const int maxAge = 100;
  static const double minHeightCm = 100;
  static const double maxHeightCm = 250;
  static const int maxNameLength = 40;

  static const String male = 'Male';
  static const String female = 'Female';
  static const List<String> genders = [male, female];

  /// Error message or null. [label] is used in the message ("First name").
  static String? validateName(String? raw, String label,
      {bool required = true}) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return required ? 'Enter your ${label.toLowerCase()}' : null;
    if (text.length > maxNameLength) {
      return '$label must be $maxNameLength characters or fewer';
    }
    return null;
  }

  /// Whole number of years, or null when [raw] is not one.
  static int? parseAge(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  static String? validateAge(String? raw) {
    final age = parseAge(raw);
    if (age == null) return 'Enter your age in years';
    if (age < minAge || age > maxAge) {
      return 'Age must be between $minAge and $maxAge';
    }
    return null;
  }

  /// Height in cm; accepts a decimal comma.
  static double? parseHeight(String? raw) {
    final text = (raw ?? '').trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    final v = double.tryParse(text);
    if (v == null || v.isNaN || v.isInfinite) return null;
    return v;
  }

  static String? validateHeight(String? raw) {
    final h = parseHeight(raw);
    if (h == null) return 'Enter your height in cm, e.g. 175';
    if (h < minHeightCm || h > maxHeightCm) {
      return 'Height must be between ${minHeightCm.toInt()} and '
          '${maxHeightCm.toInt()} cm';
    }
    return null;
  }

  static String? validateGender(String? value) =>
      genders.contains(value) ? null : 'Choose your gender';

  /// "AB" from "Ann" + "Bell"; "?" when both are empty.
  static String initials(String firstName, String surname) {
    final first = firstName.trim();
    final last = surname.trim();
    final a = first.isNotEmpty ? first[0].toUpperCase() : '';
    final b = last.isNotEmpty ? last[0].toUpperCase() : '';
    return '$a$b'.isEmpty ? '?' : '$a$b';
  }

  /// Name shown when the user has not stored a first name yet. Shared by the
  /// Home greeting and the Profile tab so they never disagree.
  static const String fallbackName = 'Champ';

  /// Full display name; falls back to [fallbackName] when nothing is stored.
  static String displayName(dynamic firstName, dynamic surname) {
    final full = '${(firstName ?? '').toString().trim()} '
            '${(surname ?? '').toString().trim()}'
        .trim();
    return full.isEmpty ? fallbackName : full;
  }

  /// Where support requests go. One constant so the address, the mail link
  /// and the fallback messages can never drift apart.
  static const String supportEmail = 'buddyspps204@gmail.com';

  ///
  /// The subject is percent-encoded by hand: `queryParameters` writes spaces
  /// as '+', which several mail apps show literally.
  static Uri supportMailUri() => Uri(
        scheme: 'mailto',
        path: supportEmail,
        query: 'subject=${Uri.encodeComponent('Support Request - Fitness App')}',
      );

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// "Nov 2026", or an em dash when the join date is unknown.
  static String memberSinceLabel(DateTime? joined) =>
      joined == null ? '\u2014' : '${_months[joined.month - 1]} ${joined.year}';

  /// "1.0.10 (32)", or just the version when there is no build number.
  static String versionLabel(String version, String buildNumber) {
    if (version.isEmpty) return '';
    return buildNumber.isEmpty ? version : '$version ($buildNumber)';
  }
}

/// Which reminder switches are on, for the one-line summary on the Profile
/// tab. The keys and defaults mirror the switches on the reminders screen
/// (`GymAlarmSettingWidget`), which stays the single place that writes them.
class ReminderSummary {
  ReminderSummary._();

  /// SharedPreferences key -> value used when the user never touched it.
  static const Map<String, bool> defaults = {
    'gym_alarm_enabled': false,
    'notif_workout_reminders_enabled': false,
    'notif_streak_reminders_enabled': true,
    'notif_recovery_reminders_enabled': false,
    'notif_water_reminders_enabled': false,
    'notif_weekly_recap_enabled': true,
  };

  static int get total => defaults.length;

  /// Number of switches that are on, reading each through [read] (which
  /// returns null for a key that was never saved).
  static int enabledCount(bool? Function(String key) read) {
    var count = 0;
    defaults.forEach((key, fallback) {
      if (read(key) ?? fallback) count++;
    });
    return count;
  }

  /// "All reminders off" or "3 of 6 on".
  static String label(int enabled) =>
      enabled <= 0 ? 'All reminders off' : '$enabled of $total on';
}
