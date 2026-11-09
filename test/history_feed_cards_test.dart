import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/workout_logs/widgets/legacy_workout_log_card.dart';
import 'package:fitness_app/presentation/workout_logs/widgets/workout_session_card.dart';
import 'package:fitness_app/presentation/workout_logs/workout_log_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

// Monday 9 Nov 2026 noon.
final _now = DateTime(2026, 11, 9, 12);

WorkoutSession _session(
  String id,
  DateTime date, {
  int seconds = 2700,
  double volume = 3200,
  String status = 'completed',
  List<String> exercises = const ['Bench Press', 'Overhead Press'],
}) {
  return WorkoutSession(
    id: id,
    userId: 'u',
    workoutName: 'Push Day',
    dayName: 'Push',
    startedAt: date,
    completedAt: date,
    durationSeconds: seconds,
    status: status,
    totalVolume: volume,
    exercises: [
      for (var i = 0; i < exercises.length; i++)
        SessionExercise(exerciseName: exercises[i], order: i, sets: const []),
    ],
  );
}

WorkoutLog _log(String name, DateTime date) => WorkoutLog(
      id: 'l-$name',
      exerciseName: name,
      date: date,
      sets: [WorkoutSet(weight: 20, reps: 10, isCompleted: true)],
      category: 'Strength',
    );

Future<void> _pumpCard(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

void main() {
  group('groupLabel', () {
    test('this week, last week, then months', () {
      expect(WorkoutLogHistoryPage.groupLabel(DateTime(2026, 11, 9), _now), 'This week');
      expect(WorkoutLogHistoryPage.groupLabel(DateTime(2026, 11, 8), _now), 'Last week');
      expect(WorkoutLogHistoryPage.groupLabel(DateTime(2026, 11, 2), _now), 'Last week');
      expect(WorkoutLogHistoryPage.groupLabel(DateTime(2026, 11, 1), _now), 'November');
      expect(WorkoutLogHistoryPage.groupLabel(DateTime(2026, 9, 20), _now), 'September');
      expect(WorkoutLogHistoryPage.groupLabel(DateTime(2025, 12, 31), _now), 'December 2025');
    });
  });

  group('buildTimeline', () {
    test('merges sessions and quick logs newest first with group headers', () {
      final feed = WorkoutHistoryFeedData(
        displayedSessions: [
          _session('new', DateTime(2026, 11, 9, 8)),
          _session('old', DateTime(2026, 10, 3, 18)),
        ],
        // A quick log from last week sits between the two sessions by date.
        displayedLegacyLogs: [_log('Barbell Curl', DateTime(2026, 11, 4, 9))],
        activeDates: const {},
      );

      final items = WorkoutLogHistoryPage.buildTimeline(feed, now: _now);
      final shape = items
          .map((i) => i.header ?? (i.session != null ? 's:${i.session!.id}' : 'l:${i.log!.exerciseName}'))
          .toList();
      expect(shape, [
        'This week',
        's:new',
        'Last week',
        'l:Barbell Curl',
        'October',
        's:old',
      ]);
    });

    test('headers can be switched off', () {
      final feed = WorkoutHistoryFeedData(
        displayedSessions: [_session('a', DateTime(2026, 11, 9))],
        displayedLegacyLogs: const [],
        activeDates: const {},
      );
      final items =
          WorkoutLogHistoryPage.buildTimeline(feed, now: _now, withHeaders: false);
      expect(items, hasLength(1));
      expect(items.first.header, isNull);
    });

    test('empty feed gives an empty list', () {
      final items = WorkoutLogHistoryPage.buildTimeline(
        const WorkoutHistoryFeedData(
          displayedSessions: [],
          displayedLegacyLogs: [],
          activeDates: {},
        ),
        now: _now,
      );
      expect(items, isEmpty);
    });
  });

  group('WorkoutSessionCard', () {
    testWidgets('shows one summary line and no Completed badge', (tester) async {
      await _pumpCard(
        tester,
        WorkoutSessionCard(session: _session('a', DateTime(2026, 11, 9, 8)), now: _now),
      );
      expect(find.text('45 min · 3,200 kg · 2 exercises'), findsOneWidget);
      expect(find.text('Completed'), findsNothing);
      expect(find.byKey(const Key('session_partial_badge')), findsNothing);
      expect(find.text('Bench Press, Overhead Press'), findsOneWidget);
      expect(find.text('Repeat'), findsOneWidget);
    });

    testWidgets('partial sessions are flagged', (tester) async {
      await _pumpCard(
        tester,
        WorkoutSessionCard(
          session: _session('a', DateTime(2026, 11, 9, 8), status: 'partial'),
          now: _now,
        ),
      );
      expect(find.byKey(const Key('session_partial_badge')), findsOneWidget);
    });

    testWidgets('leaves out duration and volume when unknown', (tester) async {
      await _pumpCard(
        tester,
        WorkoutSessionCard(
          session: _session('a', DateTime(2026, 11, 9, 8),
              seconds: 0, volume: 0, exercises: const ['Plank']),
          now: _now,
        ),
      );
      expect(find.text('1 exercise'), findsOneWidget);
    });

    testWidgets('long exercise lists collapse to +N more', (tester) async {
      await _pumpCard(
        tester,
        WorkoutSessionCard(
          session: _session('a', DateTime(2026, 11, 9, 8),
              exercises: const ['A', 'B', 'C', 'D', 'E']),
          now: _now,
        ),
      );
      expect(find.text('A, B, C +2 more'), findsOneWidget);
    });
  });

  testWidgets('quick log card says Quick log, not Legacy Log', (tester) async {
    await _pumpCard(
      tester,
      LegacyWorkoutLogCard(log: _log('Barbell Curl', DateTime(2026, 11, 4))),
    );
    expect(find.text('Quick log'), findsOneWidget);
    expect(find.text('Legacy Log'), findsNothing);
  });
}
