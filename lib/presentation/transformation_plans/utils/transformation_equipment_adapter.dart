import 'package:fitness_app/data/exercise_data.dart';

/// Utility to adapt transformation plan exercises based on the user's
/// training environment (Home vs. Gym), available equipment, and physical restrictions,
/// and provide structured dynamic warm-up and cool-down routines.
class TransformationEquipmentAdapter {
  /// Equipment categories recognized by the app
  static const String equipBarbell = 'Barbell';
  static const String equipDumbbells = 'Dumbbells';
  static const String equipCables = 'Cables';
  static const String equipMachines = 'Machines';

  /// Home alternatives mapping for gym apparatus (Cables, Machines, Barbells)
  /// Maps canonical gym exercises to dumbbell and bodyweight equivalents in ExerciseData.
  static const Map<String, String> _homeDumbbellSubstitutions = {
    // Chest / Push
    'Barbell Bench Press': 'Incline Dumbbell Press',
    'Lever Chest Press': 'Incline Dumbbell Press',
    'Close Grip Bench Press': 'Dumbbell Close Grip Press',
    'Barbell Close Grip Bench Press': 'Dumbbell Close Grip Press',
    'Barbell Decline Bench Press': 'Deep Pushups',
    'Chest Dips': 'Deep Pushups',
    'Cable Standing Fly': 'Dumbbell Fly',
    'Incline Dumbbell Fly': 'Dumbbell Fly',
    'Dumbbell Decline Fly (45 Degree)': 'Dumbbell Fly',
    'Lever Pec Dec Fly': 'Dumbbell Fly',

    // Back / Pull
    'Lat Pulldown': 'Dumbbell Bent Over Row',
    'Cable Pulldown': 'Dumbbell Bent Over Row',
    'Cable Seated Row': 'Dumbbell Bent Over Row',
    'Cable Seated Row (Normal Grip)': 'Dumbbell Bent Over Row',
    'Cable Seated Row (Parallel Grip)': 'Dumbbell Bent Over Row',
    'Cable Seated High Row (V-Bar)': 'Dumbbell Incline Row',
    'Cable One Arm Lateral Pull Down': 'Dumbbell Bent Over Row',
    'Cable One Arm Twisting Seated Row': 'Dumbbell Bent Over Row',
    'Cable Straight Arm Pulldown': 'Dumbbell Incline Row',
    'Lever T-Bar Row': 'Dumbbell Bent Over Row',
    'Lever High Row': 'Dumbbell Incline Row',
    'Barbell Underhand Bent Over Row': 'Dumbbell Bent Over Row',

    // Legs / Lower
    'Barbell Squat': 'Dumbbell Goblet Squat',
    'Classic Barbell Squat': 'Dumbbell Goblet Squat',
    'Barbell Front Chest Squat': 'Dumbbell Goblet Squat',
    'Leg Press': 'Dumbbell Goblet Squat',
    'Sled 45 Degree Wide Leg Press': 'Dumbbell Goblet Squat',
    'Sled Hack Squat': 'Dumbbell Goblet Squat',
    'Smith Machine Chair Squat': 'Dumbbell Goblet Squat',
    'Leg Extension': 'Dumbbell Goblet Squat',
    'Lying Leg Curl': 'Dumbbell Lying Femoral Curl',
    'Lying Leg Curls': 'Dumbbell Lying Femoral Curl',
    'Lever Seated Leg Curl': 'Dumbbell Lying Femoral Curl',
    'Lever Kneeling Leg Curl': 'Dumbbell Lying Femoral Curl',
    'Barbell Lunge': 'Dumbbell Lunge',

    // Posterior Chain / Deadlift
    'Smith Deadlift': 'Dumbbell Sumo Squat',
    'Barbell Straight Leg Deadlift': 'Dumbbell Sumo Squat',

    // Shoulders
    'Overhead Press': 'Dumbbell Bench Seated Press',
    'Military Press': 'Dumbbell Bench Seated Press',
    'Lever Military Press': 'Dumbbell Bench Seated Press',
    'Barbell Seated Behind Head Military Press': 'Dumbbell Arnold Press',
    'EZ Barbell Antigravity Press': 'Dumbbell Arnold Press',
    'Barbell Wide Grip Upright Row': 'Dumbbell Alternating Press',
    'Cable Rear Delt Row': 'Dumbbell Bent Over Row',
    'Face Pull': 'Dumbbell Bent Over Row',

    // Arms
    'Barbell Curl': 'Dumbbell Biceps Curl',
    'EZ Barbell Biceps Curl': 'Dumbbell Biceps Curl',
    'Cable One Arm Curl': 'Dumbbell Biceps Curl',
    'Cable Standing Inner Curl': 'Dumbbell Alternative Biceps Curl',
    'Barbell Drag Curl': 'Dumbbell Concentration Curl',
    'Cable Pushdown': 'Dumbbell Close Grip Press',
    'Cable Rope Pushdown': 'Dumbbell Close Grip Press',
    'Tricep Rope Pushdown': 'Dumbbell Close Grip Press',
  };

