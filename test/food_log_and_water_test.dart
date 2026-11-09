import 'package:fitness_app/model/meal_model.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/diet_nutrition/widgets/todays_food_log_card.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeSubscription extends ChangeNotifier implements SubscriptionProvider {
  _FakeSubscription(this._premium);
  final bool _premium;

  @override
  bool get isPremium => _premium;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MealModel _meal(String id, String title, double kcal,
        {DateTime? at, double protein = 10}) =>
    MealModel(
      id: id,
      title: title,
      calories: kcal,
      amount: 100,
      carbs: 20,
      fats: 5,
      proteins: protein,
      dateTime: at ?? DateTime.now(),
    );

Widget _host(ConsumptionProvider consumption, {required bool premium}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ConsumptionProvider>.value(value: consumption),
      ChangeNotifierProvider<SubscriptionProvider>.value(
          value: _FakeSubscription(premium)),
    ],
    child: const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: TodaysFoodLogCard())),
    ),
  );
}

void main() {
  group('ConsumptionProvider: manual meals count toward today', () {
    test('today total = plan calories + meals logged by hand', () {
      final p = ConsumptionProvider();
      p.setMealsForTesting([
        _meal('1', 'Oats', 350),
        _meal('2', 'Chicken', 450),
      ], planCalories: 600);

      expect(p.manualCaloriesToday, 800);
      expect(p.consumedCalories, 1400);
    });

    test("yesterday's meals are not counted today", () {
      final p = ConsumptionProvider();
      p.setMealsForTesting([
        _meal('1', 'Old dinner', 900,
            at: DateTime.now().subtract(const Duration(days: 1))),
        _meal('2', 'Lunch', 500),
      ]);

      expect(p.todaysMeals.map((m) => m.id), ['2']);
      expect(p.consumedCalories, 500);
    });

    test('macro totals for today add up', () {
      final p = ConsumptionProvider();
      p.setMealsForTesting([
        _meal('1', 'A', 300, protein: 20),
        _meal('2', 'B', 200, protein: 15),
      ]);
      expect(p.manualProteinToday, 35);
      expect(p.manualCarbsToday, 40);
      expect(p.manualFatsToday, 10);
    });
  });

  group('TodaysFoodLogCard', () {
    testWidgets('pro users see their meals, totals and a log button',
        (tester) async {
      final p = ConsumptionProvider()
        ..setMealsForTesting([
          _meal('1', 'Oats', 350),
          _meal('2', 'Chicken', 450),
        ]);
      await tester.pumpWidget(_host(p, premium: true));

      expect(find.text('Oats'), findsOneWidget);
      expect(find.text('Chicken'), findsOneWidget);
      expect(find.byKey(const Key('food_log_add_button')), findsOneWidget);
      expect(find.byKey(const Key('food_log_totals')), findsOneWidget);
      expect(find.textContaining('800 kcal'), findsWidgets);
      expect(find.byKey(const Key('food_log_locked')), findsNothing);
    });

    testWidgets('pro users with nothing logged see an empty state',
        (tester) async {
      await tester.pumpWidget(_host(ConsumptionProvider(), premium: true));
      expect(find.byKey(const Key('food_log_empty')), findsOneWidget);
    });

    testWidgets('free users do not see the card at all (no locked teaser)',
        (tester) async {
      final p = ConsumptionProvider()
        ..setMealsForTesting([_meal('1', 'Oats', 350)]);
      await tester.pumpWidget(_host(p, premium: false));

      expect(find.byKey(const Key('food_log_locked')), findsNothing);
      expect(find.text("Today's Food Log"), findsNothing);
      expect(find.text('Oats'), findsNothing);
      expect(find.byKey(const Key('food_log_add_button')), findsNothing);
    });

    testWidgets('without a consumption provider the card stays hidden',
        (tester) async {
      await tester.pumpWidget(ChangeNotifierProvider<SubscriptionProvider>.value(
        value: _FakeSubscription(true),
        child: const MaterialApp(
          home: Scaffold(body: TodaysFoodLogCard()),
        ),
      ));
      expect(find.text("Today's Food Log"), findsNothing);
    });
  });
}
