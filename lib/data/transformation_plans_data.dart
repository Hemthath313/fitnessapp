import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/transformation_plans/utils/transformation_equipment_adapter.dart';

/// Centralized repository of static Transformation Plan blueprints.
/// Structured data-driven curriculum with phases, weekly focus, daily workout/rest assignments,
/// and milestones.
class TransformationPlansData {
  // ──────────────────────────────────────────────────────────────────────────
  // 0. COMPLETE BEGINNER – 30 DAYS
  // ──────────────────────────────────────────────────────────────────────────
  static final TransformationPlanBlueprint beginnerFitness30 = TransformationPlanBlueprint(
    id: 'beginner_fitness_30',
    title: 'Complete Beginner – 30 Days',
    subtitle: 'Learn proper exercise mechanics, build consistency & establish a lifelong fitness base',
    description:
        'A structured 30-day foundation curriculum teaching core movement patterns, safe form, bodyweight control, and sustainable fitness habits without burnout.',
    durationDays: 30,
    goal: 'MAINTAIN',
    difficulty: 'Beginner',
    gradientColorHex: '0xFF00B074', // Emerald Green
    iconEmoji: '🌱',
    highlights: [
      '3 Manageable 25–35 Min Sessions per Week',
      'Fundamental Movement Patterns & Bodyweight Mechanics',
      '4 Scheduled Active Recovery & Rest Days per Week',
      'Zero Intimidation: Home & Gym Equipment Flexibility',
      'Clear Graduation Pathways to Muscle, Fat Loss, or Strength',
    ],
    phases: [
      // Phase 1: Getting Started (Week 1 / Days 1-7)
      TransformationPhase(
        phaseNumber: 1,
        phaseName: 'Phase 1: Getting Started',
        description: 'Introduction to basic movement patterns, safe form, core bracing, and warm-up/cool-down rituals.',
        nutritionFocus: 'Focus on hydration (2.5L+ daily), whole foods, and regular meal timing at calorie maintenance.',
        weeks: [
          _generateBeginnerWeek1(),
        ],
      ),
      // Phase 2: Building Consistency (Week 2 / Days 8-14)
      TransformationPhase(
        phaseNumber: 2,
        phaseName: 'Phase 2: Building Consistency',
        description: 'Reinforce gym habits, introduce light dumbbells, practice exercise technique, and learn recovery basics.',
        nutritionFocus: 'Adequate daily protein (1.8g/kg) and consistent pre/post-workout meal timing.',
        weeks: [
          _generateBeginnerWeek2(),
        ],
      ),
      // Phase 3: Building Strength (Week 3 / Days 15-21)
      TransformationPhase(
        phaseNumber: 3,
        phaseName: 'Phase 3: Building Strength',
        description: 'Introduce simple resistance exercises, slightly increase difficulty, and learn how to record sets and reps.',
        nutritionFocus: 'Balanced complex carbohydrates for steady energy before and after training.',
        weeks: [
          _generateBeginnerWeek3(),
        ],
      ),
      // Phase 4: Developing Independence & 30-Day Graduation (Weeks 4-5 / Days 22-30)
      TransformationPhase(
        phaseNumber: 4,
        phaseName: 'Phase 4: Independence & 30-Day Graduation',
        description: 'Develop workout autonomy, understand programming basics, and complete your 30-day assessment and graduation.',
        nutritionFocus: 'Long-term healthy nutritional lifestyle and preparation for specialized goal nutrition.',
        weeks: [
          _generateBeginnerWeek4(),
          _generateBeginnerWeek5(),
        ],
      ),
    ],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // 1. 60-DAY WEIGHT LOSS CHALLENGE
  // ──────────────────────────────────────────────────────────────────────────
  static final TransformationPlanBlueprint weightLoss60 = TransformationPlanBlueprint(
    id: 'weight_loss_60',
    title: '60-Day Weight Loss Challenge',
    subtitle: 'Ignite fat loss, boost conditioning & build lean athletic definition',
    description:
        'A high-efficiency, progressive 60-day fat loss programme combining compound strength training, metabolic conditioning, and structured deficit nutrition.',
    durationDays: 60,
    goal: 'LOSE',
    difficulty: 'Beginner to Intermediate',
    gradientColorHex: '0xFFFF5E36', // Vibrant Orange-Red
    iconEmoji: '🔥',
    highlights: [
      '4 Resistance & Conditioning Sessions per Week',
      'Sustainable Caloric Deficit & High-Protein Guidance',
      '3 Dedicated Active Recovery & Rest Days per Week',
      'Home or Gym Equipment Flexibility with Alternatives',
      'Graduation Guidance: Maintenance, Muscle, or Strength',
    ],
    phases: [
      // Phase 1: Foundation (Weeks 1-2)
      TransformationPhase(
        phaseNumber: 1,
        phaseName: 'Phase 1: Foundation & Metabolic Prep',
        description: 'Establish consistent gym habits, prime movement patterns, and kickstart fat oxidation.',
        nutritionFocus: '20% Caloric deficit with 2.0g protein/kg to protect lean muscle mass.',
        weeks: [
          _generateWeightLossWeek(1, 'Movement Calibration & Baseline Cardio'),
          _generateWeightLossWeek(2, 'Metabolic Work Capacity & Core Stability'),
        ],
      ),
      // Phase 2: Fat Burn (Weeks 3-4)
      TransformationPhase(
        phaseNumber: 2,
        phaseName: 'Phase 2: Accelerated Fat Burn',
        description: 'Increase training density and super-charge daily energy expenditure.',
        nutritionFocus: 'Hydration focus: 3L+ water daily and consistent whole-food nutrition.',
        weeks: [
          _generateWeightLossWeek(3, 'Superset Conditioning & Volume Increase'),
          _generateWeightLossWeek(4, 'Mid-Point Metabolic Test & Re-feed Guidance'),
        ],
      ),
      // Phase 3: Conditioning (Weeks 5-6)
      TransformationPhase(
        phaseNumber: 3,
        phaseName: 'Phase 3: High-Density Conditioning',
        description: 'Shorter rest intervals and intensified compound resistance circuits.',
        nutritionFocus: 'Strict macro adherence: prioritize fibrous carbohydrates and lean proteins.',
        weeks: [
          _generateWeightLossWeek(5, 'Peak Circuit Intensity & Core Definition'),
          _generateWeightLossWeek(6, 'High-Tempo Resistance & Tonnage Retention'),
        ],
      ),
      // Phase 4: Final Push (Weeks 7-9 / Days 43-60)
      TransformationPhase(
        phaseNumber: 4,
        phaseName: 'Phase 4: Final Definition & Peak Recomp',
        description: 'Maximal fat reduction and athletic muscle definition for final transformation reveal.',
        nutritionFocus: 'Final deficit push with clean re-feeds and electrolyte balance.',
        weeks: [
          _generateWeightLossWeek(7, 'Maximum Glycogen Depletion & Fat Strip'),
          _generateWeightLossWeek(8, 'Finishing Touches, Peak Photo & Final Weigh-in'),
          _generateWeightLossWeek(9, 'Transformation Celebration & Maintenance Prep'),
        ],
      ),
    ],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // 2. 90-DAY MUSCLE BUILDING CHALLENGE
  // ──────────────────────────────────────────────────────────────────────────
  static final TransformationPlanBlueprint muscleBuilding90 = TransformationPlanBlueprint(
    id: 'muscle_building_90',
    title: '90-Day Muscle Building Challenge',
    subtitle: 'Pack on dense lean muscle with structured hypertrophy periodization',
    description:
        'A comprehensive 3-month hypertrophy curriculum designed to maximize mechanical tension, muscle protein synthesis, and full-body muscular development.',
    durationDays: 90,
    goal: 'GAIN',
    difficulty: 'Beginner to Intermediate',
    gradientColorHex: '0xFF2F6BFF', // Electric Blue
    iconEmoji: '⚡',
    highlights: [
      'Structured 4-5 Day Hypertrophy Split (40-50 min)',
      '10-15% Clean Caloric Surplus & 2.0g Protein/kg',
      'Progressive Overload Tracking & 1RM Monitoring',
      'Scheduled Deload Weeks (Weeks 4 & 8) for Recovery',
      'Gym & Home Dumbbell Equipment Flexibility',
    ],
    phases: [
      // Phase 1: Base Hypertrophy (Weeks 1-4)
      TransformationPhase(
        phaseNumber: 1,
        phaseName: 'Phase 1: Foundation Hypertrophy',
        description: 'Master compound movements and build neuromuscular efficiency for growth.',
        nutritionFocus: '10-15% Caloric surplus with 2.0g protein/kg for clean bulking.',
        weeks: [
          _generateHypertrophyWeek(1, 'Baseline Volume & Form Alignment'),
          _generateHypertrophyWeek(2, 'Progressive Load Ramping'),
          _generateHypertrophyWeek(3, 'Mechanical Tension Build'),
          _generateHypertrophyWeek(4, 'Phase 1 Deload & Growth Consolidation'),
        ],
      ),
      // Phase 2: Maximum Volume (Weeks 5-8)
      TransformationPhase(
        phaseNumber: 2,
        phaseName: 'Phase 2: Maximum Hypertrophic Volume',
        description: 'High volume push-pull-legs stimulus targeting maximum sarcoplasmic hypertrophy.',
        nutritionFocus: 'Consistent nutrient timing: post-workout carbs and protein synthesis peaks.',
        weeks: [
          _generateHypertrophyWeek(5, 'Volume Accumulation – Upper/Lower Focus'),
          _generateHypertrophyWeek(6, 'High Rep-Range Pump & Blood Flow'),
          _generateHypertrophyWeek(7, 'Peak Weekly Tonnage Overload'),
          _generateHypertrophyWeek(8, 'Active Recovery & Mid-Plan Checkpoint'),
        ],
      ),
      // Phase 3: Peak Mass & Density (Weeks 9-13)
      TransformationPhase(
        phaseNumber: 3,
        phaseName: 'Phase 3: Peak Mass & Density',
        description: 'Heavy compound loads followed by targeted isolation supersets for deep muscle maturity.',
        nutritionFocus: 'Peak caloric support with clean unrefined carbs and essential fatty acids.',
        weeks: [
          _generateHypertrophyWeek(9, 'Heavy Tension & Muscle Density'),
          _generateHypertrophyWeek(10, 'Targeted Muscle Isolation Blast'),
          _generateHypertrophyWeek(11, 'Peak Overload Week – Personal Records'),
          _generateHypertrophyWeek(12, 'Final Hypertrophic Surge'),
          _generateHypertrophyWeek(13, 'Transformation Results & Measurement Reveal'),
        ],
      ),
    ],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // 3. 12-WEEK STRENGTH BUILDING CHALLENGE
  // ──────────────────────────────────────────────────────────────────────────
  static final TransformationPlanBlueprint strength12Week = TransformationPlanBlueprint(
    id: 'strength_12_week',
    title: '12-Week Strength Building Challenge',
    subtitle: 'Skyrocket your Squat, Bench, and Deadlift with periodized strength training',
    description:
        'An uncompromising 12-week powerbuilding curriculum designed to build raw tendon strength, core stability, and breakthrough numbers on major compound lifts.',
    durationDays: 84, // 12 weeks × 7 days
    goal: 'STRENGTH',
    difficulty: 'Intermediate',
    gradientColorHex: '0xFF9B51E0', // Deep Royal Purple
    iconEmoji: '🏆',
    highlights: [
      'Structured 4-Day Strength & Power Split (45-55 min)',
      'Linear Periodization for Squat, Bench & Deadlift',
      'Estimated 1RM Tracking & PR Vault Integration',
      'Scheduled Deload Weeks (Weeks 4, 8 & 11) for CNS Reset',
      'Commercial Gym & Home Dumbbell Equipment Adaptation',
    ],
    phases: [
      // Phase 1: Technique & Work Capacity (Weeks 1-4)
      TransformationPhase(
        phaseNumber: 1,
        phaseName: 'Phase 1: Technical Mastery & Work Capacity',
        description: 'Hone barbell bar path, core bracing, and establish verified 1RM starting baselines.',
        nutritionFocus: 'Maintenance or slight 5% surplus with balanced micronutrients and creatine.',
        weeks: [
          _generateStrengthWeek(1, 'Barbell Setup & Baseline 1RM Calibration'),
          _generateStrengthWeek(2, 'Volume Accumulation (5x5 Compound Focus)'),
          _generateStrengthWeek(3, 'Load Progression & Scapular/Hip Stability'),
          _generateStrengthWeek(4, 'Scheduled Deload & Central Nervous System Recovery'),
        ],
      ),
      // Phase 2: Heavy Load Accumulation (Weeks 5-8)
      TransformationPhase(
        phaseNumber: 2,
        phaseName: 'Phase 2: Heavy Load Progression',
        description: 'Shift from 5-rep sets down to heavy 3-rep sets at 80-85% 1RM.',
        nutritionFocus: 'Pre-workout intra-workout carb fueling to maximize heavy lifting output.',
        weeks: [
          _generateStrengthWeek(5, 'Sub-Maximal Heavy 4-Rep Protocol'),
          _generateStrengthWeek(6, 'High-Intensity Overload & Bar Velocity'),
          _generateStrengthWeek(7, '3-Rep Heavy Strength Wave'),
          _generateStrengthWeek(8, 'Pre-Peak CNS Deload Week'),
        ],
      ),
      // Phase 3: Peak Strength & PR Testing (Weeks 9-12)
      TransformationPhase(
        phaseNumber: 3,
        phaseName: 'Phase 3: Peak Strength & 1RM Breakthrough',
        description: 'Taper volume and maximize intensity to test and smash all-time personal records.',
        nutritionFocus: 'Peak recovery nutrition: sleep, hydration, and high-protein intake.',
        weeks: [
          _generateStrengthWeek(9, 'Heavy Doubles (2-Rep Protocol at 90% 1RM)'),
          _generateStrengthWeek(10, 'Singles Preparation & Neural Potentiation'),
          _generateStrengthWeek(11, 'Deload & Mental Readiness Taper'),
          _generateStrengthWeek(12, 'PR Test Day: Squat, Bench & Deadlift Maxes'),
        ],
      ),
    ],
  );

  /// Primary transformation programmes (prominently featured)
  static List<TransformationPlanBlueprint> get primaryPlans => [
        beginnerFitness30,
        weightLoss60,
        muscleBuilding90,
      ];

  /// Specialised / Advanced transformation programmes
  static List<TransformationPlanBlueprint> get specialisedPlans => [
        strength12Week,
      ];

  /// All available transformation programmes
  static List<TransformationPlanBlueprint> get allPlans => [
        beginnerFitness30,
        weightLoss60,
        muscleBuilding90,
        strength12Week,
      ];

  /// Find plan by ID with null safety
  static TransformationPlanBlueprint? getById(String id) {
    try {
      return allPlans.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Default milestones generator for a programme
  static List<TransformationMilestone> createDefaultMilestones(TransformationPlanBlueprint plan) {
    if (plan.id == 'beginner_fitness_30') {
      return const [
        TransformationMilestone(
          id: 'beg_day_7',
          title: 'First Week Champion',
          description: 'Completed your first 7 days of movement calibration and healthy habits!',
          triggerDay: 7,
        ),
        TransformationMilestone(
          id: 'beg_day_14',
          title: 'Habit Builder',
          description: 'Two consecutive weeks of consistent movement and logging. Routine unlocked!',
          triggerDay: 14,
        ),
        TransformationMilestone(
          id: 'beg_day_21',
          title: 'Form & Strength Master',
          description: 'Three weeks strong! Movement patterns feel natural and confidence is high.',
          triggerDay: 21,
        ),
        TransformationMilestone(
          id: 'beg_day_30',
          title: '30-Day Fitness Graduate',
          description: 'Congratulations! You completed the 30-day foundation. Ready to level up!',
          triggerDay: 30,
        ),
      ];
    } else if (plan.id == 'weight_loss_60') {
      return const [
        TransformationMilestone(
          id: 'wl_day_7',
          title: 'Week 1 Survivor',
          description: 'Completed your first 7 days of structured fat loss training!',
          triggerDay: 7,
        ),
        TransformationMilestone(
          id: 'wl_day_14',
          title: 'Consistency Locked',
          description: 'Two weeks of uninterrupted nutrition and workouts logged.',
          triggerDay: 14,
        ),
        TransformationMilestone(
          id: 'wl_day_30',
          title: 'Mid-Way Champion',
          description: 'Halfway point! First milestone progress photos and weigh-in check.',
          triggerDay: 30,
        ),
        TransformationMilestone(
          id: 'wl_day_45',
          title: 'Definition Peak',
          description: 'Entering the final definition phase with high metabolic momentum.',
          triggerDay: 45,
        ),
        TransformationMilestone(
          id: 'wl_day_60',
          title: '60-Day Transformation Master',
          description: 'You transformed your body, discipline, and daily lifestyle. Bravo!',
          triggerDay: 60,
        ),
      ];
    } else if (plan.id == 'muscle_building_90') {
      return const [
        TransformationMilestone(
          id: 'mb_day_7',
          title: 'Foundation Laid',
          description: 'First week of high-volume hypertrophy finished strong.',
          triggerDay: 7,
        ),
        TransformationMilestone(
          id: 'mb_day_30',
          title: 'Base Built',
          description: 'Phase 1 complete! Noticeable shoulder and chest fullness.',
          triggerDay: 30,
        ),
        TransformationMilestone(
          id: 'mb_day_60',
          title: 'Volume Master',
          description: 'Two full months of hypertrophy overload and nutrition adherence.',
          triggerDay: 60,
        ),
        TransformationMilestone(
          id: 'mb_day_90',
          title: 'Titan Physique',
          description: '90 Days of serious muscle building completed. Legendary dedication!',
          triggerDay: 90,
        ),
      ];
    } else {
      // Strength 12-week
      return const [
        TransformationMilestone(
          id: 'st_day_7',
          title: 'Form Master',
          description: 'Week 1 barbell baselines verified and recorded.',
          triggerDay: 7,
        ),
        TransformationMilestone(
          id: 'st_day_28',
          title: 'Technique Mastered',
          description: 'Phase 1 complete! Solid core bracing and linear progress.',
          triggerDay: 28,
        ),
        TransformationMilestone(
          id: 'st_day_56',
          title: 'Heavy Lifter',
          description: 'Phase 2 complete! Working sets now above 80% of your starting max.',
          triggerDay: 56,
        ),
        TransformationMilestone(
          id: 'st_day_84',
          title: 'Strength Record Breaker',
          description: '12 Weeks done! New personal bests recorded on major compound lifts.',
          triggerDay: 84,
        ),
      ];
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // INTERNAL WEEK GENERATORS
  // ──────────────────────────────────────────────────────────────────────────

  static TransformationWeekBlueprint _generateBeginnerWeek1() {
    return TransformationWeekBlueprint(
      weekNumber: 1,
      focus: 'Movement Patterns & Form Guidance',
      weekTip: 'Focus on clean technique and full control on every repetition. Never rush through reps.',
      days: [
        TransformationDayBlueprint(
          dayIndex: 1,
          dayType: 'workout',
          muscleGroup: 'Full Body Movement Baseline A',
          exerciseNames: const [
            'Deep Pushups',
            'Dumbbell Goblet Squat',
            'Twisting Crunch',
          ],
          targetSets: 3,
          targetReps: '8-10',
          notes: 'Master controlled movement tempo and complete range of motion. Beginner tip: knee pushups are welcome. Rest 60-90s between sets.',
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Full Body Movement Baseline A'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Full Body Movement Baseline A'),
        ),
        const TransformationDayBlueprint(
          dayIndex: 2,
          dayType: 'active_recovery',
          muscleGroup: 'Active Recovery & Hydration',
          exerciseNames: [],
          notes: 'Take a relaxed 20–30 minute walk outdoors or on treadmill. Hydrate with 2.5L water.',
        ),
        TransformationDayBlueprint(
          dayIndex: 3,
          dayType: 'workout',
          muscleGroup: 'Full Body Movement Baseline B',
          exerciseNames: const [
            'Cable Seated Row',
            'Dumbbell Lunge',
            'Air Twist Crunch',
          ],
          targetSets: 3,
          targetReps: '8-10',
          notes: 'Keep shoulders pulled down, back flat, and maintain gentle core bracing.',
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Full Body Movement Baseline B'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Full Body Movement Baseline B'),
        ),
        const TransformationDayBlueprint(
          dayIndex: 4,
          dayType: 'rest',
          muscleGroup: 'Rest & Mobility Stretch',
          exerciseNames: [],
          notes: 'Complete rest day. Perform 5–10 minutes of light gentle stretching.',
        ),
        TransformationDayBlueprint(
          dayIndex: 5,
          dayType: 'workout',
          muscleGroup: 'Full Body Foundation Circuit',
          exerciseNames: const [
            'Dumbbell Bent Over Row',
            'Leg Press',
            'Dumbbell Bench Seated Press',
          ],
          targetSets: 3,
          targetReps: '8-10',
          notes: 'Smooth, continuous reps. Focus on building mind-muscle connection.',
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Full Body Foundation Circuit'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Full Body Foundation Circuit'),
        ),
        const TransformationDayBlueprint(
          dayIndex: 6,
          dayType: 'active_recovery',
          muscleGroup: 'Active Recovery Walk',
          exerciseNames: [],
          notes: 'Casual 20–30 min stroll to enhance blood flow and reduce stiffness.',
        ),
        const TransformationDayBlueprint(
          dayIndex: 7,
          dayType: 'rest',
          muscleGroup: 'Week 1 Habit Review & Rest',
          exerciseNames: [],
          notes: 'First week completed! Reflect on how your body feels and prepare for Week 2.',
        ),
      ],
    );
  }

  static TransformationWeekBlueprint _generateBeginnerWeek2() {
    return TransformationWeekBlueprint(
      weekNumber: 2,
      focus: 'Beginner Full-Body & Equipment Basics',
      weekTip: 'Select light weights where the final 2 reps feel moderately challenging but form stays immaculate.',
      days: [
        TransformationDayBlueprint(
          dayIndex: 1,
          dayType: 'workout',
          muscleGroup: 'Full Body Dumbbell Basics A',
          exerciseNames: const [
            'Dumbbell Goblet Squat',
            'Incline Dumbbell Press',
            'Dumbbell Bent Over Row',
          ],
          targetSets: 3,
          targetReps: '10',
          notes: 'Lower the weights with a steady 2-second tempo. Breathe rhythmically.',
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Full Body Dumbbell Basics A'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Full Body Dumbbell Basics A'),
        ),
        const TransformationDayBlueprint(
          dayIndex: 2,
          dayType: 'active_recovery',
          muscleGroup: '20-Minute Brisk Walk',
          exerciseNames: [],
          notes: 'Aim for 6,000–8,000 steps and light upper-body rotations.',
        ),
        TransformationDayBlueprint(
          dayIndex: 3,
          dayType: 'workout',
          muscleGroup: 'Full Body Dumbbell Basics B',
          exerciseNames: const [
            'Dumbbell Lunge',
            'Cable Seated Row',
            'Dumbbell Arnold Press',
          ],
          targetSets: 3,
          targetReps: '10',
          notes: 'Keep core engaged and posture upright throughout all dumbbell presses.',
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Full Body Dumbbell Basics B'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Full Body Dumbbell Basics B'),
        ),
        const TransformationDayBlueprint(
          dayIndex: 4,
          dayType: 'rest',
          muscleGroup: 'Mid-Week Rest & Recovery',
          exerciseNames: [],
          notes: 'Quality sleep and rest allow your muscular and nervous system to adapt.',
        ),
        TransformationDayBlueprint(
          dayIndex: 5,
          dayType: 'workout',
          muscleGroup: 'Posterior Chain & Core Stability',
          exerciseNames: const [
            'Leg Press',
            'Deep Pushups',
            'Twisting Crunch',
            'Lying Leg Curl',
          ],
          targetSets: 3,
          targetReps: '10',
          notes: 'Feel your hamstrings and abdominal wall working together.',
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Posterior Chain & Core Stability'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Posterior Chain & Core Stability'),
        ),
        const TransformationDayBlueprint(
          dayIndex: 6,
          dayType: 'active_recovery',
          muscleGroup: 'Mobility Stretches & Walking',
          exerciseNames: [],
          notes: 'Gentle hips and hamstring mobility routine + 20 min walk.',
        ),
        const TransformationDayBlueprint(
          dayIndex: 7,
          dayType: 'rest',
          muscleGroup: 'Two-Week Habit Check-in',
          exerciseNames: [],
          notes: 'Two weeks of consistent workouts logged! Two more weeks to graduation.',
        ),
      ],
    );
  }

  static TransformationWeekBlueprint _generateBeginnerWeek3() {
    return TransformationWeekBlueprint(
      weekNumber: 3,
      focus: 'Progressive Resistance & Workout Logging',
      weekTip: 'Record every completed set and rep in the session tracker. Tracking builds confidence!',
      days: [
        TransformationDayBlueprint(
          dayIndex: 1,
          dayType: 'workout',
          muscleGroup: 'Progressive Resistance Intro A',
          exerciseNames: const [
            'Barbell Bench Press',
            'Classic Barbell Squat',
            'Cable Seated Row',
          ],
          targetSets: 3,
          targetReps: '8-10',
          notes: 'Log your starting weights in the app. Maintain strict bar paths.',
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Progressive Resistance Intro A'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Progressive Resistance Intro A'),
        ),
        const TransformationDayBlueprint(
          dayIndex: 2,
          dayType: 'active_recovery',
          muscleGroup: 'Active Recovery Walk & Stretch',
          exerciseNames: [],
          notes: '25 min outdoor walk and gentle leg stretches.',
        ),
        TransformationDayBlueprint(
          dayIndex: 3,
          dayType: 'workout',
          muscleGroup: 'Progressive Resistance Intro B',
          exerciseNames: const [
            'Dumbbell Bench Seated Press',
            'Dumbbell Sumo Squat',
            'Dumbbell Biceps Curl',
          ],
          targetSets: 3,
          targetReps: '8-10',
          notes: 'No swinging on curls or presses. Strict form isolates target muscles.',
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Progressive Resistance Intro B'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Progressive Resistance Intro B'),
        ),
        const TransformationDayBlueprint(
          dayIndex: 4,
          dayType: 'rest',
          muscleGroup: 'Muscular Recuperation',
          exerciseNames: [],
          notes: 'Full recovery day. Focus on nutritious meals and hydration.',
        ),
        TransformationDayBlueprint(
          dayIndex: 5,
          dayType: 'workout',
          muscleGroup: 'Full Body Strength & Core Confidence',
          exerciseNames: const [
            'Lever Chest Press',
            'Lying Leg Curl',
            'Close Grip Push-up',
            'Air Twist Crunch',
          ],
          targetSets: 3,
          targetReps: '10',
          notes: 'Push comfortably to 1-2 reps shy of technical failure.',
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Full Body Strength & Core Confidence'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Full Body Strength & Core Confidence'),
        ),
        const TransformationDayBlueprint(
          dayIndex: 6,
          dayType: 'active_recovery',
          muscleGroup: 'Outdoor Walk & Mobility',
          exerciseNames: [],
          notes: '30-minute refreshing walk to support recovery.',
        ),
        const TransformationDayBlueprint(
          dayIndex: 7,
          dayType: 'rest',
          muscleGroup: 'Week 3 Check-in & Rest',
          exerciseNames: [],
          notes: '3 weeks done! You are now in the final phase of the beginner foundation.',
        ),
      ],
    );
  }

  static TransformationWeekBlueprint _generateBeginnerWeek4() {
    return TransformationWeekBlueprint(
      weekNumber: 4,
      focus: 'Developing Training Independence',
      weekTip: 'Trust your technique and intuition. You now understand exercise pacing and form.',
      days: [
        TransformationDayBlueprint(
          dayIndex: 1,
          dayType: 'workout',
          muscleGroup: 'Autonomous Full Body A',
          exerciseNames: const [
            'Classic Barbell Squat',
            'Dumbbell Hammer Press',
            'Cable Pulldown',
          ],
          targetSets: 3,
          targetReps: '8-10',
          notes: 'Notice how much more natural each exercise feels compared to Day 1.',
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Autonomous Full Body A'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Autonomous Full Body A'),
        ),
        const TransformationDayBlueprint(
          dayIndex: 2,
          dayType: 'active_recovery',
          muscleGroup: 'Active Recovery Walk',
          exerciseNames: [],
          notes: '20–30 min brisk walk to keep muscles supple.',
        ),
        TransformationDayBlueprint(
          dayIndex: 3,
          dayType: 'workout',
          muscleGroup: 'Autonomous Full Body B',
          exerciseNames: const [
            'Dumbbell Goblet Squat',
            'Deep Pushups',
            'Cable Seated Row',
          ],
          targetSets: 3,
          targetReps: '8-10',
          notes: 'Pristine execution on pushups and squats. Full control.',
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Autonomous Full Body B'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Autonomous Full Body B'),
        ),
        const TransformationDayBlueprint(
          dayIndex: 4,
          dayType: 'rest',
          muscleGroup: 'Rest & Mental Preparation',
          exerciseNames: [],
          notes: 'Rest, hydrate, and prepare for your final workouts and assessment.',
        ),
        TransformationDayBlueprint(
          dayIndex: 5,
          dayType: 'workout',
          muscleGroup: 'Autonomous Full Body C',
          exerciseNames: const [
            'Leg Press',
            'Dumbbell Arnold Press',
            'Twisting Crunch',
          ],
          targetSets: 3,
          targetReps: '10',
          notes: 'Final regular full-body training session of the core 4 weeks!',
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Autonomous Full Body C'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Autonomous Full Body C'),
        ),
        const TransformationDayBlueprint(
          dayIndex: 6,
          dayType: 'active_recovery',
          muscleGroup: 'Gentle Walk & Stretch',
          exerciseNames: [],
          notes: 'Light stroll and hamstring/chest stretches.',
        ),
        const TransformationDayBlueprint(
          dayIndex: 7,
          dayType: 'rest',
          muscleGroup: 'Pre-Assessment Rest',
          exerciseNames: [],
          notes: 'Rest fully before the Days 29-30 final benchmark & graduation.',
        ),
      ],
    );
  }

  static TransformationWeekBlueprint _generateBeginnerWeek5() {
    return TransformationWeekBlueprint(
      weekNumber: 5,
      focus: 'Assessment & 30-Day Graduation',
      weekTip: 'Celebrate your dedication! 30 days of consistent training is a massive milestone.',
      days: [
        TransformationDayBlueprint(
          dayIndex: 1,
          dayType: 'workout',
          muscleGroup: '30-Day Fitness Benchmark Assessment',
          exerciseNames: const [
            'Deep Pushups',
            'Dumbbell Goblet Squat',
            'Twisting Crunch',
          ],
          targetSets: 3,
          targetReps: '8-12 Clean Reps',
          notes: 'Test your endurance and compare your strength and form against your Day 1 baseline!',
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('30-Day Fitness Benchmark Assessment'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('30-Day Fitness Benchmark Assessment'),
        ),
        const TransformationDayBlueprint(
          dayIndex: 2,
          dayType: 'active_recovery',
          muscleGroup: '30-Day Graduation & Next Steps',
          exerciseNames: [],
          notes: 'Congratulations on completing 30 days! You built a real fitness habit. Tap to finalize and choose your next path.',
        ),
      ],
    );
  }

  static TransformationWeekBlueprint _generateWeightLossWeek(int weekNum, String focus) {
    int targetSets;
    String targetReps;
    String weekTip;
    String day1Notes;
    String day2Notes;
    String day4Notes;
    String day5Notes;

    if (weekNum <= 2) {
      // Phase 1: Foundation (Weeks 1-2)
      targetSets = 3;
      targetReps = '12-15';
      weekTip = 'Keep rest times around 60 seconds to build metabolic work capacity and perfect movement mechanics.';
      day1Notes = 'Movement calibration: 3 sets with explosive concentrics and 60s rest.';
      day2Notes = 'Upper body tempo: controlled 2s eccentric and 60s rest.';
      day4Notes = 'Lower body form: controlled depth and rhythmic breathing.';
      day5Notes = 'Foundation finish: core engagement and metabolic tempo.';
    } else if (weekNum == 3) {
      // Phase 2: Accelerated Fat Burn - Volume Bump (Week 3)
      targetSets = 4;
      targetReps = '12-15';
      weekTip = 'Shorten rest periods to 45 seconds to maximize metabolic fatigue and caloric afterburn.';
      day1Notes = 'Density increase: 4 sets with 45s rest to drive high metabolic output.';
      day2Notes = 'Upper conditioning: 4 sets, focus on squeezing target muscles with short rest.';
      day4Notes = 'Leg & core burn: 4 sets, steady tempo with 45s rest.';
      day5Notes = 'Full body sprint: 4 sets, high heart rate conditioning.';
    } else if (weekNum == 4) {
      // Phase 2: Mid-Plan Recovery & Consolidation (Week 4)
      targetSets = 2; // Mid-plan consolidation week
      targetReps = '12';
      weekTip = 'Mid-plan consolidation week! Reduced volume (2 sets) allows joint recovery while maintaining metabolic momentum.';
      day1Notes = 'Recovery week: 2 crisp sets at 60s rest. Focus on technique and joint comfort.';
      day2Notes = 'Active consolidation: 2 sets per movement. Avoid pushing to technical failure.';
      day4Notes = 'Consolidation leg work: 2 smooth sets. Focus on blood flow and range of motion.';
      day5Notes = 'Recovery circuit finish: 2 light sets, preparing the body for Phase 3.';
    } else if (weekNum <= 6) {
      // Phase 3: High-Density Conditioning (Weeks 5-6)
      targetSets = 4;
      targetReps = '15';
      weekTip = 'High-density circuits: Rest strictly 40 seconds to ignite maximum EPOC (excess post-exercise oxygen consumption).';
      day1Notes = 'Circuit density: 4 sets of 15 reps with 40s rest intervals.';
      day2Notes = 'Upper hypertrophy conditioning: 4 sets of 15 reps, fast transitions.';
      day4Notes = 'High-rep leg burn: 4 sets of 15 reps, explosive drive.';
      day5Notes = 'Peak conditioning: 4 sets of 15 reps to failure on the last set.';
    } else if (weekNum <= 8) {
      // Phase 4: Final Definition Push (Weeks 7-8)
      targetSets = 4;
      targetReps = '12-15';
      weekTip = 'Final definition push: Maximum effort and full muscle contractions to preserve every ounce of lean mass.';
      day1Notes = 'Maximal fat stripping: 4 high-effort sets, leaving zero reps in reserve.';
      day2Notes = 'Upper body chiseling: 4 sets with 45s rest for tight muscle definition.';
      day4Notes = 'Lower body striations: 4 sets, deep stretch and full lockout.';
      day5Notes = 'Max depletion: 4 challenging sets to empty remaining glycogen stores.';
    } else {
      // Week 9: Transition & Maintenance Prep
      targetSets = 3;
      targetReps = '12';
      weekTip = 'Celebrate your 60-day fat loss milestone and prepare for post-challenge sustainable maintenance.';
      day1Notes = 'Peak week workout: 3 sets, crisp form and proud intensity.';
      day2Notes = 'Maintenance calibration: 3 sets, focusing on muscle fullness.';
      day4Notes = 'Final lower body session: 3 sets, celebrate your newly built leg strength.';
      day5Notes = 'Graduation session: 3 sets, finish your 60-day transformation in style!';
    }

    if (weekNum == 9) {
      return TransformationWeekBlueprint(
        weekNumber: 9,
        focus: focus,
        weekTip: weekTip,
        days: [
          TransformationDayBlueprint(
            dayIndex: 1,
            dayType: 'workout',
            muscleGroup: 'Full Body Metabolic Blast',
            exerciseNames: const [
              'Barbell Bench Press',
              'Dumbbell Lunge',
              'Cable Pulldown',
              'Twisting Crunch',
            ],
            targetSets: targetSets,
            targetReps: targetReps,
            notes: day1Notes,
            warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Full Body Metabolic Blast'),
            cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Full Body Metabolic Blast'),
          ),
          TransformationDayBlueprint(
            dayIndex: 2,
            dayType: 'workout',
            muscleGroup: 'Upper Body Conditioning & Core',
            exerciseNames: const [
              'Incline Dumbbell Press',
              'Cable Seated Row',
              'Dumbbell Seated Lateral Raise',
              'Air Twist Crunch',
            ],
            targetSets: targetSets,
            targetReps: targetReps,
            notes: day2Notes,
            warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Upper Body Conditioning & Core'),
            cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Upper Body Conditioning & Core'),
          ),
          const TransformationDayBlueprint(
            dayIndex: 3,
            dayType: 'active_recovery',
            muscleGroup: 'Active Recovery Walk & Final Measurements',
            exerciseNames: [],
            notes: '30 min brisk walk, record final body measurements and prepare for transformation celebration.',
          ),
          const TransformationDayBlueprint(
            dayIndex: 4,
            dayType: 'active_recovery',
            muscleGroup: '60-Day Transformation Celebration & Next Steps',
            exerciseNames: [],
            notes: 'Congratulations on finishing 60 days! Tap below to finalize your transformation and choose your next goal.',
          ),
        ],
      );
    }

    return TransformationWeekBlueprint(
      weekNumber: weekNum,
      focus: focus,
      weekTip: weekTip,
      days: [
        TransformationDayBlueprint(
          dayIndex: 1,
          dayType: 'workout',
          muscleGroup: 'Full Body Metabolic Blast',
          exerciseNames: const [
            'Barbell Bench Press',
            'Dumbbell Lunge',
            'Cable Pulldown',
            'Twisting Crunch',
          ],
          targetSets: targetSets,
          targetReps: targetReps,
          notes: day1Notes,
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Full Body Metabolic Blast'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Full Body Metabolic Blast'),
        ),
        TransformationDayBlueprint(
          dayIndex: 2,
          dayType: 'workout',
          muscleGroup: 'Upper Body Conditioning & Core',
          exerciseNames: const [
            'Incline Dumbbell Press',
            'Cable Seated Row',
            'Dumbbell Seated Lateral Raise',
            'Air Twist Crunch',
          ],
          targetSets: targetSets,
          targetReps: targetReps,
          notes: day2Notes,
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Upper Body Conditioning & Core'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Upper Body Conditioning & Core'),
        ),
        const TransformationDayBlueprint(
          dayIndex: 3,
          dayType: 'active_recovery',
          muscleGroup: 'Active Recovery & Mobility',
          exerciseNames: [],
          notes: 'Aim for 8,000–10,000 steps and light lower-body stretching.',
        ),
        TransformationDayBlueprint(
          dayIndex: 4,
          dayType: 'workout',
          muscleGroup: 'Lower Body & Core Burn',
          exerciseNames: const [
            'Classic Barbell Squat',
            'Leg Extension',
            'Lying Leg Curl',
            'Twisting Crunch',
          ],
          targetSets: targetSets,
          targetReps: targetReps,
          notes: day4Notes,
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Lower Body & Core Burn'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Lower Body & Core Burn'),
        ),
        TransformationDayBlueprint(
          dayIndex: 5,
          dayType: 'workout',
          muscleGroup: 'High-Intensity Full Body Finish',
          exerciseNames: const [
            'Deep Pushups',
            'Dumbbell Bent Over Row',
            'Dumbbell Goblet Squat',
            'Air Twist Crunch',
          ],
          targetSets: targetSets,
          targetReps: targetReps,
          notes: day5Notes,
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('High-Intensity Full Body Finish'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('High-Intensity Full Body Finish'),
        ),
        const TransformationDayBlueprint(
          dayIndex: 6,
          dayType: 'rest',
          muscleGroup: 'Rest & Nutrient Replenishment',
          exerciseNames: [],
          notes: 'Hydrate well, hit daily protein goal, and rest.',
        ),
        const TransformationDayBlueprint(
          dayIndex: 7,
          dayType: 'rest',
          muscleGroup: 'Weekly Check-in & Rest',
          exerciseNames: [],
          notes: 'Log your morning weight and review your nutrition adherence.',
        ),
      ],
    );
  }

  static TransformationWeekBlueprint _generateHypertrophyWeek(int weekNum, String focus) {
    int targetSets;
    String targetReps;
    String weekTip;
    String chestNotes;
    String backNotes;
    String legNotes;
    String shoulderNotes;

    final isDeload = weekNum == 4 || weekNum == 8;

    if (isDeload) {
      // Deload Weeks 4 and 8: Reduced volume (2 sets per exercise)
      targetSets = 2;
      targetReps = '8-10';
      weekTip = 'Deload Week! Reduced volume (2 sets, RPE 6-7) dissipates accumulated systemic fatigue and resensitizes muscle tissue.';
      chestNotes = 'Deload Chest: 2 sets at RPE 6-7. Focus on clean movement tempo without pushing to failure.';
      backNotes = 'Deload Back: 2 sets at RPE 6-7. Clean scapular retraction and light pump.';
      legNotes = 'Deload Legs: 2 sets at RPE 6-7. Maintain joint lubrication and mobility.';
      shoulderNotes = 'Deload Shoulders & Arms: 2 sets at RPE 6-7. Promote recovery for the next heavy phase.';
    } else if (weekNum == 1) {
      // Week 1: Hypertrophy baseline
      targetSets = 3;
      targetReps = '8-12';
      weekTip = 'Establish baseline weights for all compound exercises. Focus on explosive concentric and 2-second eccentric.';
      chestNotes = 'Baseline volume: 3 sets of 8-12 reps. Log starting loads accurately.';
      backNotes = 'Baseline pulling: 3 sets, full lat flare and controlled rows.';
      legNotes = 'Baseline quad & hamstring: 3 sets, hit parallel depth on squats.';
      shoulderNotes = 'Baseline delts & arms: 3 sets, strict overhead form.';
    } else if (weekNum <= 3) {
      // Weeks 2-3: Phase 1 Volume Ramp
      targetSets = 4;
      targetReps = '8-12';
      weekTip = 'Aim to add 1 rep or 1.25kg to your main compound lifts each week for progressive overload.';
      chestNotes = 'Volume accumulation: 4 sets of 8-12 reps. Push each set to 2 reps in reserve.';
      backNotes = 'Back thickness: 4 sets, pull with elbows and squeeze shoulder blades.';
      legNotes = 'Leg hypertrophy: 4 sets of 8-10 reps with powerful leg drive.';
      shoulderNotes = 'Cannonball shoulders: 4 sets of 10-12 reps, strict execution.';
    } else if (weekNum <= 7) {
      // Weeks 5-7: Phase 2 Volume Accumulation
      targetSets = 4;
      targetReps = '8-12';
      weekTip = 'Accumulate quality hypertrophy volume. Ensure protein intake reaches at least 2.0g per kg of bodyweight.';
      chestNotes = 'Overload chest: 4 sets, 8-12 reps, RPE 8-9 on final set.';
      backNotes = 'High-volume back: 4 sets, strict rows and pulldowns with maximal squeeze.';
      legNotes = 'Leg overload: 4 sets, progressive weight increases on squats.';
      shoulderNotes = 'Shoulder hypertrophy: 4 sets, full range lateral raises and presses.';
    } else if (weekNum <= 10) {
      // Weeks 9-10: Phase 3 Heavy Mechanical Tension
      targetSets = 4;
      targetReps = '6-8';
      weekTip = 'Heavier resistance stimulates high-threshold motor units. Rest 90-120 seconds between sets.';
      chestNotes = 'Heavy mechanical tension: 4 sets of 6-8 reps with heavier working weight.';
      backNotes = 'Heavy compound rows: 4 sets of 6-8 reps, strict bracing.';
      legNotes = 'Heavy squat loading: 4 sets of 6-8 reps, explosive drive out of the hole.';
      shoulderNotes = 'Heavy overhead pressing: 4 sets of 6-8 reps, lock out securely.';
    } else if (weekNum == 11) {
      // Week 11: Phase 3 Peak Overload & PR Testing
      targetSets = 4;
      targetReps = '5-6';
      weekTip = 'Test your personal records! Your 10 weeks of progressive overload culminate this week in the PR Vault.';
      chestNotes = 'PR Bench Press attempt: 4 sets of 5-6 reps, push for a new 5RM.';
      backNotes = 'PR Row attempt: 4 sets of 5-6 reps, maximum strength execution.';
      legNotes = 'PR Squat attempt: 4 sets of 5-6 reps, test your lower body power.';
      shoulderNotes = 'PR Overhead Press: 4 sets of 5-6 reps, celebrate your strength gains.';
    } else if (weekNum == 12) {
      // Week 12: Phase 3 Metabolic Overload & Drop Sets
      targetSets = 4;
      targetReps = '10-12';
      weekTip = 'Chase maximal muscle pump and cellular swelling. Final set includes a controlled drop set.';
      chestNotes = 'Metabolic pump: 4 sets of 10-12 reps, 1 drop set on final exercise.';
      backNotes = 'Back blood pooling: 4 sets of 10-12 reps with squeeze holds.';
      legNotes = 'High-rep leg pump: 4 sets of 10-12 reps, deep quadriceps burn.';
      shoulderNotes = '3D delts pump: 4 sets of 10-12 reps with partial reps on last set.';
    } else {
      // Week 13: Final Peak Week & Measurement Reveal
      targetSets = 3;
      targetReps = '8-10';
      weekTip = 'Congratulations on 90 days! Take your final progress photos, log your measurements, and celebrate your gains.';
      chestNotes = 'Peak chest fullness: 3 crisp sets, mind-muscle mastery.';
      backNotes = 'Peak V-taper: 3 crisp sets, showcasing your newly built back width.';
      legNotes = 'Peak lower physique: 3 crisp sets, admire your leg definition.';
      shoulderNotes = 'Final transformation workout: 3 sets, finish your 90-day titan journey!';
    }

    final days = <TransformationDayBlueprint>[
      TransformationDayBlueprint(
        dayIndex: 1,
        dayType: 'workout',
        muscleGroup: 'Chest & Triceps Hypertrophy',
        exerciseNames: const [
          'Barbell Bench Press',
          'Incline Dumbbell Press',
          'Cable Standing Fly',
          'Barbell Close Grip Bench Press',
          'Cable Pushdown',
        ],
        targetSets: targetSets,
        targetReps: targetReps,
        notes: chestNotes,
        warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Chest & Triceps Hypertrophy'),
        cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Chest & Triceps Hypertrophy'),
      ),
      TransformationDayBlueprint(
        dayIndex: 2,
        dayType: 'workout',
        muscleGroup: 'Back & Biceps Thickness',
        exerciseNames: const [
          'Barbell Underhand Bent Over Row',
          'Cable Pulldown',
          'Cable Seated Row',
          'Barbell Curl',
          'Dumbbell Concentration Curl',
        ],
        targetSets: targetSets,
        targetReps: targetReps,
        notes: backNotes,
        warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Back & Biceps Thickness'),
        cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Back & Biceps Thickness'),
      ),
      const TransformationDayBlueprint(
        dayIndex: 3,
        dayType: 'active_recovery',
        muscleGroup: 'Rest & Growth Synthesis',
        exerciseNames: [],
        notes: 'Muscle grows outside the gym. Fuel with high protein and sleep.',
      ),
      TransformationDayBlueprint(
        dayIndex: 4,
        dayType: 'workout',
        muscleGroup: 'Legs & Calves Hypertrophy',
        exerciseNames: const [
          'Classic Barbell Squat',
          'Leg Press',
          'Leg Extension',
          'Lying Leg Curl',
          'Dumbbell Standing Calf Raise',
        ],
        targetSets: targetSets,
        targetReps: targetReps,
        notes: legNotes,
        warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Legs & Calves Hypertrophy'),
        cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Legs & Calves Hypertrophy'),
      ),
      TransformationDayBlueprint(
        dayIndex: 5,
        dayType: 'workout',
        muscleGroup: 'Shoulders & Arms Cannonball',
        exerciseNames: const [
          'Military Press',
          'Dumbbell Seated Lateral Raise',
          'Dumbbell Incline Rear Lateral Raise',
          'Dumbbell Biceps Curl',
          'Dumbbell Incline Triceps Extension',
        ],
        targetSets: targetSets,
        targetReps: targetReps,
        notes: shoulderNotes,
        warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Shoulders & Arms Cannonball'),
        cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Shoulders & Arms Cannonball'),
      ),
    ];

    if (weekNum == 13) {
      days.add(
        const TransformationDayBlueprint(
          dayIndex: 6,
          dayType: 'active_recovery',
          muscleGroup: '90-Day Titan Celebration & Graduation',
          exerciseNames: [],
          notes: 'Congratulations on completing 90 days! Record final body metrics, celebrate personal records, and view your graduation pathways.',
        ),
      );
    } else {
      days.addAll(const [
        TransformationDayBlueprint(
          dayIndex: 6,
          dayType: 'rest',
          muscleGroup: 'Rest & Deep Recovery',
          exerciseNames: [],
          notes: 'Full rest day. Replenish glycogen stores with wholesome carbs.',
        ),
        TransformationDayBlueprint(
          dayIndex: 7,
          dayType: 'rest',
          muscleGroup: 'Weekly Progress & Rest',
          exerciseNames: [],
          notes: 'Review week tonnage and prepare for next week progressive overload.',
        ),
      ]);
    }

    return TransformationWeekBlueprint(
      weekNumber: weekNum,
      focus: focus,
      weekTip: weekTip,
      days: days,
    );
  }

  static TransformationWeekBlueprint _generateStrengthWeek(int weekNum, String focus) {
    int benchSets;
    String benchReps;
    int squatSets;
    String squatReps;
    int deadliftSets;
    String deadliftReps;
    int pressSets;
    String pressReps;
    String weekTip;
    String benchNotes;
    String squatNotes;
    String deadliftNotes;
    String pressNotes;

    final isDeload = weekNum == 4 || weekNum == 8 || weekNum == 11;

    if (isDeload) {
      // Deload Weeks 4, 8, 11: Reduced volume (3 sets) at submaximal RPE 6-7
      benchSets = 3;
      benchReps = '5';
      squatSets = 3;
      squatReps = '5';
      deadliftSets = 3;
      deadliftReps = '5';
      pressSets = 3;
      pressReps = '5';
      weekTip = 'Scheduled Deload Week! Reduced volume (3 sets, RPE 6-7) dissipates central nervous system fatigue and allows tendons to supercompensate.';
      benchNotes = 'Deload Bench: 3 crisp sets of 5 reps. Focus on bar speed and scapular stability without pushing near failure.';
      squatNotes = 'Deload Squat: 3 sets of 5 reps at moderate load. Lubricate knee and hip joints with perfect depth.';
      deadliftNotes = 'Deload Deadlift: 3 sets of 5 reps. Perfect hip wedge and explosive floor push.';
      pressNotes = 'Deload Overhead: 3 sets of 5 reps. Solid core bracing and active overhead lockout.';
    } else if (weekNum <= 3) {
      // Phase 1 (Weeks 1-3): Technical Foundation & 5x5 Compound Accumulation
      benchSets = 5;
      benchReps = '5';
      squatSets = 5;
      squatReps = '5';
      deadliftSets = 4;
      deadliftReps = '5';
      pressSets = 4;
      pressReps = '6-8';
      weekTip = 'Phase 1: 5x5 Compound Foundation. Rest 2–3 minutes between working sets to ensure complete ATP-CP system recovery.';
      benchNotes = '5x5 Bench: Maintain firm leg drive, retracted shoulder blades, and controlled bar path.';
      squatNotes = '5x5 Squat: Brace abdominal wall with valsalva maneuver before every descent. Hit parallel depth.';
      deadliftNotes = 'Heavy Deadlift: 4 sets of 5 reps. Lock out fully with glutes, avoiding lumbar hyperextension.';
      pressNotes = 'Military Press: 4 sets of 6-8 reps. Strict vertical press path with neutral spine.';
    } else if (weekNum <= 7) {
      // Phase 2 (Weeks 5-7): Heavy Strength Wave (3-5 Reps)
      benchSets = 4;
      benchReps = '3-5';
      squatSets = 4;
      squatReps = '3-5';
      deadliftSets = 4;
      deadliftReps = '3-5';
      pressSets = 4;
      pressReps = '5';
      weekTip = 'Phase 2: Heavy Strength Progression. Shift to heavy 3–5 rep working sets with 1–2 reps in reserve (RPE 8).';
      benchNotes = 'Heavy Bench: 4 sets of 3-5 reps. Drive through feet and press explosively off chest.';
      squatNotes = 'Heavy Squat: 4 sets of 3-5 reps. Maintain upright torso and drive out of the hole.';
      deadliftNotes = 'Heavy Pulling: 4 sets of 3-5 reps. Squeeze lats tight and maintain bar contact against shins.';
      pressNotes = 'Heavy Press: 4 sets of 5 reps. Full overhead lockout with active traps.';
    } else if (weekNum <= 10) {
      // Phase 3 (Weeks 9-10): Sub-maximal Power & Heavy Triples
      benchSets = 4;
      benchReps = '3';
      squatSets = 4;
      squatReps = '3';
      deadliftSets = 3;
      deadliftReps = '3';
      pressSets = 3;
      pressReps = '5';
      weekTip = 'Phase 3: Heavy Triples (3 reps) at ~85–90% 1RM. Rest 3 minutes between heavy sets for maximal motor unit recruitment.';
      benchNotes = 'Heavy Triples Bench: 4 sets of 3 reps. Maximum focus and crisp bar velocity.';
      squatNotes = 'Heavy Triples Squat: 4 sets of 3 reps. Unshakeable core brace and explosive drive.';
      deadliftNotes = 'Heavy Triples Deadlift: 3 sets of 3 reps. Clean pulls with maximum intent.';
      pressNotes = 'Heavy Press: 3 sets of 5 reps. Solid base with zero knee dip.';
    } else {
      // Week 12: Peak Strength Benchmark & Graduation
      benchSets = 3;
      benchReps = '3-5';
      squatSets = 3;
      squatReps = '3-5';
      deadliftSets = 3;
      deadliftReps = '3-5';
      pressSets = 3;
      pressReps = '5';
      weekTip = 'Week 12 Peak & Graduation! Record your clean working weights to update your estimated 1RMs in the PR Vault, then celebrate your 12-week transformation!';
      benchNotes = 'Peak Bench: 3 crisp sets of 3-5 reps. Celebrate your strength breakthrough!';
      squatNotes = 'Peak Squat: 3 crisp sets of 3-5 reps. Showcase your leg armor and depth.';
      deadliftNotes = 'Peak Deadlift: 3 crisp sets of 3-5 reps. Powerful, decisive pulls from the floor.';
      pressNotes = 'Peak Press: 3 sets of 5 reps. Masterful overhead strength execution.';
    }

    final day7Blueprint = weekNum == 12
        ? const TransformationDayBlueprint(
            dayIndex: 7,
            dayType: 'active_recovery',
            muscleGroup: '12-Week Strength Titan Celebration & Graduation',
            exerciseNames: [],
            notes: 'Congratulations on completing 12 weeks of strength building! Review your 1RM milestones in PR Vault and choose your graduation pathway.',
          )
        : const TransformationDayBlueprint(
            dayIndex: 7,
            dayType: 'rest',
            muscleGroup: 'Weekly Tonnage Assessment & Rest',
            exerciseNames: [],
            notes: 'Inspect estimated 1RM trends in PR Vault and rest.',
          );

    return TransformationWeekBlueprint(
      weekNumber: weekNum,
      focus: focus,
      weekTip: weekTip,
      days: [
        TransformationDayBlueprint(
          dayIndex: 1,
          dayType: 'workout',
          muscleGroup: 'Heavy Bench Press & Accessories',
          exerciseNames: const [
            'Barbell Bench Press',
            'Barbell Close Grip Bench Press',
            'Incline Dumbbell Press',
            'Dumbbell Hammer Press',
          ],
          targetSets: benchSets,
          targetReps: benchReps,
          notes: benchNotes,
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Heavy Bench Press & Accessories'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Heavy Bench Press & Accessories'),
        ),
        TransformationDayBlueprint(
          dayIndex: 2,
          dayType: 'workout',
          muscleGroup: 'Heavy Squat & Core Stability',
          exerciseNames: const [
            'Classic Barbell Squat',
            'Barbell Straight Leg Deadlift',
            'Leg Press',
            'Twisting Crunch',
          ],
          targetSets: squatSets,
          targetReps: squatReps,
          notes: squatNotes,
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Heavy Squat & Core Stability'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Heavy Squat & Core Stability'),
        ),
        const TransformationDayBlueprint(
          dayIndex: 3,
          dayType: 'rest',
          muscleGroup: 'CNS Recovery Day',
          exerciseNames: [],
          notes: 'Complete rest for central nervous system recuperation.',
        ),
        TransformationDayBlueprint(
          dayIndex: 4,
          dayType: 'workout',
          muscleGroup: 'Heavy Deadlift & Posterior Chain',
          exerciseNames: const [
            'Smith Deadlift',
            'Pull-ups Wide Back Grip',
            'Barbell Underhand Bent Over Row',
            'Air Twist Crunch',
          ],
          targetSets: deadliftSets,
          targetReps: deadliftReps,
          notes: deadliftNotes,
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Heavy Deadlift & Posterior Chain'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Heavy Deadlift & Posterior Chain'),
        ),
        TransformationDayBlueprint(
          dayIndex: 5,
          dayType: 'workout',
          muscleGroup: 'Military Press & Power Accessories',
          exerciseNames: const [
            'Military Press',
            'Chest Dips',
            'Barbell Curl',
            'Dumbbell Incline Rear Lateral Raise',
          ],
          targetSets: pressSets,
          targetReps: pressReps,
          notes: pressNotes,
          warmupExercises: TransformationEquipmentAdapter.getWarmupExercises('Military Press & Power Accessories'),
          cooldownExercises: TransformationEquipmentAdapter.getCooldownExercises('Military Press & Power Accessories'),
        ),
        const TransformationDayBlueprint(
          dayIndex: 6,
          dayType: 'rest',
          muscleGroup: 'Rest & Joint Health',
          exerciseNames: [],
          notes: 'Hydrate, foam roll, and maintain adequate protein intake.',
        ),
        day7Blueprint,
      ],
    );
  }
}
