
class WarmupRoutine {
  final String target;
  final List<WarmupExercise> exercises;

  const WarmupRoutine({required this.target, required this.exercises});
}

class WarmupExercise {
  final String name;
  final String durationOrReps;
  final String description;

  const WarmupExercise({
    required this.name,
    required this.durationOrReps,
    required this.description,
  });
}

class WarmupData {
  static const List<WarmupRoutine> routines = [
    WarmupRoutine(
      target: 'Leg Day (Lower Body)',
      exercises: [
        WarmupExercise(
          name: 'Leg Swings (Front/Back)',
          durationOrReps: '15 reps/leg',
          description: 'Swing leg forward and backward to loosen hips.',
        ),
         WarmupExercise(
          name: 'Leg Swings (Side-to-Side)',
          durationOrReps: '15 reps/leg',
          description: 'Swing leg across body to open adductors.',
        ),
        WarmupExercise(
          name: 'Bodyweight Squats',
          durationOrReps: '20 reps',
          description: 'Deep squats to engage quads and glutes.',
        ),
        WarmupExercise(
          name: 'Walking Lunges',
          durationOrReps: '10 reps/leg',
          description: 'Dynamic stretch for hip flexors and quads.',
        ),
      ],
    ),
    WarmupRoutine(
      target: 'Push Day (Chest/Shoulders)',
      exercises: [
        WarmupExercise(
          name: 'Arm Circles',
          durationOrReps: '30 seconds',
          description: 'Large circles forward and backward.',
        ),
        WarmupExercise(
          name: 'Band Pull-Aparts',
          durationOrReps: '20 reps',
          description: 'Engage rear delts and scapula.',
        ),
        WarmupExercise(
          name: 'Push-ups to Downward Dog',
          durationOrReps: '10 reps',
          description: 'Activate chest and stretch shoulders.',
        ),
        WarmupExercise(
          name: 'Rotator Cuff Rotations',
          durationOrReps: '15 reps/arm',
          description: 'Light external rotations for stability.',
        ),
      ],
    ),
    WarmupRoutine(
      target: 'Pull Day (Back/Biceps)',
      exercises: [
        WarmupExercise(
          name: 'Cat-Cow Stretch',
          durationOrReps: '1 minute',
          description: 'Mobilize the spine.',
        ),
        WarmupExercise(
          name: 'Thoracic Rotations',
          durationOrReps: '10 reps/side',
          description: 'Open up the mid-back.',
        ),
        WarmupExercise(
          name: 'Band Rows (Light)',
          durationOrReps: '20 reps',
          description: 'Activate lats and rhomboids.',
        ),
         WarmupExercise(
          name: 'Dead Hang',
          durationOrReps: '30 seconds',
          description: 'Decompress spine and stretch lats.',
        ),
      ],
    ),
     WarmupRoutine(
      target: 'Full Body / HIIT',
      exercises: [
        WarmupExercise(
          name: 'Jumping Jacks',
          durationOrReps: '1 minute',
          description: 'Raise heart rate.',
        ),
        WarmupExercise(
          name: 'Inchworms',
          durationOrReps: '10 reps',
          description: 'Stretch hamstrings and engage core.',
        ),
        WarmupExercise(
          name: 'World\'s Greatest Stretch',
          durationOrReps: '5 reps/side',
          description: 'Full body mobility opener.',
        ),
      ],
    ),
  ];
}
