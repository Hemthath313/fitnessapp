import 'package:fitness_app/presentation/cardio_workouts/cardio_log_panel.dart';
import 'package:fitness_app/presentation/workout_splits/splits/bro_splits.dart';
import 'package:fitness_app/presentation/workout_splits/splits/full_body_split.dart';
import 'package:fitness_app/presentation/workout_splits/splits/ppl_splits.dart';
import 'package:fitness_app/presentation/workout_splits/splits/upper_lower_splits.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _scaled(Widget child) => ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      builder: (context, _) => child,
    );

Future<void> _pumpSplit(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => page),
    GoRoute(
      path: Routes.workoutGeneratorRoute,
      builder: (_, state) =>
          Scaffold(body: Text('days=${state.uri.queryParameters['days']}')),
    ),
  ]);
  await tester.pumpWidget(_scaled(MaterialApp.router(routerConfig: router)));
  await tester.pumpAndSettle();
}

void main() {
  group('Workout Splits: Use this split', () {
    // The day count is what picks the plan template in the Plan Builder:
    // 3 full body, 4 upper/lower, 5 bro split, 6 push/pull/legs.
    final cases = <(String, Widget, int)>[
      ('Full Body', const FullBodyPage(), 3),
      ('Upper/Lower', const UpperLowerPage(), 4),
      ('Bro Split', const BroSplitPage(), 5),
      ('Push/Pull/Legs', const PPLPage(), 6),
    ];

    for (final (name, page, days) in cases) {
      testWidgets('$name opens the Plan Builder for $days days', (tester) async {
        await _pumpSplit(tester, page);
        await tester.tap(find.byKey(const Key('use_this_split_button')));
        await tester.pumpAndSettle();
        expect(find.text('days=$days'), findsOneWidget);
      });
    }
  });

  group('Cardio timer', () {
    testWidgets('Log cardio is disabled until the timer has run',
        (tester) async {
      await tester.pumpWidget(_scaled(const MaterialApp(
        home: Scaffold(body: CardioLogPanel(exerciseName: 'Running')),
      )));
      await tester.pump();

      expect(find.text('Start'), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
      final log = tester.widget<OutlinedButton>(
          find.byKey(const Key('cardio_log_button')));
      expect(log.onPressed, isNull);
    });

    testWidgets('Start switches to Pause and back', (tester) async {
      await tester.pumpWidget(_scaled(const MaterialApp(
        home: Scaffold(body: CardioLogPanel(exerciseName: 'Running')),
      )));
      await tester.tap(find.byKey(const Key('cardio_timer_toggle')));
      await tester.pump();
      expect(find.text('Pause'), findsOneWidget);

      await tester.tap(find.byKey(const Key('cardio_timer_toggle')));
      await tester.pump();
      expect(find.text('Pause'), findsNothing);
    });
  });
}
