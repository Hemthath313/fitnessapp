import 'package:fitness_app/presentation/auth/pages/add_data_page.dart';
import 'package:fitness_app/presentation/auth/providers/auth_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/utils/widgets/lime_green_rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void _configureTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pumpAddDataPage(
  WidgetTester tester, {
  required AuthProvider authProvider,
  required HomeProvider homeProvider,
  required GoRouter router,
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      builder: (context, child) => MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<HomeProvider>.value(value: homeProvider),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillOnboardingForm(
  WidgetTester tester, {
  String name = 'John',
  String surname = 'Doe',
  String age = '25',
  String height = '175',
  String weight = '70',
  String? gender = 'Male',
  String? activity = 'LIGHT',
  String? goal = 'maintain weight',
}) async {
  final textFields = find.byType(TextField);
  if (name.isNotEmpty) {
    await tester.ensureVisible(textFields.at(0));
    await tester.enterText(textFields.at(0), name);
  }
  if (surname.isNotEmpty) {
    await tester.ensureVisible(textFields.at(1));
    await tester.enterText(textFields.at(1), surname);
  }
  if (age.isNotEmpty) {
    await tester.ensureVisible(textFields.at(2));
    await tester.enterText(textFields.at(2), age);
  }
  if (height.isNotEmpty) {
    await tester.ensureVisible(textFields.at(3));
    await tester.enterText(textFields.at(3), height);
  }
  if (weight.isNotEmpty) {
    await tester.ensureVisible(textFields.at(4));
    await tester.enterText(textFields.at(4), weight);
  }
  await tester.pump();

  if (gender != null) {
    final genderFinder = find.text(StringsManager.genderHint);
    await tester.ensureVisible(genderFinder);
    await tester.tap(genderFinder, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text(gender).last, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  if (activity != null) {
    final activityFinder = find.text(StringsManager.activityHint);
    await tester.ensureVisible(activityFinder);
    await tester.tap(activityFinder, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text(activity).last, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  if (goal != null) {
    final goalFinder = find.text(StringsManager.goalHint);
    await tester.ensureVisible(goalFinder);
    await tester.tap(goalFinder, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text(goal).last, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3B Batch 3: Onboarding Data Integrity', () {
    late AuthProvider authProvider;
    late HomeProvider homeProvider;
    late GoRouter testRouter;
    late bool navigatedToHome;

    setUp(() {
      authProvider = AuthProvider();
      homeProvider = HomeProvider();
      navigatedToHome = false;

      testRouter = GoRouter(
        initialLocation: '/add_data',
        routes: [
          GoRoute(
            path: '/add_data',
            builder: (context, state) => const AddDataPage(),
          ),
          GoRoute(
            path: Routes.mainRoute,
            builder: (context, state) {
              navigatedToHome = true;
              return const Scaffold(body: Text('Home Screen'));
            },
          ),
        ],
      );
    });

    testWidgets('Scenario 1: Valid input and successful Firestore persistence proceed to Home', (tester) async {
      _configureTestViewport(tester);
      bool persistCalled = false;

      authProvider.onAddUserDataForTesting = ({
        required String email,
        required String name,
        required String surname,
        required int age,
        required double height,
        required double weight,
        required String gender,
        required String activity,
        required double bmr,
        required String goal,
        required double bmi,
      }) async {
        persistCalled = true;
        expect(name, 'Alice');
        expect(surname, 'Smith');
        expect(age, 28);
        expect(height, 168.0);
        expect(weight, 62.0);
        expect(gender, 'Female');
        expect(activity, 'LIGHT');
        expect(goal, 'LOSE');
      };

      await _pumpAddDataPage(tester, authProvider: authProvider, homeProvider: homeProvider, router: testRouter);

      await _fillOnboardingForm(
        tester,
        name: 'Alice',
        surname: 'Smith',
        age: '28',
        height: '168',
        weight: '62',
        gender: 'Female',
        activity: 'LIGHT',
        goal: 'lose weight',
      );

      final buttonFinder = find.byType(LimeGreenRoundedButtonWidget);
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(persistCalled, isTrue);
      expect(navigatedToHome, isTrue);
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('Scenario 2: Empty required fields prevent submission', (tester) async {
      _configureTestViewport(tester);
      bool persistCalled = false;
      authProvider.onAddUserDataForTesting = ({
        required email, required name, required surname, required age,
        required height, required weight, required gender, required activity,
        required bmr, required goal, required bmi,
      }) async {
        persistCalled = true;
      };

      await _pumpAddDataPage(tester, authProvider: authProvider, homeProvider: homeProvider, router: testRouter);

      // Tap submit with empty form
      final buttonFinder = find.byType(LimeGreenRoundedButtonWidget);
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(persistCalled, isFalse);
      expect(navigatedToHome, isFalse);
      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('Scenario 3: Invalid numeric input does not crash the app', (tester) async {
      _configureTestViewport(tester);
      bool persistCalled = false;
      authProvider.onAddUserDataForTesting = ({
        required email, required name, required surname, required age,
        required height, required weight, required gender, required activity,
        required bmr, required goal, required bmi,
      }) async {
        persistCalled = true;
      };

      await _pumpAddDataPage(tester, authProvider: authProvider, homeProvider: homeProvider, router: testRouter);

      await _fillOnboardingForm(
        tester,
        name: 'Bob',
        surname: 'Builder',
        age: '25',
        height: '180',
        weight: '80',
      );

      final textFields = find.byType(TextField);
      final buttonFinder = find.byType(LimeGreenRoundedButtonWidget);

      // 1. Force invalid non-numeric text onto age controller
      tester.widget<TextField>(textFields.at(2)).controller!.text = 'invalid_age';
      await tester.pump();
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(persistCalled, isFalse);
      expect(navigatedToHome, isFalse);
      expect(find.text('Please enter a valid age'), findsOneWidget);

      // 2. Force invalid non-numeric text onto height controller
      tester.widget<TextField>(textFields.at(2)).controller!.text = '25';
      tester.widget<TextField>(textFields.at(3)).controller!.text = 'not_a_height';
      await tester.pump();
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(persistCalled, isFalse);
      expect(navigatedToHome, isFalse);
      expect(find.text('Please enter a valid height'), findsOneWidget);

      // 3. Force invalid non-numeric text onto weight controller
      tester.widget<TextField>(textFields.at(3)).controller!.text = '180';
      tester.widget<TextField>(textFields.at(4)).controller!.text = 'not_a_weight';
      await tester.pump();
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(persistCalled, isFalse);
      expect(navigatedToHome, isFalse);
      expect(find.text('Please enter a valid weight'), findsOneWidget);
    });

    testWidgets('Scenario 4: Invalid numeric ranges display validation errors', (tester) async {
      _configureTestViewport(tester);

      await _pumpAddDataPage(tester, authProvider: authProvider, homeProvider: homeProvider, router: testRouter);
      final buttonFinder = find.byType(LimeGreenRoundedButtonWidget);
      final textFields = find.byType(TextField);

      // Age too low (< 13)
      await _fillOnboardingForm(tester, name: 'Tom', surname: 'Hanks', age: '10', height: '175', weight: '70');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(find.text('Age must be between 13 and 120'), findsOneWidget);
      expect(navigatedToHome, isFalse);

      // Age too high (> 120)
      await tester.ensureVisible(textFields.at(2));
      await tester.enterText(textFields.at(2), '150');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(find.text('Age must be between 13 and 120'), findsOneWidget);

      // Fix age to 25, height too low (< 50)
      await tester.ensureVisible(textFields.at(2));
      await tester.enterText(textFields.at(2), '25');
      await tester.ensureVisible(textFields.at(3));
      await tester.enterText(textFields.at(3), '30');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(find.text('Height must be between 50 and 260 cm'), findsOneWidget);

      // Height too high (> 260)
      await tester.ensureVisible(textFields.at(3));
      await tester.enterText(textFields.at(3), '300');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(find.text('Height must be between 50 and 260 cm'), findsOneWidget);

      // Fix height to 180, weight too low (< 20)
      await tester.ensureVisible(textFields.at(3));
      await tester.enterText(textFields.at(3), '180');
      await tester.ensureVisible(textFields.at(4));
      await tester.enterText(textFields.at(4), '15');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(find.text('Weight must be between 20 and 400 kg'), findsOneWidget);

      // Weight too high (> 400)
      await tester.ensureVisible(textFields.at(4));
      await tester.enterText(textFields.at(4), '500');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(find.text('Weight must be between 20 and 400 kg'), findsOneWidget);
      expect(navigatedToHome, isFalse);
    });

    testWidgets('Scenario 5: Firestore network failure does not navigate to Home', (tester) async {
      _configureTestViewport(tester);

      authProvider.onAddUserDataForTesting = ({
        required email, required name, required surname, required age,
        required height, required weight, required gender, required activity,
        required bmr, required goal, required bmi,
      }) async {
        throw Exception('Network connection timed out');
      };

      await _pumpAddDataPage(tester, authProvider: authProvider, homeProvider: homeProvider, router: testRouter);
      await _fillOnboardingForm(tester);

      final buttonFinder = find.byType(LimeGreenRoundedButtonWidget);
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(navigatedToHome, isFalse);
      expect(find.text('Failed to save data: Exception: Network connection timed out'), findsOneWidget);
      // User is still on onboarding page
      expect(find.text(StringsManager.enterData), findsOneWidget);
    });

    testWidgets('Scenario 6: Firestore permission or other persistence errors are handled correctly', (tester) async {
      _configureTestViewport(tester);

      authProvider.onAddUserDataForTesting = ({
        required email, required name, required surname, required age,
        required height, required weight, required gender, required activity,
        required bmr, required goal, required bmi,
      }) async {
        throw Exception('[cloud_firestore/permission-denied] Missing or insufficient permissions.');
      };

      await _pumpAddDataPage(tester, authProvider: authProvider, homeProvider: homeProvider, router: testRouter);
      await _fillOnboardingForm(tester);

      final buttonFinder = find.byType(LimeGreenRoundedButtonWidget);
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(navigatedToHome, isFalse);
      expect(find.textContaining('permission-denied'), findsOneWidget);
      expect(find.text(StringsManager.enterData), findsOneWidget);
    });

    testWidgets('Scenario 7: Loading state resets after success and failure', (tester) async {
      _configureTestViewport(tester);

      // 1. Failure case
      authProvider.onAddUserDataForTesting = ({
        required email, required name, required surname, required age,
        required height, required weight, required gender, required activity,
        required bmr, required goal, required bmi,
      }) async {
        await Future.delayed(const Duration(milliseconds: 50));
        throw Exception('Server error');
      };

      await _pumpAddDataPage(tester, authProvider: authProvider, homeProvider: homeProvider, router: testRouter);
      await _fillOnboardingForm(tester);

      final buttonFinder = find.byType(LimeGreenRoundedButtonWidget);
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump(const Duration(milliseconds: 10));

      // Button should be loading
      LimeGreenRoundedButtonWidget buttonWidget = tester.widget(buttonFinder);
      expect(buttonWidget.isLoading, isTrue);

      // Finish async call
      await tester.pumpAndSettle();

      buttonWidget = tester.widget(buttonFinder);
      expect(buttonWidget.isLoading, isFalse, reason: 'isLoading must reset to false after failure');
    });

    testWidgets('Scenario 8: Repeated taps do not trigger duplicate submissions or navigation', (tester) async {
      _configureTestViewport(tester);
      int writeCount = 0;

      authProvider.onAddUserDataForTesting = ({
        required email, required name, required surname, required age,
        required height, required weight, required gender, required activity,
        required bmr, required goal, required bmi,
      }) async {
        writeCount++;
        await Future.delayed(const Duration(milliseconds: 100));
      };

      await _pumpAddDataPage(tester, authProvider: authProvider, homeProvider: homeProvider, router: testRouter);
      await _fillOnboardingForm(tester);

      final buttonFinder = find.byType(LimeGreenRoundedButtonWidget);
      await tester.ensureVisible(buttonFinder);

      // First tap
      await tester.tap(buttonFinder);
      await tester.pump(const Duration(milliseconds: 10));

      // Rapid second tap while request is in-flight
      await tester.tap(buttonFinder, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 10));

      // Third tap
      await tester.tap(buttonFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(writeCount, 1, reason: 'Only 1 submission write must be executed');
      expect(navigatedToHome, isTrue);
    });

    testWidgets('Scenario 9: A retry after a failed write can succeed without losing valid form input', (tester) async {
      _configureTestViewport(tester);
      int attempts = 0;

      authProvider.onAddUserDataForTesting = ({
        required email, required name, required surname, required age,
        required height, required weight, required gender, required activity,
        required bmr, required goal, required bmi,
      }) async {
        attempts++;
        if (attempts == 1) {
          throw Exception('First attempt failed');
        }
        // Second attempt succeeds
      };

      await _pumpAddDataPage(tester, authProvider: authProvider, homeProvider: homeProvider, router: testRouter);
      await _fillOnboardingForm(tester, name: 'Clara', surname: 'Oswald');

      final buttonFinder = find.byType(LimeGreenRoundedButtonWidget);
      await tester.ensureVisible(buttonFinder);

      // First attempt fails
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(attempts, 1);
      expect(navigatedToHome, isFalse);
      expect(find.text('Failed to save data: Exception: First attempt failed'), findsOneWidget);

      // Form inputs MUST be preserved
      final textFields = find.byType(TextField);
      expect(find.descendant(of: textFields.at(0), matching: find.text('Clara')), findsOneWidget);
      expect(find.descendant(of: textFields.at(1), matching: find.text('Oswald')), findsOneWidget);

      // Retry without re-typing
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(attempts, 2);
      expect(navigatedToHome, isTrue, reason: 'Retry should succeed and navigate to Home');
    });

    testWidgets('Scenario 10: Existing successful onboarding behavior remains intact', (tester) async {
      _configureTestViewport(tester);
      bool dataCompletedFlag = false;

      authProvider.onAddUserDataForTesting = ({
        required email, required name, required surname, required age,
        required height, required weight, required gender, required activity,
        required bmr, required goal, required bmi,
      }) async {
        dataCompletedFlag = true;
      };

      await _pumpAddDataPage(tester, authProvider: authProvider, homeProvider: homeProvider, router: testRouter);
      await _fillOnboardingForm(tester);

      final buttonFinder = find.byType(LimeGreenRoundedButtonWidget);
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(dataCompletedFlag, isTrue);
      expect(authProvider.isDataCompleted, isTrue);
      expect(navigatedToHome, isTrue);
    });
  });
}
