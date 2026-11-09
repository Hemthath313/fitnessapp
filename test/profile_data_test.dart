import 'package:fitness_app/presentation/profile/profile_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('names', () {
    test('first name is required, surname is optional', () {
      expect(ProfileData.validateName('', 'First name'), isNotNull);
      expect(ProfileData.validateName('   ', 'First name'), isNotNull);
      expect(ProfileData.validateName(null, 'First name'), isNotNull);
      expect(ProfileData.validateName('', 'Surname', required: false), isNull);
      expect(ProfileData.validateName('Ann', 'First name'), isNull);
    });

    test('over-long names are rejected and the message names the field', () {
      final long = 'a' * 41;
      final error = ProfileData.validateName(long, 'First name');
      expect(error, contains('First name'));
      expect(ProfileData.validateName('a' * 40, 'First name'), isNull);
    });

    test('required message is lower-cased after the verb', () {
      expect(ProfileData.validateName('', 'First name'),
          'Enter your first name');
    });
  });

  group('age', () {
    test('accepts whole years inside the range', () {
      expect(ProfileData.validateAge('13'), isNull);
      expect(ProfileData.validateAge('30'), isNull);
      expect(ProfileData.validateAge('100'), isNull);
    });

    test('rejects blank, text, decimals and out-of-range values', () {
      expect(ProfileData.validateAge(''), isNotNull);
      expect(ProfileData.validateAge(null), isNotNull);
      expect(ProfileData.validateAge('abc'), isNotNull);
      expect(ProfileData.validateAge('30.5'), isNotNull);
      expect(ProfileData.validateAge('12'), isNotNull);
      expect(ProfileData.validateAge('101'), isNotNull);
    });

    test('parseAge', () {
      expect(ProfileData.parseAge(' 42 '), 42);
      expect(ProfileData.parseAge(''), isNull);
    });
  });

  group('height', () {
    test('accepts centimetres inside the range, including a decimal comma', () {
      expect(ProfileData.validateHeight('175'), isNull);
      expect(ProfileData.validateHeight('175.5'), isNull);
      expect(ProfileData.validateHeight('175,5'), isNull);
      expect(ProfileData.validateHeight('100'), isNull);
      expect(ProfileData.validateHeight('250'), isNull);
    });

    test('rejects blank, text and out-of-range values', () {
      expect(ProfileData.validateHeight(''), isNotNull);
      expect(ProfileData.validateHeight('tall'), isNotNull);
      expect(ProfileData.validateHeight('99.9'), isNotNull);
      expect(ProfileData.validateHeight('251'), isNotNull);
      // A user typing feet by mistake gets a clear error, not a silent save.
      expect(ProfileData.validateHeight('5.9'), isNotNull);
    });

    test('parseHeight', () {
      expect(ProfileData.parseHeight('172,5'), 172.5);
      expect(ProfileData.parseHeight(''), isNull);
    });
  });

  group('gender', () {
    test('only the two stored values are valid', () {
      expect(ProfileData.validateGender('Male'), isNull);
      expect(ProfileData.validateGender('Female'), isNull);
      expect(ProfileData.validateGender(null), isNotNull);
      expect(ProfileData.validateGender(''), isNotNull);
      expect(ProfileData.validateGender('male'), isNotNull);
    });
  });

  group('display helpers', () {
    test('initials', () {
      expect(ProfileData.initials('ann', 'bell'), 'AB');
      expect(ProfileData.initials('Ann', ''), 'A');
      expect(ProfileData.initials('  ', '  '), '?');
    });

    test('displayName falls back to the shared name and trims', () {
      expect(ProfileData.displayName('Ann', 'Bell'), 'Ann Bell');
      expect(ProfileData.displayName('Ann', ''), 'Ann');
      expect(ProfileData.displayName(null, null), ProfileData.fallbackName);
      expect(ProfileData.displayName('  ', ' '), ProfileData.fallbackName);
      expect(ProfileData.fallbackName, 'Champ');
    });

    test('versionLabel', () {
      expect(ProfileData.versionLabel('1.0.10', '32'), '1.0.10 (32)');
      expect(ProfileData.versionLabel('1.0.10', ''), '1.0.10');
      expect(ProfileData.versionLabel('', '32'), '');
    });
  });

  group('ReminderSummary', () {
    test('never-saved switches use their defaults (streak and recap on)', () {
      expect(ReminderSummary.enabledCount((_) => null), 2);
      expect(ReminderSummary.total, 6);
    });

    test('counts switches the user turned on', () {
      final saved = <String, bool>{
        'gym_alarm_enabled': true,
        'notif_water_reminders_enabled': true,
      };
      expect(ReminderSummary.enabledCount((k) => saved[k]), 4);
    });

    test('a saved false overrides a default-on switch', () {
      final saved = <String, bool>{
        'notif_streak_reminders_enabled': false,
        'notif_weekly_recap_enabled': false,
      };
      expect(ReminderSummary.enabledCount((k) => saved[k]), 0);
    });

    test('everything on', () {
      expect(ReminderSummary.enabledCount((_) => true), 6);
    });

    test('label', () {
      expect(ReminderSummary.label(0), 'All reminders off');
      expect(ReminderSummary.label(3), '3 of 6 on');
    });
  });

  group('support and member-since', () {
    test('support mail link carries the address and a subject', () {
      final uri = ProfileData.supportMailUri();
      expect(uri.scheme, 'mailto');
      expect(uri.path, ProfileData.supportEmail);
      expect(uri.queryParameters['subject'], isNotEmpty);
      expect(uri.toString(), startsWith('mailto:${ProfileData.supportEmail}'));
    });

    test('memberSinceLabel', () {
      expect(ProfileData.memberSinceLabel(DateTime(2026, 11, 9)), 'Nov 2026');
      expect(ProfileData.memberSinceLabel(DateTime(2024, 1, 31)), 'Jan 2024');
      expect(ProfileData.memberSinceLabel(null), '\u2014');
    });
  });
}
