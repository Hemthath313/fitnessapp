import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/presentation/body_parts/pages/abs.dart';
import 'package:fitness_app/presentation/body_parts/pages/biceps.dart';
import 'package:fitness_app/presentation/body_parts/pages/body_parts.dart';
import 'package:fitness_app/presentation/body_parts/pages/chest.dart';
import 'package:fitness_app/presentation/body_parts/pages/lats.dart';
import 'package:fitness_app/presentation/body_parts/pages/legs.dart';
import 'package:fitness_app/presentation/body_parts/pages/shoulder.dart';
import 'package:fitness_app/presentation/body_parts/pages/triceps.dart';
import 'package:fitness_app/presentation/cardio_workouts/cardio.dart';
import 'package:fitness_app/presentation/widgets/interactive_exercise_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrapWithScreenUtil(Widget child, {Size size = const Size(375, 812)}) {
  return ScreenUtilInit(
    key: UniqueKey(),
    designSize: size,
    child: child,
    builder: (_, wrappedChild) => MaterialApp(
      home: wrappedChild,
    ),
  );
}

void main() {
  group('Phase 2A — Canonical Exercise Search & Filter Logic', () {
    test('ExerciseData.strengthExercises contains all 135 strength exercises across 7 categories', () {
      expect(ExerciseData.strengthExercises.length, 135);
      expect(
        ExerciseData.strengthExercises.length,
        ExerciseData.chest.length +
            ExerciseData.back.length +
            ExerciseData.legs.length +
            ExerciseData.shoulders.length +
            ExerciseData.biceps.length +
            ExerciseData.triceps.length +
            ExerciseData.abs.length,
      );
      expect(ExerciseData.all.length, 145);
    });

    test('Canonical exercise search matches exact, substring, multi-word tokens, and legacy aliases', () {
      // Exact & case-insensitive substring on canonical name
      final benchResults = ExerciseData.filterExercises(
        ExerciseData.chest,
        query: 'bench press',
      );
      expect(
        benchResults.map((e) => e.name),
        containsAll([
          'Barbell Bench Press',
          'Barbell Decline Bench Press',
        ]),
      );

      // Multi-word token matching regardless of word order
      final tokenResults = ExerciseData.filterExercises(
        ExerciseData.chest,
        query: 'press dumbbell incline',
      );
      expect(tokenResults.map((e) => e.name), contains('Incline Dumbbell Press'));

      // Legacy alias matching preserves backward compatibility
      final skullCrusherResults = ExerciseData.filterExercises(
        ExerciseData.triceps,
        query: 'Skull Crushers',
      );
      expect(skullCrusherResults.map((e) => e.name), contains('Cable Lying Extension'));

      final latPulldownResults = ExerciseData.filterExercises(
        ExerciseData.back,
        query: 'Lat Pulldown',
      );
      expect(latPulldownResults.map((e) => e.name), contains('Cable Pulldown'));

      // Non-matching query returns empty list
      final emptyResults = ExerciseData.filterExercises(
        ExerciseData.chest,
        query: 'nonexistent exercise xyz',
      );
      expect(emptyResults, isEmpty);
    });

    test('Every strength exercise maps cleanly to standardized difficulty and equipment filters without fabricated metadata', () {
      final validDifficulties = {'Beginner', 'Intermediate', 'Advanced'};
      final equipmentBuckets = ExerciseData.equipmentFilterOptions
          .where((option) => option != 'All')
          .toList();

      for (final exercise in ExerciseData.strengthExercises) {
        expect(
          validDifficulties.contains(exercise.difficulty),
          isTrue,
          reason: '${exercise.name} has unexpected difficulty ${exercise.difficulty}',
        );
        expect(
          ExerciseData.matchesDifficultyFilter(exercise, exercise.difficulty),
          isTrue,
        );

        final matchedEquipment = equipmentBuckets
            .where((bucket) => ExerciseData.matchesEquipmentFilter(exercise, bucket))
            .toList();
        expect(
          matchedEquipment,
          isNotEmpty,
          reason:
              '${exercise.name} with equipment "${exercise.equipment}" did not match any canonical equipment filter',
        );
      }
    });

    test('Equipment filter distinguishes Cable Machine from Machine and groups Bodyweight accurately', () {
      // Cable exercises should match Cable, not Machine
      final cablePushdown = ExerciseData.findByName('Cable Pushdown')!;
      expect(cablePushdown.equipment, contains('Cable Machine'));
      expect(ExerciseData.matchesEquipmentFilter(cablePushdown, 'Cable'), isTrue);
      expect(ExerciseData.matchesEquipmentFilter(cablePushdown, 'Machine'), isFalse);

      // Machine exercises (e.g., Lever Chest Press, Lever Pec Dec Fly, Leg Press) match Machine
      final leverChestPress = ExerciseData.findByName('Lever Chest Press')!;
      expect(ExerciseData.matchesEquipmentFilter(leverChestPress, 'Machine'), isTrue);
      expect(ExerciseData.matchesEquipmentFilter(leverChestPress, 'Cable'), isFalse);

      // Bodyweight exercises (Deep Pushups, Pull-ups Wide Back Grip) match Bodyweight
      final deepPushups = ExerciseData.findByName('Deep Pushups')!;
      final pullUp = ExerciseData.findByName('Pull-ups Wide Back Grip')!;
      expect(ExerciseData.matchesEquipmentFilter(deepPushups, 'Bodyweight'), isTrue);
      expect(ExerciseData.matchesEquipmentFilter(pullUp, 'Bodyweight'), isTrue);

      // Resistance Band exercises match Resistance Band
      final bandFly = ExerciseData.findByName('Resistance Band High Fly')!;
      expect(ExerciseData.matchesEquipmentFilter(bandFly, 'Resistance Band'), isTrue);
    });

    test('Combined search, difficulty, and equipment filters intersect accurately', () {
      final filtered = ExerciseData.filterExercises(
        ExerciseData.shoulders,
        query: 'dumbbell',
        difficulty: 'Beginner',
        equipment: 'Dumbbell',
      );
      expect(filtered, isNotEmpty);
      for (final exercise in filtered) {
        expect(exercise.difficulty, 'Beginner');
        expect(ExerciseData.matchesEquipmentFilter(exercise, 'Dumbbell'), isTrue);
        expect(ExerciseData.matchesSearchQuery(exercise, 'dumbbell'), isTrue);
      }
    });
  });

  group('Phase 2A — Muscle Group Page Search, Filter & Card UI Widget Tests', () {
    testWidgets('ChestExercisesPage supports live search, difficulty/equipment filtering, and empty-state reset',
        (tester) async {
      await tester.pumpWidget(_wrapWithScreenUtil(const ChestExercisesPage()));
      await tester.pumpAndSettle();

      // Search field and filter button exist
      expect(find.byKey(const Key('exercise_search_field')), findsOneWidget);
      expect(find.byKey(const Key('exercise_filter_button')), findsOneWidget);

      // Initial card renders equipment clearly from canonical ExerciseData
      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('Barbell, Bench'), findsWidgets);

      // 1. Search by canonical name
      await tester.enterText(
        find.byKey(const Key('exercise_search_field')),
        'Pec Dec',
      );
      await tester.pumpAndSettle();

      expect(find.text('Lever Pec Dec Fly'), findsOneWidget);
      expect(find.text('Pec Dec Machine'), findsOneWidget);
      expect(find.text('Barbell Bench Press'), findsNothing);
      expect(find.text('Showing 1 of 13 exercises'), findsOneWidget);

      // Clear search via clear icon
      await tester.tap(find.byKey(const Key('clear_exercise_search_button')));
      await tester.pumpAndSettle();
      expect(find.text('Barbell Bench Press'), findsOneWidget);

      // 2. Filter by Equipment = Dumbbell and Difficulty = Beginner via filter sheet
      await tester.tap(find.byKey(const Key('exercise_filter_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('difficulty_filter_Beginner')), findsOneWidget);
      expect(find.byKey(const Key('equipment_filter_Dumbbell')), findsOneWidget);

      await tester.tap(find.byKey(const Key('difficulty_filter_Beginner')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('equipment_filter_Dumbbell')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('apply_exercise_filters_button')));
      await tester.pumpAndSettle();

      expect(find.text('Dumbbell Hammer Press'), findsOneWidget);
      expect(find.text('Barbell Bench Press'), findsNothing);

      // 3. Selecting Advanced on Chest (0 Advanced exercises in catalog) shows graceful empty state
      await tester.tap(find.byKey(const Key('exercise_filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('difficulty_filter_Advanced')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('apply_exercise_filters_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('exercise_empty_state')), findsOneWidget);
      expect(find.text('No exercises match your search or filters.'), findsOneWidget);

      // Reset filters restores the full list
      await tester.ensureVisible(
        find.byKey(const Key('reset_exercise_filters_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reset_exercise_filters_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('exercise_empty_state')), findsNothing);
      expect(find.text('Barbell Bench Press'), findsOneWidget);
    });

    testWidgets('Long canonical exercise names render up to 2 lines without overflow across narrow screens',
        (tester) async {
      // Test with narrow 320px screen width to verify no layout overflow or text collision
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. LatExercisesPage: "Cable Straight Back Seated High Row (Reverse Grip)" (50 chars)
      await tester.pumpWidget(
        _wrapWithScreenUtil(
          const LatExercisesPage(),
          size: const Size(320, 800),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('exercise_search_field')),
        'Cable Straight Back Seated High Row',
      );
      await tester.pumpAndSettle();

      final longBackTitleFinder =
          find.text('Cable Straight Back Seated High Row (Reverse Grip)');
      expect(longBackTitleFinder, findsOneWidget);
      final longBackTitleWidget = tester.widget<Text>(longBackTitleFinder);
      expect(longBackTitleWidget.maxLines, 2);
      expect(longBackTitleWidget.overflow, TextOverflow.ellipsis);
      expect(find.text('Cable Machine'), findsWidgets);
      expect(tester.takeException(), isNull);

      // 2. ShoulderExercisesPage: "Barbell Seated Behind Head Military Press" (41 chars)
      await tester.pumpWidget(
        _wrapWithScreenUtil(
          const ShoulderExercisesPage(),
          size: const Size(320, 800),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('exercise_search_field')),
        'Seated Behind Head',
      );
      await tester.pumpAndSettle();

      final longShoulderTitleFinder =
          find.text('Barbell Seated Behind Head Military Press');
      expect(longShoulderTitleFinder, findsOneWidget);
      final longShoulderTitleWidget = tester.widget<Text>(longShoulderTitleFinder);
      expect(longShoulderTitleWidget.maxLines, 2);
      expect(longShoulderTitleWidget.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);

      // 3. TricepsExercisesPage: "Dumbbell Lying Alternate Triceps Extension" (42 chars)
      await tester.pumpWidget(
        _wrapWithScreenUtil(
          const TricepsExercisesPage(),
          size: const Size(320, 800),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('exercise_search_field')),
        'Lying Alternate Triceps',
      );
      await tester.pumpAndSettle();

      final longTricepsTitleFinder =
          find.text('Dumbbell Lying Alternate Triceps Extension');
      expect(longTricepsTitleFinder, findsOneWidget);
      final longTricepsTitleWidget = tester.widget<Text>(longTricepsTitleFinder);
      expect(longTricepsTitleWidget.maxLines, 2);
      expect(longTricepsTitleWidget.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });

    testWidgets('All remaining muscle-group pages (Legs, Biceps, Abs, Cardio) render equipment on cards and open Exercise Details',
        (tester) async {
      // Legs page
      await tester.pumpWidget(_wrapWithScreenUtil(const LegExercisesPage()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('exercise_search_field')), findsOneWidget);
      expect(find.text('Classic Barbell Squat'), findsOneWidget);
      expect(find.text('Barbell, Rack'), findsWidgets);

      // Tap card to verify detail bottom sheet still opens cleanly
      await tester.ensureVisible(find.text('Classic Barbell Squat'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Classic Barbell Squat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(InteractiveExerciseDetailWidget), findsOneWidget);

      // Dismiss bottom sheet before switching pages
      Navigator.of(tester.element(find.byType(InteractiveExerciseDetailWidget))).pop();
      await tester.pumpAndSettle();

      // Biceps page
      await tester.pumpWidget(_wrapWithScreenUtil(const BicepsExercisesPage()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('exercise_search_field')), findsOneWidget);
      expect(find.text('Barbell Curl'), findsOneWidget);

      // Abs page
      await tester.pumpWidget(_wrapWithScreenUtil(const AbsExercisesPage()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('exercise_search_field')), findsOneWidget);
      expect(find.text('V-Up'), findsOneWidget);

      // Cardio page (cards also display equipment and 2-line titles)
      await tester.pumpWidget(_wrapWithScreenUtil(const CardioExercisesPage()));
      await tester.pumpAndSettle();
      expect(find.text('Battling Ropes'), findsNWidgets(2)); // Title + Equipment row
      expect(tester.takeException(), isNull);
    });

    testWidgets('BodyPartsScreen supports global cross-category strength search and filters while preserving muscle-group grid',
        (tester) async {
      await tester.pumpWidget(_wrapWithScreenUtil(const BodyPartsScreen()));
      await tester.pumpAndSettle();

      // Default unfiltered view displays the muscle-group grid cards
      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Biceps'), findsOneWidget);

      // Searching across all strength exercises switches to filtered exercise results
      await tester.enterText(
        find.byKey(const Key('body_parts_search_field')),
        'Arnold Press',
      );
      await tester.pumpAndSettle();

      expect(find.text('Dumbbell Arnold Press'), findsOneWidget);
      expect(find.text('Dumbbells'), findsOneWidget);
      expect(find.text('Showing 1 of 135 exercises'), findsOneWidget);

      // Clearing all filters returns to the muscle-group category grid
      await tester.tap(find.byKey(const Key('clear_body_parts_filters_button')));
      await tester.pumpAndSettle();

      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Biceps'), findsOneWidget);
    });
  });
}
