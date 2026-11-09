import 'package:fitness_app/presentation/diet_nutrition/summary_card.dart';
import 'package:fitness_app/presentation/diet_nutrition/widgets/custom_meal_dialog.dart';
import 'package:fitness_app/presentation/diet_nutrition/widgets/pro_feature_gate.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

Widget _wrapScreenUtil(Widget child) => ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

Widget _gated({required bool premium}) => ChangeNotifierProvider<
        SubscriptionProvider>.value(
      value: _FakeSubscription(premium),
      child: const MaterialApp(
        home: ProFeatureGate(child: Scaffold(body: Text('LOGGING SCREEN'))),
      ),
    );

void main() {
  group('SummaryCard shows overeating honestly', () {
    testWidgets('eaten above the target shows "over", not 0 left',
        (tester) async {
      await tester.pumpWidget(_wrapScreenUtil(const SummaryCard(
        totalCalories: 2000,
        totalProtein: 150,
        totalCarbs: 200,
        totalFats: 60,
        remainingCalories: 0,
        remainingProtein: 0,
        remainingCarbs: 0,
        remainingFats: 0,
        consumedCalories: 2300,
        consumedProtein: 160,
        consumedCarbs: 210,
        consumedFats: 70,
      )));

      expect(find.text('2300 / 2000 kcal'), findsOneWidget);
      expect(find.text('300 kcal over'), findsOneWidget);
      expect(find.text('160g'), findsOneWidget);
      expect(find.textContaining('kcal left'), findsNothing);
    });

    testWidgets('under the target still shows calories left', (tester) async {
      await tester.pumpWidget(_wrapScreenUtil(const SummaryCard(
        totalCalories: 2000,
        totalProtein: 150,
        totalCarbs: 200,
        totalFats: 60,
        remainingCalories: 1500,
        remainingProtein: 100,
        remainingCarbs: 150,
        remainingFats: 40,
        consumedCalories: 500,
      )));
      expect(find.text('1500 kcal left'), findsOneWidget);
      expect(find.textContaining('over'), findsNothing);
    });
  });

  group('CustomMealValidation', () {
    test('name is required and bounded', () {
      expect(CustomMealValidation.name(''), isNotNull);
      expect(CustomMealValidation.name('   '), isNotNull);
      expect(CustomMealValidation.name('Oats'), isNull);
      expect(CustomMealValidation.name('x' * 41), isNotNull);
    });

    test('calories must be a positive whole number within range', () {
      expect(CustomMealValidation.calories(''), isNotNull);
      expect(CustomMealValidation.calories('0'), isNotNull);
      expect(CustomMealValidation.calories('abc'), isNotNull);
      expect(CustomMealValidation.calories('450'), isNull);
      expect(CustomMealValidation.calories('99999'), isNotNull);
    });

    test('macros are optional and accept decimals', () {
      expect(CustomMealValidation.macro(''), isNull);
      expect(CustomMealValidation.macro('12.5'), isNull);
      expect(CustomMealValidation.macro('-1'), isNotNull);
      expect(CustomMealValidation.macro('9999'), isNotNull);
      expect(CustomMealValidation.macro('x'), isNotNull);
    });

    test('decimal grams round instead of silently becoming 0', () {
      expect(CustomMealValidation.grams('12.5'), 13);
      expect(CustomMealValidation.grams('12.4'), 12);
      expect(CustomMealValidation.grams(''), 0);
      expect(CustomMealValidation.grams(null), 0);
    });
  });

  group('Custom meal dialog', () {
    testWidgets('does not submit an empty form, then returns a valid meal',
        (tester) async {
      CustomMealInput? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await showCustomMealDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('custom_meal_add_button')));
      await tester.pump();
      expect(result, isNull);
      expect(find.text('Give the meal a name'), findsOneWidget);
      expect(find.text('Enter the calories'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('custom_meal_meal')), 'Oats');
      await tester.enterText(find.byKey(const Key('custom_meal_calories')), '350');
      await tester.enterText(find.byKey(const Key('custom_meal_protein')), '12.5');
      await tester.tap(find.byKey(const Key('custom_meal_add_button')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.name, 'Oats');
      expect(result!.calories, 350);
      expect(result!.protein, 13);
      expect(result!.carbs, 0);
    });
  });

  group('ProFeatureGate (meal logging is Pro-only)', () {
    testWidgets('free users see the upgrade prompt, not the screen',
        (tester) async {
      await tester.pumpWidget(_gated(premium: false));
      expect(find.text('LOGGING SCREEN'), findsNothing);
      expect(find.byKey(const Key('pro_gate_title')), findsOneWidget);
      expect(find.byKey(const Key('pro_gate_upgrade_button')), findsOneWidget);
    });

    testWidgets('pro users see the screen', (tester) async {
      await tester.pumpWidget(_gated(premium: true));
      expect(find.text('LOGGING SCREEN'), findsOneWidget);
      expect(find.byKey(const Key('pro_gate_title')), findsNothing);
    });

    testWidgets('without a subscription provider the child is shown',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: ProFeatureGate(child: Scaffold(body: Text('LOGGING SCREEN'))),
      ));
      expect(find.text('LOGGING SCREEN'), findsOneWidget);
    });
  });
}
