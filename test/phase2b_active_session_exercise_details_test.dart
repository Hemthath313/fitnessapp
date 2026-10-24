import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/model/workout_model.dart';
import 'package:fitness_app/presentation/custom_workouts/day_workout_session_page.dart';
import 'package:fitness_app/presentation/widgets/interactive_exercise_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

class FakeSessionVideoPlayerController extends ValueNotifier<VideoPlayerValue>
    implements VideoPlayerController {
  final String assetPath;
  final VideoPlayerOptions? options;
  final bool shouldThrowOnInit;

  int initializeCalls = 0;
  int playCalls = 0;
  int pauseCalls = 0;
  int disposeCalls = 0;
  double? lastVolume;
  bool? lastLooping;

  FakeSessionVideoPlayerController({
    required this.assetPath,
    this.options,
    this.shouldThrowOnInit = false,
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
    initializeCalls++;
    if (shouldThrowOnInit) {
      throw Exception('Simulated missing/corrupt video asset: $assetPath');
    }
    value = value.copyWith(
      isInitialized: true,
      size: const Size(1080, 1080),
      duration: const Duration(seconds: 10),
    );
  }

  @override
  Future<void> play() async {
    playCalls++;
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> setLooping(bool looping) async {
    lastLooping = looping;
    value = value.copyWith(isLooping: looping);
  }

  @override
  Future<void> setVolume(double volume) async {
    lastVolume = volume;
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
    disposeCalls++;
    super.dispose();
  }
}

Future<void> _pumpSessionPage(
  WidgetTester tester,
  Widget child,
) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => MaterialApp(
        home: child,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('Phase 2B — Active Workout Session Exercise Demonstrations & Instructions', () {
    testWidgets(
      'Tapping an exercise in an active session opens its detail view with canonical name, instructions, and matching video',
      (tester) async {
        final createdControllers = <FakeSessionVideoPlayerController>[];
        final workouts = [
          WorkoutModel(
            id: 'w1',
            name: '[Monday] Barbell Bench Press',
            setNumber: 3,
            repNumber: 10,
            dateTime: DateTime(2026, 10, 11),
          ),
          WorkoutModel(
            id: 'w2',
            // Legacy alias should resolve to canonical 'Cable Pulldown' in detail sheet
            name: '[Monday] Lat Pulldown',
            setNumber: 3,
            repNumber: 12,
            dateTime: DateTime(2026, 10, 11),
          ),
        ];

        await _pumpSessionPage(
          tester,
          DayWorkoutSessionPage(
            dayName: 'Monday',
            workouts: workouts,
            videoViewBuilder: (_) => const SizedBox.expand(
              key: Key('fake_video_surface'),
            ),
            videoControllerFactory: (assetPath, options) {
              final ctrl = FakeSessionVideoPlayerController(
                assetPath: assetPath,
                options: options,
              );
              createdControllers.add(ctrl);
              return ctrl;
            },
          ),
        );

        // No video controllers should be created before opening details
        expect(createdControllers, isEmpty);

        // 1. Tap the first exercise title area ('1. Barbell Bench Press')
        await tester.tap(find.byKey(const Key('session_exercise_tap_0')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.byType(InteractiveExerciseDetailWidget), findsOneWidget);
        expect(find.text('Barbell Bench Press'), findsWidgets);

        final benchCatalog = ExerciseData.findByName('Barbell Bench Press')!;
        for (final step in benchCatalog.instructions) {
          expect(find.text(step), findsOneWidget);
        }

        // Verify matching video asset was initialized exactly once
        expect(createdControllers.length, 1);
        expect(
          createdControllers.first.assetPath,
          'assets/videos/chest/chest_barbell_bench_press.mp4',
        );
        expect(createdControllers.first.initializeCalls, 1);
        expect(createdControllers.first.playCalls, 1);
        expect(createdControllers.first.options?.mixWithOthers, isTrue);

        // Close first detail sheet
        await tester.tap(find.byKey(const Key('close_exercise_detail_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(InteractiveExerciseDetailWidget), findsNothing);
        expect(createdControllers.first.disposeCalls, 1);

        // 2. Tap the Guide button on the second exercise ('[Monday] Lat Pulldown')
        await tester.tap(find.byKey(const Key('session_exercise_guide_1')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.byType(InteractiveExerciseDetailWidget), findsOneWidget);
        // Canonical name for 'Lat Pulldown' is 'Cable Pulldown'
        expect(find.text('Cable Pulldown'), findsOneWidget);
        final pulldownCatalog = ExerciseData.findByName('Lat Pulldown')!;
        for (final step in pulldownCatalog.instructions) {
          expect(find.text(step), findsOneWidget);
        }
        expect(createdControllers.length, 2);
        expect(
          createdControllers.last.assetPath,
          'assets/videos/back/back_cable_pulldown.mp4',
        );
      },
    );

    testWidgets(
      'Missing video assets and unmapped custom exercises show clear unavailable message without crashing or substituting another video',
      (tester) async {
        final createdControllers = <FakeSessionVideoPlayerController>[];
        bool failAssetLoad = true;

        final workouts = [
          // 1. Custom exercise not in ExerciseData (no video asset)
          WorkoutModel(
            id: 'custom_1',
            name: '[Tuesday] Custom Jefferson Curl',
            setNumber: 3,
            repNumber: 10,
            dateTime: DateTime(2026, 10, 11),
          ),
          // 2. Exercise with a video path that fails to load initially, then succeeds on retry
          {
            'name': '[Tuesday] Barbell Bench Press',
            'setNumber': 3,
            'repNumber': 8,
            'videoPath': 'assets/videos/chest/missing_bench_demo.mp4',
          },
        ];

        await _pumpSessionPage(
          tester,
          DayWorkoutSessionPage(
            dayName: 'Tuesday',
            workouts: workouts,
            videoViewBuilder: (_) => const SizedBox.expand(),
            videoControllerFactory: (assetPath, options) {
              final ctrl = FakeSessionVideoPlayerController(
                assetPath: assetPath,
                options: options,
                shouldThrowOnInit: failAssetLoad,
              );
              createdControllers.add(ctrl);
              return ctrl;
            },
          ),
        );

        // Open details for the unmapped custom exercise
        await tester.tap(find.byKey(const Key('session_exercise_tap_0')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.byType(InteractiveExerciseDetailWidget), findsOneWidget);
        expect(find.text('Custom Jefferson Curl'), findsOneWidget);
        expect(find.byKey(const Key('exercise_video_error_state')), findsOneWidget);
        expect(find.text('Video guide unavailable'), findsOneWidget);
        // Must NOT substitute another exercise's video or create a controller for empty path
        expect(createdControllers, isEmpty);
        expect(tester.takeException(), isNull);

        // Close custom exercise detail sheet
        await tester.tap(find.byKey(const Key('close_exercise_detail_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Open details for exercise whose video asset fails to initialize
        await tester.tap(find.byKey(const Key('session_exercise_guide_1')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.byKey(const Key('exercise_video_error_state')), findsOneWidget);
        expect(find.text('Video guide unavailable'), findsOneWidget);
        expect(find.byKey(const Key('exercise_video_retry_button')), findsOneWidget);
        expect(createdControllers.length, 1);
        expect(createdControllers.first.disposeCalls, 1);

        // Retry after asset becomes available
        failAssetLoad = false;
        await tester.tap(find.byKey(const Key('exercise_video_retry_button')));
        await tester.pump();

        expect(createdControllers.length, 2);
        expect(createdControllers.last.initializeCalls, 1);
        expect(createdControllers.last.playCalls, 1);
        expect(find.byKey(const Key('exercise_video_error_state')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Active workout session state (sets, reps, weights, completed exercises, rest timer, progress) is preserved when opening and closing exercise details',
      (tester) async {
        final workouts = [
          WorkoutModel(
            id: 'w1',
            name: '[Wednesday] Classic Barbell Squat',
            setNumber: 3,
            repNumber: 8,
            dateTime: DateTime(2026, 10, 11),
          ),
          WorkoutModel(
            id: 'w2',
            name: '[Wednesday] Barbell Curl',
            setNumber: 2,
            repNumber: 12,
            dateTime: DateTime(2026, 10, 11),
          ),
        ];

        await _pumpSessionPage(
          tester,
          DayWorkoutSessionPage(
            dayName: 'Wednesday',
            workouts: workouts,
            videoViewBuilder: (_) => const SizedBox.expand(),
            videoControllerFactory: (assetPath, options) {
              return FakeSessionVideoPlayerController(
                assetPath: assetPath,
                options: options,
              );
            },
          ),
        );

        // 1. Modify weights and reps on Exercise 0 (Classic Barbell Squat)
        await tester.enterText(
          find.byKey(const Key('session_weight_input_0_0')),
          '100',
        );
        await tester.enterText(
          find.byKey(const Key('session_reps_input_0_0')),
          '8',
        );
        await tester.enterText(
          find.byKey(const Key('session_weight_input_0_1')),
          '105',
        );
        await tester.enterText(
          find.byKey(const Key('session_reps_input_0_1')),
          '6',
        );

        // 2. Add a 4th set to Exercise 0
        await tester.tap(find.byKey(const Key('session_add_set_0')));
        await tester.pump();
        expect(find.byKey(const Key('session_weight_input_0_3')), findsOneWidget);

        // 3. Complete Set 1 and Set 2 on Exercise 0 (triggers persistent Rest Timer)
        await tester.tap(find.byKey(const Key('session_set_done_0_0')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('session_set_done_0_1')));
        await tester.pump();

        // Advance session & rest timer by 5 seconds
        await tester.pump(const Duration(seconds: 5));

        // Verify state BEFORE opening exercise details:
        // Volume = (100 * 8) + (105 * 6) = 800 + 630 = 1430 kg
        // Completed sets = 2/6 sets
        // Rest timer active (120s compound - 5s = 01:55)
        expect(find.text('1430 kg'), findsOneWidget);
        expect(find.text('2/6 sets'), findsOneWidget);
        expect(find.text('2/4 sets completed'), findsOneWidget);
        expect(find.text('REST TIMER'), findsOneWidget);
        expect(find.text('01:55'), findsOneWidget);

        // 4. Open Exercise Details for Classic Barbell Squat
        await tester.tap(find.byKey(const Key('session_exercise_tap_0')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(InteractiveExerciseDetailWidget), findsOneWidget);
        expect(find.text('Classic Barbell Squat'), findsOneWidget);

        // Close Exercise Details
        await tester.tap(find.byKey(const Key('close_exercise_detail_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(InteractiveExerciseDetailWidget), findsNothing);

        // 5. Verify all session state is 100% preserved after closing details
        final weight00 = tester.widget<TextField>(
          find.byKey(const Key('session_weight_input_0_0')),
        );
        final reps00 = tester.widget<TextField>(
          find.byKey(const Key('session_reps_input_0_0')),
        );
        final weight01 = tester.widget<TextField>(
          find.byKey(const Key('session_weight_input_0_1')),
        );
        final reps01 = tester.widget<TextField>(
          find.byKey(const Key('session_reps_input_0_1')),
        );

        expect(weight00.controller?.text, '100');
        expect(reps00.controller?.text, '8');
        expect(weight00.enabled, isFalse); // Completed set stays locked/completed
        expect(weight01.controller?.text, '105');
        expect(reps01.controller?.text, '6');
        expect(weight01.enabled, isFalse);
        expect(find.byKey(const Key('session_weight_input_0_3')), findsOneWidget);
        expect(find.text('1430 kg'), findsOneWidget);
        expect(find.text('2/6 sets'), findsOneWidget);
        expect(find.text('2/4 sets completed'), findsOneWidget);
        expect(find.text('REST TIMER'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Repeatedly opening and closing exercise details and switching detail tabs does not cause excessive controller creation or lifecycle errors',
      (tester) async {
        final createdControllers = <FakeSessionVideoPlayerController>[];
        final workouts = [
          WorkoutModel(
            id: 'w1',
            name: '[Friday] Dumbbell Arnold Press',
            setNumber: 3,
            repNumber: 10,
            dateTime: DateTime(2026, 10, 11),
          ),
        ];

        await _pumpSessionPage(
          tester,
          DayWorkoutSessionPage(
            dayName: 'Friday',
            workouts: workouts,
            videoViewBuilder: (_) => const SizedBox.expand(),
            videoControllerFactory: (assetPath, options) {
              final ctrl = FakeSessionVideoPlayerController(
                assetPath: assetPath,
                options: options,
              );
              createdControllers.add(ctrl);
              return ctrl;
            },
          ),
        );

        for (int cycle = 0; cycle < 3; cycle++) {
          await tester.tap(find.byKey(const Key('session_exercise_guide_0')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));

          expect(find.byType(InteractiveExerciseDetailWidget), findsOneWidget);
          expect(createdControllers.length, cycle + 1);
          final currentController = createdControllers.last;
          expect(currentController.initializeCalls, 1);
          expect(currentController.disposeCalls, 0);

          // Switch tabs inside InteractiveExerciseDetailWidget (Instructions -> Log Set -> History -> Instructions)
          // Offstage keeps video mounted so no extra VideoPlayerController is created
          await tester.tap(find.text('Log Set'));
          await tester.pump();
          await tester.tap(find.text('History'));
          await tester.pump();
          await tester.tap(find.text('Instructions'));
          await tester.pump();

          expect(createdControllers.length, cycle + 1);
          expect(currentController.initializeCalls, 1);
          expect(currentController.disposeCalls, 0);

          // Close detail sheet
          await tester.tap(find.byKey(const Key('close_exercise_detail_button')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));

          expect(find.byType(InteractiveExerciseDetailWidget), findsNothing);
          expect(currentController.disposeCalls, 1);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Phase 2B: Swapping an exercise updates details and loads valid video without unavailable error',
      (WidgetTester tester) async {
        final List<FakeSessionVideoPlayerController> createdControllers = [];
        final workouts = [
          WorkoutModel(
            id: 'w1',
            name: 'Barbell Bench Press',
            setNumber: 3,
            repNumber: 10,
            dateTime: DateTime(2026, 10, 11),
          ),
        ];

        await _pumpSessionPage(
          tester,
          DayWorkoutSessionPage(
            dayName: 'Monday',
            workouts: workouts,
            videoViewBuilder: (_) => const SizedBox.expand(),
            videoControllerFactory: (assetPath, options) {
              final ctrl = FakeSessionVideoPlayerController(
                assetPath: assetPath,
                options: options,
              );
              createdControllers.add(ctrl);
              return ctrl;
            },
          ),
        );

        // Tap the swap button for the exercise
        await tester.tap(find.byKey(const Key('session_exercise_swap_0')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // The modal should display alternative exercises
        expect(find.text('Substitute Exercise'), findsOneWidget);
        expect(find.text('Dumbbell Bench Press'), findsOneWidget);

        // Select 'Dumbbell Bench Press'
        await tester.tap(find.text('Dumbbell Bench Press'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Modal should be closed and exercise card now shows 'Dumbbell Bench Press'
        expect(find.text('Substitute Exercise'), findsNothing);
        expect(find.textContaining('Dumbbell Bench Press'), findsOneWidget);

        // Open details guide for the swapped exercise
        await tester.tap(find.byKey(const Key('session_exercise_guide_0')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Details should open and video player controller should be initialized with the resolved video
        expect(find.byType(InteractiveExerciseDetailWidget), findsOneWidget);
        expect(find.text('Video guide unavailable'), findsNothing);
        expect(createdControllers.isNotEmpty, isTrue);
        final swappedVideoCtrl = createdControllers.last;
        expect(swappedVideoCtrl.assetPath.isNotEmpty, isTrue);
        expect(swappedVideoCtrl.assetPath.endsWith('.mp4'), isTrue);
        expect(swappedVideoCtrl.initializeCalls, 1);

        // Close detail sheet
        await tester.tap(find.byKey(const Key('close_exercise_detail_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.byType(InteractiveExerciseDetailWidget), findsNothing);
      },
    );
  });
}
