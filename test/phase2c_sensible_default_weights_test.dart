import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/presentation/custom_workouts/day_workout_session_page.dart';
import 'package:fitness_app/presentation/widgets/interactive_exercise_detail.dart';
import 'package:fitness_app/presentation/workout_logs/workout_log_screen.dart';
import 'package:fitness_app/services/progression_service.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
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

Widget _wrapWithScreenUtil(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    WorkoutLogService.clearLastLogCache();
    InteractiveExerciseDetailWidget.clearDrafts();
  });

  group('Phase 2C: Sensible Default Weights & Progression', () {
    test(
      '1. Bodyweight and no-external-load exercises default to 0 kg while weighted machines do not',
      () {
        const bodyweightExercises = <String>[
          'Deep Pushups',
          'Close Grip Pushups (Alt)',
          'Incline Push-Up',
          'Decline Push-Up',
          'Pull-Ups',
          'Chin-ups Narrow Underhand',
          'Chest Dips',
          'Tricep Dips',
          'V-Up',
          'Twisting Crunch',
          'Air Twist Crunch',
          'Vertical Leg Raise',
          'Incline Leg Hip Raise',
          'Hyperextension',
          'Stretching: Chin to Chest',
          'Stretching: Spinal Stretch',
          'Burpee',
          'Jumping Jack',
          'Mountain Climbers',
          'High Knee Run',
          'Bridge Pose',
          'Flexian Leg Sit Up',
        ];

        for (final name in bodyweightExercises) {
          expect(
            ProgressionService.isBodyweightOrNoExternalLoad(name),
            isTrue,
            reason: 'Expected "$name" to be classified as bodyweight/no-external-load',
          );
          expect(
            ProgressionService.getSensibleDefaultWeight(name),
            equals(0.0),
            reason: 'Expected "$name" default weight to be 0.0 kg',
          );
          final target = ProgressionService.calculateNextTarget(
            exerciseName: name,
            previousLog: null,
          );
          expect(target.recommendedWeight, equals(0.0));
          expect(target.type, equals(ProgressionType.baseline));
        }

        // Weighted dip / crunch machines must not be misclassified as 0 kg bodyweight
        expect(
          ProgressionService.isBodyweightOrNoExternalLoad('Lever Seated Dips'),
          isFalse,
        );
        expect(
          ProgressionService.getSensibleDefaultWeight('Lever Seated Dips'),
          equals(ProgressionService.neutralDefaultWeight),
        );
        expect(
          ProgressionService.isBodyweightOrNoExternalLoad('Kneeling Cable Crunch'),
          isFalse,
        );
        expect(
          ProgressionService.getSensibleDefaultWeight('Kneeling Cable Crunch'),
          equals(ProgressionService.neutralDefaultWeight),
        );
        expect(
          ProgressionService.isBodyweightOrNoExternalLoad('Seated Machine Crunch'),
          isFalse,
        );
        expect(
          ProgressionService.getSensibleDefaultWeight('Seated Machine Crunch'),
          equals(ProgressionService.neutralDefaultWeight),
        );
      },
    );

    test(
      '2. Exercises with usable prior history receive progression-based suggestions',
      () {
        // Compound exercise hitting top target reps (8) -> +2.5 kg step up
        final benchHistory = WorkoutLog(
          id: 'log_bench_1',
          exerciseName: 'Barbell Bench Press',
          date: DateTime(2026, 10, 10),
          sets: [
            WorkoutSet(weight: 60.0, reps: 8, isCompleted: true),
            WorkoutSet(weight: 60.0, reps: 8, isCompleted: true),
            WorkoutSet(weight: 60.0, reps: 8, isCompleted: true),
          ],
          category: 'Chest',
        );
        final benchRec = ProgressionService.calculateNextTarget(
          exerciseName: 'Barbell Bench Press',
          previousLog: benchHistory,
        );
        expect(benchRec.type, equals(ProgressionType.increaseWeight));
        expect(benchRec.recommendedWeight, equals(62.5));

        // Accessory exercise within target zone (10 reps, below max 12) -> hold weight, +1 rep target
        final curlHistory = WorkoutLog(
          id: 'log_curl_1',
          exerciseName: 'Dumbbell Bicep Curl',
          date: DateTime(2026, 10, 10),
          sets: [
            WorkoutSet(weight: 14.0, reps: 10, isCompleted: true),
            WorkoutSet(weight: 14.0, reps: 10, isCompleted: true),
          ],
          category: 'Biceps',
        );
        final curlRec = ProgressionService.calculateNextTarget(
          exerciseName: 'Dumbbell Bicep Curl',
          previousLog: curlHistory,
        );
        expect(curlRec.type, equals(ProgressionType.increaseReps));
        expect(curlRec.recommendedWeight, equals(14.0));

        // Bodyweight exercise with 0 kg history stays at 0 kg (does not add +2.5 kg)
        final pullupHistory = WorkoutLog(
          id: 'log_pullup_1',
          exerciseName: 'Pull-Ups',
          date: DateTime(2026, 10, 10),
          sets: [
            WorkoutSet(weight: 0.0, reps: 10, isCompleted: true),
            WorkoutSet(weight: 0.0, reps: 10, isCompleted: true),
          ],
          category: 'Back',
        );
        final pullupRec = ProgressionService.calculateNextTarget(
          exerciseName: 'Pull-Ups',
          previousLog: pullupHistory,
        );
        expect(pullupRec.recommendedWeight, equals(0.0));
      },
    );

    test(
      '3. Exercises with ambiguous equipment metadata and unknown custom exercises remain explicitly unconfigured without presenting 15 kg as a personalized recommendation',
      () {
        // Verify no exercise in the entire 145-exercise catalog defaults to hardcoded 12 kg
        for (final ex in ExerciseData.all) {
          final weight = ProgressionService.getSensibleDefaultWeight(
            ex.name,
            equipment: ex.equipment,
            category: ExerciseData.categoryFor(ex.name),
          );
          expect(
            weight,
            isNot(equals(12.0)),
            reason: 'Exercise "${ex.name}" should not default to hardcoded 12 kg',
          );
        }

        // Ambiguous equipment metadata exercises in catalog
        const ambiguousExercises = <String>[
          '45 Degree Side Bend', // Dumbbell (optional)
          'Donkey Calf Raise', // Machine or Bench
          'Weighted Leg Extension', // Dumbbell or Ankle Weights
          'Resistance Band High Fly', // Resistance Band
          'Band Lateral Raise', // Resistance Band
          'Resistance Band Leg Curl', // Resistance Band
          'Band Seated Hip Abduction', // Resistance Band
        ];
        for (final name in ambiguousExercises) {
          expect(
            ProgressionService.hasAmbiguousEquipmentMetadata(name),
            isTrue,
            reason:
                'Expected "$name" to be flagged as having ambiguous equipment metadata',
          );
          expect(
            ProgressionService.getInitialDefaultWeight(name),
            isNull,
            reason:
                'Expected "$name" initial default weight to be null (unconfigured)',
          );
          expect(
            ProgressionService.formatInitialWeight(name),
            equals(''),
            reason:
                'Expected "$name" formatted initial weight to be empty string rather than 15',
          );

          final rec = ProgressionService.calculateNextTarget(
            exerciseName: name,
            previousLog: null,
          );
          expect(rec.hasRecommendedWeight, isFalse);
          expect(rec.formattedWeight, equals(''));
          expect(rec.badgeLabel, equals('SELECT LOAD'));
          expect(rec.targetSummary, equals('Target: Select load × 8-12'));
          expect(rec.targetSummary, isNot(contains('15')));
        }

        // Unknown custom exercises (not in canonical catalog, not bodyweight)
        const unknownCustomExercises = <String>[
          'Custom Landmine Press',
          'Mystery Garage Lift',
          'Bulgarian Bag Rotational Swing',
        ];
        for (final customName in unknownCustomExercises) {
          expect(
            ProgressionService.hasAmbiguousEquipmentMetadata(customName),
            isTrue,
            reason:
                'Expected unknown custom exercise "$customName" to be treated as unconfigured',
          );
          expect(
            ProgressionService.getInitialDefaultWeight(customName),
            isNull,
          );
          expect(
            ProgressionService.formatInitialWeight(customName),
            equals(''),
          );

          final rec = ProgressionService.calculateNextTarget(
            exerciseName: customName,
            previousLog: null,
          );
          expect(rec.hasRecommendedWeight, isFalse);
          expect(rec.formattedWeight, equals(''));
          expect(rec.badgeLabel, equals('SELECT LOAD'));
          expect(rec.targetSummary, equals('Target: Select load × 8-12'));
          expect(rec.targetSummary, isNot(contains('15')));
        }

        // Ambiguous equipment and unknown custom exercises WITH usable history still get progression
        final donkeyHistory = WorkoutLog(
          id: 'log_donkey_1',
          exerciseName: 'Donkey Calf Raise',
          date: DateTime(2026, 10, 10),
          sets: [
            WorkoutSet(weight: 30.0, reps: 12, isCompleted: true),
            WorkoutSet(weight: 30.0, reps: 12, isCompleted: true),
          ],
          category: 'Calves',
        );
        final donkeyRec = ProgressionService.calculateNextTarget(
          exerciseName: 'Donkey Calf Raise',
          previousLog: donkeyHistory,
        );
        expect(donkeyRec.hasRecommendedWeight, isTrue);
        expect(donkeyRec.type, equals(ProgressionType.increaseWeight));
        expect(donkeyRec.recommendedWeight, equals(31.0));
        expect(donkeyRec.formattedWeight, equals('31'));

        final customHistory = WorkoutLog(
          id: 'log_custom_1',
          exerciseName: 'Custom Landmine Press',
          date: DateTime(2026, 10, 10),
          sets: [
            WorkoutSet(weight: 25.0, reps: 10, isCompleted: true),
            WorkoutSet(weight: 25.0, reps: 10, isCompleted: true),
          ],
          category: 'Shoulders',
        );
        final customRec = ProgressionService.calculateNextTarget(
          exerciseName: 'Custom Landmine Press',
          previousLog: customHistory,
        );
        expect(customRec.hasRecommendedWeight, isTrue);
        expect(customRec.type, equals(ProgressionType.increaseReps));
        expect(customRec.recommendedWeight, equals(25.0));
        expect(customRec.formattedWeight, equals('25'));

        // External resistance exercises with empty or 0 kg invalid logs fall back to baseline default
        final zeroWeightBenchLog = WorkoutLog(
          id: 'log_zero',
          exerciseName: 'Barbell Bench Press',
          date: DateTime(2026, 10, 10),
          sets: [WorkoutSet(weight: 0.0, reps: 8, isCompleted: true)],
          category: 'Chest',
        );
        final fallbackRec = ProgressionService.calculateNextTarget(
          exerciseName: 'Barbell Bench Press',
          previousLog: zeroWeightBenchLog,
        );
        expect(fallbackRec.type, equals(ProgressionType.baseline));
        expect(fallbackRec.hasRecommendedWeight, isTrue);
        expect(fallbackRec.recommendedWeight, equals(40.0));
      },
    );

    testWidgets(
      '4. InteractiveExerciseDetailWidget defaults bodyweight to 0 kg, uses history when present, and preserves user-entered weights across rebuilds and reopening',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Seed history for Cable Standing Fly (15 kg default -> 20 kg history -> +1 kg step up = 21 kg)
        WorkoutLogService.seedLastLogCache(
          'Cable Standing Fly',
          WorkoutLog(
            id: 'log_cable_1',
            exerciseName: 'Cable Standing Fly',
            date: DateTime(2026, 10, 10),
            sets: [
              WorkoutSet(weight: 20.0, reps: 12, isCompleted: true),
              WorkoutSet(weight: 20.0, reps: 12, isCompleted: true),
              WorkoutSet(weight: 20.0, reps: 12, isCompleted: true),
            ],
            category: 'Chest',
          ),
        );

        final deepPushups = ExerciseData.findByName('Deep Pushups')!;
        final cableStandingFly = ExerciseData.findByName('Cable Standing Fly')!;

        Exercise activeExercise = deepPushups;
        int rebuildCounter = 0;

        await tester.pumpWidget(
          _wrapWithScreenUtil(
            StatefulBuilder(
              builder: (context, setHostState) {
                return Scaffold(
                  body: Column(
                    children: [
                      Wrap(
                        children: [
                          ElevatedButton(
                            key: const Key('open_detail_sheet_btn'),
                            onPressed: () {
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => InteractiveExerciseDetailWidget(
                                  name: activeExercise.name,
                                  videoPath: activeExercise.videoPath,
                                  description: activeExercise.description,
                                  target: activeExercise.target,
                                  equipment: activeExercise.equipment,
                                  instructions: activeExercise.instructions,
                                  difficulty: activeExercise.difficulty,
                                  setsReps: activeExercise.setsReps,
                                  category: 'Chest',
                                  // Set table shows only inside a workout.
                                  onSetsChanged: (_) {},
                                  videoControllerFactory: (path, options) =>
                                      _FakeVideoPlayerController(
                                        assetPath: path,
                                        options: options,
                                      ),
                                  videoViewBuilder: (_) =>
                                      const SizedBox(key: Key('mock_video')),
                                ),
                              );
                            },
                            child: const Text('Open Detail'),
                          ),
                          ElevatedButton(
                            key: const Key('switch_to_cable_btn'),
                            onPressed: () {
                              setHostState(() {
                                activeExercise = cableStandingFly;
                              });
                            },
                            child: const Text('Switch Exercise'),
                          ),
                          ElevatedButton(
                            key: const Key('trigger_rebuild_btn'),
                            onPressed: () {
                              setHostState(() {
                                rebuildCounter++;
                              });
                            },
                            child: Text('Rebuild $rebuildCounter'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open Deep Pushups (Bodyweight) -> Log Set tab should default to '0'
        await tester.tap(find.byKey(const Key('open_detail_sheet_btn')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Log Set'));
        await tester.pumpAndSettle();

        final weightField0 = tester.widget<TextField>(
          find.byKey(const Key('detail_weight_input_0')),
        );
        expect(weightField0.controller!.text, equals('0'));

        // User enters custom weight '10' (e.g. weighted vest) on Set 1
        await tester.enterText(find.byKey(const Key('detail_weight_input_0')), '10');
        await tester.pump();
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('detail_weight_input_0')))
              .controller!
              .text,
          equals('10'),
        );

        // Close the exercise detail sheet and reopen it -> user-entered '10' is preserved!
        await tester.tap(find.byKey(const Key('close_exercise_detail_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('open_detail_sheet_btn')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Log Set'));
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<TextField>(find.byKey(const Key('detail_weight_input_0')))
              .controller!
              .text,
          equals('10'),
        );
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('detail_weight_input_1')))
              .controller!
              .text,
          equals('0'),
        );

        await tester.tap(find.byKey(const Key('close_exercise_detail_button')));
        await tester.pumpAndSettle();

        // Switch to Cable Crossover (has history: 20 kg x 12 -> recommends 21 kg)
        await tester.tap(find.byKey(const Key('switch_to_cable_btn')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('open_detail_sheet_btn')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Log Set'));
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<TextField>(find.byKey(const Key('detail_weight_input_0')))
              .controller!
              .text,
          equals('21'),
        );
      },
    );

    testWidgets(
      '5. DayWorkoutSessionPage and WorkoutLogScreen (Quick Log) support sensible defaults and preserve user edits across detail modal open/close',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        WorkoutLogService.seedLastLogCache(
          'Barbell Bench Press',
          WorkoutLog(
            id: 'log_bench_session',
            exerciseName: 'Barbell Bench Press',
            date: DateTime(2026, 10, 10),
            sets: [
              WorkoutSet(weight: 70.0, reps: 8, isCompleted: true),
              WorkoutSet(weight: 70.0, reps: 8, isCompleted: true),
              WorkoutSet(weight: 70.0, reps: 8, isCompleted: true),
            ],
            category: 'Chest',
          ),
        );

        final workouts = <Map<String, dynamic>>[
          {
            'name': 'Deep Pushups',
            'setNumber': 2,
            'repNumber': 12,
          },
          {
            'name': 'Barbell Bench Press',
            'setNumber': 2,
            'repNumber': 8,
          },
          {
            'name': 'Lever Pec Dec Fly',
            'setNumber': 2,
            'repNumber': 10,
          },
        ];

        await tester.pumpWidget(
          _wrapWithScreenUtil(
            DayWorkoutSessionPage(
              dayName: 'Chest',
              workouts: workouts,
              videoControllerFactory: (path, options) =>
                  _FakeVideoPlayerController(assetPath: path, options: options),
              videoViewBuilder: (_) =>
                  const SizedBox(key: Key('session_mock_video')),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        // 1. Deep Pushups (bodyweight) defaults to '0'
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('session_weight_input_0_0')))
              .controller!
              .text,
          equals('0'),
        );

        // 2. Barbell Bench Press (with history 70 kg x 8) gets progression recommendation '72.5'
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('session_weight_input_1_0')))
              .controller!
              .text,
          equals('72.5'),
        );

        // 3. Lever Pec Dec Fly (known machine external resistance, no history) gets safe neutral fallback '15'
        await tester.scrollUntilVisible(
          find.byKey(const Key('session_weight_input_2_0')),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('session_weight_input_2_0')))
              .controller!
              .text,
          equals('15'),
        );

        // User edits Barbell Bench Press Set 1 weight to '77.5' in active session
        await tester.ensureVisible(find.byKey(const Key('session_exercise_tap_1')));
        await tester.pump();
        await tester.enterText(
          find.byKey(const Key('session_weight_input_1_0')),
          '77.5',
        );
        await tester.pump();

        // Open exercise details for Barbell Bench Press and switch to Log Set tab
        await tester.tap(find.byKey(const Key('session_exercise_tap_1')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.text('Log Set'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Verify user-entered '77.5' is shown in detail sheet and not overwritten
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('detail_weight_input_0')))
              .controller!
              .text,
          equals('77.5'),
        );

        // Close detail sheet and verify active session still has '77.5'
        await tester.tap(find.byKey(const Key('close_exercise_detail_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          tester
              .widget<TextField>(find.byKey(const Key('session_weight_input_1_0')))
              .controller!
              .text,
          equals('77.5'),
        );

        // Now verify Quick Log (WorkoutLogScreen) compatibility
        await tester.pumpWidget(
          _wrapWithScreenUtil(
            const WorkoutLogScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // Tapping 'Pull-Ups' Quick Chip seeds '0' kg on unedited set
        await tester.ensureVisible(find.text('Pull-Ups'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pull-Ups'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('quick_log_weight_input_0')))
              .controller!
              .text,
          equals('0'),
        );

        // Tapping 'Barbell Bench Press' Quick Chip seeds '72.5' kg from progression history
        await tester.ensureVisible(find.text('Barbell Bench Press'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Barbell Bench Press'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('quick_log_weight_input_0')))
              .controller!
              .text,
          equals('72.5'),
        );

        // Once user manually edits weight in Quick Log, tapping another chip does not overwrite user edit
        await tester.enterText(
          find.byKey(const Key('quick_log_weight_input_0')),
          '80',
        );
        await tester.pump();
        await tester.ensureVisible(find.text('Deadlift'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Deadlift'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('quick_log_weight_input_0')))
              .controller!
              .text,
          equals('80'),
        );
      },
    );

    testWidgets(
      '6. Ambiguous equipment and unknown custom exercises in DayWorkoutSessionPage and InteractiveExerciseDetailWidget stay unconfigured instead of showing 15 kg',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final workouts = <Map<String, dynamic>>[
          {
            'name': 'Donkey Calf Raise', // Machine or Bench (ambiguous)
            'setNumber': 2,
            'repNumber': 12,
          },
          {
            'name': 'Custom Landmine Press', // Unknown custom exercise
            'setNumber': 2,
            'repNumber': 10,
          },
        ];

        await tester.pumpWidget(
          _wrapWithScreenUtil(
            DayWorkoutSessionPage(
              dayName: 'Full Body',
              workouts: workouts,
              videoControllerFactory: (path, options) =>
                  _FakeVideoPlayerController(assetPath: path, options: options),
              videoViewBuilder: (_) =>
                  const SizedBox(key: Key('session_mock_video')),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        // Neither ambiguous nor unknown custom exercise should pre-fill '15' or show 'Target: 15.0 kg'
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('session_weight_input_0_0')))
              .controller!
              .text,
          equals(''),
        );
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('session_weight_input_1_0')))
              .controller!
              .text,
          equals(''),
        );
        expect(find.textContaining('15.0 kg'), findsNothing);
        expect(find.text('SELECT LOAD'), findsNWidgets(2));
        expect(find.text('Target: Select load × 8-12'), findsNWidgets(2));

        // Open exercise detail modal for Donkey Calf Raise -> Log Set tab also starts unconfigured ('')
        await tester.tap(find.byKey(const Key('session_exercise_tap_0')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.text('Log Set'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          tester
              .widget<TextField>(find.byKey(const Key('detail_weight_input_0')))
              .controller!
              .text,
          equals(''),
        );

        // User enters '22.5' in detail sheet and closes it -> preserved in active session
        await tester.enterText(
          find.byKey(const Key('detail_weight_input_0')),
          '22.5',
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('close_exercise_detail_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          tester
              .widget<TextField>(find.byKey(const Key('session_weight_input_0_0')))
              .controller!
              .text,
          equals('22.5'),
        );
      },
    );
  });
}
