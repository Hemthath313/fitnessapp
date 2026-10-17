import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/services/strength_service.dart';

void main() {
  group('StrengthService — Epley 1RM Calculation & Guardrails', () {
    test('1-rep test returns exactly the weight lifted', () {
      final set = WorkoutSet(
        weight: 120.0,
        reps: 1,
        type: SetType.normal,
        isCompleted: true,
      );
      final est1RM = StrengthService.calculateEstimated1RM(set);
      expect(est1RM, 120.0);
    });

    test('Standard multi-rep sets calculate correct Epley 1RM', () {
      // 100kg x 10 reps = 100 * (1 + 10/30) = 133.333...
      final set100x10 = WorkoutSet(
        weight: 100.0,
        reps: 10,
        type: SetType.normal,
        isCompleted: true,
      );
      expect(StrengthService.calculateEstimated1RM(set100x10), closeTo(133.33, 0.01));

      // 80kg x 6 reps = 80 * (1 + 6/30) = 80 * 1.2 = 96.0
      final set80x6 = WorkoutSet(
        weight: 80.0,
        reps: 6,
        type: SetType.normal,
        isCompleted: true,
      );
      expect(StrengthService.calculateEstimated1RM(set80x6), 96.0);
    });

    test('Guardrail: High repetition sets (>12) are conservatively capped at 12 reps', () {
      // 100kg x 20 reps -> capped at 12 reps: 100 * (1 + 12/30) = 140.0
      final highRepSet = WorkoutSet(
        weight: 100.0,
        reps: 20,
        type: SetType.normal,
        isCompleted: true,
      );
      expect(StrengthService.calculateEstimated1RM(highRepSet), 140.0);
    });

    test('Guardrail: Warmup sets are strictly excluded (return 0.0)', () {
      final warmupSet = WorkoutSet(
        weight: 100.0,
        reps: 5,
        type: SetType.warmup,
        isCompleted: true,
      );
      expect(StrengthService.calculateEstimated1RM(warmupSet), 0.0);
    });

    test('Guardrail: Incomplete sets return 0.0', () {
      final incompleteSet = WorkoutSet(
        weight: 100.0,
        reps: 5,
        type: SetType.normal,
        isCompleted: false,
      );
      expect(StrengthService.calculateEstimated1RM(incompleteSet), 0.0);
    });

    test('Guardrail: Non-positive weight or reps return 0.0', () {
      final zeroWeightSet = WorkoutSet(
        weight: 0.0,
        reps: 10,
        type: SetType.normal,
        isCompleted: true,
      );
      expect(StrengthService.calculateEstimated1RM(zeroWeightSet), 0.0);

      final zeroRepsSet = WorkoutSet(
        weight: 80.0,
        reps: 0,
        type: SetType.normal,
        isCompleted: true,
      );
      expect(StrengthService.calculateEstimated1RM(zeroRepsSet), 0.0);

      final negativeWeightSet = WorkoutSet(
        weight: -50.0,
        reps: 5,
        type: SetType.normal,
        isCompleted: true,
      );
      expect(StrengthService.calculateEstimated1RM(negativeWeightSet), 0.0);
    });

    test('calculateEstimated1RMFromValues convenience helper matches guardrails', () {
      expect(StrengthService.calculateEstimated1RMFromValues(weight: 100.0, reps: 1), 100.0);
      expect(StrengthService.calculateEstimated1RMFromValues(weight: 60.0, reps: 6), 72.0);
      expect(StrengthService.calculateEstimated1RMFromValues(weight: 60.0, reps: 6, isWarmup: true), 0.0);
      expect(StrengthService.calculateEstimated1RMFromValues(weight: 0.0, reps: 10), 0.0);
      expect(StrengthService.calculateEstimated1RMFromValues(weight: 100.0, reps: 15), 140.0); // capped at 12
    });
  });

  group('ExerciseIdentity — Bracket Normalization & Canonical Keys', () {
    test('cleanDisplayName strips leading bracket prefixes cleanly', () {
      expect(
        ExerciseIdentity.cleanDisplayName('[Monday] Barbell Bench Press'),
        'Barbell Bench Press',
      );
      expect(
        ExerciseIdentity.cleanDisplayName('[Day 1] Squat'),
        'Squat',
      );
      expect(
        ExerciseIdentity.cleanDisplayName('[Chest & Triceps] Incline Dumbbell Press'),
        'Incline Dumbbell Press',
      );
      expect(
        ExerciseIdentity.cleanDisplayName('  Deadlift  '),
        'Deadlift',
      );
    });

    test('canonicalKey generates lowercase normalized key for hash lookups', () {
      expect(
        ExerciseIdentity.canonicalKey('[Monday] Barbell Bench Press'),
        'barbell bench press',
      );
      expect(
        ExerciseIdentity.canonicalKey('BARBELL BENCH PRESS'),
        'barbell bench press',
      );
      expect(
        ExerciseIdentity.canonicalKey('[Wednesday]   Barbell Bench Press  '),
        'barbell bench press',
      );
    });
  });

  group('StrengthService — PR Detection Across Workout Sessions', () {
    final now = DateTime.now();

    test('getAllTimePRs accurately tracks the highest estimated 1RM', () {
      final session1 = WorkoutSession(
        id: 'session_1',
        userId: 'user_test',
        workoutName: 'Chest Day',
        dayName: 'Monday',
        startedAt: now.subtract(const Duration(days: 7)),
        completedAt: now.subtract(const Duration(days: 7, hours: -1)),
        totalVolume: 1600.0,
        exercises: [
          SessionExercise(
            exerciseName: '[Monday] Barbell Bench Press',
            order: 0,
            sets: [
              WorkoutSet(weight: 80.0, reps: 8, isCompleted: true), // 80 * (1 + 8/30) = 101.33
              WorkoutSet(weight: 80.0, reps: 8, isCompleted: true),
            ],
            isCompleted: true,
          ),
        ],
      );

      final session2 = WorkoutSession(
        id: 'session_2',
        userId: 'user_test',
        workoutName: 'Chest Day',
        dayName: 'Monday',
        startedAt: now,
        completedAt: now.add(const Duration(hours: 1)),
        totalVolume: 1800.0,
        exercises: [
          SessionExercise(
            exerciseName: 'Barbell Bench Press',
            order: 0,
            sets: [
              WorkoutSet(weight: 85.0, reps: 8, isCompleted: true), // 85 * (1 + 8/30) = 107.67 (PR!)
            ],
            isCompleted: true,
          ),
        ],
      );

      final prs = StrengthService().getAllTimePRs(sessions: [session1, session2]);
      expect(prs.containsKey('barbell bench press'), true);
      final benchPR = prs['barbell bench press']!;
      expect(benchPR.weight, 85.0);
      expect(benchPR.reps, 8);
      expect(benchPR.sessionId, 'session_2');
      expect(benchPR.estimated1RM, closeTo(107.67, 0.01));
    });

    test('detectPRsInSession identifies when a session sets a new personal record', () {
      final session1 = WorkoutSession(
        id: 'session_1',
        userId: 'user_test',
        workoutName: 'Leg Day',
        dayName: 'Tuesday',
        startedAt: now.subtract(const Duration(days: 4)),
        totalVolume: 2000.0,
        exercises: [
          SessionExercise(
            exerciseName: '[Tuesday] Barbell Squat',
            order: 0,
            sets: [
              WorkoutSet(weight: 100.0, reps: 5, isCompleted: true), // 100 * (1 + 5/30) = 116.67
            ],
            isCompleted: true,
          ),
        ],
      );

      final session2 = WorkoutSession(
        id: 'session_2',
        userId: 'user_test',
        workoutName: 'Leg Day',
        dayName: 'Tuesday',
        startedAt: now,
        totalVolume: 2400.0,
        exercises: [
          SessionExercise(
            exerciseName: '[Tuesday] Barbell Squat',
            order: 0,
            sets: [
              WorkoutSet(weight: 110.0, reps: 5, isCompleted: true), // 110 * (1 + 5/30) = 128.33 (NEW PR!)
            ],
            isCompleted: true,
          ),
        ],
      );

      final newPRs = StrengthService().detectPRsInSession(
        session: session2,
        allSessions: [session1, session2],
      );

      expect(newPRs.length, 1);
      expect(newPRs.first.exerciseName, 'Barbell Squat');
      expect(newPRs.first.weight, 110.0);
      expect(newPRs.first.estimated1RM, closeTo(128.33, 0.01));
    });
  });
}
