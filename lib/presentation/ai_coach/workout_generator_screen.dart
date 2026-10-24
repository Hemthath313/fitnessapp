import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/model/workout_model.dart';
import 'package:fitness_app/services/notification_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutGeneratorScreen extends StatefulWidget {
  const WorkoutGeneratorScreen({super.key});

  static List<Exercise> get availableCatalog => ExerciseData.all;

  @override
  State<WorkoutGeneratorScreen> createState() => _WorkoutGeneratorScreenState();
}

class _WorkoutGeneratorScreenState extends State<WorkoutGeneratorScreen> {
  bool _isLoading = false;
  
  // Weekly Schedule Structure: 
  // [ { "day": "Monday", "focus": "Chest", "exercises": [...] }, ... ]
  List<Map<String, dynamic>> _generatedWeek = [];

  // Selections
  String _target = 'Full Body';
  String _level = 'Beginner';
  String _equipment = 'Gym (Full Equipment)';
  int _daysPerWeek = 3;

  static const List<String> _allWeekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  List<String> _selectedDays = ['Monday', 'Wednesday', 'Friday'];

  final List<String> _targets = [
    'Full Body',
    'Muscle Build (Hypertrophy)',
    'Strength',
    'Fat Loss'
  ];
  final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _equipments = [
    'Gym (Full Equipment)',
    'Home (Dumbbells)',
  ];
  final List<int> _daysOptions = [3, 4, 5, 6];

  @override
  void initState() {
    super.initState();
    _initGoalFromProfile();
  }

  void _initGoalFromProfile() {
    try {
      final homeProvider = Provider.of<HomeProvider?>(context, listen: false);
      final profileGoal =
          homeProvider?.userData['goal']?.toString().toLowerCase() ?? '';
      if (profileGoal.contains('lose') || profileGoal.contains('fat')) {
        _target = 'Fat Loss';
      } else if (profileGoal.contains('gain') ||
          profileGoal.contains('muscle') ||
          profileGoal.contains('hypertrophy') ||
          profileGoal.contains('build')) {
        _target = 'Muscle Build (Hypertrophy)';
      } else if (profileGoal.contains('strength')) {
        _target = 'Strength';
      } else if (profileGoal.contains('maintain')) {
        _target = 'Full Body';
      }
    } catch (_) {}

    try {
      final statsProvider =
          Provider.of<StatisticsProvider?>(context, listen: false);
      final existingDays = statsProvider?.scheduledDayNames ?? const <String>[];
      if (existingDays.length >= 3 && existingDays.length <= 6) {
        _selectedDays = List<String>.from(existingDays);
        _daysPerWeek = _selectedDays.length;
      }
    } catch (_) {}
  }

