import 'package:fitness_app/presentation/home/widgets/weekly_recap_card.dart';
import 'package:fitness_app/services/weekly_recap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => ScreenUtilInit(
      designSize: const Size(430, 810),
      builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  final sunday = DateTime(2026, 11, 8, 10);

  WeeklyRecap recap({List<int> days = const [2, 4, 6], int streak = 5}) {
    final set = days.map((d) => DateTime(2026, 11, d)).toSet();
    return WeeklyRecap.build(
      now: sunday,
      hasWorkoutOn: (d) => set.contains(DateTime(d.year, d.month, d.day)),
      target: 3,
      streak: streak,
    )!;
  }

  testWidgets('shows headline, message and streak chip', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(WeeklyRecapView(recap: recap())));
    expect(find.byKey(const Key('weekly_recap_card')), findsOneWidget);
    expect(find.text('Goal hit: 3 of 3 workouts'), findsOneWidget);
    expect(find.text('5-day streak'), findsOneWidget);
    expect(find.text('YOUR WEEK IN REVIEW'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(3));
  });

  testWidgets('no streak chip when streak is under 2', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        _wrap(WeeklyRecapView(recap: recap(days: const [2, 3], streak: 1))));
    expect(find.textContaining('-day streak'), findsNothing);
  });

  testWidgets('card renders nothing on a non-recap day', (tester) async {
    await tester.pumpWidget(
        _wrap(WeeklyRecapCard(now: DateTime(2026, 11, 11, 9))));
    expect(find.byKey(const Key('weekly_recap_card')), findsNothing);
  });
}