  /// Bodyweight fallback when only bodyweight is available (zero equipment)
  static const Map<String, String> _bodyweightSubstitutions = {
    'Barbell Bench Press': 'Deep Pushups',
    'Incline Dumbbell Press': 'Deep Pushups',
    'Lever Chest Press': 'Deep Pushups',
    'Dumbbell Hammer Press': 'Deep Pushups',
    'Chest Dips': 'Deep Pushups',
    'Dumbbell Fly': 'Deep Pushups',
    'Close Grip Bench Press': 'Close Grip Push-up',
    'Dumbbell Close Grip Press': 'Close Grip Push-up',
    'Cable Pushdown': 'Close Grip Push-up',
    'Lat Pulldown': 'Pull-ups Wide Back Grip',
    'Cable Seated Row': 'Pull-ups Wide Back Grip',
    'Dumbbell Bent Over Row': 'Pull-ups Wide Back Grip',
    'Barbell Squat': 'Classic Barbell Squat', // will use bodyweight squat
    'Dumbbell Goblet Squat': 'Deep Pushups',
    'Leg Press': 'Twisting Crunch',
    'Lying Leg Curl': 'Air Twist Crunch',
    'Overhead Press': 'Deep Pushups',
    'Dumbbell Arnold Press': 'Deep Pushups',
    'Barbell Curl': 'Pull-ups Wide Back Grip',
  };

  /// Adapts a list of exercise names based on environment and available equipment.
  /// If the workout location is 'home' or the user lacks machines/cables,
  /// returns suitable alternative exercises with the same muscle-group intent.
  static List<String> adaptExercisesForEnvironment({
    required List<String> exerciseNames,
    required String? workoutLocation,
    required List<String> availableEquipment,
    String? injuries,
  }) {
    if (exerciseNames.isEmpty) return const [];

    final isHome = workoutLocation?.trim().toLowerCase() == 'home';
    final hasCables = availableEquipment.any((e) => e.toLowerCase().contains('cable'));
    final hasMachines = availableEquipment.any((e) => e.toLowerCase().contains('machine'));
    final hasBarbell = availableEquipment.any((e) => e.toLowerCase().contains('barbell'));
    final hasDumbbells = availableEquipment.isEmpty ||
        availableEquipment.any((e) => e.toLowerCase().contains('dumbbell'));

    final adapted = <String>[];

    for (final name in exerciseNames) {
      final cleanName = ExerciseData.normalizeExerciseName(name);
      String finalName = cleanName;

      final isCableExercise = cleanName.toLowerCase().contains('cable') ||
          cleanName.toLowerCase().contains('lat pulldown') ||
          cleanName.toLowerCase().contains('face pull') ||
          cleanName.toLowerCase().contains('tricep rope pushdown');
      final isMachineExercise = cleanName.toLowerCase().contains('lever') ||
          cleanName.toLowerCase().contains('smith') ||
          cleanName.toLowerCase().contains('leg press') ||
          cleanName.toLowerCase().contains('sled') ||
          cleanName.toLowerCase().contains('leg extension') ||
          cleanName.toLowerCase().contains('leg curl');
      final isBarbellExercise = cleanName.toLowerCase().contains('barbell') ||
          cleanName.toLowerCase().contains('overhead press') ||
          cleanName.toLowerCase().contains('military press');

      final needsHomeSubstitution = isHome ||
          (isCableExercise && !hasCables) ||
          (isMachineExercise && !hasMachines) ||
          (isBarbellExercise && !hasBarbell);

      if (needsHomeSubstitution) {
        if (hasDumbbells && _homeDumbbellSubstitutions.containsKey(cleanName)) {
          finalName = _homeDumbbellSubstitutions[cleanName]!;
        } else if (!hasDumbbells && _bodyweightSubstitutions.containsKey(cleanName)) {
          finalName = _bodyweightSubstitutions[cleanName]!;
        } else if (_homeDumbbellSubstitutions.containsKey(cleanName)) {
          finalName = _homeDumbbellSubstitutions[cleanName]!;
        }
      }

      // Injury safeguards:
      // If user has a lower back injury, replace heavy axial spinal-loading exercises
      final lowerInjuries = (injuries ?? '').toLowerCase();
      if (lowerInjuries.contains('lower back') || lowerInjuries.contains('back')) {
        if (finalName == 'Classic Barbell Squat' || finalName == 'Barbell Squat') {
          finalName = 'Dumbbell Goblet Squat';
        } else if (finalName.contains('Deadlift')) {
          finalName = 'Dumbbell Sumo Squat';
        } else if (finalName == 'Barbell Underhand Bent Over Row') {
          finalName = 'Dumbbell Incline Row';
        }
      }

      // If user has knee injury, replace deep knee flexion movements
      if (lowerInjuries.contains('knee')) {
        if (finalName.contains('Lunge')) {
          finalName = 'Dumbbell Lying Femoral Curl';
        }
      }

      adapted.add(finalName);
    }

    return adapted;
  }

