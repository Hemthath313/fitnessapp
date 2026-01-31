import 'package:fitness_app/model/workout_log.dart';
import 'package:intl/intl.dart';

class WorkoutExportService {
  static String generateCSV(List<WorkoutLog> logs) {
    StringBuffer csv = StringBuffer();
    // Header
    csv.writeln('Date,Category,Exercise,Set,Reps,Weight,Notes');
    
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');
    
    for (var log in logs) {
      for (int i = 0; i < log.sets.length; i++) {
        final set = log.sets[i];
        
        // Escape notes if they contain commas
        String notes = log.notes ?? '';
        if (notes.contains(',')) {
          notes = '"$notes"';
        }
        
        csv.writeln(
          '${formatter.format(log.date)},'
          '${log.category},'
          '${log.exerciseName},'
          '${i + 1},'
          '${set.reps},'
          '${set.weight},'
          '$notes'
        );
      }
    }
    return csv.toString();
  }
}
