import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/model/personal_record_model.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/custom_workouts/widgets/workout_reward_view.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/achievements_widget.dart';
import 'package:fitness_app/presentation/home/widgets/next_badge_card.dart';
import 'package:fitness_app/presentation/widgets/interactive_exercise_detail.dart';
import 'package:fitness_app/presentation/workout_tools/plate_calculator_sheet.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/services/exercise_substitution_service.dart';
import 'package:fitness_app/services/plan_today.dart';
import 'package:fitness_app/services/progression_service.dart';
import 'package:fitness_app/services/session_reward_service.dart';
import 'package:fitness_app/services/update_service.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/haptics.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/presentation/transformation_plans/utils/transformation_equipment_adapter.dart';

class DayWorkoutSessionPage extends StatefulWidget {
  final String dayName;
  final List<dynamic> workouts; // List of WorkoutModel, Exercise, or maps
  final String? planId;
  final int? planDay;
  final VideoControllerFactory? videoControllerFactory;
  final VideoViewBuilder? videoViewBuilder;

  const DayWorkoutSessionPage({
    super.key,
    required this.dayName,
    required this.workouts,
    this.planId,
    this.planDay,
    this.videoControllerFactory,
    this.videoViewBuilder,
  });

  @override
  State<DayWorkoutSessionPage> createState() => _DayWorkoutSessionPageState();
}

