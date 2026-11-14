import 'package:fitness_app/utils/units.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => Units.setForTesting(false));

  test('kg mode prints exactly what the old code printed', () {
    Units.setForTesting(false);
    expect(Units.label, 'kg');
    expect(Units.fmt(62.5, 1), '62.5');
    expect(Units.fmtSmart(60), '60');
    expect(Units.fmtSmart(62.5), '62.5');
    expect(Units.intOf(59.9), 59);
    expect(Units.parseToKg('80'), 80);
  });

  test('lb mode converts for display and back to kg for saving', () {
    Units.setForTesting(true);
    expect(Units.label, 'lb');
    expect(Units.fmt(100, 1), '220.5');
    // Inputs are rounded to the nearest 0.5 lb.
    expect(Units.inputText(60), '132.5');
    expect(Units.parseToKg('225')!, closeTo(102.06, 0.01));
    expect(Units.parseToKg('abc'), isNull);
  });

  test('empty or zero weight gives an empty input', () {
    expect(Units.inputText(0), '');
  });
}
