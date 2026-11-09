import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/workout_logs/workout_log_history_page.dart';
import 'package:fitness_app/presentation/workout_logs/workout_session_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

WorkoutSession _session(String id, {String status = 'completed', List<String> ex = const ['Bench Press']}) {
  final now = DateTime.now();
  return WorkoutSession(
    id: id,
    userId: 'u',
    workoutName: 'Push Day',
    dayName: 'Push',
    startedAt: now,
    completedAt: now,
    durationSeconds: 1800,
    status: status,
    totalVolume: 1000,
    exercises: [
      for (var i = 0; i < ex.length; i++)
        SessionExercise(exerciseName: ex[i], order: i, sets: const []),
    ],
  );
}

WorkoutLog _log(String name, String category) => WorkoutLog(
      id: 'l-$name',
      exerciseName: name,
      date: DateTime.now(),
      sets: [WorkoutSet(weight: 0, reps: 20, isCompleted: true)],
      category: category,
    );

Future<void> _pumpHistory(
  WidgetTester tester, {
  List<WorkoutSession> sessions = const [],
  List<WorkoutLog> logs = const [],
  VoidCallback? onStart,
}) async {
  tester.view.physicalSize = const Size(430, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SubscriptionProvider>(
          create: (_) => SubscriptionProvider(autoInitialize: false),
        ),
        ChangeNotifierProvider<StatisticsProvider>(create: (_) => StatisticsProvider()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          home: WorkoutLogHistoryPage(
            sessionsStream: Stream.value(sessions),
            logsStream: Stream.value(logs),
            onStartWorkout: onStart,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('filterByType / singleMatchingExercise', () {
    final feed = WorkoutHistoryFeedData(
      displayedSessions: [_session('a'), _session('b', status: 'partial')],
      displayedLegacyLogs: [_log('Running', 'Cardio'), _log('Curl', 'Strength'), _log('Stretch', 'Mobility')],
      activeDates: const {},
    );

    test('each filter keeps the right entries', () {
      final all = WorkoutLogHistoryPage.filterByType(feed, HistoryTypeFilter.all);
      expect(all.totalDisplayCount, 5);

      final strength = WorkoutLogHistoryPage.filterByType(feed, HistoryTypeFilter.strength);
      expect(strength.displayedSessions, hasLength(2));
      expect(strength.displayedLegacyLogs.map((l) => l.exerciseName), ['Curl']);

      final cardio = WorkoutLogHistoryPage.filterByType(feed, HistoryTypeFilter.cardio);
      expect(cardio.displayedSessions, isEmpty);
      expect(cardio.displayedLegacyLogs.map((l) => l.exerciseName), ['Running']);

      final partial = WorkoutLogHistoryPage.filterByType(feed, HistoryTypeFilter.partial);
      expect(partial.displayedSessions.map((s) => s.id), ['b']);
      expect(partial.displayedLegacyLogs, isEmpty);
    });

    test('single matching exercise only when the query is unambiguous', () {
      final sessions = [_session('a', ex: ['Bench Press', 'Incline Bench Press', 'Squat'])];
      expect(WorkoutLogHistoryPage.singleMatchingExercise(sessions, const [], 'squat'), 'Squat');
      expect(WorkoutLogHistoryPage.singleMatchingExercise(sessions, const [], 'bench'), isNull);
      expect(WorkoutLogHistoryPage.singleMatchingExercise(sessions, const [], 'zzz'), isNull);
      expect(WorkoutLogHistoryPage.singleMatchingExercise(sessions, const [], '  '), isNull);
    });
  });

  group('History page', () {
    testWidgets('empty state offers Start a workout and uses the callback', (tester) async {
      var started = 0;
      await _pumpHistory(tester, onStart: () => started++);
      expect(find.text('No workout sessions yet'), findsOneWidget);
      await tester.tap(find.byKey(const Key('history_empty_start_button')));
      expect(started, 1);
      expect(find.byKey(const Key('history_empty_log_button')), findsOneWidget);
    });

    testWidgets('no filter chips when everything is strength and finished', (tester) async {
      await _pumpHistory(tester, sessions: [_session('a')]);
      expect(find.byKey(const Key('history_type_chips')), findsNothing);
    });

    testWidgets('chips appear with cardio and filter the feed', (tester) async {
      await _pumpHistory(
        tester,
        sessions: [_session('a')],
        logs: [_log('Running', 'Cardio')],
      );
      expect(find.byKey(const Key('history_type_chips')), findsOneWidget);
      expect(find.byKey(const Key('history_filter_cardio')), findsOneWidget);
      expect(find.byKey(const Key('history_filter_partial')), findsNothing);
      expect(find.text('Push Day'), findsOneWidget);

      await tester.tap(find.byKey(const Key('history_filter_cardio')));
      await tester.pump();
      expect(find.text('Push Day'), findsNothing);
      expect(find.text('Running'), findsOneWidget);

      await tester.tap(find.byKey(const Key('history_filter_all')));
      await tester.pump();
      expect(find.text('Push Day'), findsOneWidget);
    });

    testWidgets('Partial chip shows only unfinished sessions', (tester) async {
      await _pumpHistory(
        tester,
        sessions: [_session('a'), _session('b', status: 'partial')],
      );
      await tester.tap(find.byKey(const Key('history_filter_partial')));
      await tester.pump();
      expect(find.byKey(const Key('session_partial_badge')), findsOneWidget);
      expect(find.text('Workouts (1)'), findsOneWidget);
    });

    testWidgets('searching one exercise offers its progress page', (tester) async {
      await _pumpHistory(tester, sessions: [_session('a', ex: ['Squat', 'Bench Press'])]);
      expect(find.byKey(const Key('history_search_progress_link')), findsNothing);
      await tester.enterText(find.byKey(const Key('history_search_field')), 'squat');
      await tester.pump();
      expect(find.text('View progress for Squat'), findsOneWidget);
    });

    testWidgets('header has a Progress shortcut', (tester) async {
      await _pumpHistory(tester, sessions: [_session('a')]);
      expect(find.byKey(const Key('history_progress_link')), findsOneWidget);
    });
  });

  group('Session detail', () {
    testWidgets('Edit is a labelled button and Delete lives in the menu', (tester) async {
      tester.view.physicalSize = const Size(430, 1600);
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
            home: WorkoutSessionDetailPage(session: _session('a')),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.byTooltip('Delete Session'), findsNothing);

      await tester.tap(find.byKey(const Key('edit_session_button')));
      await tester.pump();
      expect(find.text('Done'), findsOneWidget);
      expect(find.byKey(const Key('edit_session_banner')), findsOneWidget);

      await tester.tap(find.byKey(const Key('session_more_menu')));
      await tester.pumpAndSettle();
      expect(find.text('Delete workout'), findsOneWidget);
      await tester.tap(find.text('Delete workout'));
      await tester.pumpAndSettle();
      // Still asks before deleting.
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
