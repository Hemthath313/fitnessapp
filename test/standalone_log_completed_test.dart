import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/presentation/widgets/interactive_exercise_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpSheet(
  WidgetTester tester, {
  ValueChanged<List<ExerciseSetDraft>>? onSetsChanged,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: InteractiveExerciseDetailWidget(
            // A name outside the catalog, so no video is loaded in the test.
            name: 'Zzz Test Move',
            videoPath: '',
            description: 'Test',
            target: 'Chest',
            equipment: 'Barbell',
            instructions: const ['Move'],
            difficulty: 'Beginner',
            setsReps: '3 sets x 8 reps',
            category: 'Chest',
            onSetsChanged: onSetsChanged,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.text('Log Set'));
  await tester.pump();
}

void main() {
  group('WorkoutLog.fromMap', () {
    test('reads sets saved without the completed flag as completed', () {
      final log = WorkoutLog.fromMap({
        'exerciseName': 'Bench Press',
        'date': Timestamp.fromDate(DateTime(2026, 11, 5)),
        'category': 'Chest',
        'sets': [
          {'weight': 60.0, 'reps': 8, 'type': 'normal', 'isCompleted': false},
          {'weight': 62.5, 'reps': 6, 'type': 'warmup', 'isCompleted': false},
          {'weight': 65.0, 'reps': 5, 'type': 'normal', 'isCompleted': true},
        ],
      }, 'doc1');

      expect(log.sets.every((s) => s.isCompleted), isTrue);
      // Everything else about the set is untouched.
      expect(log.sets[1].weight, 62.5);
      expect(log.sets[1].reps, 6);
      expect(log.sets[1].type, SetType.warmup);
    });
  });

  group('Exercise sheet Log Set tab', () {
    testWidgets('on its own shows Add to workout, not a set table',
        (tester) async {
      await _pumpSheet(tester);
      expect(find.byKey(const Key('detail_add_to_workout_button')), findsOneWidget);
      expect(find.text('Add to workout'), findsOneWidget);
      expect(find.text('Save Session Log'), findsNothing);
      expect(find.byKey(const Key('detail_weight_input_0')), findsNothing);
      expect(find.byKey(const Key('sheet_sync_hint')), findsNothing);
    });

    testWidgets('is replaced by a hint when opened from a workout',
        (tester) async {
      await _pumpSheet(tester, onSetsChanged: (_) {});
      expect(find.text('Save Session Log'), findsNothing);
      expect(find.byKey(const Key('detail_add_to_workout_button')), findsNothing);
      expect(find.byKey(const Key('sheet_sync_hint')), findsOneWidget);
      expect(find.byKey(const Key('detail_weight_input_0')), findsOneWidget);
      expect(find.byKey(const Key('detail_add_set_button')), findsOneWidget);
    });
  });
}
