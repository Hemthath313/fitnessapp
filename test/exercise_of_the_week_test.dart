import 'dart:io';

import 'package:fitness_app/data/challenge_data.dart';
import 'package:fitness_app/presentation/challenges/exercise_of_the_week.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  ChallengeExercise? exercise,
  DateTime? today,
}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: ExerciseOfTheWeekScreen(exercise: exercise, today: today),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

ChallengeExercise _byName(String name) =>
    ChallengeData.weeklyPool.firstWhere((e) => e.name == name);

void main() {
  group('weekly rotation', () {
    test('stays the same all week and changes on Monday', () {
      final monday = DateTime(2026, 11, 9);
      final sunday = DateTime(2026, 11, 15, 23, 59);
      final nextMonday = DateTime(2026, 11, 16);

      final week = ChallengeData.weeklyFeaturedExerciseFor(monday).name;
      for (var d = 0; d < 7; d++) {
        expect(
          ChallengeData.weeklyFeaturedExerciseFor(
            DateTime(2026, 11, 9 + d, 12),
          ).name,
          week,
        );
      }
      expect(ChallengeData.weeklyFeaturedExerciseFor(sunday).name, week);
      expect(
        ChallengeData.weeklyFeaturedExerciseFor(nextMonday).name,
        isNot(week),
      );
    });

    test('cycles through every exercise before repeating', () {
      final start = DateTime(2026, 3, 2);
      final seen = <String>{};
      for (var w = 0; w < ChallengeData.weeklyPool.length; w++) {
        seen.add(ChallengeData.weeklyFeaturedExerciseFor(
          start.add(Duration(days: 7 * w)),
        ).name);
      }
      expect(seen.length, ChallengeData.weeklyPool.length);
    });

    test('does not jump or repeat across New Year', () {
      final lastWeekOfYear = ChallengeData.rotationWeek(DateTime(2026, 12, 28));
      expect(ChallengeData.rotationWeek(DateTime(2027, 1, 3)), lastWeekOfYear);
      expect(
        ChallengeData.rotationWeek(DateTime(2027, 1, 4)),
        lastWeekOfYear + 1,
      );
      expect(
        ChallengeData.weeklyFeaturedExerciseFor(DateTime(2027, 1, 4)).name,
        isNot(ChallengeData.weeklyFeaturedExerciseFor(DateTime(2026, 12, 28))
            .name),
      );
    });

    test('counts days until the next featured exercise', () {
      expect(ChallengeData.daysUntilNextFeatured(DateTime(2026, 11, 9)), 7);
      expect(ChallengeData.daysUntilNextFeatured(DateTime(2026, 11, 12)), 4);
      expect(ChallengeData.daysUntilNextFeatured(DateTime(2026, 11, 15)), 1);
    });
  });

  group('exercise content', () {
    test('every featured exercise has its own cues and mistakes', () {
      for (final e in ChallengeData.weeklyPool) {
        expect(e.tips.length, greaterThanOrEqualTo(3), reason: e.name);
        expect(e.mistakes.length, greaterThanOrEqualTo(2), reason: e.name);
      }
    });

    test('cues differ between exercises', () {
      final first = ChallengeData.weeklyPool.map((e) => e.tips.first).toSet();
      expect(first.length, ChallengeData.weeklyPool.length);
    });

    test('every referenced video asset exists', () {
      for (final e in ChallengeData.weeklyPool.where((e) => e.hasVideo)) {
        expect(File(e.videoPath).existsSync(), isTrue, reason: e.videoPath);
      }
    });
  });

  group('screen', () {
    testWidgets('shows the exercise\'s own cues and mistakes', (tester) async {
      final v = _byName('V-Up');
      await _pump(tester, exercise: v);

      expect(find.text('V-Up'), findsOneWidget);
      expect(find.text('FORM CUES'), findsOneWidget);
      expect(find.text(v.tips.first), findsOneWidget);
      expect(find.text('• ${v.mistakes.first}'), findsOneWidget);
      expect(find.text('Equipment: None'), findsOneWidget);
    });

    testWidgets('falls back to generic cues when none are defined',
        (tester) async {
      await _pump(
        tester,
        exercise: const ChallengeExercise(
          name: 'Mystery Crunch',
          target: 'Abs',
          equipment: 'None',
          videoPath: '',
          setsReps: '3 sets x 10 reps',
        ),
      );
      expect(find.text(ExerciseOfTheWeekScreen.genericTips.first),
          findsOneWidget);
      expect(
        find.text('• ${ExerciseOfTheWeekScreen.genericMistakes.first}'),
        findsOneWidget,
      );
    });

    testWidgets('an exercise without a video shows a clear fallback',
        (tester) async {
      await _pump(tester, exercise: _byName('Plank'));

      expect(find.byKey(const Key('weekly_no_video')), findsOneWidget);
      expect(find.byKey(const Key('weekly_play_pause')), findsNothing);
      expect(find.textContaining('no demo clip'), findsOneWidget);
    });

    testWidgets('the demo can be paused and resumed', (tester) async {
      await _pump(tester, exercise: _byName('V-Up'));

      expect(find.byKey(const Key('weekly_no_video')), findsNothing);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      await tester.tap(find.byKey(const Key('weekly_play_pause')));
      await tester.pump();
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);

      await tester.tap(find.byKey(const Key('weekly_play_pause')));
      await tester.pump();
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });

    testWidgets('tells the user when the next exercise arrives',
        (tester) async {
      await _pump(
        tester,
        exercise: _byName('Plank'),
        today: DateTime(2026, 11, 9),
      );
      expect(find.textContaining('arrives in 7 days'), findsOneWidget);

      await _pump(
        tester,
        exercise: _byName('Plank'),
        today: DateTime(2026, 11, 15),
      );
      expect(find.textContaining('arrives tomorrow'), findsOneWidget);
    });

    testWidgets('offers a way to keep going', (tester) async {
      await _pump(tester, exercise: _byName('Plank'));
      expect(find.byKey(const Key('weekly_explore_abs')), findsOneWidget);
    });
  });
}
