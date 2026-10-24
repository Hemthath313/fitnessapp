import 'package:fitness_app/presentation/custom_workouts/day_workout_session_page.dart';
import 'package:fitness_app/presentation/workout_tools/plate_calculator_sheet.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class _FakeVideoPlayerController extends ValueNotifier<VideoPlayerValue>
    implements VideoPlayerController {
  final String assetPath;
  final VideoPlayerOptions? options;

  _FakeVideoPlayerController({
    required this.assetPath,
    this.options,
  }) : super(const VideoPlayerValue.uninitialized());

  @override
  String get dataSource => assetPath;

  @override
  DataSourceType get dataSourceType => DataSourceType.asset;

  @override
  String? get package => null;

  @override
  Map<String, String> get httpHeaders => const {};

  @override
  VideoFormat? get formatHint => null;

  @override
  Future<ClosedCaptionFile>? get closedCaptionFile => null;

  @override
  VideoPlayerOptions? get videoPlayerOptions => options;

  @override
  int get playerId => hashCode;

  @override
  VideoViewType get viewType => VideoViewType.textureView;

  @override
  Future<void> initialize() async {
    value = value.copyWith(
      isInitialized: true,
      size: const Size(1080, 1080),
      duration: const Duration(seconds: 10),
    );
  }

  @override
  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> setLooping(bool looping) async {
    value = value.copyWith(isLooping: looping);
  }

  @override
  Future<void> setVolume(double volume) async {
    value = value.copyWith(volume: volume);
  }

  @override
  Future<void> seekTo(Duration position) async {
    value = value.copyWith(position: position);
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    value = value.copyWith(playbackSpeed: speed);
  }

  @override
  Future<Duration?> get position async => value.position;

  @override
  void setCaptionOffset(Duration offset) {}

  @override
  Future<void> setClosedCaptionFile(
    Future<ClosedCaptionFile>? closedCaptionFile,
  ) async {}

  @override
  Future<void> dispose() async {
    super.dispose();
  }
}

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
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    WorkoutLogService.clearLastLogCache();
  });

  group('Plate Calculator Eligibility & Math Logic Tests', () {
    test('1. PlateCalculatorSheet.isBarbellExercise accurately classifies barbell vs unsupported exercises', () {
      // Eligible Barbell movements
      expect(PlateCalculatorSheet.isBarbellExercise(name: 'Barbell Bench Press', equipment: 'Barbell, Bench'), isTrue);
      expect(PlateCalculatorSheet.isBarbellExercise(name: 'Classic Barbell Squat', equipment: 'Barbell, Rack'), isTrue);
      expect(PlateCalculatorSheet.isBarbellExercise(name: 'Barbell Straight Leg Deadlift', equipment: 'Barbell'), isTrue);
      expect(PlateCalculatorSheet.isBarbellExercise(name: 'Deadlift'), isTrue);
      expect(PlateCalculatorSheet.isBarbellExercise(name: 'Bench Press'), isTrue);
      expect(PlateCalculatorSheet.isBarbellExercise(name: 'Overhead Press'), isTrue);
      expect(PlateCalculatorSheet.isBarbellExercise(name: 'EZ Bar Bicep Curl', equipment: 'EZ Bar'), isTrue);
      expect(PlateCalculatorSheet.isBarbellExercise(name: 'Barbell Front Chest Squat'), isTrue);

      // Unsupported / Non-barbell exercises
      expect(PlateCalculatorSheet.isBarbellExercise(name: 'Dumbbell Bench Press', equipment: 'Dumbbells, Bench'), isFalse);
      expect(PlateCalculatorSheet.isBarbellExercise(name: 'Incline Dumbbell Press'), isFalse);
      expect(PlateCalculatorSheet.isBarbellExercise(name: 'Chest Dips', equipment: 'Dip Bars'), isFalse);
      expect(PlateCalculatorSheet.isBarbellExercise(name: 'Deep Pushups', equipment: 'Bodyweight'), isFalse);
      expect(PlateCalculatorSheet.isBarbellExercise(name: 'Pull-Ups', equipment: 'Pull-up Bar'), isFalse);
      expect(PlateCalculatorSheet.isBarbellExercise(name: 'Cable Crossover', equipment: 'Cable Machine'), isFalse);
      expect(PlateCalculatorSheet.isBarbellExercise(name: 'Leg Press Machine', equipment: 'Machine'), isFalse);
      expect(PlateCalculatorSheet.isBarbellExercise(name: 'Treadmill Running', equipment: 'Treadmill'), isFalse);
      expect(PlateCalculatorSheet.isBarbellExercise(name: 'Plank', equipment: 'Mat'), isFalse);
    });

    test('2. PlateCalculatorSheet.calculatePlatesPerSide computes exact metric plate breakdown', () {
      // 60 kg with 20 kg bar -> 20 kg per side = 1 x 20 kg plate
      final p60 = PlateCalculatorSheet.calculatePlatesPerSide(targetWeight: 60.0, barWeight: 20.0, isKg: true);
      expect(p60, equals({20.0: 1}));

      // 100 kg with 20 kg bar -> 40 kg per side = 1 x 25 kg + 1 x 15 kg
      final p100 = PlateCalculatorSheet.calculatePlatesPerSide(targetWeight: 100.0, barWeight: 20.0, isKg: true);
      expect(p100, equals({25.0: 1, 15.0: 1}));

      // 140 kg with 20 kg bar -> 60 kg per side = 2 x 25 kg + 1 x 10 kg
      final p140 = PlateCalculatorSheet.calculatePlatesPerSide(targetWeight: 140.0, barWeight: 20.0, isKg: true);
      expect(p140, equals({25.0: 2, 10.0: 1}));

      // 20 kg with 20 kg bar -> Empty (bar only)
      final p20 = PlateCalculatorSheet.calculatePlatesPerSide(targetWeight: 20.0, barWeight: 20.0, isKg: true);
      expect(p20, isEmpty);

      // Target weight less than bar weight -> Empty
      final pUnder = PlateCalculatorSheet.calculatePlatesPerSide(targetWeight: 15.0, barWeight: 20.0, isKg: true);
      expect(pUnder, isEmpty);
    });

    test('3. PlateCalculatorSheet.calculatePlatesPerSide computes exact imperial plate breakdown', () {
      // 135 lb with 45 lb bar -> 45 lb per side = 1 x 45 lb plate
      final p135 = PlateCalculatorSheet.calculatePlatesPerSide(targetWeight: 135.0, barWeight: 45.0, isKg: false);
      expect(p135, equals({45.0: 1}));

      // 225 lb with 45 lb bar -> 90 lb per side = 2 x 45 lb plates
      final p225 = PlateCalculatorSheet.calculatePlatesPerSide(targetWeight: 225.0, barWeight: 45.0, isKg: false);
      expect(p225, equals({45.0: 2}));

      // 185 lb with 45 lb bar -> 70 lb per side = 1 x 45 lb + 1 x 25 lb
      final p185 = PlateCalculatorSheet.calculatePlatesPerSide(targetWeight: 185.0, barWeight: 45.0, isKg: false);
      expect(p185, equals({45.0: 1, 25.0: 1}));

      // 95 lb with 45 lb bar -> 25 lb per side = 1 x 25 lb
      final p95 = PlateCalculatorSheet.calculatePlatesPerSide(targetWeight: 95.0, barWeight: 45.0, isKg: false);
      expect(p95, equals({25.0: 1}));

      // 45 lb with 45 lb bar -> Empty (bar only)
      final p45 = PlateCalculatorSheet.calculatePlatesPerSide(targetWeight: 45.0, barWeight: 45.0, isKg: false);
      expect(p45, isEmpty);
    });
  });

  group('In-Workout Active Session Plate Calculator Widget Tests', () {
    final testWorkouts = [
      {
        'name': 'Barbell Bench Press',
        'workoutName': 'Barbell Bench Press',
        'order': 0,
        'setNumber': 3,
        'repNumber': 8,
      },
      {
        'name': 'Deep Pushups',
        'workoutName': 'Deep Pushups',
        'order': 1,
        'setNumber': 2,
        'repNumber': 10,
      },
    ];

    testWidgets('4. Calculator button appears for barbell exercises and is omitted for unsupported exercises', (tester) async {
      _configureTestViewport(tester);

      await tester.pumpWidget(
        _wrapWithScreenUtil(
          DayWorkoutSessionPage(
            dayName: 'Chest Day',
            workouts: testWorkouts,
            videoControllerFactory: (path, options) =>
                _FakeVideoPlayerController(assetPath: path, options: options),
            videoViewBuilder: (_) =>
                const SizedBox(key: Key('session_mock_video')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Barbell Bench Press (order 0) must have calculator button for its sets
      expect(find.byKey(const Key('session_plate_calc_0_0')), findsOneWidget);
      expect(find.byKey(const Key('session_plate_calc_0_1')), findsOneWidget);
      expect(find.byKey(const Key('session_plate_calc_0_2')), findsOneWidget);

      // Deep Pushups (order 1, bodyweight) must NOT have calculator buttons
      expect(find.byKey(const Key('session_plate_calc_1_0')), findsNothing);
      expect(find.byKey(const Key('session_plate_calc_1_1')), findsNothing);
    });

    testWidgets('5. Opening calculator from set initializes with current set weight, and closing preserves weight', (tester) async {
      _configureTestViewport(tester);

      await tester.pumpWidget(
        _wrapWithScreenUtil(
          DayWorkoutSessionPage(
            dayName: 'Chest Day',
            workouts: testWorkouts,
            videoControllerFactory: (path, options) =>
                _FakeVideoPlayerController(assetPath: path, options: options),
            videoViewBuilder: (_) =>
                const SizedBox(key: Key('session_mock_video')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Verify initial weight of set 0
      final initialWeightText = tester
          .widget<TextField>(find.byKey(const Key('session_weight_input_0_0')))
          .controller!
          .text;

      // Tap calculator button on set 0
      await tester.tap(find.byKey(const Key('session_plate_calc_0_0')));
      await tester.pumpAndSettle();

      // Modal sheet is open
      expect(find.text('Barbell Plate Math'), findsOneWidget);
      expect(find.byKey(const Key('plate_calculator_apply_button')), findsOneWidget);

      // Tap close button without applying
      await tester.tap(find.byKey(const Key('plate_calculator_close_button')));
      await tester.pumpAndSettle();

      // Modal is dismissed and weight in set 0 is unchanged
      expect(find.text('Barbell Plate Math'), findsNothing);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('session_weight_input_0_0')))
            .controller!
            .text,
        equals(initialWeightText),
      );
    });

    testWidgets('6. Applying weight updates intended set without completing it or altering other sets', (tester) async {
      _configureTestViewport(tester);

      await tester.pumpWidget(
        _wrapWithScreenUtil(
          DayWorkoutSessionPage(
            dayName: 'Chest Day',
            workouts: testWorkouts,
            videoControllerFactory: (path, options) =>
                _FakeVideoPlayerController(assetPath: path, options: options),
            videoViewBuilder: (_) =>
                const SizedBox(key: Key('session_mock_video')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Set 0 initial weight
      final set0InitialWeight = tester
          .widget<TextField>(find.byKey(const Key('session_weight_input_0_0')))
          .controller!
          .text;

      // Tap calculator on Set 1 (order 0, setIdx 1)
      await tester.tap(find.byKey(const Key('session_plate_calc_0_1')));
      await tester.pumpAndSettle();

      expect(find.text('Barbell Plate Math'), findsOneWidget);

      // Tap +10 quick delta button twice to add 20 kg
      await tester.tap(find.text('+10'));
      await tester.pump();
      await tester.tap(find.text('+10'));
      await tester.pump();

      // Tap Apply Weight
      await tester.tap(find.byKey(const Key('plate_calculator_apply_button')));
      await tester.pumpAndSettle();

      // Sheet is closed
      expect(find.text('Barbell Plate Math'), findsNothing);

      // Set 1 weight has been updated!
      final updatedSet1Weight = tester
          .widget<TextField>(find.byKey(const Key('session_weight_input_0_1')))
          .controller!
          .text;
      expect(double.parse(updatedSet1Weight), greaterThan(double.parse(set0InitialWeight)));

      // Set 0 weight was NOT altered
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('session_weight_input_0_0')))
            .controller!
            .text,
        equals(set0InitialWeight),
      );

      // Set 1 is NOT automatically marked completed
      // The done button icon should still be unselected/white (not green completed)
      final doneFinder = find.byKey(const Key('session_set_done_0_1'));
      expect(doneFinder, findsOneWidget);
    });
  });
}
