import 'package:fitness_app/presentation/workout_tools/plate_calculator_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void _configureTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _wrapWithScreenUtil(Widget child) {
  return ScreenUtilInit(
    key: UniqueKey(),
    designSize: const Size(430, 932),
    child: child,
    builder: (_, wrappedChild) => MaterialApp(
      home: Scaffold(body: wrappedChild),
    ),
  );
}

void main() {
  group('Plate Calculator Free Utility Verification', () {
    testWidgets('PlateCalculatorSheet renders as a free utility without PRO badges or locks', (tester) async {
      _configureTestViewport(tester);

      await tester.pumpWidget(
        _wrapWithScreenUtil(
          const PlateCalculatorSheet(initialWeight: 60.0),
        ),
      );
      await tester.pumpAndSettle();

      // Title must be present
      expect(find.text('Barbell Plate Math'), findsOneWidget);
      expect(find.text('Visual Olympic plate calculator per side'), findsOneWidget);

      // Misleading Pro badge must NOT be present
      expect(find.text('PRO TOOL'), findsNothing);
      expect(find.text('PRO'), findsNothing);
      expect(find.byIcon(Icons.lock), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
    });

    testWidgets('PlateCalculatorSheet calculates Olympic plates correctly for 60 kg', (tester) async {
      _configureTestViewport(tester);

      await tester.pumpWidget(
        _wrapWithScreenUtil(
          const PlateCalculatorSheet(initialWeight: 60.0),
        ),
      );
      await tester.pumpAndSettle();

      // Total weight: 60 kg, Bar weight: 20 kg, Per side: 20 kg
      expect(find.text('Total Weight'), findsOneWidget);
      expect(find.text('Bar Weight'), findsOneWidget);
      expect(find.text('Per Side'), findsOneWidget);

      // Breakdown should show 1 x 20 kg per side
      expect(find.text('1 × 20 kg'), findsOneWidget);
    });

    testWidgets('PlateCalculatorSheet quick delta buttons update calculation seamlessly', (tester) async {
      _configureTestViewport(tester);

      await tester.pumpWidget(
        _wrapWithScreenUtil(
          const PlateCalculatorSheet(initialWeight: 60.0),
        ),
      );
      await tester.pumpAndSettle();

      // Tap +10 delta button
      final plus10Finder = find.text('+10');
      expect(plus10Finder, findsOneWidget);
      await tester.tap(plus10Finder);
      await tester.pumpAndSettle();

      // New total: 70 kg, Per side: 25 kg -> 1 x 25 kg plate
      expect(find.text('1 × 25 kg'), findsOneWidget);
    });

    testWidgets('PlateCalculatorSheet invokes onWeightApplied callback without paywall', (tester) async {
      _configureTestViewport(tester);
      double? appliedWeight;

      await tester.pumpWidget(
        _wrapWithScreenUtil(
          PlateCalculatorSheet(
            initialWeight: 80.0,
            onWeightApplied: (w) => appliedWeight = w,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final applyButton = find.text('Apply 80 kg to Set');
      expect(applyButton, findsOneWidget);

      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      expect(appliedWeight, 80.0);
    });

    testWidgets('PlateCalculatorSheet allows switching to LBS freely without restriction', (tester) async {
      _configureTestViewport(tester);

      await tester.pumpWidget(
        _wrapWithScreenUtil(
          const PlateCalculatorSheet(initialWeight: 60.0),
        ),
      );
      await tester.pumpAndSettle();

      // Tap LBS toggle
      final lbsToggle = find.text('LBS');
      expect(lbsToggle, findsOneWidget);
      await tester.tap(lbsToggle);
      await tester.pumpAndSettle();

      // Switched to lbs; bar is standard 45lb
      expect(find.text('Standard (45lb)'), findsOneWidget);
      expect(find.text('PRO TOOL'), findsNothing);
    });
  });
}
