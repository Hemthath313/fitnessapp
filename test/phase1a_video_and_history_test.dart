import 'dart:async';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/workout_logs/workout_log_history_page.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

class FakeTestVideoPlayerController extends ValueNotifier<VideoPlayerValue>
    implements VideoPlayerController {
  final String assetPath;
  final VideoPlayerOptions? options;
  final Future<void> Function()? onInitialize;

  int initializeCalls = 0;
  int playCalls = 0;
  int pauseCalls = 0;
  int disposeCalls = 0;
  double? lastVolume;
  bool? lastLooping;

  FakeTestVideoPlayerController({
    required this.assetPath,
    this.options,
    this.onInitialize,
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
    if (onInitialize != null) {
      await onInitialize!();
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

void main() {
  group('Phase 1A — ExerciseVideoPlayer Performance & Lifecycle', () {
    testWidgets(
      'List card preview (showThumbnailOnly: true) initializes VideoPlayerController at first frame without auto-play',
      (WidgetTester tester) async {
        int factoryCallCount = 0;
        FakeTestVideoPlayerController? createdController;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExerciseVideoPlayer(
                videoPath: 'assets/videos/chest/chest_barbell_bench_press.mp4',
                width: 110,
                height: 85,
                showThumbnailOnly: true,
                videoViewBuilder: (_) => const SizedBox.expand(),
                controllerFactory: (path, options) {
                  factoryCallCount++;
                  createdController = FakeTestVideoPlayerController(
                    assetPath: path,
                    options: options,
                  );
                  return createdController!;
                },
              ),
            ),
          ),
        );
        await tester.pump();

        expect(factoryCallCount, 1);
        expect(
          createdController!.assetPath,
          'assets/videos/chest/chest_barbell_bench_press.mp4',
        );
        expect(createdController!.initializeCalls, 1);
        expect(createdController!.playCalls, 0);
        expect(createdController!.lastVolume, 0.0);
        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'didUpdateWidget disposes old controller and initializes new controller when videoPath changes, preserving mixWithOthers',
      (WidgetTester tester) async {
        final createdControllers = <FakeTestVideoPlayerController>[];

        Widget buildPlayer(String path, {double height = 180}) {
          return MaterialApp(
            home: Scaffold(
              body: ExerciseVideoPlayer(
                videoPath: path,
                height: height,
                width: 300,
                fit: BoxFit.contain,
                autoPlay: true,
                videoViewBuilder: (_) => const SizedBox.expand(),
                controllerFactory: (assetPath, options) {
                  final ctrl = FakeTestVideoPlayerController(
                    assetPath: assetPath,
                    options: options,
                  );
                  createdControllers.add(ctrl);
                  return ctrl;
                },
              ),
            ),
          );
        }

        // 1. Initial mount with video A
        await tester.pumpWidget(
          buildPlayer('assets/videos/chest/chest_barbell_bench_press.mp4'),
        );
        await tester.pump();

        expect(createdControllers.length, 1);
        final firstController = createdControllers.first;
        expect(
          firstController.assetPath,
          'assets/videos/chest/chest_barbell_bench_press.mp4',
        );
        expect(firstController.options?.mixWithOthers, isTrue);
        expect(firstController.initializeCalls, 1);
        expect(firstController.playCalls, 1);
        expect(firstController.lastVolume, 0.0);
        expect(firstController.disposeCalls, 0);

        // 2. Rebuild with same videoPath but different height -> should NOT recreate controller
        await tester.pumpWidget(
          buildPlayer(
            'assets/videos/chest/chest_barbell_bench_press.mp4',
            height: 220,
          ),
        );
        await tester.pump();
        expect(createdControllers.length, 1);
        expect(firstController.disposeCalls, 0);

        // 3. Rebuild with new videoPath -> should dispose first and initialize second
        await tester.pumpWidget(
          buildPlayer('assets/videos/legs/legs_classic_barbell_squat.mp4'),
        );
        await tester.pump();

        expect(firstController.disposeCalls, 1);
        expect(createdControllers.length, 2);
        final secondController = createdControllers.last;
        expect(
          secondController.assetPath,
          'assets/videos/legs/legs_classic_barbell_squat.mp4',
        );
        expect(secondController.initializeCalls, 1);
        expect(secondController.playCalls, 1);
      },
    );

    testWidgets(
      'In-flight async initialization is safely discarded if videoPath changes before completion',
      (WidgetTester tester) async {
        final completerA = Completer<void>();
        final createdControllers = <FakeTestVideoPlayerController>[];

        Widget buildPlayer(String path) {
          return MaterialApp(
            home: Scaffold(
              body: ExerciseVideoPlayer(
                videoPath: path,
                height: 180,
                width: 300,
                autoPlay: true,
                videoViewBuilder: (_) => const SizedBox.expand(),
                controllerFactory: (assetPath, options) {
                  final ctrl = FakeTestVideoPlayerController(
                    assetPath: assetPath,
                    options: options,
                    onInitialize: assetPath.contains('bench_press')
                        ? () => completerA.future
                        : null,
                  );
                  createdControllers.add(ctrl);
                  return ctrl;
                },
              ),
            ),
          );
        }

        await tester.pumpWidget(
          buildPlayer('assets/videos/chest/chest_barbell_bench_press.mp4'),
        );
        expect(
          find.byKey(const Key('exercise_video_loading_state')),
          findsOneWidget,
        );

        // Switch videoPath while first controller is still initializing
        await tester.pumpWidget(
          buildPlayer('assets/videos/legs/legs_classic_barbell_squat.mp4'),
        );
        await tester.pump();

        // Now complete the stale first controller's initialization
        completerA.complete();
        await tester.pump();

        expect(createdControllers.length, 2);
        expect(createdControllers.first.disposeCalls, greaterThanOrEqualTo(1));
        expect(createdControllers.last.playCalls, 1);
      },
    );

    testWidgets(
      'Initialization failure renders error state, notifies onErrorChanged, and succeeds on Retry',
      (WidgetTester tester) async {
        bool shouldFail = true;
        final errorStates = <bool>[];
        int attempts = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExerciseVideoPlayer(
                videoPath: 'assets/videos/chest/chest_dips.mp4',
                height: 180,
                width: 300,
                autoPlay: true,
                onErrorChanged: errorStates.add,
                videoViewBuilder: (_) => const SizedBox.expand(),
                controllerFactory: (assetPath, options) {
                  attempts++;
                  return FakeTestVideoPlayerController(
                    assetPath: assetPath,
                    options: options,
                    onInitialize: () async {
                      if (shouldFail) {
                        throw Exception('Decoder initialization failed');
                      }
                    },
                  );
                },
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(attempts, 1);
        expect(
          find.byKey(const Key('exercise_video_error_state')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('exercise_video_retry_button')),
          findsOneWidget,
        );
        expect(errorStates, contains(true));

        // Allow next attempt to succeed and tap Retry
        shouldFail = false;
        await tester.tap(find.byKey(const Key('exercise_video_retry_button')));
        await tester.pump();
        await tester.pump();

        expect(attempts, 2);
        expect(
          find.byKey(const Key('exercise_video_error_state')),
          findsNothing,
        );
        expect(errorStates.last, isFalse);
      },
    );
  });

  group('Phase 1A — WorkoutLogHistoryPage Feed Merging & Deduplication', () {
    final mondayMorning = DateTime(2026, 10, 5, 9, 0);
    final mondayMorningEnd = DateTime(2026, 10, 5, 9, 45);
    final tuesdayAfternoon = DateTime(2026, 10, 6, 17, 30);

    WorkoutSession createMondaySession() {
      return WorkoutSession(
        id: 'session_mon_1',
        userId: 'user_1',
        workoutName: 'Monday Push Routine',
        dayName: 'Monday',
        startedAt: mondayMorning,
        completedAt: mondayMorningEnd,
        durationSeconds: 2700,
        status: 'completed',
        totalVolume: 2400,
        exercises: [
          SessionExercise(
            exerciseName: '[Monday] Barbell Bench Press',
            order: 0,
            isCompleted: true,
            sets: [
              WorkoutSet(weight: 80, reps: 10, isCompleted: true),
              WorkoutSet(weight: 80, reps: 10, isCompleted: true),
            ],
          ),
          SessionExercise(
            exerciseName: 'Incline Dumbbell Press',
            order: 1,
            isCompleted: true,
            sets: [
              WorkoutSet(weight: 30, reps: 10, isCompleted: true),
            ],
          ),
        ],
      );
    }

    test(
      'Shows standalone exercise logs in the default All feed alongside completed WorkoutSessions',
      () {
        final mondaySession = createMondaySession();
        final tuesdayStandaloneLog = WorkoutLog(
          id: 'log_tue_1',
          exerciseName: 'Barbell Curl',
          date: tuesdayAfternoon,
          sets: [WorkoutSet(weight: 35, reps: 10, isCompleted: true)],
          notes: 'Felt strong',
          category: 'Biceps',
        );

        final feed = WorkoutLogHistoryPage.buildFeedData(
          allSessions: [mondaySession],
          allLogs: [tuesdayStandaloneLog],
          selectedDay: null,
        );

        expect(feed.displayedSessions.length, 1);
        expect(feed.displayedSessions.first.id, 'session_mon_1');
        expect(feed.displayedLegacyLogs.length, 1);
        expect(feed.displayedLegacyLogs.first.id, 'log_tue_1');
        expect(feed.totalDisplayCount, 2);
        expect(
          feed.activeDates,
          containsAll([
            DateTime(2026, 10, 5),
            DateTime(2026, 10, 6),
          ]),
        );
      },
    );

    test(
      'Does not duplicate session-related WorkoutLogs written during WorkoutSession save',
      () {
        final mondaySession = createMondaySession();

        // Logs written by WorkoutLogService.saveWorkoutSession for Monday's session
        final sessionDuplicateLog1 = WorkoutLog(
          id: 'log_mon_dup_1',
          exerciseName: 'Barbell Bench Press',
          date: mondayMorningEnd,
          sets: [
            WorkoutSet(weight: 80, reps: 10, isCompleted: true),
            WorkoutSet(weight: 80, reps: 10, isCompleted: true),
          ],
          notes: '',
          category: 'Strength',
        );
        final sessionDuplicateLog2 = WorkoutLog(
          id: 'log_mon_dup_2',
          exerciseName: 'Incline Dumbbell Press',
          date: mondayMorningEnd,
          sets: [
            WorkoutSet(weight: 30, reps: 10, isCompleted: true),
          ],
          notes: '',
          category: 'Strength',
        );

        // Standalone log on Tuesday
        final tuesdayStandaloneLog = WorkoutLog(
          id: 'log_tue_standalone',
          exerciseName: 'Lat Pulldown',
          date: tuesdayAfternoon,
          sets: [WorkoutSet(weight: 60, reps: 12, isCompleted: true)],
          notes: '',
          category: 'Back',
        );

        final allFeed = WorkoutLogHistoryPage.buildFeedData(
          allSessions: [mondaySession],
          allLogs: [
            sessionDuplicateLog1,
            sessionDuplicateLog2,
            tuesdayStandaloneLog,
          ],
          selectedDay: null,
        );

        expect(allFeed.displayedSessions.length, 1);
        expect(allFeed.displayedLegacyLogs.length, 1);
        expect(allFeed.displayedLegacyLogs.first.id, 'log_tue_standalone');
        expect(allFeed.totalDisplayCount, 2);

        // Calendar filter on Monday: shows Monday session and 0 duplicate logs
        final mondayFeed = WorkoutLogHistoryPage.buildFeedData(
          allSessions: [mondaySession],
          allLogs: [
            sessionDuplicateLog1,
            sessionDuplicateLog2,
            tuesdayStandaloneLog,
          ],
          selectedDay: DateTime(2026, 10, 5),
        );
        expect(mondayFeed.displayedSessions.length, 1);
        expect(mondayFeed.displayedLegacyLogs, isEmpty);

        // Calendar filter on Tuesday: shows Tuesday standalone log
        final tuesdayFeed = WorkoutLogHistoryPage.buildFeedData(
          allSessions: [mondaySession],
          allLogs: [
            sessionDuplicateLog1,
            sessionDuplicateLog2,
            tuesdayStandaloneLog,
          ],
          selectedDay: DateTime(2026, 10, 6),
        );
        expect(tuesdayFeed.displayedSessions, isEmpty);
        expect(tuesdayFeed.displayedLegacyLogs.length, 1);
        expect(tuesdayFeed.displayedLegacyLogs.first.id, 'log_tue_standalone');
      },
    );
  });
}
