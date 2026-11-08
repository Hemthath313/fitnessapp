import 'package:fitness_app/services/plan_today.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 2026-11-08 is a Sunday.
  final sunday = DateTime(2026, 11, 8);
  final wednesday = DateTime(2026, 11, 11);

  test('today in plan: it leads and the rest follow from tomorrow', () {
    final split = splitPlanDays(['Monday', 'Wednesday', 'Friday'], wednesday);
    expect(split.today, 'Wednesday');
    expect(split.later, ['Friday', 'Monday']);
    expect(split.nextUp, 'Wednesday');
  });

  test('rest day: today is null and next up is the following planned day', () {
    final split = splitPlanDays(['Monday', 'Wednesday', 'Friday'], sunday);
    expect(split.today, isNull);
    expect(split.later, ['Monday', 'Wednesday', 'Friday']);
    expect(split.nextUp, 'Monday');
  });

  test('order wraps past Sunday', () {
    final split = splitPlanDays(['Tuesday', 'Saturday'], DateTime(2026, 11, 7));
    expect(split.today, 'Saturday');
    expect(split.later, ['Tuesday']);
  });

  test('non-weekday names are appended after weekdays', () {
    final split = splitPlanDays(['Chest', 'Monday'], sunday);
    expect(split.today, isNull);
    expect(split.later, ['Monday', 'Chest']);
  });

  test('empty plan has no next up', () {
    final split = splitPlanDays(const [], sunday);
    expect(split.today, isNull);
    expect(split.later, isEmpty);
    expect(split.nextUp, isNull);
  });
}
