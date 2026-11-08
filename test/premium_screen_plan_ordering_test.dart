import 'package:fitness_app/presentation/in_app_purchases/premimum_screen.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

class _FakeProductDetails extends ProductDetails {
  _FakeProductDetails({
    required super.id,
    required super.title,
    required super.description,
    required super.price,
    required super.rawPrice,
    required super.currencyCode,
  });
}

class _TestSubscriptionProvider extends SubscriptionProvider {
  _TestSubscriptionProvider({
    required List<SubscriptionPlan> mockPlans,
    bool isPremium = false,
  })  : _mockPlans = mockPlans,
        _testIsPremium = isPremium,
        super(autoInitialize: false);

  final List<SubscriptionPlan> _mockPlans;
  final bool _testIsPremium;

  @override
  bool get isPremium => _testIsPremium;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  List<SubscriptionPlan> get plans => _mockPlans;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final monthlyDetails = _FakeProductDetails(
    id: 'gymbuddy_premium_monthly:monthly',
    title: 'Gym Buddy AI Premium Monthly',
    description: 'Auto-renews every month.',
    price: '\$9.99',
    rawPrice: 9.99,
    currencyCode: 'USD',
  );

  final yearlyDetails = _FakeProductDetails(
    id: 'gymbuddy_premium_monthly:yearly',
    title: 'Gym Buddy AI Premium Yearly',
    description: 'Best value! Auto-renews every year.',
    price: '\$79.99',
    rawPrice: 79.99,
    currencyCode: 'USD',
  );

  final lifetimeDetails = _FakeProductDetails(
    id: 'premium_yearly',
    title: 'Gym Buddy AI Premium Lifetime',
    description: 'One-time payment. Full lifetime access.',
    price: '\$149.99',
    rawPrice: 149.99,
    currencyCode: 'USD',
  );

  final monthlyPlan = SubscriptionPlan(
    id: 'gymbuddy_premium_monthly:monthly',
    title: 'Gym Buddy AI Premium Monthly',
    description: 'Auto-renews every month.',
    price: '\$9.99',
    isYearly: false,
    isLifetime: false,
    productDetails: monthlyDetails,
  );

  final yearlyPlan = SubscriptionPlan(
    id: 'gymbuddy_premium_monthly:yearly',
    title: 'Gym Buddy AI Premium Yearly',
    description: 'Best value! Auto-renews every year.',
    price: '\$79.99',
    isYearly: true,
    isLifetime: false,
    productDetails: yearlyDetails,
  );

  final lifetimePlan = SubscriptionPlan(
    id: 'premium_yearly',
    title: 'Gym Buddy AI Premium Lifetime',
    description: 'One-time payment. Full lifetime access.',
    price: '\$149.99',
    isYearly: false,
    isLifetime: true,
    productDetails: lifetimeDetails,
  );

  group('Premium Screen Plan Ordering Tests', () {
    testWidgets(
      'Plans are strictly displayed in order: Monthly first, Yearly second, Lifetime last',
      (tester) async {
        // Provide them deliberately in reverse/jumbled order: Lifetime, Yearly, Monthly
        final jumbledPlans = [lifetimePlan, yearlyPlan, monthlyPlan];

        final provider = _TestSubscriptionProvider(mockPlans: jumbledPlans);

        tester.view.physicalSize = const Size(430, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ChangeNotifierProvider<SubscriptionProvider>.value(
            value: provider,
            child: ScreenUtilInit(
              designSize: const Size(375, 812),
              builder: (_, __) => const MaterialApp(
                home: PremiumScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check that all 3 plans are rendered
        final monthlyFinder = find.text('Gym Buddy AI Premium Monthly');
        final yearlyFinder = find.text('Gym Buddy AI Premium Yearly');
        final lifetimeFinder = find.text('Gym Buddy AI Premium Lifetime');

        expect(monthlyFinder, findsOneWidget);
        expect(yearlyFinder, findsOneWidget);
        expect(lifetimeFinder, findsOneWidget);

        // Verify vertical position: Monthly top, Yearly middle, Lifetime bottom (at last)
        final monthlyTop = tester.getTopLeft(monthlyFinder).dy;
        final yearlyTop = tester.getTopLeft(yearlyFinder).dy;
        final lifetimeTop = tester.getTopLeft(lifetimeFinder).dy;

        expect(
          monthlyTop < yearlyTop,
          isTrue,
          reason: 'Monthly plan ($monthlyTop) must appear before Yearly plan ($yearlyTop)',
        );

        expect(
          yearlyTop < lifetimeTop,
          isTrue,
          reason: 'Yearly plan ($yearlyTop) must appear before Lifetime plan ($lifetimeTop)',
        );
      },
    );

    test('SubscriptionPlan isMonthly helper returns true only for non-yearly non-lifetime plans', () {
      expect(monthlyPlan.isMonthly, isTrue);
      expect(monthlyPlan.isYearly, isFalse);
      expect(monthlyPlan.isLifetime, isFalse);

      expect(yearlyPlan.isMonthly, isFalse);
      expect(yearlyPlan.isYearly, isTrue);
      expect(yearlyPlan.isLifetime, isFalse);

      expect(lifetimePlan.isMonthly, isFalse);
      expect(lifetimePlan.isYearly, isFalse);
      expect(lifetimePlan.isLifetime, isTrue);
    });
  });
}