  /// Returns structured dynamic warm-up movements (5–10 minutes) based on target muscle focus.
  static List<String> getWarmupExercises(String? muscleGroup) {
    final lower = (muscleGroup ?? '').toLowerCase();

    if (lower.contains('chest') ||
        lower.contains('push') ||
        lower.contains('shoulder') ||
        lower.contains('arm') ||
        lower.contains('tricep') ||
        lower.contains('upper')) {
      return const [
        'Arm Circles & Shoulder Rotations (60s)',
        'Band or Towel Shoulder Dislocates (60s)',
        'Scapular Wall Slides (60s)',
        'Inchworm to Push-up Walkouts (90s)',
        'Torso Twists & Chest Expansion (60s)',
      ];
    } else if (lower.contains('leg') ||
        lower.contains('squat') ||
        lower.contains('quad') ||
        lower.contains('lower')) {
      return const [
        'Bodyweight Air Squats (60s)',
        'Dynamic Leg Swings (Front & Lateral) (90s)',
        'Walking Hip Opener Lunges (90s)',
        'Glute Bridge Hip Activations (60s)',
        'Ankle Circles & Calf Bounces (60s)',
      ];
    } else if (lower.contains('back') ||
        lower.contains('pull') ||
        lower.contains('deadlift') ||
        lower.contains('posterior')) {
      return const [
        'Cat-Cow Spinal Flexion & Extension (60s)',
        'Bird-Dog Core Stability (90s)',
        'Hinged Good Morning (Unweighted) (60s)',
        'Band Pull-Aparts & Lat Activations (60s)',
        'World\'s Greatest Stretch (90s)',
      ];
    } else {
      // Full Body / Metabolic Conditioning
      return const [
        'Jumping Jacks & High Knees (90s)',
        'World\'s Greatest Stretch (90s)',
        'Bodyweight Air Squats (60s)',
        'Push-up to Downward Dog (90s)',
        'Hip Flexor Dynamic Lunge (60s)',
      ];
    }
  }

  /// Returns structured recovery and cooldown movements (approx. 5 minutes) based on target muscle focus.
  static List<String> getCooldownExercises(String? muscleGroup) {
    final lower = (muscleGroup ?? '').toLowerCase();

    if (lower.contains('chest') ||
        lower.contains('push') ||
        lower.contains('shoulder') ||
        lower.contains('arm') ||
        lower.contains('tricep') ||
        lower.contains('upper')) {
      return const [
        'Doorway Pectoral & Biceps Stretch (60s)',
        'Cross-Body Shoulder Stretch (60s)',
        'Overhead Triceps & Lat Stretch (60s)',
        'Child\'s Pose with Deep Diaphragmatic Breathing (90s)',
      ];
    } else if (lower.contains('leg') ||
        lower.contains('squat') ||
        lower.contains('quad') ||
        lower.contains('lower')) {
      return const [
        'Standing Quadriceps Stretch (60s)',
        'Seated Hamstring & Calf Reach (60s)',
        'Figure-4 Glute & Piriformis Stretch (60s)',
        'Butterfly Groin Stretch (60s)',
        'Deep Recovery Breathing (60s)',
      ];
    } else if (lower.contains('back') ||
        lower.contains('pull') ||
        lower.contains('deadlift') ||
        lower.contains('posterior')) {
      return const [
        'Child\'s Pose to Cobra Spinal Stretch (90s)',
        'Supine Torso Spinal Twist (60s)',
        'Seated Forward Fold Hamstring Stretch (60s)',
        'Kneeling Lat & Upper Back Stretch (60s)',
      ];
    } else {
      // Full Body / Metabolic
      return const [
        'Child\'s Pose with Deep Belly Breathing (90s)',
        'Standing Quad & Hip Flexor Stretch (60s)',
        'Seated Hamstring Reach (60s)',
        'Supine Spinal Twist & Recovery Reset (60s)',
      ];
    }
  }
}
