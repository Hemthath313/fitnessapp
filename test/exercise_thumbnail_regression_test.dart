import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/presentation/body_parts/pages/body_parts.dart';
import 'package:fitness_app/presentation/body_parts/pages/chest.dart';
import 'package:fitness_app/presentation/body_parts/pages/legs.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

class FakeRegressionVideoPlayerController
    extends ValueNotifier<VideoPlayerValue>
    implements VideoPlayerController {
  final String assetPath;
  final VideoPlayerOptions? options;

  int initializeCalls = 0;
  int playCalls = 0;
  int pauseCalls = 0;
  int seekCalls = 0;
  Duration? lastSeekPosition;
  double? lastVolume;
  bool? lastLooping;

  FakeRegressionVideoPlayerController({
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
    initializeCalls++;
    value = value.copyWith(
      isInitialized: true,
      duration: const Duration(seconds: 15),
      size: const Size(1920, 1080),
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
  Future<void> seekTo(Duration position) async {
    seekCalls++;
    lastSeekPosition = position;
    value = value.copyWith(position: position);
  }

  @override
  Future<void> setVolume(double volume) async {
    lastVolume = volume;
    value = value.copyWith(volume: volume);
  }

  @override
  Future<void> setLooping(bool looping) async {
    lastLooping = looping;
    value = value.copyWith(isLooping: looping);
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

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Exercise Thumbnail Regression & Unique Exercise Resolution Tests', () {
    test('Exercise catalog has unique, exercise-specific video paths for distinct exercises', () {
      final chestExercises = ExerciseData.chest;
      final benchPress = chestExercises.firstWhere((e) => e.name == 'Barbell Bench Press');
      final declinePress = chestExercises.firstWhere((e) => e.name == 'Barbell Decline Bench Press');
      final dips = chestExercises.firstWhere((e) => e.name == 'Chest Dips');

      expect(benchPress.videoPath, 'assets/videos/chest/chest_barbell_bench_press.mp4');
      expect(declinePress.videoPath, 'assets/videos/chest/chest_barbell_decline_bench_press.mp4');
      expect(dips.videoPath, 'assets/videos/chest/chest_dips.mp4');

      // Verify all 3 paths are distinct and non-empty
      expect(benchPress.videoPath, isNot(equals(declinePress.videoPath)));
      expect(benchPress.videoPath, isNot(equals(dips.videoPath)));
      expect(declinePress.videoPath, isNot(equals(dips.videoPath)));
    });

    testWidgets('Barbell Bench Press, Barbell Decline Bench Press, and Chest Dips each initialize their own video controller',
        (tester) async {
      final createdControllers = <String, FakeRegressionVideoPlayerController>{};

      Widget buildThumbnail(String path) {
        return ExerciseVideoPlayer(
          videoPath: path,
          width: 110,
          height: 92,
          showThumbnailOnly: true,
          videoViewBuilder: (_) => const SizedBox.expand(),
          controllerFactory: (assetPath, options) {
            final ctrl = FakeRegressionVideoPlayerController(
              assetPath: assetPath,
              options: options,
            );
            createdControllers[assetPath] = ctrl;
            return ctrl;
          },
        );
      }

      const benchPath = 'assets/videos/chest/chest_barbell_bench_press.mp4';
      const declinePath = 'assets/videos/chest/chest_barbell_decline_bench_press.mp4';
      const dipsPath = 'assets/videos/chest/chest_dips.mp4';

      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              buildThumbnail(benchPath),
              buildThumbnail(declinePath),
              buildThumbnail(dipsPath),
            ],
          ),
        ),
      );
      await tester.pump();

      // Ensure all 3 distinct controllers were created with their respective video paths
      expect(createdControllers.length, 3);
      expect(createdControllers.containsKey(benchPath), isTrue);
      expect(createdControllers.containsKey(declinePath), isTrue);
      expect(createdControllers.containsKey(dipsPath), isTrue);

      // Verify each controller was initialized, paused at Duration.zero, and muted (not auto-playing)
      for (final ctrl in createdControllers.values) {
        expect(ctrl.initializeCalls, 1);
        expect(ctrl.seekCalls, 1);
        expect(ctrl.lastSeekPosition, Duration.zero);
        expect(ctrl.playCalls, 0);
        expect(ctrl.lastVolume, 0.0);
      }

      // Verify 3 play arrow overlay buttons are shown for the 3 individual thumbnails
      expect(find.byIcon(Icons.play_arrow_rounded), findsNWidgets(3));
    });

    testWidgets('ChestExercisesPage simplified UI: info banner removed, filter button opens compact bottom sheet',
        (tester) async {
      await tester.pumpWidget(_wrap(const ChestExercisesPage()));
      await tester.pumpAndSettle();

      // 1. Info banner text is removed
      expect(
        find.text('All exercises include detailed video demonstrations and step-by-step instructions.'),
        findsNothing,
      );

      // 2. Search field and exercise count exist
      expect(find.byKey(const Key('exercise_search_field')), findsOneWidget);
      expect(find.textContaining('Showing'), findsNothing); // count hidden when not filtering

      // 3. Permanent filter chips are NOT on the main screen
      expect(find.byKey(const Key('difficulty_filter_Beginner')), findsNothing);
      expect(find.byKey(const Key('equipment_filter_Dumbbell')), findsNothing);

      // 4. Filter button is present beside search field
      expect(find.byKey(const Key('exercise_filter_button')), findsOneWidget);

      // 5. Tapping filter button opens compact bottom sheet with filters
      await tester.tap(find.byKey(const Key('exercise_filter_button')));
      await tester.pumpAndSettle();

      expect(find.text('Filter Exercises'), findsOneWidget);
      expect(find.byKey(const Key('difficulty_filter_Beginner')), findsOneWidget);
      expect(find.byKey(const Key('equipment_filter_Dumbbell')), findsOneWidget);
      expect(find.byKey(const Key('apply_exercise_filters_button')), findsOneWidget);

      // Apply filter and verify filtered count updates
      await tester.tap(find.byKey(const Key('difficulty_filter_Beginner')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('apply_exercise_filters_button')));
      await tester.pumpAndSettle();

      expect(find.text('Barbell Decline Bench Press'), findsNothing);
      expect(find.byKey(const Key('clear_all_filters_button')), findsOneWidget);
    });

    testWidgets('Filter bottom sheet draft behavior: selecting does not change background until Apply, reset affects draft only, closing discards, and reopening reflects applied',
        (tester) async {
      await tester.pumpWidget(_wrap(const ChestExercisesPage()));
      await tester.pumpAndSettle();

      // Initial state: all 13 chest exercises
      expect(find.textContaining('Showing'), findsNothing); // count hidden when not filtering
      expect(find.text('Barbell Decline Bench Press'), findsOneWidget);

      // 1. Open bottom sheet
      await tester.tap(find.byKey(const Key('exercise_filter_button')));
      await tester.pumpAndSettle();

      // Verify "Apply Filters" text is fully visible without clipping or overflow
      expect(find.text('Apply Filters'), findsOneWidget);
      final applyButtonWidget = find.byKey(const Key('apply_exercise_filters_button'));
      expect(applyButtonWidget, findsOneWidget);
      final applyRenderBox = tester.renderObject(applyButtonWidget) as RenderBox;
      expect(applyRenderBox.size.height, greaterThan(40));
      expect(tester.takeException(), isNull);

      // 2. Select Beginner filter inside sheet
      await tester.tap(find.byKey(const Key('difficulty_filter_Beginner')));
      await tester.pumpAndSettle();

      // Draft inside sheet is selected
      expect(
        tester.widget<ChoiceChip>(find.byKey(const Key('difficulty_filter_Beginner'))).selected,
        isTrue,
      );

      // CRITICAL: Background list MUST NOT change yet — Barbell Decline Bench Press (Intermediate) is still rendered
      expect(find.textContaining('Showing'), findsNothing); // count hidden when not filtering
      expect(find.text('Barbell Decline Bench Press'), findsOneWidget);

      // 3. Close bottom sheet WITHOUT tapping Apply (discard draft)
      Navigator.of(tester.element(find.byKey(const Key('apply_exercise_filters_button')))).pop();
      await tester.pumpAndSettle();

      // Sheet is closed
      expect(find.byKey(const Key('apply_exercise_filters_button')), findsNothing);

      // Background list is still unfiltered (draft was discarded)
      expect(find.textContaining('Showing'), findsNothing); // count hidden when not filtering
      expect(find.text('Barbell Decline Bench Press'), findsOneWidget);

      // 4. Reopen sheet -> should reflect currently applied filters ('All', not 'Beginner')
      await tester.tap(find.byKey(const Key('exercise_filter_button')));
      await tester.pumpAndSettle();

      expect(
        tester.widget<ChoiceChip>(find.byKey(const Key('difficulty_filter_Beginner'))).selected,
        isFalse,
      );
      expect(
        tester.widget<ChoiceChip>(find.byKey(const Key('difficulty_filter_All'))).selected,
        isTrue,
      );

      // 5. Select Dumbbell + Beginner and tap Apply Filters
      await tester.tap(find.byKey(const Key('difficulty_filter_Beginner')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('equipment_filter_Dumbbell')));
      await tester.pumpAndSettle();

      // Still unchanged in background before Apply
      expect(find.textContaining('Showing'), findsNothing); // count hidden when not filtering

      await tester.tap(find.byKey(const Key('apply_exercise_filters_button')));
      await tester.pumpAndSettle();

      // Now sheet closed and background list is updated
      expect(find.byKey(const Key('apply_exercise_filters_button')), findsNothing);
      expect(find.text('Dumbbell Hammer Press'), findsOneWidget);
      expect(find.text('Dumbbell Fly'), findsOneWidget);
      expect(find.text('Incline Dumbbell Press'), findsOneWidget);
      expect(find.text('Barbell Bench Press'), findsNothing);
      expect(find.text('Barbell Decline Bench Press'), findsNothing);
      expect(find.text('Showing 3 of 13 exercises'), findsOneWidget);

      // 6. Reopen sheet -> should reflect applied filters (Beginner & Dumbbell are selected)
      await tester.tap(find.byKey(const Key('exercise_filter_button')));
      await tester.pumpAndSettle();

      expect(
        tester.widget<ChoiceChip>(find.byKey(const Key('difficulty_filter_Beginner'))).selected,
        isTrue,
      );
      expect(
        tester.widget<ChoiceChip>(find.byKey(const Key('equipment_filter_Dumbbell'))).selected,
        isTrue,
      );

      // 7. Tap "Reset" inside the sheet -> resets only the draft selections
      await tester.tap(find.byKey(const Key('reset_sheet_filters_button')));
      await tester.pumpAndSettle();

      expect(
        tester.widget<ChoiceChip>(find.byKey(const Key('difficulty_filter_All'))).selected,
        isTrue,
      );
      expect(
        tester.widget<ChoiceChip>(find.byKey(const Key('equipment_filter_All'))).selected,
        isTrue,
      );
      expect(
        tester.widget<ChoiceChip>(find.byKey(const Key('difficulty_filter_Beginner'))).selected,
        isFalse,
      );

      // Background list is STILL filtered by Beginner+Dumbbell before Apply is tapped
      expect(find.text('Showing 3 of 13 exercises'), findsOneWidget);
      expect(find.text('Barbell Decline Bench Press'), findsNothing);

      // Tap Apply Filters to commit the reset
      await tester.tap(find.byKey(const Key('apply_exercise_filters_button')));
      await tester.pumpAndSettle();

      // Now list is fully reset
      expect(find.textContaining('Showing'), findsNothing); // count hidden when not filtering
      expect(find.text('Barbell Decline Bench Press'), findsOneWidget);
    });

    testWidgets('LegExercisesPage applies filters only on Apply tap, preserving draft isolation',
        (tester) async {
      await tester.pumpWidget(_wrap(const LegExercisesPage()));
      await tester.pumpAndSettle();

      expect(find.text('Classic Barbell Squat'), findsOneWidget);
      final initialCountText = tester
          .widgetList<Text>(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains('exercises')))
          .map((t) => t.data)
          .first;

      // Open filter bottom sheet
      await tester.tap(find.byKey(const Key('exercise_filter_button')));
      await tester.pumpAndSettle();

      // Select Machine filter (draft only)
      await tester.tap(find.byKey(const Key('equipment_filter_Machine')));
      await tester.pumpAndSettle();

      // Background list must not have changed yet
      expect(find.text('Classic Barbell Squat'), findsOneWidget);
      expect(
        tester
            .widgetList<Text>(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains('exercises')))
            .map((t) => t.data)
            .first,
        equals(initialCountText),
      );

      // Tap Apply Filters
      await tester.tap(find.byKey(const Key('apply_exercise_filters_button')));
      await tester.pumpAndSettle();

      // Classic Barbell Squat (Barbell) is gone, Leg Press (Machine) is present
      expect(find.text('Classic Barbell Squat'), findsNothing);
      expect(find.text('Leg Press'), findsOneWidget);

      // Clear filters button resets
      await tester.tap(find.byKey(const Key('clear_all_filters_button')));
      await tester.pumpAndSettle();
      expect(find.text('Classic Barbell Squat'), findsOneWidget);
    });

    testWidgets('BodyPartsScreen has inline filters removed, uses filter bottom sheet with draft isolation, preserves grid and navigation',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrap(const BodyPartsScreen()));
      await tester.pumpAndSettle();

      // 1. Verify inline filter rows are removed
      expect(find.byKey(const Key('body_parts_difficulty_filter_All')), findsNothing);
      expect(find.byKey(const Key('body_parts_difficulty_filter_Beginner')), findsNothing);
      expect(find.byKey(const Key('body_parts_equipment_filter_All')), findsNothing);
      expect(find.byKey(const Key('difficulty_filter_All')), findsNothing);

      // 2. Search field and filter button are present
      expect(find.byKey(const Key('body_parts_search_field')), findsOneWidget);
      expect(find.byKey(const Key('exercise_filter_button')), findsOneWidget);

      // 3. Category cards grid is visible when search query is empty
      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Biceps'), findsOneWidget);

      // 4. Tap filter icon -> opens bottom sheet
      await tester.tap(find.byKey(const Key('exercise_filter_button')));
      await tester.pumpAndSettle();

      expect(find.text('Filter Exercises'), findsOneWidget);
      expect(find.byKey(const Key('reset_sheet_filters_button')), findsOneWidget);
      expect(find.byKey(const Key('apply_exercise_filters_button')), findsOneWidget);
      expect(find.byKey(const Key('difficulty_filter_Beginner')), findsOneWidget);

      // Close bottom sheet without applying
      Navigator.of(tester.element(find.byKey(const Key('apply_exercise_filters_button')))).pop();
      await tester.pumpAndSettle();
      expect(find.text('Filter Exercises'), findsNothing);

      // 5. Enter search query 'Press'
      await tester.enterText(find.byKey(const Key('body_parts_search_field')), 'Press');
      await tester.pumpAndSettle();

      // Search results appear: muscle-group grid replaced by exercise cards
      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('Dumbbell Hammer Press'), findsOneWidget);
      final initialCountText = tester
          .widgetList<Text>(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains('exercises')))
          .map((t) => t.data)
          .first;

      // 6. Open filter bottom sheet
      await tester.tap(find.byKey(const Key('exercise_filter_button')));
      await tester.pumpAndSettle();

      // Select Beginner (draft only)
      await tester.tap(find.byKey(const Key('difficulty_filter_Beginner')));
      await tester.pumpAndSettle();

      // Chip in sheet is selected
      expect(
        tester.widget<ChoiceChip>(find.byKey(const Key('difficulty_filter_Beginner'))).selected,
        isTrue,
      );

      // Background results must NOT change before tapping Apply:
      // Barbell Bench Press (Intermediate) is still present
      expect(find.text('Barbell Bench Press'), findsOneWidget);

      // 7. Dismiss sheet without applying (discard draft)
      Navigator.of(tester.element(find.byKey(const Key('apply_exercise_filters_button')))).pop();
      await tester.pumpAndSettle();

      // Barbell Bench Press still present, count unchanged
      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(
        tester
            .widgetList<Text>(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains('exercises')))
            .map((t) => t.data)
            .first,
        equals(initialCountText),
      );

      // 8. Reopen sheet: verify draft was discarded and reflects applied ('All')
      await tester.tap(find.byKey(const Key('exercise_filter_button')));
      await tester.pumpAndSettle();

      expect(
        tester.widget<ChoiceChip>(find.byKey(const Key('difficulty_filter_Beginner'))).selected,
        isFalse,
      );
      expect(
        tester.widget<ChoiceChip>(find.byKey(const Key('difficulty_filter_All'))).selected,
        isTrue,
      );

      // 9. Select Beginner and tap Apply Filters
      await tester.tap(find.byKey(const Key('difficulty_filter_Beginner')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('apply_exercise_filters_button')));
      await tester.pumpAndSettle();

      // Bottom sheet closed and background results now updated
      expect(find.text('Filter Exercises'), findsNothing);
      expect(find.text('Dumbbell Hammer Press'), findsOneWidget);
      expect(find.text('Barbell Bench Press'), findsNothing);

      // 10. Reopen sheet, tap Reset (draft only resets), background still filtered until Apply
      await tester.tap(find.byKey(const Key('exercise_filter_button')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ChoiceChip>(find.byKey(const Key('difficulty_filter_Beginner'))).selected,
        isTrue,
      );
      await tester.tap(find.byKey(const Key('reset_sheet_filters_button')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ChoiceChip>(find.byKey(const Key('difficulty_filter_All'))).selected,
        isTrue,
      );
      // Still filtered in background
      expect(find.text('Barbell Bench Press'), findsNothing);

      // Apply the reset
      await tester.tap(find.byKey(const Key('apply_exercise_filters_button')));
      await tester.pumpAndSettle();

      // Now intermediate press is back
      expect(find.text('Barbell Bench Press'), findsOneWidget);

      // 11. Clear search query -> muscle-group cards reappear
      await tester.tap(find.byKey(const Key('clear_body_parts_search_button')));
      await tester.pumpAndSettle();

      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Biceps'), findsOneWidget);

      // 12. Tapping a category card navigates to the category page
      await tester.ensureVisible(find.text('Chest'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chest'));
      await tester.pumpAndSettle();

      expect(find.byType(ChestExercisesPage), findsOneWidget);
    });
  });
}
