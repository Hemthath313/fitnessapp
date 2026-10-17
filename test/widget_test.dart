import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';

void main() {
  testWidgets('Gym Buddy core theme and brand identity smoke test', (WidgetTester tester) async {
    // Build a test widget utilizing Gym Buddy's core theme colors and brand palette
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          primaryColor: ColorManager.primary,
          scaffoldBackgroundColor: ColorManager.background,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Gym Buddy'),
            backgroundColor: ColorManager.primary,
          ),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Adaptive Strength Partner',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.neonVolt,
                  ),
                  child: const Text('Start Workout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Verify brand typography and widgets render successfully
    expect(find.text('Gym Buddy'), findsOneWidget);
    expect(find.text('Adaptive Strength Partner'), findsOneWidget);
    expect(find.text('Start Workout'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
