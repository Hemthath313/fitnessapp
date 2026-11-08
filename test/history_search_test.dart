import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/workout_logs/workout_log_history_page.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSession _session(String id, String name, List<String> exercises) {
  return WorkoutSession(
    id: id,
    userId: 'u',
    workoutName: name,
    dayName: 'Monday',
    startedAt: DateTime(2026, 11, 5, 18),
    completedAt: DateTime(2026, 11, 5, 19),
    totalVolume: 0,
    exercises: [
      for (var i = 0; i < exercises.length; i++)
        SessionExercise(exerciseName: exercises[i], order: i, sets: const []),
    ],
  );
}

WorkoutLog _log(String name) => WorkoutLog(
      id: 'l-$name',
      exerciseName: name,
      date: DateTime(2026, 11, 1),
      sets: const [],
      category: 'Strength',
    );

void main() {
  final feed = WorkoutHistoryFeedData(
    displayedSessions: [
      _session('a', 'Push Day', ['Bench Press', 'Overhead Press']),
      _session('b', 'Leg Day', ['[Monday] Squat', 'Leg Press']),
    ],
    displayedLegacyLogs: [_log('Barbell Curl'), _log('Bench Press')],
    activeDates: {DateTime(2026, 11, 5)},
  );

  test('empty or blank query returns the feed untouched', () {
    expect(WorkoutLogHistoryPage.filterFeed(feed, ''), same(feed));
    expect(WorkoutLogHistoryPage.filterFeed(feed, '   '), same(feed));
  });

  test('matches workout names and exercise names, ignoring case', () {
    final byName = WorkoutLogHistoryPage.filterFeed(feed, 'leg day');
    expect(byName.displayedSessions.map((s) => s.id), ['b']);

    final byExercise = WorkoutLogHistoryPage.filterFeed(feed, 'BENCH');
    expect(byExercise.displayedSessions.map((s) => s.id), ['a']);
    expect(byExercise.displayedLegacyLogs.map((l) => l.exerciseName), ['Bench Press']);
  });

  test('ignores bracket prefixes and needs every word to match', () {
    final squat = WorkoutLogHistoryPage.filterFeed(feed, 'squat');
    expect(squat.displayedSessions.map((s) => s.id), ['b']);

    final both = WorkoutLogHistoryPage.filterFeed(feed, 'leg squat');
    expect(both.displayedSessions.map((s) => s.id), ['b']);

    final none = WorkoutLogHistoryPage.filterFeed(feed, 'bench squat');
    expect(none.displayedSessions, isEmpty);
    expect(none.totalDisplayCount, 0);
  });

  test('keeps calendar dots for all days while searching', () {
    final result = WorkoutLogHistoryPage.filterFeed(feed, 'zzz');
    expect(result.activeDates, feed.activeDates);
  });
}
