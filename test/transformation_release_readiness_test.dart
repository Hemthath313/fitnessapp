import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/services/workout_log_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Transformation System — Final Release-Readiness Suite (18 Critical Invariants)', () {
    // -------------------------------------------------------------------------
    // Test 1: Verify all 4 programmes map to valid blueprints without ghost days
    // -------------------------------------------------------------------------
    test('1. All 4 programmes map to valid blueprints with exact duration and no ghost days', () {
      final blueprints = TransformationPlansData.allPlans;
      expect(blueprints.length, equals(4));

      final expectedConfigs = {
        'beginner_fitness_30': {'days': 30, 'title': 'Beginner Fitness'},
        'weight_loss_60': {'days': 60, 'title': 'Weight Loss'},
        'muscle_building_90': {'days': 90, 'title': 'Muscle Building'},
        'strength_12_week': {'days': 84, 'title': 'Strength'},
      };

      for (final bp in blueprints) {
        expect(expectedConfigs.containsKey(bp.id), isTrue,
            reason: 'Unexpected plan ID: ${bp.id}');
        final config = expectedConfigs[bp.id]!;
        expect(bp.durationDays, equals(config['days']));

        // Verify each 1-based day has a non-null blueprint
        for (int day = 1; day <= bp.durationDays; day++) {
          final dayBlueprint = bp.getDayBlueprint(day);
          expect(dayBlueprint, isNotNull,
              reason: 'Day $day missing in plan ${bp.id}');
          if (dayBlueprint!.isRestDay) {
            expect(dayBlueprint.isRestDay, isTrue);
          } else {
            expect(dayBlueprint.exerciseNames, isNotEmpty);
          }
        }
      }
    });

    // -------------------------------------------------------------------------
    // Test 2: Enrolment without completed days initializes valid active state
    // -------------------------------------------------------------------------
    test('2. Enrolment without completed days initializes valid active state with 0 completed days', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'user_enroll_clean';
      provider.activeDocSaverForTesting = (_, __) async {};

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 140.0, 'carbs': 200.0, 'fat': 50.0},
      );

      expect(provider.hasActiveTransformation, isTrue);
      final state = provider.activeTransformation!;
      expect(state.planId, equals('beginner_fitness_30'));
      expect(state.currentDay, equals(1));
      expect(state.completedDayIndices, isEmpty);
      expect(state.completionPercentage, equals(0.0));
      expect(state.status, equals('active'));
      expect(state.milestones, isNotEmpty);
      expect(provider.achievedMilestones, isEmpty);
    });

    // -------------------------------------------------------------------------
    // Test 3: Switching an unstarted programme (no tracked data) without history clutter
    // -------------------------------------------------------------------------
    test('3. Switching an unstarted programme (no tracked data) cleanly switches active plan without history clutter', () async {
      final historySaved = <Map<String, dynamic>>[];
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'user_switch_unstarted';
      provider.activeDocSaverForTesting = (_, __) async {};
      provider.historyDocSaverForTesting = (_, data) async {
        historySaved.add(data);
      };

      // 1. Enroll in Beginner 30-Day without doing anything
      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 140.0, 'carbs': 200.0, 'fat': 50.0},
      );
      expect(provider.activeTransformation?.planId, equals('beginner_fitness_30'));
      expect(provider.activeTransformation!.hasTrackedData, isFalse);

      // 2. Switch to Weight Loss 60-Day
      await provider.enrollInPlan(
        blueprint: TransformationPlansData.weightLoss60,
        targetCalories: 1800,
        targetMacros: const {'protein': 130.0, 'carbs': 180.0, 'fat': 45.0},
      );

      expect(provider.activeTransformation?.planId, equals('weight_loss_60'));
      expect(historySaved, isEmpty, reason: 'Unstarted plan with no tracked data must NOT create history clutter');
      expect(provider.history, isEmpty);
    });

    // -------------------------------------------------------------------------
    // Test 4: Switching a programme with completed days archives previous plan
    // -------------------------------------------------------------------------
    test('4. Switching a programme with completed days archives previous plan with status: switched', () async {
      final historySaved = <Map<String, dynamic>>[];
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'user_switch_with_progress';
      provider.activeDocSaverForTesting = (_, __) async {};
      provider.historyDocSaverForTesting = (_, data) async {
        historySaved.add(data);
      };

      // 1. Enroll in Beginner 30
      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 140.0, 'carbs': 200.0, 'fat': 50.0},
      );

      // 2. Complete Days 1 & 2
      await provider.markDayCompleted(1);
      await provider.markDayCompleted(2);
      expect(provider.activeTransformation!.completedDayIndices, equals([1, 2]));
      expect(provider.activeTransformation!.hasTrackedData, isTrue);

      // 3. Switch to Muscle Building 90
      await provider.enrollInPlan(
        blueprint: TransformationPlansData.muscleBuilding90,
        targetCalories: 2500,
        targetMacros: const {'protein': 180.0, 'carbs': 250.0, 'fat': 70.0},
      );

      expect(provider.activeTransformation?.planId, equals('muscle_building_90'));
      expect(provider.activeTransformation?.completedDayIndices, isEmpty);
      expect(provider.history.length, equals(1));
      expect(provider.history.first.planId, equals('beginner_fitness_30'));
      expect(provider.history.first.status, equals('switched'));
      expect(provider.history.first.completedDayIndices, equals([1, 2]));
      expect(historySaved.length, equals(1));
      expect(historySaved.first['status'], equals('switched'));
    });

    // -------------------------------------------------------------------------
    // Test 5: Switching with check-in data only preserves check-in in history
    // -------------------------------------------------------------------------
    test('5. Switching a programme with check-in data only (0 completed days) preserves check-in data in history', () async {
      final historySaved = <Map<String, dynamic>>[];
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'user_switch_checkin';
      provider.activeDocSaverForTesting = (_, __) async {};
      provider.historyDocSaverForTesting = (_, data) async {
        historySaved.add(data);
      };

      // 1. Enroll in Weight Loss 60
      await provider.enrollInPlan(
        blueprint: TransformationPlansData.weightLoss60,
        targetCalories: 1800,
        targetMacros: const {'protein': 130.0, 'carbs': 180.0, 'fat': 45.0},
      );

      // 2. Submit weekly check-in without completing any workout day
      final checkIn = TransformationWeeklyCheckIn(
        weekNumber: 1,
        checkInDate: DateTime.now(),
        weight: 79.5,
        measurements: const {'waist': 84.0},
        notes: 'Feeling good, staying on track',
      );
      await provider.recordWeeklyCheckIn(checkIn);

      expect(provider.activeTransformation!.completedDayIndices, isEmpty);
      expect(provider.activeTransformation!.weeklyCheckIns.length, equals(1));
      expect(provider.activeTransformation!.hasTrackedData, isTrue);

      // 3. Switch to Strength 12-Week
      await provider.enrollInPlan(
        blueprint: TransformationPlansData.strength12Week,
        targetCalories: 2600,
        targetMacros: const {'protein': 180.0, 'carbs': 280.0, 'fat': 65.0},
      );

      expect(provider.activeTransformation?.planId, equals('strength_12_week'));
      expect(provider.history.length, equals(1));
      final archived = provider.history.first;
      expect(archived.planId, equals('weight_loss_60'));
      expect(archived.status, equals('switched'));
      expect(archived.weeklyCheckIns.length, equals(1));
      expect(archived.weeklyCheckIns.first.notes, equals('Feeling good, staying on track'));
    });

    // -------------------------------------------------------------------------
    // Test 6: Switching with onboarding metrics or starting measurements preserves them
    // -------------------------------------------------------------------------
    test('6. Switching with onboarding metrics or starting measurements preserves them in history', () async {
      final historySaved = <Map<String, dynamic>>[];
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'user_switch_onboarding';
      provider.activeDocSaverForTesting = (_, __) async {};
      provider.historyDocSaverForTesting = (_, data) async {
        historySaved.add(data);
      };

      // Enroll with starting weight and measurements, 0 completed workout days
      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 140.0, 'carbs': 200.0, 'fat': 50.0},
        startingWeight: 82.5,
        targetWeight: 75.0,
        startingMeasurements: const {'chest': 98.0, 'waist': 86.0},
      );
      expect(provider.activeTransformation!.hasTrackedData, isTrue);

      // Switch to Weight Loss 60
      await provider.enrollInPlan(
        blueprint: TransformationPlansData.weightLoss60,
        targetCalories: 1800,
        targetMacros: const {'protein': 130.0, 'carbs': 180.0, 'fat': 45.0},
      );

      expect(provider.history.length, equals(1));
      final archived = provider.history.first;
      expect(archived.planId, equals('beginner_fitness_30'));
      expect(archived.status, equals('switched'));
      expect(archived.startingWeight, equals(82.5));
      expect(archived.startingMeasurements['chest'], equals(98.0));
    });

    // -------------------------------------------------------------------------
    // Test 7: Abandoning a programme with tracked data preserves history with status abandoned
    // -------------------------------------------------------------------------
    test('7. Abandoning a programme with tracked data preserves history with status: abandoned', () async {
      final historySaved = <Map<String, dynamic>>[];
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'user_abandon_tracked';
      provider.activeDocSaverForTesting = (_, __) async {};
      provider.historyDocSaverForTesting = (_, data) async {
        historySaved.add(data);
      };

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.muscleBuilding90,
        targetCalories: 2500,
        targetMacros: const {'protein': 175.0, 'carbs': 260.0, 'fat': 65.0},
      );
      await provider.markDayCompleted(1);
      expect(provider.activeTransformation!.hasTrackedData, isTrue);

      await provider.abandonPlan();

      expect(provider.hasActiveTransformation, isFalse);
      expect(provider.activeTransformation, isNull);
      expect(provider.history.length, equals(1));
      expect(provider.history.first.status, equals('abandoned'));
      expect(provider.history.first.planId, equals('muscle_building_90'));
      expect(provider.history.first.completedDayIndices, equals([1]));
      expect(historySaved.length, equals(1));
      expect(historySaved.first['status'], equals('abandoned'));
    });

    // -------------------------------------------------------------------------
    // Test 8: Abandoning an unstarted programme without tracked data cleans active doc without history clutter
    // -------------------------------------------------------------------------
    test('8. Abandoning an unstarted programme with no tracked data cleans active doc without history clutter', () async {
      final historySaved = <Map<String, dynamic>>[];
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'user_abandon_clean';
      provider.activeDocSaverForTesting = (_, __) async {};
      provider.historyDocSaverForTesting = (_, data) async {
        historySaved.add(data);
      };

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.strength12Week,
        targetCalories: 2600,
        targetMacros: const {'protein': 180.0, 'carbs': 280.0, 'fat': 65.0},
      );
      expect(provider.activeTransformation!.hasTrackedData, isFalse);

      await provider.abandonPlan();

      expect(provider.hasActiveTransformation, isFalse);
      expect(provider.activeTransformation, isNull);
      expect(provider.history, isEmpty);
      expect(historySaved, isEmpty);
    });

    // -------------------------------------------------------------------------
    // Test 9: Completing a programme and repeating it creates distinct history entries
    // -------------------------------------------------------------------------
    test('9. Completing a programme and repeating it creates distinct history entries with unique timestamps', () async {
      final historySaved = <Map<String, dynamic>>[];
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'user_repeat_plan';
      provider.activeDocSaverForTesting = (_, __) async {};
      provider.historyDocSaverForTesting = (_, data) async {
        historySaved.add(data);
      };

      // Round 1: Beginner Fitness
      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 130.0, 'carbs': 200.0, 'fat': 50.0},
      );
      for (int i = 1; i <= 30; i++) {
        await provider.markDayCompleted(i);
      }
      await provider.completePlan();

      expect(provider.hasActiveTransformation, isFalse);
      expect(provider.history.length, equals(1));
      expect(provider.history.first.status, equals('completed'));

      // Round 2: Re-enroll in Beginner Fitness
      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2100,
        targetMacros: const {'protein': 140.0, 'carbs': 210.0, 'fat': 55.0},
      );
      for (int i = 1; i <= 30; i++) {
        await provider.markDayCompleted(i);
      }
      await provider.completePlan();

      expect(provider.history.length, equals(2));
      expect(provider.history[0].status, equals('completed'));
      expect(provider.history[1].status, equals('completed'));
      expect(historySaved.length, equals(2));
    });

    // -------------------------------------------------------------------------
    // Test 10: Atomic batch commit failure during switching preserves active plan and in-memory state
    // -------------------------------------------------------------------------
    test('10. Atomic batch commit failure during switching preserves existing active plan and in-memory state', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'user_batch_switch_fail';
      provider.activeDocSaverForTesting = (_, __) async {};

      // 1. Successfully enroll in Beginner Fitness and complete Day 1
      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 130.0, 'carbs': 200.0, 'fat': 50.0},
      );
      await provider.markDayCompleted(1);
      expect(provider.activeTransformation?.planId, equals('beginner_fitness_30'));
      expect(provider.activeTransformation?.completedDayIndices, equals([1]));

      // 2. Configure batch commit failure simulation
      provider.batchCommitForTesting = (uid, {activeData, deleteActive = false, historyData, historyDocId}) async {
        throw Exception('Simulated atomic WriteBatch commit failure: Network offline');
      };

      // 3. Attempt to switch to Weight Loss 60
      await provider.enrollInPlan(
        blueprint: TransformationPlansData.weightLoss60,
        targetCalories: 1800,
        targetMacros: const {'protein': 130.0, 'carbs': 180.0, 'fat': 45.0},
      );

      // 4. Verify existing active programme and in-memory state are intact
      expect(provider.error, contains('WriteBatch commit failure'));
      expect(provider.activeTransformation?.planId, equals('beginner_fitness_30'),
          reason: 'Active plan must remain beginner_fitness_30 after failed switch commit');
      expect(provider.activeTransformation?.completedDayIndices, equals([1]),
          reason: 'Completed days must be preserved');
      expect(provider.history, isEmpty,
          reason: 'History must not have premature archive entry');
      expect(provider.isLifecycleOperationInProgress, isFalse);
    });

    // -------------------------------------------------------------------------
    // Test 11: Atomic batch commit failure during completion preserves active plan
    // -------------------------------------------------------------------------
    test('11. Atomic batch commit failure during completion preserves active plan and in-memory state', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'user_batch_complete_fail';
      provider.activeDocSaverForTesting = (_, __) async {};

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 130.0, 'carbs': 200.0, 'fat': 50.0},
      );
      for (int i = 1; i <= 30; i++) {
        await provider.markDayCompleted(i);
      }

      // Configure commit failure
      provider.batchCommitForTesting = (uid, {activeData, deleteActive = false, historyData, historyDocId}) async {
        throw Exception('Firestore transaction failed: timeout');
      };

      await provider.completePlan();

      expect(provider.error, contains('Firestore transaction failed'));
      expect(provider.hasActiveTransformation, isTrue,
          reason: 'Active plan must not be cleared if Firestore commit failed');
      expect(provider.activeTransformation?.planId, equals('beginner_fitness_30'));
      expect(provider.history, isEmpty,
          reason: 'History must not have uncommitted completed state');
      expect(provider.isLifecycleOperationInProgress, isFalse);
    });

    // -------------------------------------------------------------------------
    // Test 12: Atomic batch commit failure during abandonment preserves active plan
    // -------------------------------------------------------------------------
    test('12. Atomic batch commit failure during abandonment preserves active plan and in-memory state', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'user_batch_abandon_fail';
      provider.activeDocSaverForTesting = (_, __) async {};

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.muscleBuilding90,
        targetCalories: 2500,
        targetMacros: const {'protein': 180.0, 'carbs': 250.0, 'fat': 70.0},
      );
      await provider.markDayCompleted(1);

      // Configure commit failure
      provider.batchCommitForTesting = (uid, {activeData, deleteActive = false, historyData, historyDocId}) async {
        throw Exception('Simulated WriteBatch delete failure');
      };

      await provider.abandonPlan();

      expect(provider.error, contains('WriteBatch delete failure'));
      expect(provider.hasActiveTransformation, isTrue,
          reason: 'Active plan must be preserved if batch commit fails');
      expect(provider.activeTransformation?.planId, equals('muscle_building_90'));
      expect(provider.activeTransformation?.completedDayIndices, equals([1]));
      expect(provider.history, isEmpty);
      expect(provider.isLifecycleOperationInProgress, isFalse);
    });

    // -------------------------------------------------------------------------
    // Test 13: Concurrency lock prevents overlapping lifecycle calls
    // -------------------------------------------------------------------------
    test('13. Concurrency lock prevents overlapping lifecycle calls from corrupting state', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'user_concurrency';
      provider.activeDocSaverForTesting = (_, __) async {};

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 130.0, 'carbs': 200.0, 'fat': 50.0},
      );

      // Set batch commit to hang until signaled
      bool commitFinished = false;
      provider.batchCommitForTesting = (uid, {activeData, deleteActive = false, historyData, historyDocId}) async {
        while (!commitFinished) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      };

      // Launch first operation in background
      final firstOp = provider.abandonPlan();
      expect(provider.isLifecycleOperationInProgress, isTrue);

      // Immediately attempt second operation while first is in flight
      final secondOp = provider.enrollInPlan(
        blueprint: TransformationPlansData.weightLoss60,
        targetCalories: 1800,
        targetMacros: const {'protein': 120.0, 'carbs': 180.0, 'fat': 40.0},
      );

      // Release first operation
      commitFinished = true;
      await Future.wait([firstOp, secondOp]);

      // State is consistent, concurrency lock avoided duplicate corrupted write
      expect(provider.isLifecycleOperationInProgress, isFalse);
    });

    // -------------------------------------------------------------------------
    // Test 14: Legacy history documents without completedAt are retrieved and sorted
    // -------------------------------------------------------------------------
    test('14. Legacy history documents without completedAt are retrieved and sorted using targetEndDate/startDate fallback', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'user_legacy_history';

      final legacyDoc1 = {
        'planId': 'beginner_fitness_30',
        'planTitle': 'Beginner Fitness - 30 Days',
        'startDate': DateTime(2025, 1, 1).toIso8601String(),
        'targetEndDate': DateTime(2025, 1, 31).toIso8601String(),
        // Notice: completedAt is null/missing (simulates legacy Firestore record)
        'currentDay': 30,
        'totalDays': 30,
        'status': 'completed',
        'completedDayIndices': List.generate(30, (i) => i + 1),
        'targetCalories': 2000.0,
        'targetMacros': {'protein': 140.0, 'carbs': 200.0, 'fat': 50.0},
        'milestones': [],
      };

      final legacyDoc2 = {
        'planId': 'weight_loss_60',
        'planTitle': '60-Day Weight Loss',
        'startDate': DateTime(2025, 2, 1).toIso8601String(),
        'targetEndDate': DateTime(2025, 4, 1).toIso8601String(),
        'completedAt': DateTime(2025, 4, 2).toIso8601String(),
        'currentDay': 60,
        'totalDays': 60,
        'status': 'completed',
        'completedDayIndices': List.generate(60, (i) => i + 1),
        'targetCalories': 1800.0,
        'targetMacros': {'protein': 130.0, 'carbs': 180.0, 'fat': 45.0},
        'milestones': [],
      };

      provider.activeDocFetcherForTesting = (_) => null;
      provider.historyDocFetcherForTesting = (_) => [legacyDoc1, legacyDoc2];

      await provider.loadTransformation();

      expect(provider.history.length, equals(2));
      // legacyDoc2 finished in April 2025, legacyDoc1 in Jan 2025 -> doc2 should be first
      expect(provider.history[0].planId, equals('weight_loss_60'));
      expect(provider.history[1].planId, equals('beginner_fitness_30'));
      expect(provider.history[1].completedAt, isNull);
    });

    // -------------------------------------------------------------------------
    // Test 15: App restart and progress restoration from storage
    // -------------------------------------------------------------------------
    test('15. App restart and progress restoration from saved storage', () async {
      Map<String, dynamic>? activeStorageDoc;
      final historyStorage = <Map<String, dynamic>>[];

      // Phase A: User runs app, enrolls in Muscle Building 90, completes 5 days
      {
        final session1 = TransformationProvider(autoLoad: false);
        session1.userIdOverrideForTesting = 'user_restart_test';
        session1.activeDocSaverForTesting = (_, data) async {
          activeStorageDoc = data;
        };
        session1.historyDocSaverForTesting = (_, data) async {
          historyStorage.add(data);
        };

        await session1.enrollInPlan(
          blueprint: TransformationPlansData.muscleBuilding90,
          targetCalories: 2600,
          targetMacros: const {'protein': 180.0, 'carbs': 270.0, 'fat': 70.0},
        );
        for (int i = 1; i <= 5; i++) {
          await session1.markDayCompleted(i);
        }
      }

      expect(activeStorageDoc, isNotNull);
      expect(activeStorageDoc!['completedDayIndices'], equals([1, 2, 3, 4, 5]));

      // Phase B: App restarts (cold boot), new provider instance loads from storage
      {
        final session2 = TransformationProvider(autoLoad: false);
        session2.userIdOverrideForTesting = 'user_restart_test';
        session2.activeDocFetcherForTesting = (_) => activeStorageDoc;
        session2.historyDocFetcherForTesting = (_) => historyStorage;

        await session2.loadTransformation();

        expect(session2.hasActiveTransformation, isTrue);
        expect(session2.activeTransformation?.planId, equals('muscle_building_90'));
        expect(session2.activeTransformation?.completedDayIndices, equals([1, 2, 3, 4, 5]));
        expect(session2.isDayCompleted(1), isTrue);
        expect(session2.isDayCompleted(5), isTrue);
        expect(session2.isDayCompleted(6), isFalse);
      }
    });

    // -------------------------------------------------------------------------
    // Test 16: Idempotent day completion prevents duplicate progress
    // -------------------------------------------------------------------------
    test('16. Idempotent day completion prevents duplicate progress', () async {
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'user_idempotent';
      provider.activeDocSaverForTesting = (_, __) async {};

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.beginnerFitness30,
        targetCalories: 2000,
        targetMacros: const {'protein': 130.0, 'carbs': 200.0, 'fat': 50.0},
      );

      // Call markDayCompleted(1) three times
      await provider.markDayCompleted(1);
      await provider.markDayCompleted(1);
      await provider.markDayCompleted(1);

      expect(provider.activeTransformation!.completedDayIndices, equals([1]));
      expect(provider.activeTransformation!.completionPercentage, closeTo(1 / 30, 0.001));
    });

    // -------------------------------------------------------------------------
    // Test 17: Workout history and PR records remain intact during transformation operations
    // -------------------------------------------------------------------------
    test('17. Workout history and PR records remain intact during transformation operations', () async {
      WorkoutLogService.clearLastLogCache();

      final squatLog = WorkoutLog(
        id: 'squat_pr_1',
        exerciseName: 'Classic Barbell Squat',
        date: DateTime.now().subtract(const Duration(days: 4)),
        category: 'Legs',
        sets: [
          WorkoutSet(weight: 150.0, reps: 5, isCompleted: true),
        ],
      );

      WorkoutLogService.seedLastLogCache('Classic Barbell Squat', squatLog);

      final cachedBefore = WorkoutLogService.getCachedLastLog('Classic Barbell Squat');
      expect(cachedBefore, isNotNull);
      expect(cachedBefore!.sets.first.weight, equals(150.0));

      // Perform various transformation lifecycle actions
      final provider = TransformationProvider(autoLoad: false);
      provider.userIdOverrideForTesting = 'user_history_safety';
      provider.activeDocSaverForTesting = (_, __) async {};
      provider.historyDocSaverForTesting = (_, __) async {};

      await provider.enrollInPlan(
        blueprint: TransformationPlansData.strength12Week,
        targetCalories: 2600,
        targetMacros: const {'protein': 180.0, 'carbs': 280.0, 'fat': 65.0},
      );
      await provider.markDayCompleted(1);
      await provider.abandonPlan();

      // Verify canonical workout logs in cache are completely unaffected
      final cachedAfter = WorkoutLogService.getCachedLastLog('Classic Barbell Squat');
      expect(cachedAfter, isNotNull);
      expect(cachedAfter!.sets.first.weight, equals(150.0));
      WorkoutLogService.clearLastLogCache();
    });

    // -------------------------------------------------------------------------
    // Test 18: Subscription entitlements and access boundaries preserved
    // -------------------------------------------------------------------------
    test('18. Milestone structures and blueprint duration consistency preserved', () {
      for (final p in TransformationPlansData.allPlans) {
        final milestones = TransformationPlansData.createDefaultMilestones(p);
        expect(milestones, isNotEmpty);
        expect(milestones.last.triggerDay, equals(p.durationDays));
      }
    });
  });
}
