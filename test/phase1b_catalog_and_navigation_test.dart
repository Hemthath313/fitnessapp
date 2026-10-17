import 'dart:io';

import 'package:fitness_app/data/challenge_data.dart';
import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/presentation/ai_coach/workout_generator_screen.dart';
import 'package:fitness_app/presentation/body_parts/pages/abs.dart';
import 'package:fitness_app/presentation/body_parts/pages/biceps.dart';
import 'package:fitness_app/presentation/body_parts/pages/lats.dart';
import 'package:fitness_app/presentation/body_parts/pages/shoulder.dart';
import 'package:fitness_app/presentation/body_parts/pages/triceps.dart';
import 'package:fitness_app/presentation/cardio_workouts/cardio.dart';
import 'package:fitness_app/presentation/workout_logs/workout_log_screen.dart';
import 'package:fitness_app/presentation/workouts/pages/workout_tab_page.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('Phase 1B — Exercise Catalog Integrity', () {
    test('Every category is populated with expected exercise counts (145 total)', () {
      expect(ExerciseData.chest.length, 13);
      expect(ExerciseData.back.length, 20);
      expect(ExerciseData.lats.length, 20);
      expect(ExerciseData.legs.length, 24);
      expect(ExerciseData.shoulders.length, 27);
      expect(ExerciseData.biceps.length, 17);
      expect(ExerciseData.triceps.length, 21);
      expect(ExerciseData.arms.length, 38);
      expect(ExerciseData.abs.length, 13);
      expect(ExerciseData.cardio.length, 10);
      expect(ExerciseData.all.length, 145);
    });

    test('All 145 exercises have valid non-empty metadata and unique canonical names', () {
      final seenNames = <String>{};
      for (final exercise in ExerciseData.all) {
        expect(exercise.name.trim(), isNotEmpty,
            reason: 'Exercise name must not be empty');
        expect(exercise.videoPath.trim(), isNotEmpty,
            reason: 'Video path missing for ${exercise.name}');
        expect(exercise.description.trim(), isNotEmpty,
            reason: 'Description missing for ${exercise.name}');
        expect(exercise.target.trim(), isNotEmpty,
            reason: 'Target muscle missing for ${exercise.name}');
        expect(exercise.equipment.trim(), isNotEmpty,
            reason: 'Equipment missing for ${exercise.name}');
        expect(exercise.difficulty.trim(), isNotEmpty,
            reason: 'Difficulty missing for ${exercise.name}');
        expect(exercise.setsReps.trim(), isNotEmpty,
            reason: 'Sets/reps missing for ${exercise.name}');
        expect(exercise.instructions, isNotEmpty,
            reason: 'Instructions missing for ${exercise.name}');

        final lower = exercise.name.toLowerCase();
        expect(seenNames.add(lower), isTrue,
            reason: 'Duplicate canonical exercise name found: ${exercise.name}');
      }
    });

    test('Every referenced video asset path in ExerciseData.all exists on disk', () {
      final missingPaths = <String>[];
      for (final exercise in ExerciseData.all) {
        final file = File(exercise.videoPath);
        if (!file.existsSync()) {
          missingPaths.add('${exercise.name}: ${exercise.videoPath}');
        }
      }
      expect(missingPaths, isEmpty,
          reason: 'Missing video files on disk: ${missingPaths.join(', ')}');
    });

    test('ExerciseData.findByName and categoryFor work across all 8 categories', () {
      final categorySamples = <String, String>{
        'Barbell Bench Press': 'Chest',
        'Pull-ups Wide Back Grip': 'Back',
        'Classic Barbell Squat': 'Legs',
        'Military Press': 'Shoulders',
        'Barbell Curl': 'Biceps',
        'Cable Pushdown': 'Triceps',
        'V-Up': 'Abs',
        'Burpee': 'Cardio',
      };

      categorySamples.forEach((name, expectedCategory) {
        final found = ExerciseData.findByName(name);
        expect(found, isNotNull, reason: 'Failed to find $name');
        expect(found!.name, name);
        expect(ExerciseData.categoryFor(name), expectedCategory);

        // Also verify case-insensitivity and [Day] tag stripping
        final taggedFound =
            ExerciseData.findByName('[Monday] ${name.toLowerCase()}');
        expect(taggedFound, isNotNull);
        expect(taggedFound!.name, name);
      });
    });

    test('Legacy exercise names and quick-chip aliases resolve for backward compatibility', () {
      final legacyMappings = <String, String>{
        '[Monday] Wide Grip Pull Up': 'Pull-ups Wide Back Grip',
        '[Monday] Barbell Bent Over Row': 'Barbell Underhand Bent Over Row',
        'Lat Pulldown': 'Cable Pulldown',
        'Seated Cable Row': 'Cable Seated Row',
        '[Wednesday] Standing Military Press': 'Military Press',
        'Seated Barbell Press': 'Barbell Seated Behind Head Military Press',
        'Dumbbell Lateral Raise': 'Dumbbell Seated Lateral Raise',
        'Arnold Press': 'Dumbbell Arnold Press',
        '[Friday] Dumbbell Curl': 'Dumbbell Biceps Curl',
        '[Wednesday] Tricep Pushdown': 'Cable Pushdown',
        'Skull Crushers': 'Cable Lying Extension',
        'Barbell Squat': 'Classic Barbell Squat',
        'Deadlift': 'Barbell Straight Leg Deadlift',
        'Overhead Press': 'Military Press',
        'Barbell Row': 'Barbell Underhand Bent Over Row',
        'Pull-Ups': 'Pull-ups Wide Back Grip',
      };

      legacyMappings.forEach((legacyName, expectedCanonical) {
        final resolved = ExerciseData.findByName(legacyName);
        expect(resolved, isNotNull,
            reason: 'Legacy name "$legacyName" failed to resolve');
        expect(resolved!.name, expectedCanonical);
      });
    });
  });

  group('Phase 1B — AI Workout Generator & Quick Log Catalog Access', () {
    test('WorkoutLogScreen autocomplete suggestedExercises includes all 8 categories (145 exercises)', () {
      final suggestions = WorkoutLogScreen.suggestedExercises;
      expect(suggestions.length, 145);

      // Verify every category has representative exercises in autocomplete
      expect(suggestions, contains('Barbell Bench Press')); // Chest
      expect(suggestions, contains('Barbell Underhand Bent Over Row')); // Back
      expect(suggestions, contains('Classic Barbell Squat')); // Legs
      expect(suggestions, contains('Military Press')); // Shoulders
      expect(suggestions, contains('Dumbbell Concentration Curl')); // Biceps
      expect(suggestions, contains('Cable Overhead Triceps Extension')); // Triceps
      expect(suggestions, contains('V-Up')); // Abs
      expect(suggestions, contains('Battling Ropes')); // Cardio
    });

    test('WorkoutGeneratorScreen availableCatalog exposes all 145 exercises across all 8 categories', () {
      final catalog = WorkoutGeneratorScreen.availableCatalog;
      expect(catalog.length, 145);
      final categoriesRepresented = catalog
          .map((e) => ExerciseData.categoryFor(e.name))
          .whereType<String>()
          .toSet();
      expect(
        categoriesRepresented,
        containsAll([
          'Chest',
          'Back',
          'Legs',
          'Shoulders',
          'Biceps',
          'Triceps',
          'Abs',
          'Cardio',
        ]),
      );
    });
  });

  group('Phase 1B — WorkoutTabPage Arms Navigation (Biceps & Triceps)', () {
    test('WorkoutTabPage.exerciseLibraryCategories includes both Biceps and Triceps routes', () {
      final labels = WorkoutTabPage.exerciseLibraryCategories
          .map((c) => c['label'] as String)
          .toList();
      final routes = WorkoutTabPage.exerciseLibraryCategories
          .map((c) => c['route'] as String)
          .toList();

      expect(labels, containsAll(['Biceps', 'Triceps', 'Abs', 'Cardio']));
      expect(routes, contains(Routes.bicepsRoute));
      expect(routes, contains(Routes.tricepsRoute));
      expect(routes, contains(Routes.absRoute));
      expect(routes, contains(Routes.cardioRoute));
    });

    testWidgets('Users can navigate to both Biceps and Triceps from WorkoutTabPage category cards',
        (tester) async {
      final visitedRoutes = <String>[];
      final router = GoRouter(
        initialLocation: '/test-categories',
        routes: [
          GoRoute(
            path: '/test-categories',
            builder: (context, state) => Scaffold(
              body: GridView.builder(
                itemCount: WorkoutTabPage.exerciseLibraryCategories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemBuilder: (context, index) {
                  final cat = WorkoutTabPage.exerciseLibraryCategories[index];
                  return InkWell(
                    onTap: () => context.push(cat['route'] as String),
                    child: Center(child: Text(cat['label'] as String)),
                  );
                },
              ),
            ),
          ),
          GoRoute(
            path: Routes.bicepsRoute,
            builder: (context, state) {
              visitedRoutes.add(Routes.bicepsRoute);
              return const BicepsExercisesPage();
            },
          ),
          GoRoute(
            path: Routes.tricepsRoute,
            builder: (context, state) {
              visitedRoutes.add(Routes.tricepsRoute);
              return const TricepsExercisesPage();
            },
          ),
          GoRoute(
            path: Routes.backRoute,
            builder: (context, state) => const LatExercisesPage(),
          ),
          GoRoute(
            path: Routes.shouldersRoute,
            builder: (context, state) => const ShoulderExercisesPage(),
          ),
          GoRoute(
            path: Routes.absRoute,
            builder: (context, state) => const AbsExercisesPage(),
          ),
          GoRoute(
            path: Routes.cardioRoute,
            builder: (context, state) => const CardioExercisesPage(),
          ),
        ],
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Biceps'), findsOneWidget);
      expect(find.text('Triceps'), findsOneWidget);

      await tester.tap(find.text('Biceps'));
      await tester.pumpAndSettle();
      expect(visitedRoutes, contains(Routes.bicepsRoute));
      expect(find.text('Biceps Workouts'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Triceps'));
      await tester.pumpAndSettle();
      expect(visitedRoutes, contains(Routes.tricepsRoute));
      expect(find.text('Triceps Workouts'), findsOneWidget);
    });
  });

  group('Phase 1B Follow-up — ChallengeData Video Asset Integrity & Fallback', () {
    test('Every video asset referenced by ChallengeData exists on disk or uses explicit empty fallback', () {
      final missingAssets = <String>[];
      int plankFallbackCount = 0;

      // 1. Check all 30 days of sixPackCurriculum
      expect(ChallengeData.sixPackCurriculum.length, 30);
      ChallengeData.sixPackCurriculum.forEach((day, exercises) {
        expect(exercises, isNotEmpty, reason: 'Day $day has no exercises');
        for (final exercise in exercises) {
          if (exercise.name == 'Plank') {
            expect(exercise.videoPath, isEmpty,
                reason: 'Plank on Day $day should use empty videoPath fallback instead of missing abs_plank.mp4');
            expect(exercise.hasVideo, isFalse);
            plankFallbackCount++;
          } else {
            expect(exercise.videoPath.trim(), isNotEmpty,
                reason: '${exercise.name} on Day $day should have a video path');
            expect(exercise.hasVideo, isTrue);
            if (!File(exercise.videoPath).existsSync()) {
              missingAssets.add('Day $day ${exercise.name}: ${exercise.videoPath}');
            }
          }
        }
      });

      // 2. Check all items in weeklyPool
      expect(ChallengeData.weeklyPool, isNotEmpty);
      for (final exercise in ChallengeData.weeklyPool) {
        if (exercise.name == 'Plank') {
          expect(exercise.videoPath, isEmpty,
              reason: 'Weekly pool Plank should use empty videoPath fallback instead of missing abs_plank.mp4');
          expect(exercise.hasVideo, isFalse);
          plankFallbackCount++;
        } else {
          expect(exercise.videoPath.trim(), isNotEmpty,
              reason: 'Weekly pool ${exercise.name} should have a video path');
          expect(exercise.hasVideo, isTrue);
          if (!File(exercise.videoPath).existsSync()) {
            missingAssets.add('WeeklyPool ${exercise.name}: ${exercise.videoPath}');
          }
        }
      }

      expect(missingAssets, isEmpty,
          reason: 'ChallengeData references non-existent video assets: ${missingAssets.join(', ')}');
      // 10 days (1, 4, 7, ..., 28) + 1 weeklyPool entry = 11 Plank entries
      expect(plankFallbackCount, 11);
    });

    testWidgets('Plank empty videoPath renders safe fallback in both list thumbnail and detail player modes',
        (tester) async {
      final plankExercise = ChallengeData.sixPackCurriculum[1]!
          .firstWhere((e) => e.name == 'Plank');
      expect(plankExercise.videoPath, isEmpty);
      expect(plankExercise.hasVideo, isFalse);

      // 1. List preview mode (showThumbnailOnly: true)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseVideoPlayer(
              videoPath: plankExercise.videoPath,
              width: 60,
              height: 60,
              showThumbnailOnly: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('exercise_video_static_preview')), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center_rounded), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(tester.takeException(), isNull);

      // 2. Detail / Exercise-of-the-Week mode (autoPlay: true)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseVideoPlayer(
              videoPath: plankExercise.videoPath,
              width: 300,
              height: 220,
              autoPlay: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('exercise_video_error_state')), findsOneWidget);
      expect(find.text('Video guide unavailable'), findsOneWidget);
      expect(find.byKey(const Key('exercise_video_retry_button')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
