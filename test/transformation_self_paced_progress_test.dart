import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Self-paced programme position (UserTransformationState.resolveProgress).
void main() {
  final today = DateTime(2026, 11, 13, 18, 30);
  DateTime daysAgo(int n) => DateTime(2026, 11, 13).subtract(Duration(days: n));
  String key(DateTime d) => UserTransformationState.dateKey(d);

  UserTransformationState plan({
    required DateTime start,
    List<int> completed = const [],
    Map<int, String> dates = const {},
    int currentDay = 1,
  }) {
    return UserTransformationState(
      planId: 'test',
      planTitle: 'Test plan',
      startDate: start,
      targetEndDate: start.add(const Duration(days: 30)),
      currentDay: currentDay,
      totalDays: 30,
      completedDayIndices: completed,
      completedDayDates: dates,
      targetCalories: 2000,
      targetMacros: const {'protein': 140.0},
    );
  }

  // Days 7, 14, 21, 28 are rest days.
  bool rest(int d) => d % 7 == 0;

  test('started 2 days ago, Day 1 finished today: Day 1 stays done until tomorrow', () {
    final s = plan(start: daysAgo(2), completed: [1], dates: {1: key(daysAgo(0))});
    expect(s.resolveProgress(today, isRestDay: rest).day, 1);
  });

  test('Day 1 finished yesterday: today is Day 2', () {
    final s = plan(start: daysAgo(2), completed: [1], dates: {1: key(daysAgo(1))});
    expect(s.resolveProgress(today, isRestDay: rest).day, 2);
  });

  test('older saves without completion dates move on to the next day', () {
    final s = plan(start: daysAgo(2), completed: [1]);
    expect(s.resolveProgress(today, isRestDay: rest).day, 2);
  });

  test('missing calendar days pauses the plan instead of skipping ahead', () {
    final s = plan(start: daysAgo(10), completed: [1], dates: {1: key(daysAgo(10))});
    expect(s.resolveProgress(today, isRestDay: rest).day, 2);
  });

  test('rest day is today right after the last workout, then passes', () {
    final dates = {for (var d = 1; d <= 6; d++) d: key(daysAgo(1))};
    final yesterdayDone = plan(start: daysAgo(6), completed: [1, 2, 3, 4, 5, 6], dates: dates);
    final r1 = yesterdayDone.resolveProgress(today, isRestDay: rest);
    expect(r1.day, 7);
    expect(r1.passedRestDays, isEmpty);

    final olderDates = {for (var d = 1; d <= 6; d++) d: key(daysAgo(2))};
    final twoDaysAgo = plan(start: daysAgo(8), completed: [1, 2, 3, 4, 5, 6], dates: olderDates);
    final r2 = twoDaysAgo.resolveProgress(today, isRestDay: rest);
    expect(r2.day, 8);
    expect(r2.passedRestDays.keys, [7]);
  });

  test('ticking a rest day today never pins the plan to that rest day', () {
    final s = plan(start: daysAgo(0), completed: [7], dates: {7: key(daysAgo(0))});
    expect(s.resolveProgress(today, isRestDay: rest).day, 1);
  });

  test('all days done resolves to the final day', () {
    final all = List.generate(30, (i) => i + 1);
    final s = plan(
      start: daysAgo(40),
      completed: all,
      dates: {for (final d in all) d: key(daysAgo(5))},
    );
    expect(s.resolveProgress(today, isRestDay: rest).day, 30);
  });

  test('completion dates survive a save and reload', () {
    final s = plan(start: daysAgo(2), completed: [1], dates: {1: key(daysAgo(0))});
    final reloaded = UserTransformationState.fromMap(s.toMap());
    expect(reloaded.completedDayDates, {1: key(daysAgo(0))});
  });

  test('workout summaries survive a save and reload', () {
    final s = UserTransformationState(
      planId: 'test',
      planTitle: 'Test plan',
      startDate: daysAgo(1),
      targetEndDate: daysAgo(1).add(const Duration(days: 30)),
      currentDay: 1,
      totalDays: 30,
      completedDayIndices: const [1],
      completedDaySummaries: const {
        1: {'sets': 15, 'minutes': 42, 'prs': 1},
      },
      targetCalories: 2000,
      targetMacros: const {'protein': 140.0},
    );
    final reloaded = UserTransformationState.fromMap(s.toMap());
    expect(reloaded.completedDaySummaries[1], {'sets': 15, 'minutes': 42, 'prs': 1});
  });
}