class _DayWorkoutSessionPageState extends State<DayWorkoutSessionPage>
    with WidgetsBindingObserver {
  late final WorkoutLogService _logService = WorkoutLogService();
  late List<_SessionExerciseState> _exercises;
  
  bool _isSaving = false;
  bool _isSessionFinished = false;
  bool _isDetailSheetOpen = false;
  WorkoutSession? _finishedSession;
  WorkoutRewardData _reward = const WorkoutRewardData();

  // Elapsed Session Timer
  Timer? _sessionTimer;
  int _elapsedSeconds = 0;
  DateTime _startedAt = DateTime.now();
  // Set when the app goes to the background. Timers stop there, so the gap is
  // added back when the app returns.
  DateTime? _backgroundedAt;
  // Created once so a retry after a failed save writes the same session id.
  String? _sessionId;

  // An unfinished session is kept here so a crash or a closed app loses nothing.
  static const String _draftKey = 'active_workout_draft_v1';
  static const String _warmupOpenKey = 'session_warmup_expanded';
  static const String _cooldownOpenKey = 'session_cooldown_expanded';

  // Non-blocking Persistent Rest Timer
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isRestTimerActive = false;

  // Warm-up & Cooldown Routines (Non-volume-contributing preparation & recovery)
  late final List<String> _warmupRoutines;
  late final List<String> _cooldownRoutines;
  final Set<int> _completedWarmups = {};
  final Set<int> _completedCooldowns = {};
  bool _isWarmupExpanded = false;
  bool _isCooldownExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    UpdateService().setWorkoutSessionActive(true);
    _startSessionTimer();
    _warmupRoutines = TransformationEquipmentAdapter.getWarmupExercises(widget.dayName);
    _cooldownRoutines = TransformationEquipmentAdapter.getCooldownExercises(widget.dayName);
    _initExercises();
    _loadHistoryAndProgression();
    _loadSectionPrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerResumeIfDraft());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt ??= DateTime.now();
      _saveDraft();
    } else if (state == AppLifecycleState.resumed) {
      final since = _backgroundedAt;
      _backgroundedAt = null;
      if (since == null || !mounted || _isSessionFinished) return;
      final away = DateTime.now().difference(since).inSeconds;
      if (away <= 1) return;
      var restFinished = false;
      setState(() {
        _elapsedSeconds += away;
        if (_isRestTimerActive) {
          final remaining = _restSecondsRemaining - away;
          if (remaining <= 0) {
            _restTimer?.cancel();
            _isRestTimerActive = false;
            _restSecondsRemaining = 0;
            restFinished = true;
          } else {
            _restSecondsRemaining = remaining;
          }
        }
      });
      if (restFinished) _notifyRestFinished();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    UpdateService().setWorkoutSessionActive(false);
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    for (var ex in _exercises) {
      ex.dispose();
    }
    super.dispose();
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_isSessionFinished) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _initExercises() {
    _exercises = widget.workouts.asMap().entries.map((entry) {
      final index = entry.key;
      final w = entry.value;

      String rawName;
      int totalSets = 3;
      int targetReps = 8;
      String? customVideoPath;
      String? customDescription;
      String? customTarget;
      String? customEquipment;
      String? customDifficulty;
      List<String>? customInstructions;

      if (w is Map) {
        rawName = (w['name'] as String?) ?? (w['workoutName'] as String?) ?? '';
        totalSets = (w['setNumber'] as num?)?.toInt() ?? 3;
        targetReps = (w['repNumber'] as num?)?.toInt() ?? 8;
        customVideoPath = w['videoPath'] as String?;
        customDescription = w['description'] as String?;
        customTarget = w['target'] as String?;
        customEquipment = w['equipment'] as String?;
        customDifficulty = w['difficulty'] as String?;
        if (w['instructions'] is List) {
          customInstructions =
              (w['instructions'] as List).map((e) => e.toString()).toList();
        }
      } else if (w is Exercise) {
        rawName = w.name;
        customVideoPath = w.videoPath;
        customDescription = w.description;
        customTarget = w.target;
        customEquipment = w.equipment;
        customDifficulty = w.difficulty;
        customInstructions = w.instructions;
      } else {
        rawName = w.name as String;
        totalSets = (w.setNumber as num?)?.toInt() ?? 3;
        targetReps = (w.repNumber as num?)?.toInt() ?? 8;
      }

      final cleanName = ExerciseData.normalizeExerciseName(rawName);
      final cachedLog = WorkoutLogService.getCachedLastLog(cleanName);
      final initialProgression = ProgressionService.calculateNextTarget(
        exerciseName: cleanName,
        previousLog: cachedLog,
        defaultTargetReps: targetReps,
        equipment: customEquipment,
        category: widget.dayName,
      );
      final defaultWeightStr = initialProgression.formattedWeight;

      return _SessionExerciseState(
        exerciseName: cleanName,
        order: index,
        defaultSets: totalSets,
        defaultReps: targetReps,
        customVideoPath: customVideoPath,
        customDescription: customDescription,
        customTarget: customTarget,
        customEquipment: customEquipment,
        customDifficulty: customDifficulty,
        customInstructions: customInstructions,
        previousLog: cachedLog,
        progression: initialProgression,
        weightControllers: List.generate(
          totalSets,
          (_) => TextEditingController(text: defaultWeightStr),
        ),
        repControllers: List.generate(
          totalSets,
          (i) {
            if (cachedLog != null && cachedLog.sets.isNotEmpty) {
              if (initialProgression.type == ProgressionType.increaseWeight) {
                return TextEditingController(
                  text: '${initialProgression.targetMinReps}',
                );
              }
              if (i < cachedLog.sets.length && cachedLog.sets[i].reps > 0) {
                return TextEditingController(text: '${cachedLog.sets[i].reps}');
              }
            }
            return TextEditingController(text: '$targetReps');
          },
        ),
        setTypes: List.generate(totalSets, (_) => SetType.normal),
        isCompleted: List.generate(totalSets, (_) => false),
      );
    }).toList();
  }

  Future<void> _loadHistoryAndProgression() async {
    for (var ex in _exercises) {
      WorkoutLog? previousLog;
      try {
        previousLog = await _logService.getLastExerciseLog(ex.exerciseName);
      } catch (_) {
        previousLog = null;
      }
      final progression = ProgressionService.calculateNextTarget(
        exerciseName: ex.exerciseName,
        previousLog: previousLog,
        defaultTargetReps: ex.defaultReps,
        equipment: ex.customEquipment,
        category: widget.dayName,
      );

      if (mounted) {
        setState(() {
          ex.previousLog = previousLog;
          ex.progression = progression;
          ex.isLoadingHistory = false;

          // Auto-seed unedited sets with progression target / sensible default
          final seedWeightStr = progression.formattedWeight;
          final seedRepsStr = '${progression.targetMinReps}';

          for (int i = 0; i < ex.weightControllers.length; i++) {
            if (ex.isCompleted[i]) continue;

            if (!ex.isWeightUserEdited[i]) {
              ex.setProgrammaticWeight(i, seedWeightStr);
            }
            if (!ex.isRepsUserEdited[i]) {
              if (progression.type == ProgressionType.increaseWeight) {
                ex.setProgrammaticReps(i, seedRepsStr);
              } else if (previousLog != null &&
                  i < previousLog.sets.length &&
                  previousLog.sets[i].reps > 0) {
                ex.setProgrammaticReps(i, '${previousLog.sets[i].reps}');
              } else {
                ex.setProgrammaticReps(i, seedRepsStr);
              }
            }
          }
        });
      }
    }
  }

  // Rest Timer Controls (Non-blocking)
  void _triggerRestTimer(bool isCompound) {
    _restTimer?.cancel();
    final duration = isCompound ? 120 : 90;
    setState(() {
      _restSecondsRemaining = duration;
      _isRestTimerActive = true;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_restSecondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _isRestTimerActive = false;
          _restSecondsRemaining = 0;
        });
        _notifyRestFinished();
      } else {
        setState(() {
          _restSecondsRemaining--;
        });
      }
    });
  }

  /// Rest is over: buzz so it is felt with the phone in a pocket or locked.
  Future<void> _notifyRestFinished() async {
    Haptics.heavy();
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(pattern: [0, 300, 150, 300]);
      }
    } catch (_) {}
  }

  void _adjustRestTimer(int deltaSeconds) {
    setState(() {
      _restSecondsRemaining = (_restSecondsRemaining + deltaSeconds).clamp(5, 600);
      _isRestTimerActive = true;
    });
  }

  void _skipRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _isRestTimerActive = false;
      _restSecondsRemaining = 0;
    });
  }

  Exercise _resolveExerciseForSession(_SessionExerciseState ex) {
    final cleanName = ExerciseData.normalizeExerciseName(ex.exerciseName);
    final catalogExercise = ExerciseData.findByName(ex.exerciseName);
    final setsRepsLabel = '${ex.isCompleted.length} sets × ${ex.defaultReps} reps';

    if (catalogExercise != null) {
      return Exercise(
        name: catalogExercise.name,
        videoPath: (ex.customVideoPath != null && ex.customVideoPath!.trim().isNotEmpty)
            ? ex.customVideoPath!
            : catalogExercise.videoPath,
        description: ex.customDescription ?? catalogExercise.description,
        target: ex.customTarget ?? catalogExercise.target,
        equipment: ex.customEquipment ?? catalogExercise.equipment,
        difficulty: ex.customDifficulty ?? catalogExercise.difficulty,
        setsReps: setsRepsLabel,
        instructions: (ex.customInstructions != null &&
                ex.customInstructions!.isNotEmpty)
            ? ex.customInstructions!
            : catalogExercise.instructions,
      );
    }

    // Fallback: search across catalog for keyword match
    Exercise? fallbackCatalog;
    for (final candidate in ExerciseData.all) {
      if (ExerciseData.matchesSearchQuery(candidate, ex.exerciseName)) {
        fallbackCatalog = candidate;
        break;
      }
    }

    if (fallbackCatalog != null) {
      return Exercise(
        name: cleanName.isNotEmpty ? cleanName : fallbackCatalog.name,
        videoPath: (ex.customVideoPath != null && ex.customVideoPath!.trim().isNotEmpty)
            ? ex.customVideoPath!
            : fallbackCatalog.videoPath,
        description: ex.customDescription ?? fallbackCatalog.description,
        target: ex.customTarget ?? fallbackCatalog.target,
        equipment: ex.customEquipment ?? fallbackCatalog.equipment,
        difficulty: ex.customDifficulty ?? fallbackCatalog.difficulty,
        setsReps: setsRepsLabel,
        instructions: (ex.customInstructions != null &&
                ex.customInstructions!.isNotEmpty)
            ? ex.customInstructions!
            : fallbackCatalog.instructions,
      );
    }

    return Exercise(
      name: cleanName.isNotEmpty ? cleanName : ex.exerciseName,
      videoPath: ex.customVideoPath ?? '',
      description: ex.customDescription ??
          'Perform this exercise with controlled form and full range of motion.',
      target: ex.customTarget ??
          (ProgressionService.isCompound(ex.exerciseName)
              ? 'Compound Movement'
              : 'Target Muscle Group'),
      equipment: ex.customEquipment ?? 'Standard Gym Equipment',
      difficulty: ex.customDifficulty ?? 'Intermediate',
      setsReps: setsRepsLabel,
      instructions: (ex.customInstructions != null &&
              ex.customInstructions!.isNotEmpty)
          ? ex.customInstructions!
          : const [
              'Set up with proper posture and engage your core before starting the movement.',
              'Control the eccentric (lowering) phase and avoid using momentum.',
              'Complete your target reps while maintaining strict technique.',
            ],
    );
  }

  Future<void> _showExerciseDetails(_SessionExerciseState ex) async {
    if (_isDetailSheetOpen || !mounted) return;
    _isDetailSheetOpen = true;

    final resolvedExercise = _resolveExerciseForSession(ex);
    final category = ExerciseData.categoryFor(ex.exerciseName) ?? widget.dayName;

    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetContext) => InteractiveExerciseDetailWidget(
          name: resolvedExercise.name,
          videoPath: resolvedExercise.videoPath,
          description: resolvedExercise.description,
          target: resolvedExercise.target,
          equipment: resolvedExercise.equipment,
          instructions: resolvedExercise.instructions,
          difficulty: resolvedExercise.difficulty,
          setsReps: resolvedExercise.setsReps,
          category: category,
          videoControllerFactory: widget.videoControllerFactory,
          videoViewBuilder: widget.videoViewBuilder,
          initialSets: ex.toSetDrafts(),
          onSetsChanged: (drafts) {
            if (mounted) {
              final before = ex.completedSetsCount;
              setState(() {
                ex.applySetDrafts(drafts);
              });
              if (ex.completedSetsCount > before) {
                // One rest timer for the whole workout, started here too.
                if (_totalCompletedSets < _totalPlannedSets) {
                  _triggerRestTimer(ProgressionService.isCompound(ex.exerciseName));
                } else {
                  _skipRestTimer();
                }
              }
              _saveDraft();
            }
          },
        ),
      );
    } finally {
      _isDetailSheetOpen = false;
    }
  }

  // Exercise Substitution
  void _showSubstituteModal(_SessionExerciseState ex) {
    final alternatives = ExerciseSubstitutionService.getSubstitutions(ex.exerciseName);

    showModalBottomSheet(
      context: context,
      backgroundColor: ColorManager.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Substitute Exercise',
                      style: TextStyle(
                        color: ColorManager.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(tooltip: 'Close', 
                    icon: Icon(Icons.close, color: ColorManager.textTertiary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(
                'Select an alternative that targets the same muscle group:',
                style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
              ),
              SizedBox(height: 12.h),
              ...alternatives.map((altName) {
                return Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  decoration: BoxDecoration(
                    color: ColorManager.surfaceDark,
                    borderRadius: BorderRadius.circular(AppRadius.small.r),
                    border: Border.all(color: ColorManager.divider),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: Icon(Icons.swap_horiz_rounded, color: ColorManager.primaryText),
                      title: Text(
                        altName,
                        style: TextStyle(color: ColorManager.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: ColorManager.textTertiary),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _applySubstitution(ex, altName);
                      },
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _applySubstitution(_SessionExerciseState ex, String newExerciseName) async {
    final catalogExercise = ExerciseData.findByName(newExerciseName);
    setState(() {
      ex.exerciseName = newExerciseName;
      ex.customVideoPath = catalogExercise?.videoPath;
      ex.customDescription = catalogExercise?.description;
      ex.customTarget = catalogExercise?.target;
      ex.customEquipment = catalogExercise?.equipment;
      ex.customDifficulty = catalogExercise?.difficulty;
      ex.customInstructions = catalogExercise?.instructions;
      ex.isLoadingHistory = true;
    });

    WorkoutLog? previousLog;
    try {
      previousLog = await _logService.getLastExerciseLog(newExerciseName);
    } catch (_) {
      previousLog = null;
    }
    final progression = ProgressionService.calculateNextTarget(
      exerciseName: newExerciseName,
      previousLog: previousLog,
      defaultTargetReps: ex.defaultReps,
      category: widget.dayName,
    );

    if (mounted) {
      setState(() {
        ex.previousLog = previousLog;
        ex.progression = progression;
        ex.isLoadingHistory = false;

        final seedWeightStr = progression.formattedWeight;

        for (int i = 0; i < ex.weightControllers.length; i++) {
          if (!ex.isCompleted[i]) {
            ex.isWeightUserEdited[i] = false;
            ex.isRepsUserEdited[i] = false;
            ex.setProgrammaticWeight(i, seedWeightStr);
            if (progression.type != ProgressionType.increaseWeight &&
                previousLog != null &&
                i < previousLog.sets.length &&
                previousLog.sets[i].reps > 0) {
              ex.setProgrammaticReps(i, '${previousLog.sets[i].reps}');
            } else {
              ex.setProgrammaticReps(i, '${progression.targetMinReps}');
            }
          }
        }
      });
    }
  }

  double get _totalSessionVolume {
    double vol = 0;
    for (var ex in _exercises) {
      vol += ex.volume;
    }
    return vol;
  }

  int get _totalCompletedSets {
    int count = 0;
    for (var ex in _exercises) {
      count += ex.completedSetsCount;
    }
    return count;
  }

  int get _totalPlannedSets {
    int count = 0;
    for (var ex in _exercises) {
      count += ex.isCompleted.length;
    }
    return count;
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Gathers what the reward screen celebrates. Every lookup is best-effort:
  /// a failure only means that card is left out, never that saving fails.
  Future<WorkoutRewardData> _collectRewards(
      WorkoutSession session, int streakBefore) async {
    if (!mounted) {
      return WorkoutRewardData(
          streakBefore: streakBefore, streakAfter: streakBefore);
    }
    int streakAfter = streakBefore;
    int longest = 0;
    int thisWeek = 0;
    int target = 3;
    List<AchievementDef> unlocked = const [];
    BadgeProgress? next;

    try {
      final stats = Provider.of<StatisticsProvider?>(context, listen: false);
      if (stats != null) {
        streakAfter = stats.currentStreak;
        longest = stats.longestStreak;
        thisWeek = stats.workoutsCompletedThisWeek;
        target = stats.weeklyTarget;

        final ids = stats.consumeNewlyUnlocked();
        unlocked = [
          for (final id in ids)
            ...allAchievements.where((a) => a.id == id),
        ];
        next = nextBadgeProgress(
          unlocked: stats.unlockedAchievements,
          totalWorkouts: stats.totalWorkouts,
          currentStreak: stats.currentStreak,
        );
      }
    } catch (_) {}

    // What comes next in the weekly plan (best effort).
    String? nextUp;
    try {
      final wp = Provider.of<WorkoutProvider?>(context, listen: false);
      if (wp != null) {
        final grouped = wp.groupedSplitWorkouts;
        final split = splitPlanDays(grouped.keys, DateTime.now());
        // Today's plan day is the one just finished, so look past it.
        final next = widget.dayName == split.today
            ? (split.later.isEmpty ? null : split.later.first)
            : split.nextUp;
        if (next != null && next != widget.dayName) {
          final n = grouped[next]?.length ?? 0;
          nextUp = n > 0 ? '$next · $n exercise${n == 1 ? '' : 's'}' : next;
        }
      }
    } catch (_) {}

    var prs = const <PersonalRecord>[];
    try {
      final all = await _logService
          .getSessionsFuture(limit: 200)
          .timeout(const Duration(seconds: 3));
      prs = SessionRewards.meaningfulPRs(session: session, allSessions: all);
    } catch (_) {}

    return WorkoutRewardData(
      streakBefore: streakBefore,
      streakAfter: streakAfter,
      longestStreak: longest,
      newPRs: prs,
      unlockedBadges: unlocked,
      workoutsThisWeek: thisWeek,
      weeklyTarget: target,
      nextBadge: next,
      nextUp: nextUp,
    );
  }

  // Finish Workout (Full or Partial)
  Future<void> _finishWorkout({required bool isPartial}) async {
    if (_isSaving || _isSessionFinished) return;
    setState(() => _isSaving = true);

    try {
      String uid = '';
      try {
        uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      } catch (_) {}

      final workoutProvider =
          Provider.of<WorkoutProvider?>(context, listen: false);
      final now = workoutProvider?.currentNow ?? DateTime.now();

      final List<SessionExercise> sessionExercises = [];
      for (var ex in _exercises) {
        final List<WorkoutSet> sets = [];
        for (int i = 0; i < ex.isCompleted.length; i++) {
          final w = double.tryParse(ex.weightControllers[i].text) ?? 0.0;
          final r = int.tryParse(ex.repControllers[i].text) ?? ex.defaultReps;
          sets.add(WorkoutSet(
            weight: w,
            reps: r,
            type: ex.setTypes[i],
            isCompleted: ex.isCompleted[i],
          ));
        }

        final bool hasAnyCompleted = ex.isCompleted.any((c) => c);
        if (hasAnyCompleted || !isPartial) {
          sessionExercises.add(SessionExercise(
            exerciseName: ex.exerciseName,
            order: ex.order,
            sets: sets,
            isCompleted: ex.isCompleted.every((c) => c),
          ));
        }
      }

      final session = WorkoutSession(
        id: _sessionId ??= 'session_${now.millisecondsSinceEpoch}',
        userId: uid,
        workoutName: '${widget.dayName} Routine',
        dayName: widget.dayName,
        startedAt: _startedAt,
        completedAt: now,
        durationSeconds: () {
          final wall = DateTime.now().difference(_startedAt).inSeconds;
          return wall > _elapsedSeconds ? wall : _elapsedSeconds;
        }(),
        status: isPartial ? 'partial' : 'completed',
        totalVolume: _totalSessionVolume,
        exercises: sessionExercises,
        planId: widget.planId,
        planDay: widget.planDay,
      );

      // Atomic Batch Save. This is the one step that must succeed.
      await _logService.saveWorkoutSession(session);
      await _clearDraft();

      // Everything below is best effort. The workout is already saved, so a
      // failure here must never show "Failed to save" or invite a second save.
      int streakBefore = 0;
      var reward = const WorkoutRewardData();
      try {
        if (mounted) {
          final statsProvider =
              Provider.of<StatisticsProvider?>(context, listen: false);
          try {
            streakBefore = statsProvider?.currentStreak ?? 0;
          } catch (_) {}
          await statsProvider?.updateStreak();
        }
        reward = await _collectRewards(session, streakBefore);
      } catch (e) {
        debugPrint('Post-save streak/reward step failed: $e');
      }

      try {
        // Mark day-specific SharedPreferences flag (never mark a shared "any routine" flag for today)
        final prefs = await SharedPreferences.getInstance();
        final todayKey = DateFormat('yyyy-MM-dd').format(now);
        await prefs.setBool(
            'completed_routine_${widget.dayName}_$todayKey', true);

        // Notify WorkoutProvider with day-specific completion
        if (mounted) {
          Provider.of<WorkoutProvider?>(context, listen: false)
              ?.markWorkoutDayCompleted(widget.dayName, completedAt: now);
        }
      } catch (e) {
        debugPrint('Post-save completion flag step failed: $e');
      }

      // If this session is part of an active Transformation Plan, synchronize day completion
      if (mounted && widget.planDay != null) {
        try {
          final transformationProvider =
              Provider.of<TransformationProvider?>(context, listen: false);
          if (transformationProvider != null &&
              transformationProvider.hasActiveTransformation) {
            final active = transformationProvider.activeTransformation!;
            if (widget.planId == null || active.planId == widget.planId) {
              await transformationProvider.markDayCompleted(widget.planDay!);
            }
          }
        } catch (tpError) {
          debugPrint('TransformationProvider synchronization error: $tpError');
        }
      }

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isSessionFinished = true;
        _finishedSession = session;
        _reward = reward;
      });
      UpdateService().setWorkoutSessionActive(false);
    } catch (e) {
      debugPrint('Error saving workout session: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Couldn't save your workout. Check your connection and try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ---- Draft: survive a crash, a call or the app being closed ------------

  Future<void> _saveDraft() async {
    if (_isSessionFinished) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_totalCompletedSets == 0) {
        await prefs.remove(_draftKey);
        return;
      }
      final data = <String, dynamic>{
        'dayName': widget.dayName,
        'planId': widget.planId,
        'planDay': widget.planDay,
        'elapsedSeconds': _elapsedSeconds,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'exercises': [
          for (final ex in _exercises)
            {
              'name': ex.exerciseName,
              'weights': ex.weightControllers.map((c) => c.text).toList(),
              'reps': ex.repControllers.map((c) => c.text).toList(),
              'types': ex.setTypes.map((t) => t.name).toList(),
              'done': ex.isCompleted.toList(),
            },
        ],
      };
      await prefs.setString(_draftKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
    } catch (_) {}
  }

  Future<void> _offerResumeIfDraft() async {
    Map<String, dynamic>? draft;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey);
      if (raw == null) return;
      draft = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt =
          DateTime.fromMillisecondsSinceEpoch((draft['savedAt'] as num).toInt());
      if (DateTime.now().difference(savedAt) > const Duration(hours: 12)) {
        await prefs.remove(_draftKey);
        return;
      }
    } catch (_) {
      return;
    }
    final map = draft;

    try {
      if (map['dayName'] != widget.dayName) return;
      final saved = (map['exercises'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (saved.length < _exercises.length) return;
      final doneCount = saved.fold<int>(
          0,
          (sum, e) =>
              sum + (e['done'] as List).where((d) => d == true).length);
      if (doneCount == 0 || !mounted) return;

      final resume = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
          backgroundColor: ColorManager.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
          title: Text('Resume workout?',
              style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold)),
          content: Text(
            'You have an unfinished ${widget.dayName} workout with $doneCount logged sets. Pick up where you left off?',
            style: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp),
          ),
          actions: [
            TextButton(
              key: const Key('session_resume_start_fresh'),
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Start fresh'),
            ),
            ElevatedButton(
              key: const Key('session_resume_confirm'),
              onPressed: () => Navigator.pop(c, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary),
              child: const Text('Resume',
                  style: TextStyle(
                      color: ColorManager.onMint, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (resume != true) {
        await _clearDraft();
        return;
      }

      // Exercises added during the workout are added back first.
      while (_exercises.length < saved.length) {
        final found =
            ExerciseData.findByName(saved[_exercises.length]['name'] as String? ?? '');
        if (found == null) return;
        _addExercise(found);
      }
      for (var i = 0; i < saved.length; i++) {
        final name = saved[i]['name'] as String? ?? _exercises[i].exerciseName;
        if (name != _exercises[i].exerciseName) {
          await _applySubstitution(_exercises[i], name);
        }
      }
      if (!mounted) return;
      setState(() {
        final elapsed = (map['elapsedSeconds'] as num?)?.toInt() ?? 0;
        _elapsedSeconds = elapsed;
        _startedAt = DateTime.now().subtract(Duration(seconds: elapsed));
        for (var i = 0; i < saved.length; i++) {
          final ex = _exercises[i];
          final weights = List<String>.from(saved[i]['weights'] as List);
          final reps = List<String>.from(saved[i]['reps'] as List);
          final types = List<String>.from(saved[i]['types'] as List);
          final done = List<bool>.from(saved[i]['done'] as List);
          while (ex.weightControllers.length < weights.length) {
            ex.addSet();
          }
          while (ex.weightControllers.length > weights.length &&
              ex.weightControllers.length > 1) {
            ex.removeSet(ex.weightControllers.length - 1);
          }
          for (var j = 0; j < ex.weightControllers.length && j < weights.length; j++) {
            ex.setProgrammaticWeight(j, weights[j]);
            ex.setProgrammaticReps(j, reps[j]);
            ex.isWeightUserEdited[j] = true;
            ex.isRepsUserEdited[j] = true;
            ex.setTypes[j] = SetType.values.firstWhere(
              (t) => t.name == types[j],
              orElse: () => SetType.normal,
            );
            ex.isCompleted[j] = done[j];
          }
        }
      });
    } catch (e) {
      debugPrint('Could not restore workout draft: $e');
    }
  }

  Future<void> _loadSectionPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final warm = prefs.getBool(_warmupOpenKey);
      final cool = prefs.getBool(_cooldownOpenKey);
      if (!mounted) return;
      if (warm != null || cool != null) {
        setState(() {
          _isWarmupExpanded = warm ?? _isWarmupExpanded;
          _isCooldownExpanded = cool ?? _isCooldownExpanded;
        });
      }
    } catch (_) {}
  }

  Future<void> _rememberSection(String key, bool open) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, open);
    } catch (_) {}
  }

  Future<bool> _onWillPop() async {
    if (_isSessionFinished) return true;

    final hasCompletedSets = _totalCompletedSets > 0;
    if (!hasCompletedSets) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: ColorManager.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text('Exit Workout?', style: TextStyle(color: ColorManager.textPrimary)),
          content: Text('No sets have been logged yet.', style: TextStyle(color: ColorManager.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Exit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return discard ?? false;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ColorManager.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
        title: Row(
          children: [
            Icon(Icons.save_outlined, color: ColorManager.primary, size: 22.sp),
            SizedBox(width: 8.w),
            Text('Finish Early?', style: TextStyle(color: ColorManager.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'You completed $_totalCompletedSets sets. Would you like to save your completed sets or discard the session?',
          style: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, 'continue'),
            child: Text('Continue Workout', style: TextStyle(color: ColorManager.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, 'discard'),
            child: const Text('Discard', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, 'save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button.r)),
            ),
            child: const Text('Save & Finish', style: TextStyle(color: ColorManager.onMint, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result == 'save') {
      await _finishWorkout(isPartial: true);
      return false; // Handled by completion screen
    } else if (result == 'discard') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: ColorManager.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
          title: Text('Discard workout?',
              style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold)),
          content: Text(
            "Your $_totalCompletedSets logged sets will be deleted. This can't be undone.",
            style: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp),
          ),
          actions: [
            TextButton(
              key: const Key('session_keep_workout'),
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Keep workout'),
            ),
            ElevatedButton(
              key: const Key('session_confirm_discard'),
              onPressed: () => Navigator.pop(c, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Discard', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await _clearDraft();
        return true;
      }
      return false;
    }
    return false;
  }

  void _closeSession() {
    if (!mounted) return;
    final goRouter = GoRouter.maybeOf(context);
    if (goRouter != null && goRouter.canPop()) {
      goRouter.pop();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (goRouter != null) {
      goRouter.go(Routes.mainRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSessionFinished && _finishedSession != null) {
      return _buildCompletionView();
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: ColorManager.background,
        appBar: AppBar(
          backgroundColor: ColorManager.surface,
          elevation: 0,
          leading: IconButton(tooltip: 'Close', 
            icon: Icon(Icons.close_rounded, color: ColorManager.textPrimary),
            onPressed: () async {
              final pop = await _onWillPop();
              if (pop && mounted) _closeSession();
            },
          ),
          centerTitle: true,
          title: Column(
            children: [
              Text(
                '${widget.dayName} Routine',
                style: TextStyle(
                  color: ColorManager.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 12.sp, color: ColorManager.primaryText),
                    SizedBox(width: 4.w),
                    Text(_formatTimer(_elapsedSeconds), style: TextStyle(color: ColorManager.primaryText, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8.w),
                    Text('•', style: TextStyle(color: ColorManager.textTertiary)),
                    SizedBox(width: 8.w),
                    Text('${_totalSessionVolume.toStringAsFixed(0)} kg', style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp)),
                    SizedBox(width: 8.w),
                    Text('•', style: TextStyle(color: ColorManager.textTertiary)),
                    SizedBox(width: 8.w),
                    Text('$_totalCompletedSets/$_totalPlannedSets sets', style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.fitness_center_rounded, color: ColorManager.primaryText, size: 20.sp),
              tooltip: 'Plate Calculator',
              onPressed: () => PlateCalculatorSheet.show(context),
            ),
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: TextButton(
                onPressed: _totalCompletedSets > 0 && !_isSaving
                    ? () => _finishWorkout(isPartial: _totalCompletedSets < _totalPlannedSets)
                    : null,
                child: _isSaving
                    ? SizedBox(width: 16.w, height: 16.h, child: const CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        'Finish',
                        style: TextStyle(
                          color: _totalCompletedSets > 0 ? ColorManager.primary : ColorManager.textTertiary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Single Scrollable Table of Warmup, Exercises, and Cooldown
            ListView.builder(
              padding: EdgeInsets.only(
                left: 14.w,
                right: 14.w,
                top: 14.h,
                bottom: (_isRestTimerActive || _allSetsDone) ? 90.h : 30.h,
              ),
              itemCount: _exercises.length + 3,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildWarmupCard();
                } else if (index <= _exercises.length) {
                  return _buildExerciseCard(_exercises[index - 1], index - 1);
                } else if (index == _exercises.length + 1) {
                  return _buildAddExerciseButton();
                } else {
                  return _buildCooldownCard();
                }
              },
            ),

            // Persistent Non-Blocking Rest Timer (Slides up from bottom)
            if (_isRestTimerActive)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildPersistentRestBar(),
              ),

            // Once every set is ticked the next step is obvious and within
            // thumb reach: a full-width Finish bar at the bottom.
            if (_allSetsDone && !_isRestTimerActive)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildFinishBar(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(_SessionExerciseState ex, int exerciseIndex) {
    final bool isCompound = ProgressionService.isCompound(ex.exerciseName);

    return Container(
      key: Key('session_exercise_card_${ex.order}'),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(
          color: ex.isAllCompleted
              ? const Color(0xFF4CAF50).withValues(alpha: 0.5)
              : ColorManager.divider,
        ),
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Title Row: Tappable Exercise Name + Guide Button + Swap Button
          Row(
            children: [
              Expanded(
                child: InkWell(
                  key: Key('session_exercise_tap_${ex.order}'),
                  onTap: () => _showExerciseDetails(ex),
                  borderRadius: BorderRadius.circular(8.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${exerciseIndex + 1}. ${ex.exerciseName}',
                                style: TextStyle(
                                  color: ColorManager.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Icon(
                              Icons.play_circle_outline_rounded,
                              size: 16.sp,
                              color: ColorManager.primaryText,
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: ColorManager.surfaceDark,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                isCompound ? 'COMPOUND' : 'ACCESSORY',
                                style: TextStyle(
                                  color: isCompound ? ColorManager.primary : ColorManager.textTertiary,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Flexible(
                              child: Text(
                                '${ex.completedSetsCount}/${ex.isCompleted.length} sets completed',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              // Guide / Video Demonstration Button
              InkWell(
                key: Key('session_exercise_guide_${ex.order}'),
                onTap: () => _showExerciseDetails(ex),
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: ColorManager.surfaceDark,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: ColorManager.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.ondemand_video_rounded, size: 14.sp, color: ColorManager.primaryText),
                      SizedBox(width: 4.w),
                      Text('Guide', style: TextStyle(color: ColorManager.primaryText, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              // Swap Button
              InkWell(
                key: Key('session_exercise_swap_${ex.order}'),
                onTap: () => _showSubstituteModal(ex),
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: ColorManager.surfaceDark,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: ColorManager.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 14.sp, color: ColorManager.primaryText),
                      SizedBox(width: 4.w),
                      Text('Swap', style: TextStyle(color: ColorManager.primaryText, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // 2. Progressive Overload Target Banner (Deterministic Double Progression)
          if (ex.progression != null)
            Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: ColorManager.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: ColorManager.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, color: ColorManager.primaryText, size: 18.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                ex.progression!.badgeLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: ColorManager.primaryText, fontSize: 11.sp, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Flexible(
                              child: Text(
                                ex.progression!.targetSummary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: TextStyle(color: ColorManager.white, fontSize: 11.sp, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          ex.progression!.reason,
                          style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // 3. Set Table Headers: [SET] | [PREV] | [KG] | [REPS] | [DONE]
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              children: [
                SizedBox(width: 28.w, child: Center(child: Text('SET', style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp, fontWeight: FontWeight.bold)))),
                SizedBox(width: 56.w, child: Center(child: Text('PREV', style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp, fontWeight: FontWeight.bold)))),
                Expanded(flex: 6, child: Center(child: Text('KG', style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp, fontWeight: FontWeight.bold)))),
                Expanded(flex: 5, child: Center(child: Text('REPS', style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp, fontWeight: FontWeight.bold)))),
                SizedBox(width: 48.w, child: Center(child: Text('DONE', style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp, fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
          const Divider(height: 1),

          // 4. Set Rows
          ...List.generate(ex.isCompleted.length, (setIdx) {
            return _buildSetRow(ex, setIdx, isCompound);
          }),

          // 5. Card Footer: [+ Add Set] & [- Remove Set]
          SizedBox(height: 8.h),
          Row(
            children: [
              TextButton.icon(
                key: Key('session_add_set_${ex.order}'),
                onPressed: () {
                  setState(() {
                    ex.addSet();
                  });
                  _saveDraft();
                },
                icon: Icon(Icons.add_rounded, size: 14.sp, color: ColorManager.primaryText),
                label: Text('Add Set', style: TextStyle(color: ColorManager.primaryText, fontSize: 11.sp, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                key: Key('session_weight_step_${ex.order}'),
                onPressed: () => _cycleWeightStep(ex, isCompound),
                child: Text(
                  'Step ${_fmtKg(_stepFor(ex, isCompound))} kg',
                  style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
                ),
              ),
              const Spacer(),
              if (ex.isCompleted.length > 1)
                TextButton(
                  key: Key('session_remove_set_${ex.order}'),
                  onPressed: () {
                    setState(() {
                      ex.removeSet(ex.isCompleted.length - 1);
                    });
                    _saveDraft();
                  },
                  child: Text('Remove Set', style: TextStyle(color: Colors.redAccent.shade100, fontSize: 11.sp)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(_SessionExerciseState ex, int setIdx, bool isCompound) {
    final isDone = ex.isCompleted[setIdx];
    final resolvedExercise = _resolveExerciseForSession(ex);
    final isBarbell = PlateCalculatorSheet.isBarbellExercise(
      name: resolvedExercise.name,
      equipment: resolvedExercise.equipment,
    );

    // Previous Performance Ghost Value
    String prevStr = '—';
    if (ex.previousLog != null && setIdx < ex.previousLog!.sets.length) {
      final prevSet = ex.previousLog!.sets[setIdx];
      prevStr = '${prevSet.weight.toStringAsFixed(prevSet.weight % 1 == 0 ? 0 : 1)}×${prevSet.reps}';
    }

    final row = Container(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFF1E4331).withValues(alpha: 0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          // 1. Set Number Badge
          SizedBox(
            width: 28.w,
            child: Center(
              child: Tooltip(
                message: 'Tap to change set type',
                child: InkWell(
                  key: Key('session_set_type_${ex.order}_$setIdx'),
                  onTap: () => _cycleSetType(ex, setIdx),
                  borderRadius: BorderRadius.circular(10.r),
                  child: SizedBox(
                    width: 28.w,
                    height: 44.h,
                    child: Center(
                      child: Container(
                        width: 22.w,
                        height: 22.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? const Color(0xFF4CAF50)
                              : _setTypeColor(ex.setTypes[setIdx])
                                  .withValues(alpha: ex.setTypes[setIdx] == SetType.normal ? 1 : 0.25),
                          border: ex.setTypes[setIdx] == SetType.normal
                              ? null
                              : Border.all(color: _setTypeColor(ex.setTypes[setIdx]), width: 1),
                        ),
                        child: Center(
                          child: Text(
                            _setTypeLabel(ex.setTypes[setIdx], setIdx),
                            style: TextStyle(
                              color: isDone ? Colors.white : ColorManager.textSecondary,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Ghost Text: Previous Performance
          SizedBox(
            width: 56.w,
            child: Center(
              child: Text(
                prevStr,
                style: TextStyle(
                  color: ColorManager.textTertiary,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // 3. Weight Input Field + Stepper (+ Barbell Plate Calculator)
          Expanded(
            flex: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepperButton(
                  icon: Icons.remove,
                  onTap: isDone ? null : () {
                    final curr = double.tryParse(ex.weightControllers[setIdx].text) ?? 0.0;
                    final next = (curr - _stepFor(ex, isCompound)).clamp(0.0, 500.0);
                    ex.weightControllers[setIdx].text = _fmtKg(next);
                    setState(() {});
                  },
                ),
                SizedBox(width: isBarbell ? 2.w : 4.w),
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isBarbell ? 38.w : 46.w),
                    child: SizedBox(
                      height: 32.h,
                      child: TextField(
                        key: Key('session_weight_input_${ex.order}_$setIdx'),
                        controller: ex.weightControllers[setIdx],
                        enabled: !isDone,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: ColorManager.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: '—',
                          hintStyle: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp),
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: ColorManager.surfaceDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isBarbell ? 2.w : 4.w),
                _buildStepperButton(
                  icon: Icons.add,
                  onTap: isDone ? null : () {
                    final curr = double.tryParse(ex.weightControllers[setIdx].text) ?? 0.0;
                    final next = (curr + _stepFor(ex, isCompound)).clamp(0.0, 500.0);
                    ex.weightControllers[setIdx].text = _fmtKg(next);
                    setState(() {});
                  },
                ),
                if (isBarbell) ...[
                  SizedBox(width: 3.w),
                  _buildPlateCalcButton(ex, setIdx, isDone),
                ],
              ],
            ),
          ),

          // 4. Reps Input Field + Stepper
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepperButton(
                  icon: Icons.remove,
                  onTap: isDone ? null : () {
                    final curr = int.tryParse(ex.repControllers[setIdx].text) ?? ex.defaultReps;
                    final next = (curr - 1).clamp(1, 100);
                    ex.repControllers[setIdx].text = '$next';
                    setState(() {});
                  },
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 38.w),
                    child: SizedBox(
                      height: 32.h,
                      child: TextField(
                        key: Key('session_reps_input_${ex.order}_$setIdx'),
                        controller: ex.repControllers[setIdx],
                        enabled: !isDone,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: ColorManager.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: ColorManager.surfaceDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                _buildStepperButton(
                  icon: Icons.add,
                  onTap: isDone ? null : () {
                    final curr = int.tryParse(ex.repControllers[setIdx].text) ?? ex.defaultReps;
                    final next = curr + 1;
                    ex.repControllers[setIdx].text = '$next';
                    setState(() {});
                  },
                ),
              ],
            ),
          ),

          // 5. 1-Tap Done Button
          SizedBox(
            width: 48.w,
            child: Center(
              child: InkWell(
                key: Key('session_set_done_${ex.order}_$setIdx'),
                onTap: () {
                  setState(() {
                    ex.isCompleted[setIdx] = !ex.isCompleted[setIdx];
                  });

                  if (ex.isCompleted[setIdx]) {
                    // Felt confirmation for every ticked set.
                    Haptics.light();
                    // Rest only while sets remain. After the last set of the
                    // whole workout there is nothing to rest for.
                    if (_totalCompletedSets < _totalPlannedSets) {
                      _triggerRestTimer(isCompound);
                    } else {
                      _skipRestTimer();
                    }
                  }
                  _saveDraft();
                },
                borderRadius: BorderRadius.circular(10.r),
                child: SizedBox(
                  width: 48.w,
                  height: 44.h,
                  child: Center(
                    child: Container(
                      width: 32.w,
                      height: 32.h,
                      decoration: BoxDecoration(
                        color: isDone ? const Color(0xFF4CAF50) : ColorManager.surfaceDark,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: isDone ? const Color(0xFF81C784) : ColorManager.divider,
                        ),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 16.sp,
                        color: isDone ? Colors.white : ColorManager.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Swipe a row left to delete that set (a workout keeps at least one).
    return Dismissible(
      key: ObjectKey(ex.weightControllers[setIdx]),
      direction: ex.isCompleted.length > 1
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16.w),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(Icons.delete_outline_rounded,
            color: Colors.redAccent, size: 20.sp),
      ),
      onDismissed: (_) {
        setState(() => ex.removeSet(setIdx));
        _saveDraft();
      },
      child: row,
    );
  }

  Widget _buildStepperButton({required IconData icon, VoidCallback? onTap}) {
    // Same 18 x 24 look; the tappable box is 44 tall (the width is capped by
    // the row, so it grows only as far as the layout allows).
    // Tap to step once; press and hold to keep stepping (dumbbell jumps, reps).
    return _HoldRepeat(
      onStep: onTap,
      child: SizedBox(
        width: 24.w,
        height: 44.h,
        child: Center(
          child: Container(
            width: 18.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: ColorManager.surfaceDark,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Icon(icon, size: 11.sp, color: onTap != null ? ColorManager.textSecondary : Colors.white24),
          ),
        ),
      ),
    );
  }

  Widget _buildPlateCalcButton(_SessionExerciseState ex, int setIdx, bool isDone) {
    return Tooltip(
      message: 'Barbell Plate Calculator',
      child: InkWell(
        key: Key('session_plate_calc_${ex.order}_$setIdx'),
        onTap: isDone ? null : () => _openPlateCalculator(ex, setIdx),
        borderRadius: BorderRadius.circular(8.r),
        child: SizedBox(
          width: 24.w,
          height: 44.h,
          child: Center(
            child: Container(
              width: 20.w,
              height: 24.h,
              decoration: BoxDecoration(
                color: isDone
                    ? ColorManager.surfaceDark
                    : ColorManager.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(
                  color: isDone
                      ? Colors.white12
                      : ColorManager.primary.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.calculate_outlined,
                  size: 13.sp,
                  color: isDone ? Colors.white24 : ColorManager.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openPlateCalculator(_SessionExerciseState ex, int setIdx) {
    final currWeight =
        double.tryParse(ex.weightControllers[setIdx].text) ?? 0.0;
    final initialWeight = currWeight > 0 ? currWeight : 60.0;

    PlateCalculatorSheet.show(
      context,
      initialWeight: initialWeight,
      onWeightApplied: (appliedWeight) {
        final formatted = appliedWeight % 1 == 0
            ? appliedWeight.toInt().toString()
            : appliedWeight.toStringAsFixed(1);
        setState(() {
          ex.setProgrammaticWeight(setIdx, formatted);
          ex.isWeightUserEdited[setIdx] = true;
        });
      },
    );
  }

  // ---- Weight step ----------------------------------------------------------

  static const List<double> _weightSteps = [1.0, 1.25, 2.0, 2.5, 5.0];

  /// Compound lifts step 2.5 kg and other exercises 1 kg until the lifter
  /// picks a step for that exercise (for example 1.25 kg micro-plates).
  double _stepFor(_SessionExerciseState ex, bool isCompound) =>
      ex.weightStep ?? (isCompound ? 2.5 : 1.0);

  /// 100, 102.5 and 101.25 all print without padding zeros.
  String _fmtKg(double v) {
    if (v % 1 == 0) return v.toStringAsFixed(0);
    if ((v * 10) % 1 == 0) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }

  void _cycleWeightStep(_SessionExerciseState ex, bool isCompound) {
    final current = _stepFor(ex, isCompound);
    final i = _weightSteps.indexOf(current);
    setState(() {
      ex.weightStep = _weightSteps[(i + 1) % _weightSteps.length];
    });
  }

  // ---- Set types ----------------------------------------------------------

  Color _setTypeColor(SetType t) {
    switch (t) {
      case SetType.warmup:
        return Colors.amber;
      case SetType.drop:
        return Colors.purpleAccent;
      case SetType.failure:
        return Colors.redAccent;
      case SetType.normal:
        return ColorManager.surfaceDark;
    }
  }

  String _setTypeLabel(SetType t, int setIdx) {
    switch (t) {
      case SetType.warmup:
        return 'W';
      case SetType.drop:
        return 'D';
      case SetType.failure:
        return 'F';
      case SetType.normal:
        return '${setIdx + 1}';
    }
  }

  /// Normal -> warm-up -> drop -> failure -> normal.
  void _cycleSetType(_SessionExerciseState ex, int setIdx) {
    Haptics.light();
    setState(() {
      final next = (ex.setTypes[setIdx].index + 1) % SetType.values.length;
      ex.setTypes[setIdx] = SetType.values[next];
    });
    _saveDraft();
  }

  // ---- Add an exercise during the workout -----------------------------------

  void _addExercise(Exercise picked) {
    const sets = 3;
    const reps = 8;
    final cleanName = ExerciseData.normalizeExerciseName(picked.name);
    final cachedLog = WorkoutLogService.getCachedLastLog(cleanName);
    final progression = ProgressionService.calculateNextTarget(
      exerciseName: cleanName,
      previousLog: cachedLog,
      defaultTargetReps: reps,
      equipment: picked.equipment,
      category: widget.dayName,
    );
    final ex = _SessionExerciseState(
      exerciseName: cleanName,
      order: _exercises.length,
      defaultSets: sets,
      defaultReps: reps,
      customVideoPath: picked.videoPath,
      customDescription: picked.description,
      customTarget: picked.target,
      customEquipment: picked.equipment,
      customDifficulty: picked.difficulty,
      customInstructions: picked.instructions,
      previousLog: cachedLog,
      progression: progression,
      weightControllers: List.generate(
          sets, (_) => TextEditingController(text: progression.formattedWeight)),
      repControllers: List.generate(sets,
          (_) => TextEditingController(text: '${progression.targetMinReps}')),
      setTypes: List.generate(sets, (_) => SetType.normal),
      isCompleted: List.generate(sets, (_) => false),
    );
    setState(() => _exercises.add(ex));
    _loadHistoryAndProgression();
  }

  Future<void> _showAddExerciseSheet() async {
    final picked = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorManager.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        var query = '';
        return StatefulBuilder(builder: (ctx, setSheetState) {
          final all = ExerciseData.all;
          final matches = (query.trim().isEmpty
                  ? all
                  : all.where((e) => ExerciseData.matchesSearchQuery(e, query)))
              .take(60)
              .toList();
          return Padding(
            padding: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              top: 16.h,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16.h,
            ),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add exercise',
                      style: TextStyle(
                          color: ColorManager.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 10.h),
                  TextField(
                    key: const Key('session_add_exercise_search'),
                    autofocus: false,
                    onChanged: (v) => setSheetState(() => query = v),
                    style: TextStyle(color: ColorManager.white, fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: 'Search exercises',
                      hintStyle: TextStyle(color: ColorManager.textTertiary),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: ColorManager.textTertiary),
                      filled: true,
                      fillColor: ColorManager.surfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Expanded(
                    child: matches.isEmpty
                        ? Center(
                            child: Text('No exercise found',
                                style: TextStyle(
                                    color: ColorManager.textSecondary)))
                        : ListView.builder(
                            itemCount: matches.length,
                            itemBuilder: (_, i) {
                              final e = matches[i];
                              return ListTile(
                                key: Key('session_add_exercise_option_$i'),
                                contentPadding: EdgeInsets.zero,
                                title: Text(e.name,
                                    style: TextStyle(
                                        color: ColorManager.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.sp)),
                                subtitle: Text(e.target,
                                    style: TextStyle(
                                        color: ColorManager.textTertiary,
                                        fontSize: 12.sp)),
                                trailing: Icon(Icons.add_circle_outline_rounded,
                                    color: ColorManager.primaryText),
                                onTap: () => Navigator.pop(ctx, e),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
    if (picked != null && mounted) {
      _addExercise(picked);
      _saveDraft();
    }
  }

  Widget _buildAddExerciseButton() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: OutlinedButton.icon(
        key: const Key('session_add_exercise_button'),
        onPressed: _showAddExerciseSheet,
        icon: Icon(Icons.add_rounded, color: ColorManager.primary, size: 18.sp),
        label: Text('Add exercise',
            style: TextStyle(
                color: ColorManager.primary,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          minimumSize: Size.fromHeight(48.h),
          side: BorderSide(color: ColorManager.primary.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button.r)),
        ),
      ),
    );
  }

  bool get _allSetsDone =>
      _totalPlannedSets > 0 && _totalCompletedSets >= _totalPlannedSets;

  Widget _buildFinishBar() {
    return Container(
      key: const Key('session_finish_bar'),
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        border: Border(
            top: BorderSide(
                color: ColorManager.primary.withValues(alpha: 0.4), width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            key: const Key('session_finish_workout_button'),
            onPressed: _isSaving ? null : () => _finishWorkout(isPartial: false),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
              foregroundColor: ColorManager.onMint,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button.r)),
            ),
            child: _isSaving
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: const CircularProgressIndicator(
                        strokeWidth: 2, color: ColorManager.onMint))
                : Text('Finish workout',
                    style: TextStyle(
                        fontSize: 16.sp, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  // Persistent Non-blocking Rest Bar
  Widget _buildPersistentRestBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        border: Border(top: BorderSide(color: ColorManager.primary.withValues(alpha: 0.4), width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Icon(Icons.timer_outlined, color: ColorManager.primary, size: 20.sp),
            SizedBox(width: 8.w),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REST TIMER',
                  style: TextStyle(color: ColorManager.primary, fontSize: 11.sp, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                ),
                Text(
                  _formatTimer(_restSecondsRemaining),
                  style: TextStyle(color: ColorManager.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            // [-30s]
            TextButton(
              onPressed: () => _adjustRestTimer(-30),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                backgroundColor: ColorManager.surfaceDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              child: Text('-30s', style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp)),
            ),
            SizedBox(width: 6.w),
            // [+30s]
            TextButton(
              onPressed: () => _adjustRestTimer(30),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                backgroundColor: ColorManager.surfaceDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              child: Text('+30s', style: TextStyle(color: ColorManager.primary, fontSize: 11.sp, fontWeight: FontWeight.bold)),
            ),
            SizedBox(width: 6.w),
            // [Skip]
            ElevatedButton(
              onPressed: _skipRestTimer,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                backgroundColor: ColorManager.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              child: Text('Skip', style: TextStyle(color: ColorManager.onMint, fontSize: 11.sp, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // Dynamic Warm-up Routine Card (5–10 min)
  Widget _buildWarmupCard() {
    return Container(
      key: const Key('session_warmup_card'),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(
          color: const Color(0xFFFFA500).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() => _isWarmupExpanded = !_isWarmupExpanded);
              _rememberSection(_warmupOpenKey, _isWarmupExpanded);
            },
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA500).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.whatshot_rounded, color: Color(0xFFFFA500), size: 16),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dynamic Warm-Up (5–10 min)',
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Prepare muscles, activate joint capsules & raise core temp',
                          style: TextStyle(
                            color: ColorManager.textSecondary,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isWarmupExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: ColorManager.textSecondary,
                    size: 20.sp,
                  ),
                ],
              ),
            ),
          ),
          if (_isWarmupExpanded) ...[
            Divider(height: 1, color: ColorManager.divider),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              child: Column(
                children: _warmupRoutines.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final routine = entry.value;
                  final isDone = _completedWarmups.contains(idx);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isDone) {
                          _completedWarmups.remove(idx);
                        } else {
                          _completedWarmups.add(idx);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 5.h),
                      child: Row(
                        children: [
                          Icon(
                            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: isDone ? ColorManager.success : ColorManager.textTertiary,
                            size: 18.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              routine,
                              style: TextStyle(
                                color: isDone ? ColorManager.textTertiary : ColorManager.textPrimary,
                                fontSize: 11.sp,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Cool-Down & Recovery Card (5 min)
  Widget _buildCooldownCard() {
    return Container(
      key: const Key('session_cooldown_card'),
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(
          color: const Color(0xFF2F6BFF).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() => _isCooldownExpanded = !_isCooldownExpanded);
              _rememberSection(_cooldownOpenKey, _isCooldownExpanded);
            },
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F6BFF).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.self_improvement_rounded, color: Color(0xFF2F6BFF), size: 16),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cool-Down & Recovery (5 min)',
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Gentle stretching, parasympathetic reset & stiffness reduction',
                          style: TextStyle(
                            color: ColorManager.textSecondary,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isCooldownExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: ColorManager.textSecondary,
                    size: 20.sp,
                  ),
                ],
              ),
            ),
          ),
          if (_isCooldownExpanded) ...[
            Divider(height: 1, color: ColorManager.divider),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              child: Column(
                children: _cooldownRoutines.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final routine = entry.value;
                  final isDone = _completedCooldowns.contains(idx);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isDone) {
                          _completedCooldowns.remove(idx);
                        } else {
                          _completedCooldowns.add(idx);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 5.h),
                      child: Row(
                        children: [
                          Icon(
                            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: isDone ? ColorManager.success : ColorManager.textTertiary,
                            size: 18.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              routine,
                              style: TextStyle(
                                color: isDone ? ColorManager.textTertiary : ColorManager.textPrimary,
                                fontSize: 11.sp,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Completion Screen
  Widget _buildCompletionView() {
    return WorkoutRewardView(
      session: _finishedSession!,
      dayName: widget.dayName,
      data: _reward,
      onDone: _closeSession,
      onViewSession: GoRouter.maybeOf(context) == null
          ? null
          : () => context.push(
                Routes.workoutSessionDetailRoute,
                extra: _finishedSession,
              ),
    );
  }
}

class _SessionExerciseState {
  String exerciseName;
  final int order;
  final int defaultSets;
  final int defaultReps;
  String? customVideoPath;
  String? customDescription;
  String? customTarget;
  String? customEquipment;
  String? customDifficulty;
  List<String>? customInstructions;
  WorkoutLog? previousLog;
  ProgressionRecommendation? progression;
  bool isLoadingHistory = true;
  // null = default (2.5 kg compound, 1 kg other); set from the Step button.
  double? weightStep;
  List<TextEditingController> weightControllers;
  List<TextEditingController> repControllers;
  List<SetType> setTypes;
  List<bool> isCompleted;
  late List<bool> isWeightUserEdited;
  late List<bool> isRepsUserEdited;
  late List<String> _lastWeightTexts;
  late List<String> _lastRepTexts;
  bool _isProgrammaticUpdate = false;

  _SessionExerciseState({
    required this.exerciseName,
    required this.order,
    required this.defaultSets,
    required this.defaultReps,
    this.customVideoPath,
    this.customDescription,
    this.customTarget,
    this.customEquipment,
    this.customDifficulty,
    this.customInstructions,
    this.previousLog,
    this.progression,
    required this.weightControllers,
    required this.repControllers,
    required this.setTypes,
    required this.isCompleted,
  }) {
    isWeightUserEdited = List.generate(weightControllers.length, (_) => false);
    isRepsUserEdited = List.generate(repControllers.length, (_) => false);
    _lastWeightTexts = weightControllers.map((c) => c.text).toList();
    _lastRepTexts = repControllers.map((c) => c.text).toList();
    for (int i = 0; i < weightControllers.length; i++) {
      _attachListeners(i);
    }
  }

  void _attachListeners(int index) {
    final wCtrl = weightControllers[index];
    final rCtrl = repControllers[index];
    wCtrl.addListener(() {
      if (_isProgrammaticUpdate) return;
      final idx = weightControllers.indexOf(wCtrl);
      if (idx != -1 && wCtrl.text != _lastWeightTexts[idx]) {
        _lastWeightTexts[idx] = wCtrl.text;
        isWeightUserEdited[idx] = true;
      }
    });
    rCtrl.addListener(() {
      if (_isProgrammaticUpdate) return;
      final idx = repControllers.indexOf(rCtrl);
      if (idx != -1 && rCtrl.text != _lastRepTexts[idx]) {
        _lastRepTexts[idx] = rCtrl.text;
        isRepsUserEdited[idx] = true;
      }
    });
  }

  void setProgrammaticWeight(int index, String value) {
    if (index < 0 || index >= weightControllers.length) return;
    _isProgrammaticUpdate = true;
    _lastWeightTexts[index] = value;
    weightControllers[index].text = value;
    _isProgrammaticUpdate = false;
  }

  void setProgrammaticReps(int index, String value) {
    if (index < 0 || index >= repControllers.length) return;
    _isProgrammaticUpdate = true;
    _lastRepTexts[index] = value;
    repControllers[index].text = value;
    _isProgrammaticUpdate = false;
  }

  List<ExerciseSetDraft> toSetDrafts() {
    return List.generate(weightControllers.length, (i) {
      return ExerciseSetDraft(
        weight: weightControllers[i].text,
        reps: repControllers[i].text,
        isCompleted: isCompleted[i],
        isWeightUserEdited: isWeightUserEdited[i],
        isRepsUserEdited: isRepsUserEdited[i],
      );
    });
  }

  void applySetDrafts(List<ExerciseSetDraft> drafts) {
    while (weightControllers.length < drafts.length) {
      addSet();
    }
    while (weightControllers.length > drafts.length && weightControllers.length > 1) {
      removeSet(weightControllers.length - 1);
    }
    for (int i = 0; i < drafts.length && i < weightControllers.length; i++) {
      final d = drafts[i];
      if (d.isWeightUserEdited || weightControllers[i].text != d.weight) {
        setProgrammaticWeight(i, d.weight);
        isWeightUserEdited[i] = d.isWeightUserEdited;
      }
      if (d.isRepsUserEdited || repControllers[i].text != d.reps) {
        setProgrammaticReps(i, d.reps);
        isRepsUserEdited[i] = d.isRepsUserEdited;
      }
      isCompleted[i] = d.isCompleted;
    }
  }

  void dispose() {
    for (var c in weightControllers) {
      c.dispose();
    }
    for (var c in repControllers) {
      c.dispose();
    }
  }

  void addSet() {
    final fallbackWeight = progression != null
        ? progression!.formattedWeight
        : ProgressionService.formatInitialWeight(
            exerciseName,
            equipment: customEquipment,
          );
    final lastWeight =
        weightControllers.isNotEmpty ? weightControllers.last.text : fallbackWeight;
    final lastReps =
        repControllers.isNotEmpty ? repControllers.last.text : '$defaultReps';
    final newIndex = weightControllers.length;
    weightControllers.add(TextEditingController(text: lastWeight));
    repControllers.add(TextEditingController(text: lastReps));
    setTypes.add(SetType.normal);
    isCompleted.add(false);
    isWeightUserEdited.add(false);
    isRepsUserEdited.add(false);
    _lastWeightTexts.add(lastWeight);
    _lastRepTexts.add(lastReps);
    _attachListeners(newIndex);
  }

  void removeSet(int index) {
    if (weightControllers.length > 1) {
      weightControllers[index].dispose();
      weightControllers.removeAt(index);
      repControllers[index].dispose();
      repControllers.removeAt(index);
      setTypes.removeAt(index);
      isCompleted.removeAt(index);
      isWeightUserEdited.removeAt(index);
      isRepsUserEdited.removeAt(index);
      _lastWeightTexts.removeAt(index);
      _lastRepTexts.removeAt(index);
    }
  }

  double get volume {
    double vol = 0;
    for (int i = 0; i < isCompleted.length; i++) {
      if (isCompleted[i] && setTypes[i] != SetType.warmup) {
        final w = double.tryParse(weightControllers[i].text) ?? 0.0;
        final r = int.tryParse(repControllers[i].text) ?? 0;
        vol += w * r;
      }
    }
    return vol;
  }

  int get completedSetsCount => isCompleted.where((c) => c).length;
  bool get isAllCompleted => isCompleted.isNotEmpty && isCompleted.every((c) => c);
}

/// Tap once to step; press and hold to repeat. Used by the +/- steppers.
class _HoldRepeat extends StatefulWidget {
  const _HoldRepeat({required this.onStep, required this.child});

  final VoidCallback? onStep;
  final Widget child;

  @override
  State<_HoldRepeat> createState() => _HoldRepeatState();
}

class _HoldRepeatState extends State<_HoldRepeat> {
  Timer? _timer;

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.onStep;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: step,
      onLongPressStart: step == null
          ? null
          : (_) {
              step();
              _timer = Timer.periodic(
                const Duration(milliseconds: 140),
                (_) => widget.onStep?.call(),
              );
            },
      onLongPressEnd: (_) => _stop(),
      onLongPressCancel: _stop,
      child: widget.child,
    );
  }
}
