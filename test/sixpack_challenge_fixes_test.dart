import 'dart:async';

import 'package:fitness_app/data/challenge_data.dart';
import 'package:fitness_app/presentation/challenges/30_days_sixpack.dart';
import 'package:fitness_app/presentation/challenges/challenge_progress.dart';
import 'package:fitness_app/presentation/challenges/daily_challenge.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeSub extends ChangeNotifier implements SubscriptionProvider {
  _FakeSub({this.premium = false, this.loading = false});

  bool premium;
  bool loading;

  @override
  bool get isPremium => premium;

  @override
  bool get isLoading => loading;

  void update({bool? premium, bool? loading}) {
    this.premium = premium ?? this.premium;
    this.loading = loading ?? this.loading;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStore implements SixPackProgressStore {
  _FakeStore({this.progress = const ChallengeProgress()});

  ChallengeProgress progress;
  Object? loadError;
  Object? saveError;
  Completer<void>? saveGate;
  final recordGate = Completer<void>();

  final savedDays = <int>[];
  var loads = 0;
  var records = 0;
  final feedback = <String>[];

  @override
  Future<ChallengeProgress> load() async {
    loads++;
    final error = loadError;
    if (error != null) throw error;
    return progress;
  }

  @override
  Future<void> saveCompletion(int day) async {
    savedDays.add(day);
    final gate = saveGate;
    if (gate != null) await gate.future;
    final error = saveError;
    if (error != null) throw error;
  }

  @override
  Future<void> saveFeedback(String text) async {
    feedback.add(text);
  }

  @override
  Future<void> recordWorkout(int day) async {
    records++;
    await recordGate.future;
  }
}

Future<void> _pump(WidgetTester tester, Widget child, _FakeSub sub) async {
  tester.view.physicalSize = const Size(900, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: ChangeNotifierProvider<SubscriptionProvider>.value(
          value: sub,
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

/// Pumps [page] on top of a root route so `Navigator.pop` behaves as in the app.
Future<void> _pumpPushed(WidgetTester tester, Widget page, _FakeSub sub) async {
  tester.view.physicalSize = const Size(900, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChangeNotifierProvider<SubscriptionProvider>.value(
                    value: sub,
                    child: page,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _checkAllThree(WidgetTester tester) async {
  final boxes = find.byType(Checkbox);
  for (var i = 0; i < 3; i++) {
    await tester.tap(boxes.at(i));
    await tester.pump();
  }
}

Finder _finishButton(int day) =>
    find.widgetWithText(ElevatedButton, 'Finish Day $day');

void main() {
  group('ChallengeProgress', () {
    test('parses missing / odd Firestore data safely', () {
      expect(ChallengeProgress.fromMap(null).lastCompletedDay, 0);
      expect(ChallengeProgress.fromMap({}).currentDay, 1);
      expect(
        ChallengeProgress.fromMap({'lastCompletedDay': 4.0}).lastCompletedDay,
        4,
      );
      expect(
        ChallengeProgress.fromMap({'lastCompletedDay': 'x'}).lastCompletedDay,
        0,
      );
      expect(
        ChallengeProgress.fromMap({'lastCompletedDay': 99}).lastCompletedDay,
        30,
      );
      expect(
        ChallengeProgress.fromMap({'completionDate': 'not a date'})
            .completionDate,
        isNull,
      );
    });

    test('only moves forward', () {
      const p = ChallengeProgress(lastCompletedDay: 5);
      expect(p.advancesProgress(6), isTrue);
      expect(p.advancesProgress(5), isFalse);
      expect(p.advancesProgress(2), isFalse);
      expect(p.isCompleted(5), isTrue);
      expect(p.isCompleted(6), isFalse);
      expect(p.currentDay, 6);
    });

    test('detects a workout completed today', () {
      final now = DateTime(2026, 11, 9, 20);
      expect(
        ChallengeProgress(
          lastCompletedDay: 1,
          completionDate: DateTime(2026, 11, 9, 7),
        ).isCompletedToday(now),
        isTrue,
      );
      expect(
        ChallengeProgress(
          lastCompletedDay: 1,
          completionDate: DateTime(2026, 11, 8, 23),
        ).isCompletedToday(now),
        isFalse,
      );
      expect(const ChallengeProgress().isCompletedToday(now), isFalse);
    });
  });

  group('Finish Day', () {
    testWidgets('shows the celebration without waiting for logging/streak',
        (tester) async {
      final store = _FakeStore();
      var streakCalls = 0;
      var completes = 0;
      await _pump(
        tester,
        DailyExercisePage(
          day: 1,
          onComplete: () => completes++,
          store: store,
          updateStreak: () async => streakCalls++,
        ),
        _FakeSub(),
      );

      await _checkAllThree(tester);
      await tester.tap(_finishButton(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // recordWorkout is still blocked, yet the dialog is already up.
      expect(store.savedDays, [1]);
      expect(store.records, 1);
      expect(streakCalls, 0);
      expect(find.textContaining('Day 1 Done'), findsOneWidget);
      expect(completes, 1);

      // Background work finishes afterwards.
      store.recordGate.complete();
      await tester.pump();
      await tester.pump();
      expect(streakCalls, 1);
    });

    testWidgets('shows progress and ignores a second tap while saving',
        (tester) async {
      final store = _FakeStore()..saveGate = Completer<void>();
      await _pump(
        tester,
        DailyExercisePage(
          day: 1,
          onComplete: () {},
          store: store,
          updateStreak: () async {},
        ),
        _FakeSub(),
      );

      await _checkAllThree(tester);
      await tester.tap(_finishButton(1));
      await tester.pump();

      expect(find.byKey(const Key('sixpack_finish_progress')), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();
      expect(store.savedDays, [1]);

      store.saveGate!.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.textContaining('Day 1 Done'), findsOneWidget);
      expect(find.byKey(const Key('sixpack_finish_progress')), findsNothing);
    });

    testWidgets('a failed save tells the user and allows a retry',
        (tester) async {
      final store = _FakeStore()..saveError = Exception('offline');
      await _pump(
        tester,
        DailyExercisePage(
          day: 1,
          onComplete: () {},
          store: store,
          updateStreak: () async {},
        ),
        _FakeSub(),
      );

      await _checkAllThree(tester);
      await tester.tap(_finishButton(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining("Couldn't save your progress"), findsOneWidget);
      expect(find.textContaining('Day 1 Done'), findsNothing);
      expect(store.records, 0);
      expect(_finishButton(1), findsOneWidget);

      // Retry succeeds.
      store.saveError = null;
      await tester.tap(_finishButton(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(store.savedDays, [1, 1]);
      expect(find.textContaining('Day 1 Done'), findsOneWidget);
    });

    testWidgets('a slow save is queued: user still moves on, with a notice',
        (tester) async {
      final store = _FakeStore()..saveError = TimeoutException('slow');
      await _pump(
        tester,
        DailyExercisePage(
          day: 1,
          onComplete: () {},
          store: store,
          updateStreak: () async {},
        ),
        _FakeSub(),
      );

      await _checkAllThree(tester);
      await tester.tap(_finishButton(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('Day 1 Done'), findsOneWidget);
      expect(find.textContaining('will sync'), findsOneWidget);
    });

    testWidgets('re-doing an earlier day never rewinds progress',
        (tester) async {
      final store = _FakeStore(
        progress: ChallengeProgress(
          lastCompletedDay: 3,
          completionDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
      await _pump(
        tester,
        DailyExercisePage(
          day: 2,
          onComplete: () {},
          store: store,
          updateStreak: () async {},
        ),
        _FakeSub(),
      );

      // Already-completed day opens with everything ticked.
      expect(
        tester.widgetList<Checkbox>(find.byType(Checkbox)).every((c) => c.value!),
        isTrue,
      );

      expect(find.byKey(const Key('sixpack_completed_banner')), findsOneWidget);
      expect(find.text('Finish Day 2'), findsNothing);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Log Day 2 again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(store.savedDays, isEmpty);
      expect(store.records, 1);
      expect(find.textContaining('Day 2 Done'), findsOneWidget);
    });
  });

  group('Pro lock on the day screen', () {
    testWidgets('does not flash the paywall while membership is loading',
        (tester) async {
      final sub = _FakeSub(loading: true);
      await _pump(
        tester,
        DailyExercisePage(day: 4, onComplete: () {}, store: _FakeStore()),
        sub,
      );

      expect(find.text('Premium Day'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      sub.update(premium: true, loading: false);
      await tester.pump();
      expect(find.text('Premium Day'), findsNothing);
      expect(find.byType(Checkbox), findsNWidgets(3));
    });

    testWidgets('shows the paywall for a confirmed free user', (tester) async {
      await _pump(
        tester,
        DailyExercisePage(day: 4, onComplete: () {}, store: _FakeStore()),
        _FakeSub(),
      );
      expect(find.text('Premium Day'), findsOneWidget);
      expect(find.textContaining('Finish Day'), findsNothing);
    });

    testWidgets('days 1-3 stay free', (tester) async {
      await _pump(
        tester,
        DailyExercisePage(day: 3, onComplete: () {}, store: _FakeStore()),
        _FakeSub(),
      );
      expect(find.text('Premium Day'), findsNothing);
    });
  });

  group('Challenge list', () {
    testWidgets('shows an error with retry instead of a blank screen',
        (tester) async {
      final store = _FakeStore()..loadError = Exception('no network');
      await _pump(
        tester,
        SixPackChallengeSelectionScreen(store: store),
        _FakeSub(),
      );

      expect(find.text("Couldn't load your challenge progress"), findsOneWidget);
      expect(find.byType(GridView), findsNothing);

      store
        ..loadError = null
        ..progress = const ChallengeProgress(lastCompletedDay: 2);
      await tester.tap(find.byKey(const Key('sixpack_retry_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
      expect(store.loads, 2);
    });

    testWidgets('tapping a Pro day while membership loads does not open paywall',
        (tester) async {
      await _pump(
        tester,
        SixPackChallengeSelectionScreen(store: _FakeStore()),
        _FakeSub(loading: true),
      );

      await tester.tap(find.byIcon(Icons.lock).first);
      await tester.pump();

      expect(find.textContaining('Checking your membership'), findsOneWidget);
    });
  });

  group('Locked-day messaging', () {
    test('tells the user which day is next', () {
      const p = ChallengeProgress(lastCompletedDay: 4);
      final now = DateTime(2026, 11, 9, 10);
      final msg = p.lockedMessage(8, now);
      expect(msg, contains('Day 8 unlocks after you finish Day 7'));
      expect(msg, contains('on Day 5'));
    });

    test('explains the once-a-day rule for today\'s slot', () {
      final now = DateTime(2026, 11, 9, 10);
      final p = ChallengeProgress(lastCompletedDay: 2, completionDate: now);
      expect(p.lockedMessage(3, now), contains('Day 3 unlocks tomorrow'));
    });

    testWidgets('a future day shows the specific message', (tester) async {
      await _pump(
        tester,
        SixPackChallengeSelectionScreen(store: _FakeStore()),
        _FakeSub(premium: true),
      );
      await tester.tap(find.text('3'));
      await tester.pump();
      expect(
        find.textContaining('Day 3 unlocks after you finish Day 2'),
        findsOneWidget,
      );
    });

    testWidgets("today's wait slot explains the rest rule", (tester) async {
      final store = _FakeStore(
        progress: ChallengeProgress(
          lastCompletedDay: 1,
          completionDate: DateTime.now(),
        ),
      );
      await _pump(
        tester,
        SixPackChallengeSelectionScreen(store: store),
        _FakeSub(),
      );
      await tester.tap(find.byIcon(Icons.access_time_filled));
      await tester.pump();
      expect(find.text('Come back tomorrow!'), findsOneWidget);
      expect(find.textContaining('next day unlocks tomorrow'), findsOneWidget);
    });
  });

  group('Pro preview', () {
    testWidgets('shows the day\'s exercises before the paywall',
        (tester) async {
      await _pump(
        tester,
        SixPackChallengeSelectionScreen(store: _FakeStore()),
        _FakeSub(),
      );
      await tester.tap(find.byIcon(Icons.lock).first);
      await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Day 4 is a Pro day'), findsOneWidget);
      for (final exercise in ChallengeData.sixPackCurriculum[4]!) {
        expect(find.text(exercise.name), findsWidgets);
      }
      expect(find.byKey(const Key('sixpack_pro_preview_cta')), findsOneWidget);
    });
  });

  group('Completed day and Day 30', () {
    testWidgets('a fresh day has no completed banner', (tester) async {
      await _pump(
        tester,
        DailyExercisePage(day: 1, onComplete: () {}, store: _FakeStore()),
        _FakeSub(),
      );
      expect(find.byKey(const Key('sixpack_completed_banner')), findsNothing);
      expect(_finishButton(1), findsNothing);
      expect(find.text('Complete all 3 workouts'), findsOneWidget);
    });

    testWidgets('Day 30 feedback is saved', (tester) async {
      final store = _FakeStore();
      await _pumpPushed(
        tester,
        DailyExercisePage(
          day: 30,
          onComplete: () {},
          store: store,
          updateStreak: () async {},
        ),
        _FakeSub(premium: true),
      );

      await _checkAllThree(tester);
      await tester.tap(_finishButton(30));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.textContaining('CHALLENGE COMPLETE'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('sixpack_feedback_field')),
        '  Loved the plan  ',
      );
      await tester.tap(find.text('Submit & Finish'));
      await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));

      expect(store.feedback, ['Loved the plan']);
      expect(find.text('Thank you for your feedback!'), findsOneWidget);
    });

    testWidgets('Day 30 with no feedback saves nothing', (tester) async {
      final store = _FakeStore();
      await _pumpPushed(
        tester,
        DailyExercisePage(
          day: 30,
          onComplete: () {},
          store: store,
          updateStreak: () async {},
        ),
        _FakeSub(premium: true),
      );

      await _checkAllThree(tester);
      await tester.tap(_finishButton(30));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Submit & Finish'));
      await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));

      expect(store.feedback, isEmpty);
      expect(find.textContaining('Well done'), findsOneWidget);
    });
  });
}
