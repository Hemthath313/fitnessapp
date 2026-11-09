import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_home_box.dart';
import 'package:fitness_app/presentation/home/widgets/dashboard_ai_workout_generator_card.dart';
import 'package:fitness_app/presentation/home/widgets/fitness_data_widget.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/utils/router/router.dart';

class _MockTransformationProvider extends ChangeNotifier
    implements TransformationProvider {
  UserTransformationState? _activeTransformation;

  _MockTransformationProvider({UserTransformationState? activeState}) {
    _activeTransformation = activeState;
  }

  void setActiveTransformation(UserTransformationState? state) {
    _activeTransformation = state;
    notifyListeners();
  }

  @override
  UserTransformationState? get activeTransformation => _activeTransformation;

  @override
  bool get hasActiveTransformation =>
      _activeTransformation != null && _activeTransformation!.status == 'active';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UserTransformationState _createMockTransformationState() {
  return UserTransformationState(
    planId: 'beginner_fitness_30',
    planTitle: '30-Day Beginner Fitness',
    startDate: DateTime.now().subtract(const Duration(days: 2)),
    targetEndDate: DateTime.now().add(const Duration(days: 28)),
    currentDay: 3,
    totalDays: 30,
    status: 'active',
    completedDayIndices: [1, 2],
    targetCalories: 2200.0,
    dailyWaterTargetMl: 2500.0,
    targetMacros: {'protein': 120, 'carbs': 200, 'fat': 60},
    milestones: [],
  );
}

class _MockHomeProvider extends ChangeNotifier implements HomeProvider {
  Map<String, dynamic> _userData = {};

  @override
  Map<String, dynamic> get userData => _userData;

  void setUserData(Map<String, dynamic> data) {
    _userData = data;
    notifyListeners();
  }

  @override
  Future<Map<String, dynamic>> fetchUserData() async => _userData;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockSubscriptionProvider extends ChangeNotifier
    implements SubscriptionProvider {
  bool _isPremium = false;

  @override
  bool get isPremium => _isPremium;

  void setPremium(bool val) {
    _isPremium = val;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestConsumptionProvider extends ChangeNotifier
    implements ConsumptionProvider {
  int _consumedCalories = 1450;
  double _waterADay = 1.8;
  double _waterGoalLiters = 2.5;

  @override
  int get consumedCalories => _consumedCalories;

  void setConsumedCalories(int calories) {
    _consumedCalories = calories;
    notifyListeners();
  }

  @override
  double get waterADay => _waterADay;

  void setWaterADay(double water) {
    _waterADay = water;
    notifyListeners();
  }

  @override
  double get waterGoalLiters => _waterGoalLiters;

  @override
  void setWaterGoal(double liters) {
    if (liters > 0) {
      _waterGoalLiters = liters;
      notifyListeners();
    }
  }

  @override
  Future<void> getConsumedCalories() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockStatisticsProvider extends ChangeNotifier
    implements StatisticsProvider {
  @override
  int get currentStreak => 7;

  @override
  List<String> get scheduledDayNames => ['Monday', 'Wednesday', 'Friday'];

  @override
  bool get hasActiveSchedule => true;

  @override
  bool get hasWorkoutToday => false;

  @override
  bool isPendingScheduledDay([DateTime? date]) => false;

  @override
  bool isRestDay([DateTime? date]) => false;

  @override
  int get totalWorkouts => 3;

  @override
  List<String> get unlockedAchievements => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void _setViewport(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _captureRepaintBoundary(
  WidgetTester tester,
  GlobalKey key,
  String fileName,
) async {
  try {
    final context = key.currentContext;
    if (context != null) {
      final boundary = context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2.0);
          final byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final file = File(
                '/Users/hemthath/.gemini/antigravity/brain/0985b2e0-957d-4124-a5ef-faaac7edec5d/$fileName');
            await file.writeAsBytes(byteData.buffer.asUint8List());
          }
        });
      }
    }
  } catch (_) {
    // Non-fatal if headless capture environment
  }
}

Widget _buildResponsiveHarness({
  required Widget child,
  required double screenWidth,
  required double screenHeight,
  GlobalKey? boundaryKey,
  double textScaleFactor = 1.0,
  TransformationProvider? transformationProvider,
  HomeProvider? homeProvider,
  SubscriptionProvider? subscriptionProvider,
  ConsumptionProvider? consumptionProvider,
}) {
  final tp = transformationProvider ??
      _MockTransformationProvider(activeState: _createMockTransformationState());
  final hp = homeProvider ?? _MockHomeProvider();
  if (homeProvider == null && hp is _MockHomeProvider) {
    hp.setUserData({
      'bmr': 1750.0,
      'targetCalories': 2250.0,
      'weight': 78.0,
      'height': 178.0,
      'age': 27,
      'gender': 'Male',
      'activity': 'MODERATE',
      'goal': 'MAINTAIN',
      'bmi': 24.6,
    });
  }
  final subp = subscriptionProvider ?? _MockSubscriptionProvider();
  final cp = consumptionProvider ?? _TestConsumptionProvider();
  final sp = _MockStatisticsProvider();
  final wp = WorkoutProvider();

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: SingleChildScrollView(
              child: RepaintBoundary(
                key: boundaryKey,
                child: child,
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: Routes.workoutGeneratorRoute,
        builder: (context, state) => const Scaffold(body: Text('AI Generator')),
      ),
      GoRoute(
        path: Routes.addWaterRoute,
        builder: (context, state) => const Scaffold(body: Text('Add Water')),
      ),
      GoRoute(
        path: Routes.changeWeightRoute,
        builder: (context, state) => const Scaffold(body: Text('Profile')),
      ),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TransformationProvider>.value(value: tp),
      ChangeNotifierProvider<HomeProvider>.value(value: hp),
      ChangeNotifierProvider<SubscriptionProvider>.value(value: subp),
      ChangeNotifierProvider<ConsumptionProvider>.value(value: cp),
      ChangeNotifierProvider<StatisticsProvider>.value(value: sp),
      ChangeNotifierProvider<WorkoutProvider>.value(value: wp),
    ],
    child: ScreenUtilInit(
      designSize: Size(screenWidth, screenHeight),
      builder: (context, _) => MaterialApp.router(
        routerConfig: router,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<FlutterErrorDetails> overflowErrors;
  void Function(FlutterErrorDetails)? previousOnError;

  setUp(() {
    overflowErrors = [];
    previousOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed by') ||
          details.exceptionAsString().contains('A RenderFlex overflowed')) {
        overflowErrors.add(details);
      }
      previousOnError?.call(details);
    };
  });

  tearDown(() {
    FlutterError.onError = previousOnError;
  });

  group('Phase 2 — Responsive Layout: AI Workout Generator Card', () {
    testWidgets('1. AI Generator header renders cleanly at 360dp width with zero overflow',
        (tester) async {
      _setViewport(tester, 360, 640);
      final key = GlobalKey();

      await tester.pumpWidget(
        _buildResponsiveHarness(
          child: const DashboardAiWorkoutGeneratorCard(),
          screenWidth: 360,
          screenHeight: 640,
          boundaryKey: key,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(overflowErrors, isEmpty,
          reason: 'No RenderFlex overflow on 360dp AI Generator card');
      expect(find.text('PLAN BUILDER'), findsOneWidget);
      expect(find.text('3–6 Day Custom Splits'), findsOneWidget);
      expect(find.text('Build Your Workout Routine'), findsOneWidget);

      await _captureRepaintBoundary(tester, key, 'phase2_ai_generator_360dp.png');
    });

    testWidgets('2. AI Generator header renders cleanly at 390dp width with zero overflow',
        (tester) async {
      _setViewport(tester, 390, 844);
      final key = GlobalKey();

      await tester.pumpWidget(
        _buildResponsiveHarness(
          child: const DashboardAiWorkoutGeneratorCard(),
          screenWidth: 390,
          screenHeight: 844,
          boundaryKey: key,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(overflowErrors, isEmpty);
      expect(find.text('PLAN BUILDER'), findsOneWidget);
      expect(find.text('3–6 Day Custom Splits'), findsOneWidget);

      await _captureRepaintBoundary(tester, key, 'phase2_ai_generator_390dp.png');
    });

    testWidgets('3. AI Generator header renders cleanly at 430dp width with zero overflow',
        (tester) async {
      _setViewport(tester, 430, 932);
      final key = GlobalKey();

      await tester.pumpWidget(
        _buildResponsiveHarness(
          child: const DashboardAiWorkoutGeneratorCard(),
          screenWidth: 430,
          screenHeight: 932,
          boundaryKey: key,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(overflowErrors, isEmpty);
      expect(find.text('PLAN BUILDER'), findsOneWidget);
      expect(find.text('3–6 Day Custom Splits'), findsOneWidget);

      await _captureRepaintBoundary(tester, key, 'phase2_ai_generator_430dp.png');
    });
  });

  group('Phase 2 — Responsive Layout: Calorie Tracker & Fitness Data Widget', () {
    testWidgets('4. Calorie tracker renders cleanly at 360dp width with zero overflow',
        (tester) async {
      _setViewport(tester, 360, 640);
      final key = GlobalKey();

      await tester.pumpWidget(
        _buildResponsiveHarness(
          child: const FitnessDataWidget(),
          screenWidth: 360,
          screenHeight: 640,
          transformationProvider: _MockTransformationProvider(),
          boundaryKey: key,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(overflowErrors, isEmpty,
          reason: 'No RenderFlex overflow on 360dp Calorie tracker');
      expect(find.text('Daily Calorie Tracker'), findsOneWidget);
      expect(find.text('2250 kcal'), findsOneWidget);
      expect(find.text('1450 kcal'), findsOneWidget);
      expect(find.text('800 kcal'), findsOneWidget);

      await _captureRepaintBoundary(tester, key, 'phase2_calorie_tracker_360dp.png');
    });

    testWidgets('5. Calorie tracker renders cleanly at 390dp width with zero overflow',
        (tester) async {
      _setViewport(tester, 390, 844);
      final key = GlobalKey();

      await tester.pumpWidget(
        _buildResponsiveHarness(
          child: const FitnessDataWidget(),
          screenWidth: 390,
          screenHeight: 844,
          boundaryKey: key,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(overflowErrors, isEmpty);
      expect(find.text('Daily Calorie Tracker'), findsOneWidget);

      await _captureRepaintBoundary(tester, key, 'phase2_calorie_tracker_390dp.png');
    });

    testWidgets('6. Calorie tracker renders cleanly at 430dp width with zero overflow',
        (tester) async {
      _setViewport(tester, 430, 932);
      final key = GlobalKey();

      await tester.pumpWidget(
        _buildResponsiveHarness(
          child: const FitnessDataWidget(),
          screenWidth: 430,
          screenHeight: 932,
          boundaryKey: key,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(overflowErrors, isEmpty);
      expect(find.text('Daily Calorie Tracker'), findsOneWidget);

      await _captureRepaintBoundary(tester, key, 'phase2_calorie_tracker_430dp.png');
    });
  });

  group('Phase 2 — Responsive Layout: Challenge Carousel Card', () {
    testWidgets('7. Challenge carousel renders cleanly at 360dp width with zero overflow',
        (tester) async {
      _setViewport(tester, 360, 640);
      final key = GlobalKey();

      await tester.pumpWidget(
        _buildResponsiveHarness(
          child: CarouselHomeBox(
            deviceWidth: 360,
            image: 'assets/images/sixpack.png',
            onTap: () {},
            title: 'Six-Pack Abs Challenge',
            badge: 'CHALLENGE',
            subtitle: '30-Day Core Transformation',
            actionText: 'Start Challenge',
          ),
          screenWidth: 360,
          screenHeight: 640,
          boundaryKey: key,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(overflowErrors, isEmpty,
          reason: 'No collision or overflow on 360dp Carousel card');
      expect(find.text('CHALLENGE'), findsOneWidget);
      expect(find.text('Start Challenge'), findsOneWidget);
      expect(find.text('Six-Pack Abs Challenge'), findsOneWidget);

      await _captureRepaintBoundary(tester, key, 'phase2_challenge_carousel_360dp.png');
    });

    testWidgets('8. Challenge carousel renders cleanly at 390dp width with zero overflow',
        (tester) async {
      _setViewport(tester, 390, 844);
      final key = GlobalKey();

      await tester.pumpWidget(
        _buildResponsiveHarness(
          child: CarouselHomeBox(
            deviceWidth: 390,
            image: 'assets/images/sixpack.png',
            onTap: () {},
            title: 'Six-Pack Abs Challenge',
            badge: 'CHALLENGE',
            subtitle: '30-Day Core Transformation',
            actionText: 'Start Challenge',
          ),
          screenWidth: 390,
          screenHeight: 844,
          boundaryKey: key,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(overflowErrors, isEmpty);
      expect(find.text('CHALLENGE'), findsOneWidget);

      await _captureRepaintBoundary(tester, key, 'phase2_challenge_carousel_390dp.png');
    });

    testWidgets('9. Challenge carousel renders cleanly at 430dp width with zero overflow',
        (tester) async {
      _setViewport(tester, 430, 932);
      final key = GlobalKey();

      await tester.pumpWidget(
        _buildResponsiveHarness(
          child: CarouselHomeBox(
            deviceWidth: 430,
            image: 'assets/images/sixpack.png',
            onTap: () {},
            title: 'Six-Pack Abs Challenge',
            badge: 'CHALLENGE',
            subtitle: '30-Day Core Transformation',
            actionText: 'Start Challenge',
          ),
          screenWidth: 430,
          screenHeight: 932,
          boundaryKey: key,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(overflowErrors, isEmpty);
      expect(find.text('CHALLENGE'), findsOneWidget);

      await _captureRepaintBoundary(tester, key, 'phase2_challenge_carousel_430dp.png');
    });
  });

  group('Phase 2 — Responsive Layout: Text Scaling & Edge Cases', () {
    testWidgets('10. Increased text scaling (1.3x) adapts cleanly without RenderFlex overflows',
        (tester) async {
      _setViewport(tester, 360, 640);
      final key = GlobalKey();

      await tester.pumpWidget(
        _buildResponsiveHarness(
          child: Column(
            children: [
              const DashboardAiWorkoutGeneratorCard(),
              const FitnessDataWidget(),
              CarouselHomeBox(
                deviceWidth: 360,
                image: 'assets/images/sixpack.png',
                onTap: () {},
                title: 'Six-Pack Abs Challenge',
                badge: 'CHALLENGE',
                subtitle: '30-Day Core Transformation',
                actionText: 'Start Challenge',
              ),
            ],
          ),
          screenWidth: 360,
          screenHeight: 640,
          textScaleFactor: 1.3,
          boundaryKey: key,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(overflowErrors, isEmpty,
          reason: 'All cards must adapt cleanly at 1.3x text scaling');
      await _captureRepaintBoundary(tester, key, 'phase2_text_scale_high.png');
    });

    testWidgets('11. Long text handling (extended badge, long title, long subtitle) truncates gracefully',
        (tester) async {
      _setViewport(tester, 360, 640);

      await tester.pumpWidget(
        _buildResponsiveHarness(
          child: CarouselHomeBox(
            deviceWidth: 360,
            image: 'assets/images/sixpack.png',
            onTap: () {},
            title: 'Super Advanced High-Intensity Explosive Functional Power Challenge',
            badge: 'EXTREME MULTI-WEEK FEATURED CHALLENGE',
            subtitle: 'Comprehensive 12-Week Advanced Periodized Progressive Overload Program',
            actionText: 'Start This Long Named Challenge',
          ),
          screenWidth: 360,
          screenHeight: 640,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(overflowErrors, isEmpty,
          reason: 'Long titles and badges must flex without RenderFlex overflow');
    });

    testWidgets('12. Missing user data renders honest setup state at 360dp without layout overflow',
        (tester) async {
      _setViewport(tester, 360, 640);
      final hp = _MockHomeProvider();
      hp.setUserData({
        'bmr': 0.0,
        'weight': 0.0,
        'height': 0.0,
        'age': 0,
      });

      await tester.pumpWidget(
        _buildResponsiveHarness(
          child: const FitnessDataWidget(),
          screenWidth: 360,
          screenHeight: 640,
          transformationProvider: _MockTransformationProvider(),
          homeProvider: hp,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(overflowErrors, isEmpty);
      expect(find.text('Not Set'), findsOneWidget);
      expect(find.text('--'), findsOneWidget);
      expect(find.text('Set daily calorie target in Profile'), findsOneWidget);
    });

    testWidgets('13. Comprehensive verification: No RenderFlex overflow across entire Dashboard Column',
        (tester) async {
      _setViewport(tester, 360, 640);

      await tester.pumpWidget(
        _buildResponsiveHarness(
          child: Column(
            children: [
              const DashboardAiWorkoutGeneratorCard(),
              const SizedBox(height: 16),
              const FitnessDataWidget(),
              const SizedBox(height: 16),
              CarouselHomeBox(
                deviceWidth: 360,
                image: 'assets/images/sixpack.png',
                onTap: () {},
                title: 'Six-Pack Abs Challenge',
                badge: 'CHALLENGE',
                subtitle: '30-Day Core Transformation',
                actionText: 'Start Challenge',
              ),
            ],
          ),
          screenWidth: 360,
          screenHeight: 640,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(overflowErrors, isEmpty,
          reason: 'Zero RenderFlex overflow across the combined dashboard column at 360dp');
    });
  });
}
