import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/services/exercise_substitution_service.dart';

void main() {
  group('ExerciseSubstitutionService Tests', () {
    test('All substitution suggestions resolve to valid exercises with existing video assets', () {
      final allSubstitutions = <String>{};

      // Test substitutions from all canonical exercises
      for (final exercise in ExerciseData.all) {
        final subs = ExerciseSubstitutionService.getSubstitutions(exercise.name);
        expect(subs.isNotEmpty, isTrue, reason: 'Exercise ${exercise.name} should have substitution suggestions');
        allSubstitutions.addAll(subs);
      }

      // Also test common user queries
      final commonQueries = [
        'bench press',
        'barbell bench press',
        'squat',
        'barbell squat',
        'deadlift',
        'barbell deadlift',
        'overhead press',
        'shoulder press',
        'lat pulldown',
        'pull-ups',
        'bicep curl',
        'triceps pushdown',
        'lunge',
        'leg curl',
        'leg extension',
      ];

      for (final query in commonQueries) {
        final subs = ExerciseSubstitutionService.getSubstitutions(query);
        expect(subs.isNotEmpty, isTrue, reason: 'Query $query should have substitutions');
        allSubstitutions.addAll(subs);
      }

      // Verify each substitution recommendation resolves to a valid catalog exercise
      for (final subName in allSubstitutions) {
        final resolved = ExerciseData.findByName(subName);
        expect(
          resolved,
          isNotNull,
          reason: 'Substitution "$subName" must resolve to an Exercise via ExerciseData.findByName',
        );

        expect(
          resolved!.videoPath.isNotEmpty,
          isTrue,
          reason: 'Resolved exercise for "$subName" must have a non-empty videoPath',
        );

        expect(
          resolved.videoPath.endsWith('.mp4'),
          isTrue,
          reason: 'Resolved videoPath for "$subName" must be an MP4 video',
        );

        expect(
          File(resolved.videoPath).existsSync(),
          isTrue,
          reason: 'Video asset file "${resolved.videoPath}" for "$subName" must exist on disk',
        );

        expect(
          resolved.instructions.isNotEmpty,
          isTrue,
          reason: 'Resolved exercise for "$subName" must contain step-by-step instructions',
        );
      }
    });

    test('Common alias variations like dehyphenated names resolve cleanly', () {
      expect(ExerciseData.findByName('push-ups'), isNotNull);
      expect(ExerciseData.findByName('push ups'), isNotNull);
      expect(ExerciseData.findByName('pushups'), isNotNull);
      expect(ExerciseData.findByName('pull-ups'), isNotNull);
      expect(ExerciseData.findByName('pull ups'), isNotNull);
      expect(ExerciseData.findByName('dumbbell bench press'), isNotNull);
      expect(ExerciseData.findByName('goblet squat'), isNotNull);
      expect(ExerciseData.findByName('hack squat'), isNotNull);
      expect(ExerciseData.findByName('bulgarian split squat'), isNotNull);
      expect(ExerciseData.findByName('romanian deadlift'), isNotNull);
      expect(ExerciseData.findByName('hammer curl'), isNotNull);
      expect(ExerciseData.findByName('cable bicep curl'), isNotNull);
    });
  });
}
