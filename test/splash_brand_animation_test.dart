import 'package:fitness_app/presentation/splash_screen/widgets/splash_brand_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Animation<double> intro, {double textScale = 1.0}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: SplashBrandAnimation.background,
          body: Center(child: SplashBrandAnimation(intro: intro)),
        ),
      ),
    ),
  );
}

void main() {
  group('SplashBrandAnimation', () {
    testWidgets('wordmark and tagline are hidden at the start and visible at the end',
        (tester) async {
      final controller =
          AnimationController(vsync: const TestVSync(), duration: const Duration(seconds: 2));
      addTearDown(controller.dispose);

      await tester.pumpWidget(_host(controller));
      Opacity opacityOf(Finder f) =>
          tester.widget<Opacity>(find.ancestor(of: f, matching: find.byType(Opacity)).first);

      final tagline = find.text(SplashBrandAnimation.tagline);
      expect(opacityOf(tagline).opacity, 0);

      controller.value = 1;
      await tester.pump();
      expect(opacityOf(tagline).opacity, 1);
      expect(tester.takeException(), isNull);
    });

    for (final width in [320.0, 390.0, 430.0]) {
      testWidgets('does not overflow at ${width.toInt()}px wide with 1.3x text',
          (tester) async {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final controller = AnimationController(
            vsync: const TestVSync(), duration: const Duration(seconds: 2))
          ..value = 1;
        addTearDown(controller.dispose);

        await tester.pumpWidget(_host(controller, textScale: 1.3));
        expect(tester.takeException(), isNull);
        expect(find.byType(CustomPaint), findsWidgets);
      });
    }

    testWidgets('exposes one accessible label for the whole brand moment',
        (tester) async {
      final handle = tester.ensureSemantics();
      final controller = AnimationController(
          vsync: const TestVSync(), duration: const Duration(seconds: 2))
        ..value = 1;
      addTearDown(controller.dispose);

      await tester.pumpWidget(_host(controller));
      expect(
        find.bySemanticsLabel(
            '${SplashBrandAnimation.name}. ${SplashBrandAnimation.tagline}'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('renders every frame of the intro without errors', (tester) async {
      final controller = AnimationController(
          vsync: const TestVSync(), duration: const Duration(seconds: 2));
      addTearDown(controller.dispose);

      await tester.pumpWidget(_host(controller));
      for (var i = 0; i <= 20; i++) {
        controller.value = i / 20;
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'frame $i');
      }
    });
  });
}
