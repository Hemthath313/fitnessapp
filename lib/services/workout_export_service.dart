import 'package:fitness_app/model/workout_log.dart';
import 'package:intl/intl.dart';

class WorkoutExportService {
  /// Quotes a CSV cell when it contains a comma, quote or line break
  /// (RFC 4180), doubling any quotes inside it.
  static String escapeCell(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// "gym_buddy_workouts_2026-11-08.csv"
  static String fileName(DateTime now) =>
      'gym_buddy_workouts_${DateFormat('yyyy-MM-dd').format(now)}.csv';

  static String generateCSV(List<WorkoutLog> logs) {
    final csv = StringBuffer();
    // Header
    csv.writeln('Date,Category,Exercise,Set,Reps,Weight,Notes');

    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');

    for (var log in logs) {
      for (int i = 0; i < log.sets.length; i++) {
        final set = log.sets[i];

        csv.writeln(
          '${formatter.format(log.date)},'
          '${escapeCell(log.category)},'
          '${escapeCell(log.exerciseName)},'
          '${i + 1},'
          '${set.reps},'
          '${set.weight},'
          '${escapeCell(log.notes ?? '')}',
        );
      }
    }
    return csv.toString();
  }
}
