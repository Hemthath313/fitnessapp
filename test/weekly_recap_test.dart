import 'package:fitness_app/services/weekly_recap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 2026-11-08 is a Sunday; week = Mon 2 Nov .. Sun 8 Nov.
  final sunday = DateTime(2026, 11, 8, 10);
  final monday = DateTime(2026, 11, 9, 9);
  final wednesday = DateTime(2026, 11, 11, 9);

  bool Function(DateTime) on(List<DateTime> days) {
    final set = days.map((d) => DateTime(d.year, d.month, d.day)).toSet();
    return (d) => set.contains(DateTime(d.year, d.month, d.day));
  }

  test('only Sunday and Monday are recap days', () {
    expect(WeeklyRecap.isRecapDay(sunday), isTrue);
    expect(WeeklyRecap.isRecapDay(monday), isTrue);
    expect(WeeklyRecap.isRecapDay(wednesday), isFalse);
    expect(
      WeeklyRecap.build(
          now: wednesday,
          hasWorkoutOn: on([DateTime(2026, 11, 9)]),
          target: 3,
          streak: 1),
      isNull,
    );
  });

  test('recap week start: Sunday -> this Monday, Monday -> previous Monday', () {
    expect(WeeklyRecap.recapWeekStart(sunday), DateTime(2026, 11, 2));
    expect(WeeklyRecap.recapWeekStart(monday), DateTime(2026, 11, 2));
  });

  test('empty week gives no recap', () {
    expect(
      WeeklyRecap.build(
          now: sunday, hasWorkoutOn: on(const []), target: 3, streak: 0),
      isNull,
    );
  });

  test('goal hit on Sunday', () {
    final r = WeeklyRecap.build(
      now: sunday,
      hasWorkoutOn: on([
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 4),
        DateTime(2026, 11, 6),
      ]),
      target: 3,
      streak: 5,
    )!;
    expect(r.title, 'Your week in review');
    expect(r.workouts, 3);
    expect(r.goalHit, isTrue);
    expect(r.headline, 'Goal hit: 3 of 3 workouts');
    expect(r.activeDays, [true, false, true, false, true, false, false]);
    expect(r.streakText, '5-day streak');
  });

  test('one short on Sunday nudges toward finishing today', () {
    final r = WeeklyRecap.build(
      now: sunday,
      hasWorkoutOn: on([DateTime(2026, 11, 2), DateTime(2026, 11, 4)]),
      target: 3,
      streak: 0,
    )!;
    expect(r.goalHit, isFalse);
    expect(r.message, contains('One more session today'));
    expect(r.streakText, isNull);
  });

  test('Monday recaps the previous week, not the new one', () {
    final r = WeeklyRecap.build(
      now: monday,
      hasWorkoutOn: on([
        DateTime(2026, 11, 3),
        DateTime(2026, 11, 5),
        DateTime(2026, 11, 9), // today (new week) must not count
      ]),
      target: 4,
      streak: 2,
    )!;
    expect(r.title, 'Last week in review');
    expect(r.workouts, 2);
    expect(r.message, 'A fresh week starts today.');
  });

  test('delta only shown when same or better, never a drop', () {
    final prevWeek = [
      DateTime(2026, 10, 26),
      DateTime(2026, 10, 28),
    ];
    final better = WeeklyRecap.build(
      now: sunday,
      hasWorkoutOn: on([
        ...prevWeek,
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 3),
        DateTime(2026, 11, 5),
      ]),
      target: 3,
      streak: 0,
    )!;
    expect(better.deltaText, '+1 vs the week before');

    final same = WeeklyRecap.build(
      now: sunday,
      hasWorkoutOn: on([...prevWeek, DateTime(2026, 11, 2), DateTime(2026, 11, 3)]),
      target: 3,
      streak: 0,
    )!;
    expect(same.deltaText, 'Same as the week before');

    final worse = WeeklyRecap.build(
      now: sunday,
      hasWorkoutOn: on([...prevWeek, DateTime(2026, 11, 2)]),
      target: 3,
      streak: 0,
    )!;
    expect(worse.deltaText, isNull);
  });

  test('non-positive target falls back to 3', () {
    final r = WeeklyRecap.build(
      now: sunday,
      hasWorkoutOn: on([DateTime(2026, 11, 2)]),
      target: 0,
      streak: 0,
    )!;
    expect(r.target, 3);
  });
}
