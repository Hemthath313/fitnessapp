import 'package:fitness_app/presentation/progress/progress_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Monday 9 Nov 2026, mid-afternoon.
  final now = DateTime(2026, 11, 9, 15, 30);

  TimedValue at(int y, int m, int d, double v, [int h = 8]) =>
      TimedValue(DateTime(y, m, d, h), v);

  group('dayKey / legacy months', () {
    test('dayKey is yyyymmdd', () {
      expect(ProgressData.dayKey(DateTime(2026, 11, 9)), 20261109);
      expect(ProgressData.dayKey(DateTime(2026, 1, 2, 23, 59)), 20260102);
    });

    test('legacy month in the past or current month maps to this year', () {
      expect(ProgressData.legacyMonthToDate(11, now), DateTime(2026, 11, 1));
      expect(ProgressData.legacyMonthToDate(3, now), DateTime(2026, 3, 1));
    });

    test('legacy month still in the future belongs to last year', () {
      expect(ProgressData.legacyMonthToDate(12, now), DateTime(2025, 12, 1));
    });

    test('legacy month is clamped to 1..12', () {
      expect(ProgressData.legacyMonthToDate(0, now), DateTime(2026, 1, 1));
      expect(ProgressData.legacyMonthToDate(99, now), DateTime(2025, 12, 1));
    });
  });

  group('ranges', () {
    test('week covers today and the 6 days before it', () {
      expect(ProgressRange.week.startFor(now), DateTime(2026, 11, 3));
    });

    test('inRange keeps boundaries and drops older / future entries', () {
      final entries = [
        at(2026, 11, 2, 80), // 1 day too old for the week window
        at(2026, 11, 3, 79), // first day of the window
        at(2026, 11, 9, 78, 6), // today
        at(2026, 11, 10, 77), // tomorrow: not real yet
      ];
      final week = ProgressData.inRange(entries, ProgressRange.week, now);
      expect(week.map((e) => e.value), [79, 78]);
    });

    test('inRange returns entries sorted oldest to newest', () {
      final entries = [
        at(2026, 11, 8, 78),
        at(2026, 11, 4, 80),
        at(2026, 11, 6, 79),
      ];
      final list = ProgressData.inRange(entries, ProgressRange.week, now);
      expect(list.map((e) => e.value), [80, 79, 78]);
    });

    test('same month in different years is no longer collapsed', () {
      final entries = [
        at(2025, 11, 9, 90),
        at(2026, 11, 9, 80),
      ];
      expect(ProgressData.inRange(entries, ProgressRange.year, now).length, 1);
      expect(ProgressData.inRange(entries, ProgressRange.year, now).first.value,
          80);
    });

    test('several readings in one month are all kept', () {
      final entries = [
        at(2026, 11, 1, 82),
        at(2026, 11, 5, 81),
        at(2026, 11, 9, 80),
      ];
      expect(
          ProgressData.inRange(entries, ProgressRange.month, now).length, 3);
    });
  });

  group('delta', () {
    test('null when there are no readings or only one', () {
      expect(ProgressData.deltaInRange([], ProgressRange.month, now), isNull);
      expect(
          ProgressData.deltaInRange(
              [at(2026, 11, 5, 80)], ProgressRange.month, now),
          isNull);
    });

    test('last minus first inside the window, ignoring older readings', () {
      final entries = [
        at(2026, 6, 1, 95), // outside the month window
        at(2026, 10, 20, 84),
        at(2026, 11, 9, 82),
      ];
      expect(ProgressData.deltaInRange(entries, ProgressRange.month, now),
          closeTo(-2, 1e-9));
    });

    test('two readings on one day still compare by time', () {
      final entries = [
        at(2026, 11, 9, 81, 7),
        at(2026, 11, 9, 82, 18),
      ];
      expect(ProgressData.deltaInRange(entries, ProgressRange.week, now),
          closeTo(1, 1e-9));
    });
  });

  group('chart axis', () {
    test('x runs from 0 at window start to days-1 at today midnight', () {
      final start = ProgressRange.month.startFor(now);
      expect(ProgressData.xFor(start, ProgressRange.month, now), 0);
      expect(
          ProgressData.xFor(DateTime(2026, 11, 9), ProgressRange.month, now),
          29);
    });

    test('today in the afternoon sits inside the final day', () {
      final x = ProgressData.xFor(now, ProgressRange.week, now);
      expect(x, greaterThan(6));
      expect(x, lessThan(7));
    });

    test('labels match the dates they sit on', () {
      // Week window: Tue 3 Nov .. Mon 9 Nov 2026.
      expect(ProgressData.axisLabel(0, ProgressRange.week, now), 'Tue');
      expect(ProgressData.axisLabel(6, ProgressRange.week, now), 'Mon');
      expect(ProgressData.axisLabel(0, ProgressRange.month, now), '11 Oct');
      expect(ProgressData.axisLabel(29, ProgressRange.month, now), '9 Nov');
      expect(ProgressData.axisLabel(0, ProgressRange.year, now), 'Nov');
    });
  });

  group('validation', () {
    test('weight rejects blank, text and out-of-range values', () {
      expect(ProgressData.validateWeight(''), isNotNull);
      expect(ProgressData.validateWeight(' '), isNotNull);
      expect(ProgressData.validateWeight('.'), isNotNull);
      expect(ProgressData.validateWeight(null), isNotNull);
      expect(ProgressData.validateWeight('0'), isNotNull);
      expect(ProgressData.validateWeight('19.9'), isNotNull);
      expect(ProgressData.validateWeight('401'), isNotNull);
    });

    test('weight accepts normal values and a decimal comma', () {
      expect(ProgressData.validateWeight('72.5'), isNull);
      expect(ProgressData.validateWeight('72,5'), isNull);
      expect(ProgressData.validateWeight('20'), isNull);
      expect(ProgressData.validateWeight('400'), isNull);
      expect(ProgressData.parseNumber('72,5'), 72.5);
    });

    test('measurement blank is only allowed when keeping an old value', () {
      expect(ProgressData.validateMeasurement('', 'Chest'), isNotNull);
      expect(
          ProgressData.validateMeasurement('', 'Chest', allowBlank: true),
          isNull);
      expect(ProgressData.validateMeasurement('4', 'Chest'), isNotNull);
      expect(ProgressData.validateMeasurement('301', 'Chest'), isNotNull);
      expect(ProgressData.validateMeasurement('98.5', 'Chest'), isNull);
      expect(ProgressData.validateMeasurement('x', 'Chest'), isNotNull);
    });

    test('error messages name the field', () {
      expect(ProgressData.validateMeasurement('', 'Waist'),
          contains('Waist'));
    });

    test('prefill never shows null or zero', () {
      expect(ProgressData.prefill(null), '');
      expect(ProgressData.prefill(0), '');
      expect(ProgressData.prefill(0.0), '');
      expect(ProgressData.prefill('abc'), '');
      expect(ProgressData.prefill(72.5), '72.5');
      expect(ProgressData.prefill(72.0), '72');
      expect(ProgressData.prefill(72), '72');
    });
  });

  group('back-dated entries', () {
    test('no entries: anything becomes the current weight', () {
      expect(ProgressData.isOnOrAfterLatest([], DateTime(2020, 1, 1)), isTrue);
    });

    test('today or later than the newest entry is the current weight', () {
      final entries = [at(2026, 11, 5, 80), at(2026, 11, 8, 79)];
      expect(ProgressData.isOnOrAfterLatest(entries, DateTime(2026, 11, 8, 6)),
          isTrue);
      expect(ProgressData.isOnOrAfterLatest(entries, DateTime(2026, 11, 9)),
          isTrue);
    });

    test('an older day does not replace the current weight', () {
      final entries = [at(2026, 11, 5, 80), at(2026, 11, 8, 79)];
      expect(ProgressData.isOnOrAfterLatest(entries, DateTime(2026, 11, 6)),
          isFalse);
    });

    test('order of the list does not matter', () {
      final entries = [at(2026, 11, 8, 79), at(2026, 11, 5, 80)];
      expect(ProgressData.isOnOrAfterLatest(entries, DateTime(2026, 11, 6)),
          isFalse);
    });

    test('entryTimestamp keeps the time for today, noon for a past day', () {
      expect(ProgressData.entryTimestamp(DateTime(2026, 11, 9), now), now);
      expect(ProgressData.entryTimestamp(DateTime(2026, 11, 2), now),
          DateTime(2026, 11, 2, 12));
    });

    test('formatDay', () {
      expect(ProgressData.formatDay(DateTime(2026, 11, 9)), '9 Nov 2026');
      expect(ProgressData.formatDay(DateTime(2025, 1, 31)), '31 Jan 2025');
    });

    test('TimedValue carries an optional document id', () {
      expect(TimedValue(DateTime(2026, 1, 1), 70, id: 'abc').id, 'abc');
      expect(TimedValue(DateTime(2026, 1, 1), 70).id, isNull);
    });
  });

  group('summarize', () {
    test('null with fewer than two readings', () {
      expect(ProgressData.summarize([]), isNull);
      expect(ProgressData.summarize([at(2026, 11, 1, 80)]), isNull);
    });

    test('start, latest, lowest, highest and change', () {
      final s = ProgressData.summarize([
        at(2026, 11, 9, 81),
        at(2026, 11, 1, 84),
        at(2026, 11, 5, 80),
      ])!;
      expect(s.start, 84);
      expect(s.latest, 81);
      expect(s.lowest, 80);
      expect(s.highest, 84);
      expect(s.change, closeTo(-3, 1e-9));
    });

    test('per week is the change spread over the real time span', () {
      // 14 days, -2 kg  => -1 kg per week.
      final s = ProgressData.summarize([
        at(2026, 10, 26, 82),
        at(2026, 11, 9, 80),
      ])!;
      expect(s.perWeek, closeTo(-1, 1e-6));
    });

    test('per week is withheld when the span is under a week', () {
      final s = ProgressData.summarize([
        at(2026, 11, 5, 82),
        at(2026, 11, 9, 81),
      ])!;
      expect(s.perWeek, isNull);
    });
  });

  group('goal weight', () {
    test('validateGoalWeight', () {
      expect(ProgressData.validateGoalWeight(''), isNotNull);
      expect(ProgressData.validateGoalWeight('abc'), isNotNull);
      expect(ProgressData.validateGoalWeight('19'), isNotNull);
      expect(ProgressData.validateGoalWeight('401'), isNotNull);
      expect(ProgressData.validateGoalWeight('70'), isNull);
      expect(ProgressData.validateGoalWeight('70,5'), isNull);
      expect(ProgressData.validateGoalWeight(''), contains('goal'));
    });

    test('goalProgressText says lose, gain or reached', () {
      expect(ProgressData.goalProgressText(75, 70), '5.0 kg to lose');
      expect(ProgressData.goalProgressText(65, 70.5), '5.5 kg to gain');
      expect(ProgressData.goalProgressText(70, 70), 'Goal reached');
      expect(ProgressData.goalProgressText(70.04, 70), 'Goal reached');
    });
  });
}
