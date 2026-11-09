import 'package:fitness_app/presentation/workout_logs/workout_log_screen.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host() {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('open_log'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WorkoutLogScreen()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(_host());
  await tester.tap(find.byKey(const Key('open_log')));
  await tester.pumpAndSettle();
}

Future<void> _fillExercise(
  WidgetTester tester,
  String chip, {
  String weight = '100',
  String reps = '5',
}) async {
  await tester.ensureVisible(find.text(chip));
  await tester.tap(find.text(chip));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('quick_log_weight_input_0')), weight);
  await tester.enterText(find.byKey(const Key('quick_log_reps_input_0')), reps);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => WorkoutLogService.clearLastLogCache());

  testWidgets('date defaults to Today and saves with today\'s date', (tester) async {
    await _open(tester);
    expect(find.text('Today'), findsOneWidget);

    await _fillExercise(tester, 'Barbell Squat');
    await _tap(tester, const Key('log_save_button'));

    final logs = WorkoutLogService.localLogsForTesting;
    expect(logs, hasLength(1));
    final now = DateTime.now();
    expect(logs.first.date.year, now.year);
    expect(logs.first.date.month, now.month);
    expect(logs.first.date.day, now.day);
  });

  testWidgets('a past date is saved on that day, not today', (tester) async {
    final now = DateTime.now();
    if (now.day == 1) return; // yesterday would be in the previous month view
    final target = now.day - 1;

    await _open(tester);
    await _tap(tester, const Key('log_date_row'));
    await tester.tap(find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.text('$target'),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Yesterday'), findsOneWidget);

    await _fillExercise(tester, 'Deadlift');
    await _tap(tester, const Key('log_save_button'));

    final logs = WorkoutLogService.localLogsForTesting;
    expect(logs, hasLength(1));
    expect(logs.first.date.day, target);
  });

  testWidgets('two strength exercises are saved as one session', (tester) async {
    await _open(tester);

    await _fillExercise(tester, 'Barbell Squat');
    await _tap(tester, const Key('log_add_another_button'));
    expect(find.byKey(const Key('log_added_0')), findsOneWidget);
    // The form is cleared for the next exercise.
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('quick_log_reps_input_0')))
          .controller!
          .text,
      isEmpty,
    );

    await _fillExercise(tester, 'Deadlift', weight: '120', reps: '3');
    await _tap(tester, const Key('log_save_button'));

    final sessions = WorkoutLogService.localSessionsForTesting;
    expect(sessions, hasLength(1));
    expect(sessions.first.exercises.map((e) => e.exerciseName).toList(),
        ['Barbell Squat', 'Deadlift']);
    expect(sessions.first.totalVolume, 100 * 5 + 120 * 3);
  });

  testWidgets('adding an exercise with no reps is refused', (tester) async {
    await _open(tester);
    await tester.ensureVisible(find.text('Deadlift'));
    await tester.tap(find.text('Deadlift'));
    await tester.pumpAndSettle();
    await _tap(tester, const Key('log_add_another_button'));
    expect(find.text('Please enter at least 1 rep for your sets'), findsOneWidget);
    expect(find.byKey(const Key('log_added_0')), findsNothing);
  });

  testWidgets('an added exercise can be removed before saving', (tester) async {
    await _open(tester);
    await _fillExercise(tester, 'Barbell Squat');
    await _tap(tester, const Key('log_add_another_button'));
    expect(find.byKey(const Key('log_added_0')), findsOneWidget);
    await _tap(tester, const Key('log_added_remove_0'));
    expect(find.byKey(const Key('log_added_0')), findsNothing);
  });
}
