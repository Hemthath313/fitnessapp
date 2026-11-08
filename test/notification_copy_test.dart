import 'package:fitness_app/services/notification_copy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('firstNameOf', () {
    test('takes and capitalises the first word', () {
      expect(NotificationCopy.firstNameOf('  hemthath s '), 'Hemthath');
    });
    test('ignores empty and placeholder names', () {
      expect(NotificationCopy.firstNameOf(null), '');
      expect(NotificationCopy.firstNameOf('  '), '');
      expect(NotificationCopy.firstNameOf('User'), '');
      expect(NotificationCopy.firstNameOf('guest'), '');
    });
  });

  group('copy', () {
    test('streak reminder reflects the streak', () {
      final t = NotificationCopy.streakReminder(
          name: 'Asha', streak: 5, longest: 9);
      expect(t.title, contains('5-day streak'));
      expect(t.body, startsWith('Asha, '));
      expect(t.body, contains('5-day'));
    });

    test('streak reminder without name is capitalised', () {
      final t =
          NotificationCopy.streakReminder(name: '', streak: 0, longest: 0);
      expect(t.body[0], t.body[0].toUpperCase());
      expect(t.body, isNot(startsWith(', ')));
    });

    test('comeback copy is guilt-free and uses best streak when known', () {
      const banned = ['miss you', "don't lose", 'lose your', '😢', '📉'];
      for (final days in [3, 7, 14]) {
        for (final longest in [0, 2, 12]) {
          final t = NotificationCopy.comeback(
              days: days, name: 'Asha', longest: longest);
          final text = '${t.title} ${t.body}'.toLowerCase();
          for (final b in banned) {
            expect(text.contains(b), isFalse, reason: '$days/$longest: $b');
          }
          if (longest >= 3) {
            expect(t.body, contains('$longest-day'));
          } else {
            expect(t.body, isNot(contains('-day best')));
          }
        }
      }
    });

    test('water copy is time-neutral', () {
      final t = NotificationCopy.water(name: '');
      expect('${t.title} ${t.body}', isNot(contains('PM')));
    });

    test('workout day names the day and is not streak-specific', () {
      final t = NotificationCopy.workoutDay(day: 'Monday', name: 'Asha');
      expect(t.title, contains('Monday'));
      expect(t.body, startsWith('Asha, '));
      expect(t.body, isNot(contains('streak')));
    });

    test('weekly recap copy: goal hit vs in progress', () {
      final hit = NotificationCopy.weeklyRecap(
          name: 'Asha', workouts: 3, target: 3, streak: 4);
      expect(hit.title, contains('Week complete'));
      expect(hit.body, startsWith('Asha, '));
      expect(hit.body, contains('3 of 3'));

      final one = NotificationCopy.weeklyRecap(
          name: '', workouts: 1, target: 3, streak: 0);
      expect(one.body, contains('1 workout this week'));
      expect(one.body, isNot(contains('streak')));

      final some = NotificationCopy.weeklyRecap(
          name: '', workouts: 2, target: 3, streak: 3);
      expect(some.body, contains('2 workouts this week'));
      expect(some.body, contains('3-day streak'));
    });

    test('rest day copy', () {
      expect(NotificationCopy.restDay(name: 'Asha').body, startsWith('Asha, '));
    });

    test('all variants are deterministic', () {
      expect(NotificationCopy.comeback(days: 7, name: 'A', longest: 5),
          NotificationCopy.comeback(days: 7, name: 'A', longest: 5));
    });
  });

  group('NotificationProfile', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults when nothing cached', () async {
      final p = await NotificationProfile.load();
      expect(p.firstName, '');
      expect(p.currentStreak, 0);
      expect(p.longestStreak, 0);
    });

    test('round-trips name and streaks', () async {
      await NotificationProfile.saveName('hemthath s');
      await NotificationProfile.saveStreak(current: 4, longest: 11);
      final p = await NotificationProfile.load();
      expect(p.firstName, 'Hemthath');
      expect(p.currentStreak, 4);
      expect(p.longestStreak, 11);
    });

    test('empty name does not overwrite cached name', () async {
      await NotificationProfile.saveName('Asha');
      await NotificationProfile.saveName('');
      expect((await NotificationProfile.load()).firstName, 'Asha');
    });
  });
}
