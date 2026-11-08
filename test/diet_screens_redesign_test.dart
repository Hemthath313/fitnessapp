import 'package:fitness_app/presentation/consumption/pages/new_meal_page.dart';
import 'package:fitness_app/presentation/diet_nutrition/meals/meal_card.dart';
import 'package:fitness_app/presentation/diet_nutrition/summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(430, 932),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

Map<String, dynamic> _meal({bool done = false, num protein = 25, num kcal = 700}) =>
    {
      'name': 'Breakfast',
      'calories': kcal,
      'protein': protein,
      'isCompleted': done,
    };

void main() {
  group('MealCard', () {
    testWidgets('shows meal info and uses no ListTile', (tester) async {
      await tester.pumpWidget(_wrap(MealCard(
        meal: _meal(),
        index: 0,
        onToggleMeal: (_) {},
        onTap: () {},
      )));

      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('700 kcal | 25g Protein'), findsOneWidget);
      // ListTile inside a coloured container caused the "ink splashes may be
      // invisible" warning.
      expect(find.byType(ListTile), findsNothing);
      expect(find.byIcon(Icons.free_breakfast_rounded), findsOneWidget);
    });

    testWidgets('check button toggles, card body opens details',
        (tester) async {
      bool? toggled;
      var opened = 0;
      await tester.pumpWidget(_wrap(MealCard(
        meal: _meal(),
        index: 0,
        onToggleMeal: (v) => toggled = v,
        onTap: () => opened++,
      )));

      await tester.tap(find.bySemanticsLabel('Mark Breakfast as eaten'));
      await tester.pump();
      expect(toggled, isTrue);
      expect(opened, 0);

      await tester.tap(find.text('Breakfast'));
      await tester.pump();
      expect(opened, 1);
    });

    testWidgets('completed meal shows a check mark and un-toggles',
        (tester) async {
      bool? toggled;
      await tester.pumpWidget(_wrap(MealCard(
        meal: _meal(done: true),
        index: 0,
        onToggleMeal: (v) => toggled = v,
        onTap: () {},
      )));

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Mark Breakfast as eaten'));
      await tester.pump();
      expect(toggled, isFalse);
    });

    testWidgets('badges: high protein and low calorie', (tester) async {
      await tester.pumpWidget(_wrap(MealCard(
        meal: _meal(protein: 40, kcal: 800),
        index: 0,
        onToggleMeal: (_) {},
        onTap: () {},
      )));
      expect(find.text('High Protein'), findsOneWidget);

      await tester.pumpWidget(_wrap(MealCard(
        meal: _meal(protein: 5, kcal: 200),
        index: 0,
        onToggleMeal: (_) {},
        onTap: () {},
      )));
      expect(find.text('Low Cal'), findsOneWidget);
      expect(find.text('High Protein'), findsNothing);
    });
  });

  group('SummaryCard', () {
    testWidgets('shows consumed, total and calories left', (tester) async {
      await tester.pumpWidget(_wrap(const SummaryCard(
        totalCalories: 2000,
        totalProtein: 150,
        totalCarbs: 200,
        totalFats: 60,
        remainingCalories: 1500,
        remainingProtein: 100,
        remainingCarbs: 150,
        remainingFats: 40,
      )));

      expect(find.text('500 / 2000 kcal'), findsOneWidget);
      expect(find.text('1500 kcal left'), findsOneWidget);
      expect(find.text('50g'), findsOneWidget);
      expect(find.text('Target: 150 g'), findsOneWidget);
    });

    testWidgets('does not break when targets are zero', (tester) async {
      await tester.pumpWidget(_wrap(const SummaryCard(
        totalCalories: 0,
        totalProtein: 0,
        totalCarbs: 0,
        totalFats: 0,
        remainingCalories: 0,
        remainingProtein: 0,
        remainingCarbs: 0,
        remainingFats: 0,
      )));

      expect(find.text('0 / 0 kcal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('NewMealPage', () {
    testWidgets('validates required fields before saving', (tester) async {
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(430, 932),
        minTextAdapt: true,
        builder: (context, _) => const MaterialApp(home: NewMealPage()),
      ));

      expect(find.text('Add Meal'), findsNWidgets(2)); // title + button
      expect(find.text('Nutrition'), findsOneWidget);

      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Add Meal'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Meal'));
      await tester.pump();

      expect(find.text('Give the meal a name'), findsOneWidget);
      expect(find.text('Enter the amount'), findsOneWidget);
      expect(find.text('Enter calories'), findsOneWidget);
    });
  });
}
