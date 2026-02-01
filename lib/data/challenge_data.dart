class ChallengeExercise {
  final String name;
  final String target;
  final String equipment;
  final String videoPath;
  final String setsReps;

  const ChallengeExercise({
    required this.name,
    required this.target,
    required this.equipment,
    required this.videoPath,
    required this.setsReps,
  });
}

class ChallengeData {
  static const Map<int, List<ChallengeExercise>> sixPackCurriculum = {
    1: [
      ChallengeExercise(
        name: 'Crunch',
        target: 'Upper Abs',
        equipment: 'None',
        videoPath: 'assets/videos/abs/abs_twisting_crunch.mp4',
        setsReps: '3 sets x 20 reps',
      ),
      ChallengeExercise(
        name: 'Leg Raise',
        target: 'Lower Abs',
        equipment: 'None',
        videoPath: 'assets/videos/abs/abs_vertical_leg_raise.mp4',
        setsReps: '3 sets x 15 reps',
      ),
      ChallengeExercise(
        name: 'Plank',
        target: 'Core',
        equipment: 'None',
        videoPath: 'assets/videos/abs/abs_plank.mp4', 
        setsReps: '3 sets x 45 seconds',
      ),
    ],
    2: [
      ChallengeExercise(
        name: 'V-Up',
        target: 'Upper & Lower Abs',
        equipment: 'None',
        videoPath: 'assets/videos/abs/abs_v-up.mp4',
        setsReps: '3 sets x 12 reps',
      ),
      ChallengeExercise(
        name: 'Bicycle Crunch',
        target: 'Obliques',
        equipment: 'None',
        videoPath: 'assets/videos/abs/abs_air_twist_crunch.mp4',
        setsReps: '3 sets x 20 reps',
      ),
      ChallengeExercise(
        name: 'Hanging Leg Raise',
        target: 'Lower Abs',
        equipment: 'Pull-up Bar',
        videoPath: 'assets/videos/abs/abs_vertical_leg_raise.mp4',
        setsReps: '3 sets x 10 reps',
      ),
    ],
    // ... Additional days can be added here
  };

  static const ChallengeExercise weeklyFeaturedExercise = ChallengeExercise(
    name: 'Cable Kneeling Crunch',
    target: 'Upper Abs',
    equipment: 'Cable Machine',
    videoPath: 'assets/videos/abs/abs_cable_kneeling_crunch.mp4',
    setsReps: '4 sets x 12-15 reps',
  );
}
