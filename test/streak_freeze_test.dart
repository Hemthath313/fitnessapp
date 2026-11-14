import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// A streak freeze covers a missed workout day like a planned rest day.
void main() {
  final today = DateTime(2026, 11, 14);
  DateTime ago(int n) => DateTime(today.year, today.month, today.day - n);

  test('a missed day breaks the streak without a freeze', () {
    final streak = StatisticsProvider.calculateCurrentStreak(
      completedDates: [ago(3), ago(2)],
      referenceNow: today,
    );
    expect(streak, 0);
  });

  test('a frozen missed day keeps the streak', () {
    final streak = StatisticsProvider.calculateCurrentStreak(
      completedDates: [ago(3), ago(2)],
      referenceNow: today,
      frozenDates: {ago(1)},
    );
    expect(streak, 2);
  });

  test('a freeze does not add to the streak count', () {
    final streak = StatisticsProvider.calculateCurrentStreak(
      completedDates: [ago(3), ago(2), today],
      referenceNow: today,
      frozenDates: {ago(1)},
    );
    expect(streak, 3);
  });
}
