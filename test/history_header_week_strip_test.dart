import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/workout_logs/workout_log_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

WorkoutSession _todaySession() {
  final now = DateTime.now();
  return WorkoutSession(
    id: 's1',
    userId: 'u',
    workoutName: 'Push Day',
    dayName: 'Push',
    startedAt: now,
    completedAt: now,
    durationSeconds: 1800,
    totalVolume: 1000,
    exercises: [
      SessionExercise(exerciseName: 'Bench Press', order: 0, sets: const []),
    ],
  );
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 1600);
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
        ChangeNotifierProvider<StatisticsProvider>(
          create: (_) => StatisticsProvider(),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          home: WorkoutLogHistoryPage(
            sessionsStream: Stream.value([_todaySession()]),
            logsStream: Stream<List<WorkoutLog>>.value(const []),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('header keeps + visible and moves tools into a menu', (tester) async {
    await _pump(tester);
    expect(find.byKey(const Key('log_past_workout_button')), findsOneWidget);
    expect(find.byTooltip('Export CSV'), findsNothing);
    expect(find.byTooltip('Barbell Plate Calculator'), findsNothing);

    await tester.tap(find.byKey(const Key('history_more_menu')));
    await tester.pumpAndSettle();
    expect(find.text('Plate calculator'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('PRO'), findsOneWidget); // free user
  });

  testWidgets('stats are one line, not three tiles', (tester) async {
    await _pump(tester);
    expect(find.byKey(const Key('history_stats_line')), findsOneWidget);
    expect(find.text('Active Days'), findsNothing);
    expect(find.textContaining('active days', findRichText: true), findsOneWidget);
  });

  testWidgets('week strip shows 7 days and tapping a day filters the feed', (tester) async {
    await _pump(tester);
    expect(find.byKey(const Key('history_week_strip')), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.byType(TableCalendar), findsNothing);

    final todayKey = Key('history_week_day_${DateFormat('yyyyMMdd').format(DateTime.now())}');
    await tester.tap(find.byKey(todayKey));
    await tester.pump();
    expect(find.text('Clear Filter'), findsOneWidget);

    await tester.tap(find.byKey(todayKey));
    await tester.pump();
    expect(find.text('Clear Filter'), findsNothing);
  });

  testWidgets('week arrows move back, forward is disabled on this week', (tester) async {
    await _pump(tester);
    final next = tester.widget<IconButton>(find.byKey(const Key('history_week_next')));
    expect(next.onPressed, isNull);

    await tester.tap(find.byKey(const Key('history_week_prev')));
    await tester.pump();
    expect(find.text('This week'), findsNothing);
    final next2 = tester.widget<IconButton>(find.byKey(const Key('history_week_next')));
    expect(next2.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('history_week_next')));
    await tester.pump();
    expect(find.text('This week'), findsOneWidget);
  });

  testWidgets('Month toggle opens the full calendar and Week returns', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('history_calendar_toggle')));
    await tester.pump();
    expect(find.byType(TableCalendar), findsOneWidget);
    expect(find.byKey(const Key('history_week_strip')), findsNothing);

    await tester.tap(find.byKey(const Key('history_calendar_toggle')));
    await tester.pump();
    expect(find.byType(TableCalendar), findsNothing);
    expect(find.byKey(const Key('history_week_strip')), findsOneWidget);
  });
}
