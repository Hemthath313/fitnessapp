import 'package:fitness_app/presentation/widgets/skeleton.dart';
import 'package:fitness_app/utils/app_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => ScreenUtilInit(
      designSize: const Size(430, 810),
      builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('SkeletonList renders the requested number of items',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(const SkeletonList(itemCount: 3)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byWidgetPredicate((w) {
        final k = w.key;
        return k is ValueKey<String> && k.value.startsWith('skeleton_item_');
      }),
      findsNWidgets(3),
    );
  });

  testWidgets('Skeleton does not animate when reduce-motion is on',
      (tester) async {
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: _wrap(const Skeleton(child: SizedBox(width: 10, height: 10))),
    ));
    // Would never settle if a repeating animation were running.
    await tester.pumpAndSettle();
  });

  testWidgets('AppFeedback shows a message and replaces the previous one',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(_wrap(Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    })));
    AppFeedback.error(ctx, 'First');
    await tester.pump();
    expect(find.text('First'), findsOneWidget);
    AppFeedback.success(ctx, 'Second');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Second'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });
}
