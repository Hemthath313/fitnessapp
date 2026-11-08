import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/services/progression_service.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutLog _log(List<int> reps, {double weight = 60}) => WorkoutLog(
      id: 'l',
      exerciseName: 'Bench Press',
      date: DateTime(2026, 11, 5),
      category: 'Chest',
      sets: [
        for (final r in reps)
          WorkoutSet(weight: weight, reps: r, isCompleted: true),
      ],
    );

void main() {
  group('ProgressionService.nudgeFor', () {
    test('suggests a heavier weight only when every set hit the top reps', () {
      expect(
        ProgressionService.nudgeFor('Bench Press', _log([8, 8, 8])),
        '🔺 Try 62.5 kg today',
      );
    });

    test('holds the weight and asks for +1 rep when reps are in range', () {
      expect(
        ProgressionService.nudgeFor('Bench Press', _log([8, 7, 6])),
        'Same 60 kg, aim for +1 rep per set',
      );
    });

    test('does not push weight when minimum reps were missed', () {
      final text = ProgressionService.nudgeFor('Bench Press', _log([5, 5, 4]));
      expect(text, 'Hold 60 kg, aim for 6+ clean reps');
      expect(text, isNot(contains('Try')));
    });

    test('returns null without usable history', () {
      expect(ProgressionService.nudgeFor('Bench Press', null), isNull);
      expect(ProgressionService.nudgeFor('Bench Press', _log([])), isNull);
    });
  });
}
