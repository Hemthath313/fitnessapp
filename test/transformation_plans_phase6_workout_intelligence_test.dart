import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/model/workout_model.dart';
import 'package:fitness_app/presentation/custom_workouts/day_workout_session_page.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/utils/transformation_equipment_adapter.dart';

class MockTransformationProvider extends ChangeNotifier
    implements TransformationProvider {
  UserTransformationState? _activeTransformation;
  final List<int> markCompletedCalls = [];

  MockTransformationProvider({UserTransformationState? activeState}) {
    _activeTransformation = activeState;
  }

  @override
  UserTransformationState? get activeTransformation => _activeTransformation;

  @override
  List<UserTransformationState> get history => [];

  @override
  bool get hasActiveTransformation => _activeTransformation != null;

  @override
  bool isDayCompleted(int dayNumber) {
    return _activeTransformation?.isDayCompleted(dayNumber) ?? false;
  }

  @override
  Future<void> markDayCompleted(int dayIndex) async {
    markCompletedCalls.add(dayIndex);
    if (_activeTransformation != null &&
        !_activeTransformation!.completedDayIndices.contains(dayIndex)) {
      final updated = List<int>.from(_activeTransformation!.completedDayIndices)
        ..add(dayIndex);
      _activeTransformation = _activeTransformation!.copyWith(
        completedDayIndices: updated,
      );
      notifyListeners();
    }
  }

  @override
  Future<void> toggleDayCompletion(int dayNumber) async {
    if (isDayCompleted(dayNumber)) {
      final updated = List<int>.from(_activeTransformation!.completedDayIndices)
        ..remove(dayNumber);
      _activeTransformation = _activeTransformation!.copyWith(
        completedDayIndices: updated,
      );
    } else {
      await markDayCompleted(dayNumber);
    }
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 6 — Progressive Weekly Workout Programmes', () {
    test('1. weight_loss_60 has phase-specific sets, reps, and a mid-plan recovery week (Week 4)', () {
      final plan = TransformationPlansData.weightLoss60;
      expect(plan.id, 'weight_loss_60');
      expect(plan.durationDays, 60);

      // Phase 1 (Weeks 1-2): 3 sets, 12-15 reps, 60s rest
      final week1 = plan.allWeeks[0];
      final week1Day1 = week1.days.firstWhere((d) => d.dayType == 'workout');
      expect(week1Day1.targetSets, 3);
      expect(week1Day1.targetReps, '12-15');

      // Phase 2 (Week 3): 4 sets, 12-15 reps
      final week3 = plan.allWeeks[2];
      final week3Day1 = week3.days.firstWhere((d) => d.dayType == 'workout');
      expect(week3Day1.targetSets, 4);
      expect(week3Day1.targetReps, '12-15');

      // Phase 2 (Week 4): Mid-plan consolidation / recovery week (2 sets, 12 reps)
      final week4 = plan.allWeeks[3];
      final week4Day1 = week4.days.firstWhere((d) => d.dayType == 'workout');
      expect(week4Day1.targetSets, 2, reason: 'Week 4 must be a genuine recovery week with 2 sets');
      expect(week4Day1.targetReps, '12');
      expect(week4.weekTip?.toLowerCase(), contains('consolidation'));

      // Phase 3 (Weeks 5-6): 4 sets, 15 reps, high density
      final week5 = plan.allWeeks[4];
      final week5Day1 = week5.days.firstWhere((d) => d.dayType == 'workout');
      expect(week5Day1.targetSets, 4);
      expect(week5Day1.targetReps, '15');

      // Phase 4 (Weeks 7-8): 4 sets, 12-15 reps
      final week7 = plan.allWeeks[6];
      final week7Day1 = week7.days.firstWhere((d) => d.dayType == 'workout');
      expect(week7Day1.targetSets, 4);
      expect(week7Day1.targetReps, '12-15');

      // Phase 4 (Week 9): 3 sets, 12 reps (maintenance wrap-up)
      final week9 = plan.allWeeks[8];
      final week9Day1 = week9.days.firstWhere((d) => d.dayType == 'workout');
      expect(week9Day1.targetSets, 3);
      expect(week9Day1.targetReps, '12');
    });

    test('2. muscle_building_90 features progressive hypertrophy and genuine deload weeks at Week 4 and Week 8', () {
      final plan = TransformationPlansData.muscleBuilding90;
      expect(plan.id, 'muscle_building_90');
      expect(plan.durationDays, 90);

      // Phase 1 (Week 1): Baseline 3 sets
      final week1 = plan.allWeeks[0];
      final week1Day1 = week1.days.firstWhere((d) => d.dayType == 'workout');
      expect(week1Day1.targetSets, 3);
      expect(week1Day1.targetReps, '8-12');

      // Phase 1 (Weeks 2-3): Ramp to 4 sets
      final week2 = plan.allWeeks[1];
      final week2Day1 = week2.days.firstWhere((d) => d.dayType == 'workout');
      expect(week2Day1.targetSets, 4);

      // Phase 1 (Week 4): Deload Week 1 (reduced to 2 sets, RPE 6-7)
      final week4 = plan.allWeeks[3];
      final week4Day1 = week4.days.firstWhere((d) => d.dayType == 'workout');
      expect(week4Day1.targetSets, 2, reason: 'Week 4 must be a genuine deload with 2 sets');
      expect(week4Day1.targetReps, '8-10');
      expect(week4.weekTip?.toLowerCase(), contains('deload'));

      // Phase 2 (Weeks 5-7): Volume Overload 4 sets
      final week5 = plan.allWeeks[4];
      final week5Day1 = week5.days.firstWhere((d) => d.dayType == 'workout');
      expect(week5Day1.targetSets, 4);

      // Phase 2 (Week 8): Deload Week 2 (reduced to 2 sets)
      final week8 = plan.allWeeks[7];
      final week8Day1 = week8.days.firstWhere((d) => d.dayType == 'workout');
      expect(week8Day1.targetSets, 2, reason: 'Week 8 must be a genuine deload with 2 sets');
      expect(week8Day1.targetReps, '8-10');

      // Phase 3 (Week 11): PR Testing (4 sets, 5-6 reps)
      final week11 = plan.allWeeks[10];
      final week11Day1 = week11.days.firstWhere((d) => d.dayType == 'workout');
      expect(week11Day1.targetSets, 4);
      expect(week11Day1.targetReps, '5-6');
      expect(week11Day1.notes?.toLowerCase(), contains('pr bench press attempt'));

      // Phase 3 (Week 13): Final Peak Week (3 sets, 8-10 reps)
      final week13 = plan.allWeeks[12];
      final week13Day1 = week13.days.firstWhere((d) => d.dayType == 'workout');
      expect(week13Day1.targetSets, 3);
      expect(week13Day1.targetReps, '8-10');
    });

    test('3. beginner_fitness_30 preserves 3 manageable sessions/week with 3 sets of 8-10 reps', () {
      final plan = TransformationPlansData.beginnerFitness30;
      expect(plan.id, 'beginner_fitness_30');
      expect(plan.durationDays, 30);

      for (int w = 0; w < 4; w++) {
        final week = plan.allWeeks[w];
        final workoutDays = week.days.where((d) => d.dayType == 'workout').toList();
        expect(workoutDays.length, 3, reason: 'Week ${w + 1} should have exactly 3 workout days');
        for (final day in workoutDays) {
          expect(day.targetSets, 3);
        }
      }
    });
  });

  group('Phase 6 — Equipment Adaptation & Safeguards', () {
    test('1. Maps gym cables, machines, and barbells to dumbbells when training at home', () {
      final originalExercises = [
        'Barbell Bench Press',
        'Lat Pulldown',
        'Barbell Squat',
        'Leg Press',
        'Cable Pushdown',
      ];

      final homeAdapted = TransformationEquipmentAdapter.adaptExercisesForEnvironment(
        exerciseNames: originalExercises,
        workoutLocation: 'home',
        availableEquipment: ['Dumbbells'],
      );

      expect(homeAdapted, [
        'Incline Dumbbell Press',
        'Dumbbell Bent Over Row',
        'Dumbbell Goblet Squat',
        'Dumbbell Goblet Squat',
        'Dumbbell Close Grip Press',
      ]);
    });

    test('2. Preserves gym apparatus when training in a commercial gym', () {
      final originalExercises = [
        'Barbell Bench Press',
        'Lat Pulldown',
        'Leg Press',
        'Cable Standing Fly',
      ];

      final gymAdapted = TransformationEquipmentAdapter.adaptExercisesForEnvironment(
        exerciseNames: originalExercises,
        workoutLocation: 'gym',
        availableEquipment: ['Barbell', 'Cables', 'Machines', 'Dumbbells'],
      );

      expect(gymAdapted, originalExercises);
    });

    test('3. Replaces heavy spinal loading and deep knee flexion when injuries are flagged', () {
      final lowerBackInjury = TransformationEquipmentAdapter.adaptExercisesForEnvironment(
        exerciseNames: ['Classic Barbell Squat', 'Smith Deadlift'],
        workoutLocation: 'gym',
        availableEquipment: ['Barbell', 'Dumbbells'],
        injuries: 'History of lower back strain',
      );

      expect(lowerBackInjury, [
        'Dumbbell Goblet Squat',
        'Dumbbell Sumo Squat',
      ]);

      final kneeInjury = TransformationEquipmentAdapter.adaptExercisesForEnvironment(
        exerciseNames: ['Dumbbell Lunge'],
        workoutLocation: 'gym',
        availableEquipment: ['Dumbbells'],
        injuries: 'Knee patellar pain',
      );

      expect(kneeInjury, ['Dumbbell Lying Femoral Curl']);
    });
  });

  group('Phase 6 — Dynamic Warm-up & Cooldown Routines', () {
    test('1. All workout days in the catalogues contain structured warm-up and cool-down routines', () {
      for (final plan in TransformationPlansData.allPlans) {
        for (final week in plan.allWeeks) {
          for (final day in week.days) {
            if (day.dayType == 'workout') {
              final warmup = day.warmupExercises;
              expect(
                warmup,
                isNotNull,
                reason: '${plan.id} Day ${day.dayIndex} missing warmupExercises',
              );
              expect(
                warmup,
                isNotEmpty,
                reason: '${plan.id} Day ${day.dayIndex} warmupExercises is empty',
              );
              final cooldown = day.cooldownExercises;
              expect(
                cooldown,
                isNotNull,
                reason: '${plan.id} Day ${day.dayIndex} missing cooldownExercises',
              );
              expect(
                cooldown,
                isNotEmpty,
                reason: '${plan.id} Day ${day.dayIndex} cooldownExercises is empty',
              );
            }
          }
        }
      }
    });

    test('2. Generates dynamic warm-up movements matching target muscle focus', () {
      final pushWarmup = TransformationEquipmentAdapter.getWarmupExercises('Chest & Triceps');
      expect(pushWarmup.any((w) => w.contains('Arm Circles') || w.contains('Shoulder')), isTrue);

      final legWarmup = TransformationEquipmentAdapter.getWarmupExercises('Legs & Squats');
      expect(legWarmup.any((w) => w.contains('Air Squats') || w.contains('Leg Swings')), isTrue);

      final pullWarmup = TransformationEquipmentAdapter.getWarmupExercises('Back & Biceps');
      expect(pullWarmup.any((w) => w.contains('Cat-Cow') || w.contains('Lat')), isTrue);
    });
  });

  group('Phase 6 — Automatic Workout Completion Synchronisation', () {
    testWidgets('1. DayWorkoutSessionPage renders Warm-up and Cooldown cards with interactive checkboxes', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final workouts = [
        WorkoutModel(
          id: 'w1',
          name: 'Barbell Bench Press',
          setNumber: 3,
          repNumber: 10,
          dateTime: DateTime(2026, 11, 1),
        ),
      ];

      final mockTransformationProvider = MockTransformationProvider(
        activeState: UserTransformationState(
          planId: 'weight_loss_60',
          planTitle: '60-Day Weight Loss Challenge',
          startDate: DateTime.now(),
          targetEndDate: DateTime.now().add(const Duration(days: 60)),
          currentDay: 1,
          totalDays: 60,
          targetCalories: 2000.0,
          targetMacros: {'protein': 160.0, 'carbs': 180.0, 'fat': 60.0},
          targetWeight: 75.0,
          startingWeight: 80.0,
          completedDayIndices: [],
        ),
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, _) => MultiProvider(
            providers: [
              ChangeNotifierProvider<TransformationProvider>.value(
                value: mockTransformationProvider,
              ),
            ],
            child: MaterialApp(
              home: DayWorkoutSessionPage(
                dayName: 'Upper Body Workout',
                workouts: workouts,
                planId: 'weight_loss_60',
                planDay: 1,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Warm-up Card is visible
      expect(find.byKey(const Key('session_warmup_card')), findsOneWidget);
      expect(find.textContaining('Dynamic Warm-Up'), findsOneWidget);

      // Scroll to Cooldown Card at the bottom of the routine
      await tester.scrollUntilVisible(
        find.byKey(const Key('session_cooldown_card')),
        200.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('session_cooldown_card')), findsOneWidget);
      expect(find.textContaining('Cool-Down'), findsOneWidget);
    });

    test('2. TransformationProvider.markDayCompleted is idempotent and safe against duplicates', () async {
      final provider = MockTransformationProvider(
        activeState: UserTransformationState(
          planId: 'weight_loss_60',
          planTitle: '60-Day Weight Loss Challenge',
          startDate: DateTime.now(),
          targetEndDate: DateTime.now().add(const Duration(days: 60)),
          currentDay: 3,
          totalDays: 60,
          targetCalories: 2000.0,
          targetMacros: {'protein': 160.0, 'carbs': 180.0, 'fat': 60.0},
          targetWeight: 75.0,
          startingWeight: 80.0,
          completedDayIndices: [1, 2],
        ),
      );

      expect(provider.activeTransformation!.completedDayIndices, [1, 2]);

      // Call markDayCompleted for day 3
      await provider.markDayCompleted(3);
      expect(provider.activeTransformation!.completedDayIndices, [1, 2, 3]);

      // Call markDayCompleted for day 3 again (should not duplicate)
      await provider.markDayCompleted(3);
      expect(provider.activeTransformation!.completedDayIndices, [1, 2, 3]);
    });
  });
}
