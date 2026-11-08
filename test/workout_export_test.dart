import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/services/workout_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('escapeCell quotes commas, quotes and line breaks', () {
    expect(WorkoutExportService.escapeCell('Bench Press'), 'Bench Press');
    expect(WorkoutExportService.escapeCell('Press, incline'), '"Press, incline"');
    expect(WorkoutExportService.escapeCell('5" bar'), '"5"" bar"');
    expect(WorkoutExportService.escapeCell('a\nb'), '"a\nb"');
  });

  test('fileName carries the date', () {
    expect(
      WorkoutExportService.fileName(DateTime(2026, 11, 8, 9)),
      'gym_buddy_workouts_2026-11-08.csv',
    );
  });

  test('generateCSV writes one row per set with safe cells', () {
    final csv = WorkoutExportService.generateCSV([
      WorkoutLog(
        id: 'l',
        exerciseName: 'Press, incline',
        date: DateTime(2026, 11, 5, 18, 30),
        category: 'Strength',
        notes: 'felt "good", slow',
        sets: [
          WorkoutSet(weight: 60, reps: 8, isCompleted: true),
          WorkoutSet(weight: 62.5, reps: 6, isCompleted: true),
        ],
      ),
    ]).trim().split('\n');

    expect(csv.first, 'Date,Category,Exercise,Set,Reps,Weight,Notes');
    expect(csv.length, 3);
    expect(csv[1],
        '2026-11-05 18:30,Strength,"Press, incline",1,8,60.0,"felt ""good"", slow"');
    expect(csv[2],
        '2026-11-05 18:30,Strength,"Press, incline",2,6,62.5,"felt ""good"", slow"');
  });
}