  void _onDaysCountChanged(int count) {
    setState(() {
      _daysPerWeek = count;
      if (count == 3) {
        _selectedDays = ['Monday', 'Wednesday', 'Friday'];
      } else if (count == 4) {
        _selectedDays = ['Monday', 'Tuesday', 'Thursday', 'Friday'];
      } else if (count == 5) {
        _selectedDays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday'
        ];
      } else if (count == 6) {
        _selectedDays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday'
        ];
      }
    });
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        if (_selectedDays.length <= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('At least 3 training days are required for an effective split.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        _selectedDays.remove(day);
      } else {
        if (_selectedDays.length >= 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('At least 1 rest day is required per week for muscle recovery.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        _selectedDays.add(day);
        _selectedDays.sort((a, b) =>
            _allWeekDays.indexOf(a).compareTo(_allWeekDays.indexOf(b)));
      }
      _daysPerWeek = _selectedDays.length;
    });
  }

  Future<void> _generateWorkout() async {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider?>(context, listen: false);
    final isPremium = subscriptionProvider?.isPremium ?? false;
    if (!isPremium) {
      context.push(Routes.premiumScreen);
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedWeek = [];
    });

    // Simulate "Thinking" delay for UX
    await Future.delayed(const Duration(milliseconds: 1200));

    // Ensure selected days list is non-empty and sorted
    if (_selectedDays.isEmpty) {
      _selectedDays = ['Monday', 'Wednesday', 'Friday'];
    }

    List<Map<String, dynamic>> plan = [];

    // Generation Logic with Structured Movement Slots mapped to user-selected days
    if (_selectedDays.length == 3) {
      // 3 Day Full Body Split (A / B / C)
      plan = [
        _createDayPlan(_selectedDays[0], 'Full Body A (Chest & Quad Focus)', _buildFullBodyA()),
        _createDayPlan(_selectedDays[1], 'Full Body B (Back & Hinge Focus)', _buildFullBodyB()),
        _createDayPlan(_selectedDays[2], 'Full Body C (Hypertrophy & Core)', _buildFullBodyC()),
      ];
    } else if (_selectedDays.length == 4) {
      // 4 Day Upper / Lower
      plan = [
        _createDayPlan(_selectedDays[0], 'Upper Body A', _buildUpperBodyA()),
        _createDayPlan(_selectedDays[1], 'Lower Body A & Core', _buildLowerBodyA()),
        _createDayPlan(_selectedDays[2], 'Upper Body B', _buildUpperBodyB()),
        _createDayPlan(_selectedDays[3], 'Lower Body B & Core', _buildLowerBodyB()),
      ];
    } else if (_selectedDays.length == 5) {
      // 5 Day Bro Split
      plan = [
        _createDayPlan(_selectedDays[0], 'Chest Day', _buildChestRoutine()),
        _createDayPlan(_selectedDays[1], 'Back Day', _buildBackRoutine()),
        _createDayPlan(_selectedDays[2], 'Legs & Abs Day', _buildLegRoutine()),
        _createDayPlan(_selectedDays[3], 'Shoulder Day', _buildShoulderRoutine()),
        _createDayPlan(_selectedDays[4], 'Arms Day (Biceps & Triceps)', _buildArmRoutine()),
      ];
    } else {
      // 6 Day Push / Pull / Legs
      plan = [
        _createDayPlan(_selectedDays[0], 'Push Day A', _buildPushRoutine()),
        _createDayPlan(_selectedDays[1], 'Pull Day A', _buildPullRoutine()),
        _createDayPlan(_selectedDays[2], 'Legs & Core A', _buildLegRoutine()),
        _createDayPlan(_selectedDays[3], 'Push Day B', _buildPushRoutine()),
        _createDayPlan(_selectedDays[4], 'Pull Day B', _buildPullRoutine()),
        _createDayPlan(_selectedDays[5], 'Legs & Core B', _buildLowerBodyB()),
      ];
    }

    if (!mounted) return;
    setState(() {
      _generatedWeek = plan;
      _isLoading = false;
    });
  }

  Map<String, dynamic> _createDayPlan(String day, String focus, List<Exercise> exercises) {
    final List<Exercise> dayExercises = List<Exercise>.from(exercises);
    if (_target == 'Fat Loss') {
      final cardioOptions = _filterEquipment(ExerciseData.cardio)
          .where((c) => !dayExercises.any((e) => e.name == c.name))
          .toList();
      if (cardioOptions.isNotEmpty) {
        dayExercises.add(cardioOptions.first);
      }
    }

    int defaultSets = 3;
    String defaultReps = '10-12 reps';
    if (_target == 'Strength') {
      defaultSets = 4;
      defaultReps = '5 reps';
    } else if (_target == 'Fat Loss') {
      defaultSets = 3;
      defaultReps = '15 reps';
    } else if (_target == 'Muscle Build (Hypertrophy)') {
      defaultSets = 4;
      defaultReps = '8-12 reps';
    }

    return {
      'day': day,
      'focus': focus,
      'exercises': dayExercises.map((e) {
        String reps = defaultReps;
        if (e.setsReps.contains('x') || e.setsReps.contains('×')) {
          final parts = e.setsReps.split(RegExp(r'[x×]'));
          if (parts.length > 1) {
            reps = parts.last.trim();
          }
        }
        return {
          'name': e.name,
          'sets': defaultSets,
          'reps': reps,
          'videoPath': e.videoPath,
          'description': e.description,
          'target': e.target,
          'equipment': e.equipment,
          'difficulty': e.difficulty,
          'instructions': e.instructions,
          'setsReps': e.setsReps,
        };
      }).toList(),
    };
  }

  // Strict Equipment Filtering
  List<Exercise> _filterEquipment(List<Exercise> source) {
    if (source.isEmpty) return [];

    if (_equipment == 'Home (Dumbbells)') {
      final filtered = source.where((e) {
        final eq = e.equipment.toLowerCase();
        final isHomeFriendly = eq.contains('dumbbell') ||
            eq.contains('bodyweight') ||
            eq.contains('mat') ||
            eq.contains('none') ||
            eq.contains('band');
        final isNotGymOnly = !eq.contains('barbell') &&
            !eq.contains('cable') &&
            !eq.contains('machine');
        return isHomeFriendly && isNotGymOnly;
      }).toList();

      if (filtered.isNotEmpty) return filtered;
    }
    return source;
  }

  Exercise _pickBest(List<Exercise> source, {bool preferCompound = true, Set<String>? excludedNames}) {
    final available = _filterEquipment(source).where((e) => excludedNames == null || !excludedNames.contains(e.name)).toList();
    if (available.isEmpty) {
      return source.isNotEmpty ? source.first : ExerciseData.chest.first;
    }

    if (preferCompound) {
      final compounds = available.where((e) {
        final n = e.name.toLowerCase();
        return n.contains('bench press') ||
            n.contains('squat') ||
            n.contains('deadlift') ||
            n.contains('overhead press') ||
            n.contains('military press') ||
            n.contains('row') ||
            n.contains('dips') ||
            n.contains('lunge');
      }).toList();
      if (compounds.isNotEmpty) {
        return compounds.first;
      }
    }

    return available.first;
  }

  List<Exercise> _buildFullBodyA() {
    final Set<String> used = {};
    final e1 = _pickBest(ExerciseData.chest, preferCompound: true, excludedNames: used);
    used.add(e1.name);
    final e2 = _pickBest(ExerciseData.legs, preferCompound: true, excludedNames: used);
    used.add(e2.name);
    final e3 = _pickBest(ExerciseData.back, preferCompound: true, excludedNames: used);
    used.add(e3.name);
    final e4 = _pickBest(ExerciseData.shoulders, preferCompound: true, excludedNames: used);
    used.add(e4.name);
    final e5 = _pickBest(ExerciseData.biceps, preferCompound: false, excludedNames: used);
    return [e1, e2, e3, e4, e5];
  }

  List<Exercise> _buildFullBodyB() {
    final Set<String> used = {};
    // Deadlift / Hinge focus + Incline + Vertical Pull
    final backExercises = _filterEquipment(ExerciseData.back);
    final e1 = backExercises.isNotEmpty ? backExercises.last : ExerciseData.back.first;
    used.add(e1.name);
    final e2 = _pickBest(ExerciseData.chest, preferCompound: true, excludedNames: used);
    used.add(e2.name);
    final e3 = _pickBest(ExerciseData.legs, preferCompound: true, excludedNames: used);
    used.add(e3.name);
    final e4 = _pickBest(ExerciseData.shoulders, preferCompound: false, excludedNames: used);
    used.add(e4.name);
    final e5 = _pickBest(ExerciseData.triceps, preferCompound: false, excludedNames: used);
    return [e1, e2, e3, e4, e5];
  }

  List<Exercise> _buildFullBodyC() {
    final Set<String> used = {};
    final legExercises = _filterEquipment(ExerciseData.legs);
    final e1 = legExercises.length > 1 ? legExercises[1] : ExerciseData.legs.first;
    used.add(e1.name);
    final e2 = _pickBest(ExerciseData.chest, preferCompound: false, excludedNames: used);
    used.add(e2.name);
    final e3 = _pickBest(ExerciseData.back, preferCompound: false, excludedNames: used);
    used.add(e3.name);
    final e4 = _pickBest(ExerciseData.shoulders, preferCompound: false, excludedNames: used);
    used.add(e4.name);
    final e5 = _pickBest(ExerciseData.abs, preferCompound: false, excludedNames: used);
    return [e1, e2, e3, e4, e5];
  }

  List<Exercise> _buildUpperBodyA() {
    final Set<String> used = {};
    final e1 = _pickBest(ExerciseData.chest, preferCompound: true, excludedNames: used);
    used.add(e1.name);
    final e2 = _pickBest(ExerciseData.back, preferCompound: true, excludedNames: used);
    used.add(e2.name);
    final e3 = _pickBest(ExerciseData.shoulders, preferCompound: true, excludedNames: used);
    used.add(e3.name);
    final e4 = _pickBest(ExerciseData.chest, preferCompound: false, excludedNames: used);
    used.add(e4.name);
    final e5 = _pickBest(ExerciseData.biceps, preferCompound: false, excludedNames: used);
    return [e1, e2, e3, e4, e5];
  }

  List<Exercise> _buildUpperBodyB() {
    final Set<String> used = {};
    final e1 = _pickBest(ExerciseData.back, preferCompound: true, excludedNames: used);
    used.add(e1.name);
    final e2 = _pickBest(ExerciseData.chest, preferCompound: true, excludedNames: used);
    used.add(e2.name);
    final e3 = _pickBest(ExerciseData.shoulders, preferCompound: false, excludedNames: used);
    used.add(e3.name);
    final e4 = _pickBest(ExerciseData.back, preferCompound: false, excludedNames: used);
    used.add(e4.name);
    final e5 = _pickBest(ExerciseData.triceps, preferCompound: false, excludedNames: used);
    return [e1, e2, e3, e4, e5];
  }

  List<Exercise> _buildLowerBodyA() {
    final legExercises = _filterEquipment(ExerciseData.legs).take(4).toList();
    final absExercises = _filterEquipment(ExerciseData.abs).take(1).toList();
    return [...legExercises, ...absExercises];
  }

  List<Exercise> _buildLowerBodyB() {
    final legExercises = _filterEquipment(ExerciseData.legs);
    final selectedLegs = legExercises.length > 2
        ? legExercises.reversed.take(4).toList()
        : legExercises.take(4).toList();
    final absExercises = _filterEquipment(ExerciseData.abs).reversed.take(1).toList();
    return [...selectedLegs, ...absExercises];
  }

  List<Exercise> _buildChestRoutine() {
    return _filterEquipment(ExerciseData.chest).take(4).toList();
  }

  List<Exercise> _buildBackRoutine() {
    return _filterEquipment(ExerciseData.back).take(4).toList();
  }

  List<Exercise> _buildLegRoutine() {
    final legs = _filterEquipment(ExerciseData.legs).take(4).toList();
    final abs = _filterEquipment(ExerciseData.abs).take(1).toList();
    return [...legs, ...abs];
  }

  List<Exercise> _buildShoulderRoutine() {
    return _filterEquipment(ExerciseData.shoulders).take(4).toList();
  }

  List<Exercise> _buildArmRoutine() {
    final biceps = _filterEquipment(ExerciseData.biceps).take(2).toList();
    final triceps = _filterEquipment(ExerciseData.triceps).take(2).toList();
    return [...biceps, ...triceps];
  }

  List<Exercise> _buildPushRoutine() {
    final chest = _filterEquipment(ExerciseData.chest).take(2).toList();
    final shoulders = _filterEquipment(ExerciseData.shoulders).take(2).toList();
    final triceps = _filterEquipment(ExerciseData.triceps).take(1).toList();
    return [...chest, ...shoulders, ...triceps];
  }

  List<Exercise> _buildPullRoutine() {
    final back = _filterEquipment(ExerciseData.back).take(3).toList();
    final biceps = _filterEquipment(ExerciseData.biceps).take(1).toList();
    return [...back, ...biceps];
  }


  bool _isSaving = false;

  void _showUpgradeToSaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ColorManager.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(Icons.star_rounded, color: Colors.amber, size: 26.sp),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                'Unlock AI Workouts',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 17.sp,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your custom ${_selectedDays.length}-day split has been generated! Upgrade to Pro to save this split to your schedule, track rest timers, and access video exercise guides.',
              style: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp, height: 1.4),
            ),
            SizedBox(height: 12.h),
            _buildProPerkRow(Icons.calendar_today_rounded, 'Sync custom split to schedule'),
            SizedBox(height: 6.h),
            _buildProPerkRow(Icons.timer_outlined, 'Built-in rest timers & sound alerts'),
            SizedBox(height: 6.h),
            _buildProPerkRow(Icons.play_circle_outline_rounded, 'HD exercise video techniques'),
            SizedBox(height: 14.h),
            Text(
              'Or you can continue with our free 3-day starter split (Mon/Wed/Fri).',
              style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _activateFreeStarterPlan(context);
            },
            child: Text('Use 3-Day Free Plan', style: TextStyle(color: ColorManager.primary, fontWeight: FontWeight.w600, fontSize: 12.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.push(Routes.premiumScreen);
            },
            style: ElevatedButton.styleFrom(backgroundColor: ColorManager.primary),
            child: const Text('Go Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _activateFreeStarterPlan(BuildContext context) async {
    try {
      final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
      final statsProvider = Provider.of<StatisticsProvider>(context, listen: false);
      await workoutProvider.restoreDefaultThreeDaySplit();
      final now = workoutProvider.currentNow;
      await statsProvider.updateScheduledDays(
        const ['Monday', 'Wednesday', 'Friday'],
        effectiveDate: now,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '3-Day Starter Routine activated! Ready for your workout.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: ColorManager.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to activate starter plan: $e'),
            backgroundColor: ColorManager.error,
          ),
        );
      }
    }
  }

  Widget _buildProPerkRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15.sp, color: ColorManager.primary),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveAllWorkouts() async {
    if (_isSaving) return;

    final subscriptionProvider =
        Provider.of<SubscriptionProvider?>(context, listen: false);
    final isPremium = subscriptionProvider?.isPremium ?? false;

    if (!isPremium) {
      _showUpgradeToSaveDialog(context);
      return;
    }

    final provider = Provider.of<WorkoutProvider>(context, listen: false);

    setState(() {
      _isSaving = true;
    });

    final now = provider.currentNow;
    int count = 0;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      final List<WorkoutModel> workoutsToSave = [];

      for (int dayIndex = 0; dayIndex < _generatedWeek.length; dayIndex++) {
        final dayPlan = _generatedWeek[dayIndex];
        final dayName = dayPlan['day'] ?? 'Day';
        final exercises = dayPlan['exercises'] as List<dynamic>? ?? [];
        final scheduledDate = now;

        for (var exercise in exercises) {
          final rawName = exercise['name'] ?? 'Exercise';
          final savedName = '[$dayName] $rawName';

          // Safe rep parsing
          int repCount = 10;
          final match =
              RegExp(r'(\d+)').firstMatch(exercise['reps'].toString());
          if (match != null) {
            repCount = int.tryParse(match.group(1) ?? '10') ?? 10;
          }

          workoutsToSave.add(
            WorkoutModel(
              id: '',
              name: savedName,
              repNumber: repCount,
              setNumber: int.tryParse(exercise['sets'].toString()) ?? 3,
              dateTime: scheduledDate,
            ),
          );
          count++;
        }
      }

      if (workoutsToSave.isNotEmpty) {
        // Atomically replace weekly plan with rollback if saving fails
        await provider.replaceWeeklyPlan(workoutsToSave);
      }

      await provider.fetchAndSetWorkouts();

      if (mounted) {
        try {
          final newDays =
              _generatedWeek.map((d) => d['day'].toString()).toList();
          final statsProvider =
              Provider.of<StatisticsProvider>(context, listen: false);
          await statsProvider.updateScheduledDays(newDays);

          final prefs = await SharedPreferences.getInstance();
          if (prefs.getBool('notif_workout_reminders_enabled') ?? false) {
            final workoutHour = prefs.getInt('notif_workout_hour') ?? 8;
            final workoutMin = prefs.getInt('notif_workout_minute') ?? 0;
            await NotificationService().scheduleWorkoutDayReminders(
              scheduledDays: newDays,
              time: TimeOfDay(hour: workoutHour, minute: workoutMin),
            );
          }
          if (prefs.getBool('notif_recovery_reminders_enabled') ?? false) {
            const weekDays = [
              'Monday',
              'Tuesday',
              'Wednesday',
              'Thursday',
              'Friday',
              'Saturday',
              'Sunday',
            ];
            final newDaysSet =
                _generatedWeek.map((d) => d['day'].toString()).toSet();
            final restDays =
                weekDays.where((d) => !newDaysSet.contains(d)).toList();
            if (restDays.isNotEmpty) {
              await NotificationService()
                  .scheduleRestDayReminders(restDays: restDays);
            }
          }
        } catch (_) {}

        if (mounted) {
          Navigator.pop(context); // Pop dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Saved $count exercises to My Workouts!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: ColorManager.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              margin: EdgeInsets.all(16.w),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving: $e',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: ColorManager.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            margin: EdgeInsets.all(16.w),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildResultsSection() {
    final isPremium =
        Provider.of<SubscriptionProvider?>(context)?.isPremium ?? false;
    final bool canSave = isPremium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Your Weekly Split',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: ColorManager.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 8.w),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveAllWorkouts,
              icon: Icon(
                canSave ? Icons.bookmark_add_rounded : Icons.lock_outline_rounded,
                size: 16.sp,
                color: Colors.white,
              ),
              label: Text(
                canSave ? 'Save to Schedule' : 'Save (Pro)',
                style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: canSave ? ColorManager.primary : Colors.amber.shade700,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        ..._generatedWeek.map((dayPlan) => _buildDayCard(dayPlan)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium =
        Provider.of<SubscriptionProvider?>(context)?.isPremium ?? false;

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text('AI Workout Generator', style: TextStyle(color: ColorManager.textPrimary)),
        backgroundColor: ColorManager.background,
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(SizeManager.s16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSelectionSection(),
            SizedBox(height: 24.h),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _generateWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 18.sp, color: Colors.black),
                        SizedBox(width: 8.w),
                        Text(
                          'GENERATE WEEKLY PLAN',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
            ),
            SizedBox(height: 24.h),
            
            if (_generatedWeek.isNotEmpty) _buildResultsSection(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSelectionSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorManager.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
           _buildDropdown('Days per Week', '$_daysPerWeek Days', _daysOptions.map((e) => '$e Days').toList(), 
            (val) => _onDaysCountChanged(int.parse(val!.split(' ')[0]))),
           SizedBox(height: 12.h),

           // Interactive Day Selection Chips
           Align(
             alignment: Alignment.centerLeft,
             child: Text(
               'Active Training Days (${_selectedDays.length} selected):',
               style: TextStyle(
                 color: ColorManager.textSecondary,
                 fontSize: 13.sp,
                 fontWeight: FontWeight.w500,
               ),
             ),
           ),
           SizedBox(height: 8.h),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: _allWeekDays.map((day) {
               final isSelected = _selectedDays.contains(day);
               final shortName = day.substring(0, 3);
               return Expanded(
                 child: Padding(
                   padding: EdgeInsets.symmetric(horizontal: 2.w),
                   child: InkWell(
                     onTap: () => _toggleDay(day),
                     borderRadius: BorderRadius.circular(8.r),
                     child: AnimatedContainer(
                       duration: const Duration(milliseconds: 200),
                       padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 7.h),
                       alignment: Alignment.center,
                       decoration: BoxDecoration(
                         color: isSelected
                             ? ColorManager.primary
                             : ColorManager.surfaceDark,
                         borderRadius: BorderRadius.circular(8.r),
                         border: Border.all(
                           color: isSelected
                               ? ColorManager.primary
                               : ColorManager.divider,
                           width: 1,
                         ),
                       ),
                       child: FittedBox(
                         fit: BoxFit.scaleDown,
                         child: Text(
                           shortName,
                           style: TextStyle(
                             color: isSelected ? Colors.black : ColorManager.textTertiary,
                             fontSize: 11.sp,
                             fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                           ),
                         ),
                       ),
                     ),
                   ),
                 ),
               );
             }).toList(),
           ),
           SizedBox(height: 16.h),
          _buildDropdown('Goal', _target, _targets, (val) => setState(() => _target = val!)),
          SizedBox(height: 16.h),
          _buildDropdown('Level', _level, _levels, (val) => setState(() => _level = val!)),
          SizedBox(height: 16.h),
          _buildDropdown('Equipment', _equipment, _equipments, (val) => setState(() => _equipment = val!)),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: ColorManager.textSecondary, fontSize: 14.sp),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: ColorManager.surfaceDark,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: ColorManager.surface,
              iconEnabledColor: ColorManager.textPrimary,
              style: TextStyle(color: ColorManager.textPrimary, fontSize: 16.sp),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(Map<String, dynamic> dayPlan) {
    final exercises = dayPlan['exercises'] as List<dynamic>? ?? [];
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: ExpansionTile(
        backgroundColor: ColorManager.surface,
        collapsedBackgroundColor: ColorManager.surface,
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Text(
          dayPlan['day'] ?? 'Day',
          style: TextStyle(color: ColorManager.primary, fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
        subtitle: Text(
          dayPlan['focus'] ?? 'Workout',
          style: TextStyle(color: ColorManager.textSecondary, fontSize: 14.sp),
        ),
        children: exercises.map((e) => ListTile(
          dense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          leading: Icon(Icons.play_circle_fill, color: ColorManager.primary, size: 24.sp),
          title: Text(
            e['name'],
            style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            e['description'] ?? '',
             maxLines: 1,
             overflow: TextOverflow.ellipsis,
             style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
          ),
          trailing: Text(
            '${e['sets']}x${e['reps']}',
            style: TextStyle(color: ColorManager.textSecondary),
          ),
          onTap: () {
            // Reconstruct Exercise object for details view
            final exerciseObj = Exercise(
              name: e['name'],
              videoPath: e['videoPath'],
              description: e['description'],
              target: e['target'] ?? 'General',
              equipment: e['equipment'] ?? 'None',
              difficulty: e['difficulty'] ?? 'All Levels',
              instructions: List<String>.from(e['instructions'] ?? []),
              setsReps: e['setsReps'] ?? '${e['sets']}x${e['reps']}',
            );
            _showExerciseDetails(context, exerciseObj);
          },
        )).toList(),
      ),
    );
  }

  void _showExerciseDetails(BuildContext context, Exercise exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: ColorManager.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorManager.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Player
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: ColorManager.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: ExerciseVideoPlayer(
                          videoPath: exercise.videoPath,
                          height: 300,
                          fit: BoxFit.contain,
                          autoPlay: true, // Auto-play in detail view
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Exercise Name
                    Text(
                      exercise.name,
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Description
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ColorManager.surface,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        exercise.description,
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 16.sp,
                          height: 1.6,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Info Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            'Target',
                            exercise.target,
                            Icons.center_focus_strong,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildDetailCard(
                            'Equipment',
                            exercise.equipment,
                            Icons.sports_gymnastics,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            'Difficulty',
                            exercise.difficulty,
                            Icons.trending_up,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildDetailCard(
                            'Sets & Reps',
                            exercise.setsReps,
                            Icons.repeat,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Instructions
                    Text(
                      'How to Perform',
                      style: TextStyle(
                        color: ColorManager.primary,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ...exercise.instructions.asMap().entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ColorManager.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ColorManager.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: ColorManager.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  color: ColorManager.textPrimary,
                                  fontSize: 15.sp,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),

            // Close Button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: ColorManager.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ColorManager.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: ColorManager.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
