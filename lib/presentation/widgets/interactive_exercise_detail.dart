import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/data/exercise_data.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/services/progression_service.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/presentation/workout_tools/plate_calculator_sheet.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';

class ExerciseSetDraft {
  final String weight;
  final String reps;
  final bool isCompleted;
  final bool isWeightUserEdited;
  final bool isRepsUserEdited;

  const ExerciseSetDraft({
    required this.weight,
    required this.reps,
    this.isCompleted = false,
    this.isWeightUserEdited = false,
    this.isRepsUserEdited = false,
  });
}

class SetLogInput {
  final TextEditingController weightController;
  final TextEditingController repsController;
  bool isCompleted;
  bool isWeightUserEdited;
  bool isRepsUserEdited;
  bool _isProgrammaticWeightUpdate = false;
  bool _isProgrammaticRepsUpdate = false;
  String _lastWeightText;
  String _lastRepsText;
  VoidCallback? onUserChanged;

  SetLogInput({
    required String defaultWeight,
    required String defaultReps,
    this.isCompleted = false,
    this.isWeightUserEdited = false,
    this.isRepsUserEdited = false,
    this.onUserChanged,
  })  : _lastWeightText = defaultWeight,
        _lastRepsText = defaultReps,
        weightController = TextEditingController(text: defaultWeight),
        repsController = TextEditingController(text: defaultReps) {
    weightController.addListener(_handleWeightChanged);
    repsController.addListener(_handleRepsChanged);
  }

  void _handleWeightChanged() {
    if (_isProgrammaticWeightUpdate) return;
    if (weightController.text != _lastWeightText) {
      _lastWeightText = weightController.text;
      isWeightUserEdited = true;
      onUserChanged?.call();
    }
  }

  void _handleRepsChanged() {
    if (_isProgrammaticRepsUpdate) return;
    if (repsController.text != _lastRepsText) {
      _lastRepsText = repsController.text;
      isRepsUserEdited = true;
      onUserChanged?.call();
    }
  }

  void setProgrammaticWeight(String value) {
    _isProgrammaticWeightUpdate = true;
    _lastWeightText = value;
    weightController.text = value;
    _isProgrammaticWeightUpdate = false;
  }

  void setProgrammaticReps(String value) {
    _isProgrammaticRepsUpdate = true;
    _lastRepsText = value;
    repsController.text = value;
    _isProgrammaticRepsUpdate = false;
  }

  ExerciseSetDraft toDraft() {
    return ExerciseSetDraft(
      weight: weightController.text,
      reps: repsController.text,
      isCompleted: isCompleted,
      isWeightUserEdited: isWeightUserEdited,
      isRepsUserEdited: isRepsUserEdited,
    );
  }

  void dispose() {
    weightController.removeListener(_handleWeightChanged);
    repsController.removeListener(_handleRepsChanged);
    weightController.dispose();
    repsController.dispose();
  }
}

class InteractiveExerciseDetailWidget extends StatefulWidget {
  final String name;
  final String videoPath;
  final String description;
  final String target;
  final String equipment;
  final List<String> instructions;
  final String difficulty;
  final String setsReps;
  final String category;
  final VideoControllerFactory? videoControllerFactory;
  final VideoViewBuilder? videoViewBuilder;
  final List<ExerciseSetDraft>? initialSets;
  final ValueChanged<List<ExerciseSetDraft>>? onSetsChanged;

  const InteractiveExerciseDetailWidget({
    super.key,
    required this.name,
    required this.videoPath,
    required this.description,
    required this.target,
    required this.equipment,
    required this.instructions,
    required this.difficulty,
    required this.setsReps,
    required this.category,
    this.videoControllerFactory,
    this.videoViewBuilder,
    this.initialSets,
    this.onSetsChanged,
  });

  static final Expando<Map<String, List<ExerciseSetDraft>>> _navigatorDrafts =
      Expando<Map<String, List<ExerciseSetDraft>>>('InteractiveExerciseDetailDrafts');
  static final Map<String, List<ExerciseSetDraft>> _fallbackDrafts = {};

  static void clearDrafts() {
    _fallbackDrafts.clear();
  }

  @override
  State<InteractiveExerciseDetailWidget> createState() =>
      _InteractiveExerciseDetailWidgetState();
}

class _InteractiveExerciseDetailWidgetState
    extends State<InteractiveExerciseDetailWidget> {
  int _currentTab = 0; // 0 = Instructions, 1 = Log Set, 2 = History
  bool _hasVideoError = false;
  final List<SetLogInput> _sets = [];
  late final WorkoutLogService _logService = WorkoutLogService();
  late final Stream<List<WorkoutLog>> _logsStream = _initLogsStream();
  
  // Previous log caching
  WorkoutLog? _previousLog;
  double _historicMaxWeight = 0.0;
  bool _isLoadingPrevious = true;

  // Rest Timer State
  Timer? _restTimer;
  int _restTimerSeconds = 0;
  bool _isResting = false;

  String get _draftKey {
    final clean = ExerciseData.normalizeExerciseName(widget.name);
    final catalog = ExerciseData.findByName(clean);
    return (catalog?.name ?? clean).trim().toLowerCase();
  }

  Map<String, List<ExerciseSetDraft>> _draftStore() {
    final nav = Navigator.maybeOf(context);
    if (nav != null) {
      var map = InteractiveExerciseDetailWidget._navigatorDrafts[nav];
      if (map == null) {
        map = <String, List<ExerciseSetDraft>>{};
        InteractiveExerciseDetailWidget._navigatorDrafts[nav] = map;
      }
      return map;
    }
    return InteractiveExerciseDetailWidget._fallbackDrafts;
  }

  void _syncDrafts() {
    final drafts = _sets.map((s) => s.toDraft()).toList();
    final hasUserMutation = drafts.any(
      (d) => d.isWeightUserEdited || d.isRepsUserEdited || d.isCompleted,
    );
    if (hasUserMutation) {
      _draftStore()[_draftKey] = drafts;
    }
    widget.onSetsChanged?.call(drafts);
  }

  Stream<List<WorkoutLog>> _initLogsStream() {
    try {
      return _logService.getLogs();
    } catch (_) {
      return const Stream.empty();
    }
  }

  String get _effectiveVideoPath {
    final rawPath = widget.videoPath.trim();
    if (rawPath.isNotEmpty) return rawPath;
    final catalog = ExerciseData.findByName(widget.name);
    return catalog?.videoPath ?? '';
  }

  @override
  void initState() {
    super.initState();
    _hasVideoError = _effectiveVideoPath.isEmpty;
    _parseAndInitializeSets();
    _loadPreviousLogAndMax();
  }

  @override
  void didUpdateWidget(covariant InteractiveExerciseDetailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath || oldWidget.name != widget.name) {
      _hasVideoError = _effectiveVideoPath.isEmpty;
    }
    if (oldWidget.name != widget.name) {
      for (var set in _sets) {
        set.dispose();
      }
      _parseAndInitializeSets();
      _loadPreviousLogAndMax();
    }
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    for (var set in _sets) {
      set.dispose();
    }
    super.dispose();
  }

  int _parseDefaultRepsInt() {
    try {
      final text = widget.setsReps.toLowerCase();
      final repsRegex = RegExp(r'(\d+)\s*rep');
      final matchReps = repsRegex.firstMatch(text);
      if (matchReps != null) {
        return int.parse(matchReps.group(1)!);
      }
    } catch (_) {}
    return 12;
  }

  // Parse default sets and reps from the config string, e.g. "3 sets x 12 reps"
  void _parseAndInitializeSets() {
    int defaultSetsCount = 3;
    String defaultReps = "12";
    
    try {
      final text = widget.setsReps.toLowerCase();
      // Try extracting count of sets
      final setsRegex = RegExp(r'(\d+)\s*set');
      final matchSets = setsRegex.firstMatch(text);
      if (matchSets != null) {
        defaultSetsCount = int.parse(matchSets.group(1)!);
      }

      // Try extracting count of reps
      final repsRegex = RegExp(r'(\d+)\s*rep');
      final matchReps = repsRegex.firstMatch(text);
      if (matchReps != null) {
        defaultReps = matchReps.group(1)!;
      }
    } catch (_) {}

    _sets.clear();

    // Restore from active-session sets or unsaved user-edited draft if available
    final List<ExerciseSetDraft>? savedDrafts =
        (widget.initialSets != null && widget.initialSets!.isNotEmpty)
            ? widget.initialSets
            : _draftStore()[_draftKey];

    final cachedLog = WorkoutLogService.getCachedLastLog(widget.name);
    if (cachedLog != null) {
      _previousLog = cachedLog;
      double maxWeight = 0.0;
      for (var s in cachedLog.sets) {
        if (s.weight > maxWeight) maxWeight = s.weight;
      }
      _historicMaxWeight = maxWeight;
    }

    if (savedDrafts != null && savedDrafts.isNotEmpty) {
      for (final draft in savedDrafts) {
        _sets.add(
          SetLogInput(
            defaultWeight: draft.weight,
            defaultReps: draft.reps,
            isCompleted: draft.isCompleted,
            isWeightUserEdited: draft.isWeightUserEdited,
            isRepsUserEdited: draft.isRepsUserEdited,
            onUserChanged: _syncDrafts,
          ),
        );
      }
      return;
    }

    final progression = ProgressionService.calculateNextTarget(
      exerciseName: widget.name,
      previousLog: cachedLog,
      defaultTargetReps: int.tryParse(defaultReps) ?? 12,
      equipment: widget.equipment,
      category: widget.category,
    );
    final defaultWeightStr = progression.formattedWeight;

    for (int i = 0; i < defaultSetsCount; i++) {
      String rowReps = defaultReps;
      if (cachedLog != null && cachedLog.sets.isNotEmpty) {
        if (progression.type == ProgressionType.increaseWeight) {
          rowReps = '${progression.targetMinReps}';
        } else if (i < cachedLog.sets.length && cachedLog.sets[i].reps > 0) {
          rowReps = '${cachedLog.sets[i].reps}';
        } else if (cachedLog.sets.last.reps > 0) {
          rowReps = '${cachedLog.sets.last.reps}';
        }
      }
      _sets.add(
        SetLogInput(
          defaultWeight: defaultWeightStr,
          defaultReps: rowReps,
          onUserChanged: _syncDrafts,
        ),
      );
    }
  }

  // Fetch Firestore or cached history for previous sets and personal records
  Future<void> _loadPreviousLogAndMax() async {
    try {
      final List<WorkoutLog> logs = [];
      User? user;
      try {
        user = FirebaseAuth.instance.currentUser;
      } catch (_) {
        user = null;
      }

      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workout_logs')
            .orderBy('date', descending: true)
            .get();

        if (!mounted) return;

        final cleanTarget =
            ExerciseData.normalizeExerciseName(widget.name).toLowerCase();
        logs.addAll(
          snapshot.docs
              .map((doc) => WorkoutLog.fromMap(doc.data(), doc.id))
              .where(
                (log) =>
                    ExerciseData.normalizeExerciseName(log.exerciseName)
                        .toLowerCase() ==
                    cleanTarget,
              ),
        );
      } else {
        final cached = await _logService.getLastExerciseLog(widget.name);
        if (!mounted) return;
        if (cached != null) {
          logs.add(cached);
        }
      }

      final defaultRepsInt = _parseDefaultRepsInt();
      if (logs.isNotEmpty) {
        final latestLog = logs.first;
        WorkoutLogService.seedLastLogCache(widget.name, latestLog);
        final progression = ProgressionService.calculateNextTarget(
          exerciseName: widget.name,
          previousLog: latestLog,
          defaultTargetReps: defaultRepsInt,
          equipment: widget.equipment,
          category: widget.category,
        );
        final recommendedWeightStr = progression.formattedWeight;

        setState(() {
          _previousLog = latestLog; // Most recent log
          
          // Calculate historical max weight
          double maxWeight = 0.0;
          for (var log in logs) {
            for (var set in log.sets) {
              if (set.weight > maxWeight) {
                maxWeight = set.weight;
              }
            }
          }
          _historicMaxWeight = maxWeight;

          // Pre-fill unedited log input controllers with progression/history values
          for (int i = 0; i < _sets.length; i++) {
            if (_sets[i].isCompleted) continue;

            if (!_sets[i].isWeightUserEdited) {
              _sets[i].setProgrammaticWeight(recommendedWeightStr);
            }
            if (!_sets[i].isRepsUserEdited) {
              if (progression.type == ProgressionType.increaseWeight) {
                _sets[i].setProgrammaticReps('${progression.targetMinReps}');
              } else if (i < _previousLog!.sets.length &&
                  _previousLog!.sets[i].reps > 0) {
                _sets[i].setProgrammaticReps('${_previousLog!.sets[i].reps}');
              } else if (_previousLog!.sets.isNotEmpty &&
                  _previousLog!.sets.last.reps > 0) {
                _sets[i].setProgrammaticReps('${_previousLog!.sets.last.reps}');
              }
            }
          }
        });
      } else {
        final defaultWeightStr = ProgressionService.formatInitialWeight(
          widget.name,
          equipment: widget.equipment,
          category: widget.category,
        );
        setState(() {
          _previousLog = null;
          _historicMaxWeight = 0.0;
          for (var set in _sets) {
            if (!set.isCompleted && !set.isWeightUserEdited) {
              set.setProgrammaticWeight(defaultWeightStr);
            }
          }
        });
      }
    } catch (_) {} finally {
      if (mounted) {
        setState(() {
          _isLoadingPrevious = false;
        });
      }
    }
  }

  // Start Rest Timer
  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _restTimerSeconds = 60; // 60 seconds standard recovery rest
      _isResting = true;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restTimerSeconds <= 1) {
        timer.cancel();
        setState(() {
          _isResting = false;
          _restTimerSeconds = 0;
        });
      } else {
        setState(() {
          _restTimerSeconds--;
        });
      }
    });
  }

  // Toggle set completion and trigger rest timer
  void _toggleSetCompletion(int index) {
    setState(() {
      final wasCompleted = _sets[index].isCompleted;
      _sets[index].isCompleted = !wasCompleted;

      // Start Rest Timer on completion
      if (!wasCompleted) {
        _startRestTimer();
      }
    });
    _syncDrafts();
  }

  // Add Set row dynamically
  void _addSetRow() {
    setState(() {
      final fallbackWeight = ProgressionService.formatInitialWeight(
        widget.name,
        equipment: widget.equipment,
        category: widget.category,
      );
      String weight = fallbackWeight;
      String reps = '${_parseDefaultRepsInt()}';
      if (_sets.isNotEmpty) {
        weight = _sets.last.weightController.text;
        reps = _sets.last.repsController.text;
      }
      _sets.add(
        SetLogInput(
          defaultWeight: weight,
          defaultReps: reps,
          onUserChanged: _syncDrafts,
        ),
      );
    });
    _syncDrafts();
  }

  // Remove Set row
  void _removeSetRow() {
    if (_sets.length <= 1) return;
    setState(() {
      final removed = _sets.removeLast();
      removed.dispose();
    });
    _syncDrafts();
  }

  void _openPlateCalculator(int idx) {
    final currWeight =
        double.tryParse(_sets[idx].weightController.text) ?? 0.0;
    final initialWeight = currWeight > 0 ? currWeight : 60.0;

    PlateCalculatorSheet.show(
      context,
      initialWeight: initialWeight,
      onWeightApplied: (appliedWeight) {
        final formatted = appliedWeight % 1 == 0
            ? appliedWeight.toInt().toString()
            : appliedWeight.toStringAsFixed(1);
        setState(() {
          _sets[idx].setProgrammaticWeight(formatted);
          _sets[idx].isWeightUserEdited = true;
        });
        _syncDrafts();
      },
    );
  }

  // Save live log to Firebase
  Future<void> _saveWorkoutLog() async {
    final completedSets = _sets.where((s) => s.isCompleted).toList();
    if (completedSets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Complete at least one set before saving!'),
          backgroundColor: ColorManager.error,
        ),
      );
      return;
    }

    final List<WorkoutSet> setsToSave = [];
    double currentMaxWeight = 0.0;

    for (var set in completedSets) {
      final w = double.tryParse(set.weightController.text) ?? 0.0;
      final r = int.tryParse(set.repsController.text) ?? 0;
      setsToSave.add(WorkoutSet(weight: w, reps: r));
      if (w > currentMaxWeight) {
        currentMaxWeight = w;
      }
    }

    final WorkoutLog log = WorkoutLog(
      id: '',
      exerciseName: widget.name,
      date: DateTime.now(),
      sets: setsToSave,
      category: widget.category,
    );

    try {
      await _logService.addLog(log);
      if (mounted) {
        Provider.of<StatisticsProvider>(context, listen: false).updateStreak();
      }

      // Stop/Cancel the rest timer since the workout session is finished and saved!
      _restTimer?.cancel();
      _isResting = false;
      _restTimerSeconds = 0;
      _draftStore().remove(_draftKey);

      // Check if this was a new Personal Record
      final bool isPR = currentMaxWeight > _historicMaxWeight && _historicMaxWeight > 0;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Workout sets logged successfully!'),
            backgroundColor: ColorManager.success,
          ),
        );

        if (isPR) {
          _showPRDialog(currentMaxWeight);
        }

        // Auto reload log history and switch to history tab
        await _loadPreviousLogAndMax();
        setState(() {
          _currentTab = 2; // Swaps tab to history log list
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save workout. Please try again.'),
            backgroundColor: ColorManager.error,
          ),
        );
      }
    }
  }

  // Trigger Gold Personal Record Card
  void _showPRDialog(double prWeight) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorManager.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏆 ', style: TextStyle(fontSize: 24)),
            Text(
              'Personal Record!',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Congratulations!',
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'You lifted a new max of ${prWeight.toStringAsFixed(1)} kg in ${widget.name}!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorManager.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Awesome!', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLog(WorkoutLog log) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorManager.surface,
        title: Text('Delete Log?', style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete this workout log? This will remove these sets from your history and charts.',
          style: TextStyle(color: ColorManager.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: ColorManager.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _logService.deleteLog(log.id);
                await _loadPreviousLogAndMax();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Log deleted successfully'),
                      backgroundColor: ColorManager.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete log: $e'),
                      backgroundColor: ColorManager.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _reuseSets(WorkoutLog log) {
    setState(() {
      for (var set in _sets) {
        set.dispose();
      }
      _sets.clear();

      for (var setObj in log.sets) {
        _sets.add(
          SetLogInput(
            defaultWeight: setObj.weight.toStringAsFixed(setObj.weight % 1 == 0 ? 0 : 1),
            defaultReps: setObj.reps.toString(),
            isCompleted: false,
            isWeightUserEdited: true,
            isRepsUserEdited: true,
            onUserChanged: _syncDrafts,
          ),
        );
      }
      
      _currentTab = 1; // Navigate to Log Set tab
    });
    _syncDrafts();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${log.sets.length} sets to "Log Set" tab!'),
        backgroundColor: ColorManager.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Custom tab indicators
  Widget _buildTabButton(int index, String label) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentTab = index;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected ? ColorManager.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : ColorManager.textSecondary,
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // Render tab content
  Widget _buildTabContent(List<WorkoutLog> logs) {
    switch (_currentTab) {
      case 0:
        return _buildInstructionsPanel();
      case 1:
        return _buildLogSetPanel();
      case 2:
        return _buildHistoryPanel(logs);
      default:
        return const SizedBox();
    }
  }

  // ═══════════════════════════════════════
  // PANEL BUILDERS
  // ═══════════════════════════════════════

  Widget _buildInstructionsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: ColorManager.surfaceLight,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: ColorManager.divider),
          ),
          child: Text(
            widget.description,
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
        ),
        SizedBox(height: 20.h),

        // Badges grid
        Row(
          children: [
            Expanded(
              child: _buildBadgeCard('Target', widget.target, Icons.center_focus_strong),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildBadgeCard('Equipment', widget.equipment, Icons.sports_gymnastics),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildBadgeCard('Difficulty', widget.difficulty, Icons.trending_up),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildBadgeCard('Goal sets', widget.setsReps, Icons.repeat),
            ),
          ],
        ),
        SizedBox(height: 24.h),

        // How to Perform steps
        Text(
          'How to Perform',
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        if (widget.instructions.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: ColorManager.surfaceLight,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: ColorManager.divider),
            ),
            child: Text(
              'Detailed step-by-step instructions are not available for this exercise.',
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 14.sp,
                height: 1.4,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.instructions.length,
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: ColorManager.surfaceLight,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: ColorManager.divider),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14.r,
                      backgroundColor: ColorManager.primary,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        widget.instructions[index],
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 14.sp,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildBadgeCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: ColorManager.surfaceLight,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: ColorManager.primary, size: 22.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogSetPanel() {
    if (_isLoadingPrevious) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: [
        // Table Headers
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            children: [
              SizedBox(
                width: 40.w,
                child: Text('SET',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                width: 100.w,
                child: Text('PREVIOUS',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Text('KG',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Text('REPS',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                width: 50.w,
                child: Text('DONE',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const Divider(),

        // Log Rows
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _sets.length,
          itemBuilder: (context, idx) {
            final setInput = _sets[idx];
            final isBarbell = PlateCalculatorSheet.isBarbellExercise(
              name: widget.name,
              equipment: widget.equipment,
            );
            
            // Format previous values if available
            String prevDisplay = "—";
            if (_previousLog != null && idx < _previousLog!.sets.length) {
              final prevSet = _previousLog!.sets[idx];
              prevDisplay = "${prevSet.weight.toStringAsFixed(1)} kg x ${prevSet.reps}";
            }

            return Container(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              decoration: BoxDecoration(
                color: setInput.isCompleted ? ColorManager.success.withOpacity(0.05) : Colors.transparent,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  // Set Index
                  SizedBox(
                    width: 40.w,
                    child: Text(
                      '${idx + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Previous Log Display
                  SizedBox(
                    width: 100.w,
                    child: Text(
                      prevDisplay,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
                    ),
                  ),

                  // Weight Field
                  Expanded(
                    child: Container(
                      height: 38.h,
                      margin: EdgeInsets.symmetric(horizontal: 6.w),
                      child: TextField(
                        key: Key('detail_weight_input_$idx'),
                        controller: setInput.weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        enabled: !setInput.isCompleted,
                        style: TextStyle(color: ColorManager.textPrimary, fontSize: 14.sp),
                        decoration: InputDecoration(
                          hintText: '—',
                          hintStyle: TextStyle(color: ColorManager.textTertiary, fontSize: 13.sp),
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: setInput.isCompleted ? ColorManager.surfaceDark : ColorManager.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: ColorManager.divider),
                          ),
                          suffixIcon: isBarbell
                              ? IconButton(
                                  key: Key('detail_plate_calc_$idx'),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    Icons.calculate_outlined,
                                    size: 16.sp,
                                    color: setInput.isCompleted
                                        ? Colors.white24
                                        : ColorManager.primary,
                                  ),
                                  onPressed: setInput.isCompleted
                                      ? null
                                      : () => _openPlateCalculator(idx),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),

                  // Reps Field
                  Expanded(
                    child: Container(
                      height: 38.h,
                      margin: EdgeInsets.symmetric(horizontal: 6.w),
                      child: TextField(
                        key: Key('detail_reps_input_$idx'),
                        controller: setInput.repsController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        enabled: !setInput.isCompleted,
                        style: TextStyle(color: ColorManager.textPrimary, fontSize: 14.sp),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: setInput.isCompleted ? ColorManager.surfaceDark : ColorManager.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: ColorManager.divider),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Checkbox
                  SizedBox(
                    width: 50.w,
                    child: IconButton(
                      onPressed: () => _toggleSetCompletion(idx),
                      icon: Icon(
                        setInput.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: setInput.isCompleted ? ColorManager.success : ColorManager.textSecondary,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        SizedBox(height: 16.h),

        // Controls (Add/Delete Set)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _addSetRow,
              icon: Icon(Icons.add, size: 18.sp),
              label: const Text('Add Set'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.surfaceLight,
                foregroundColor: ColorManager.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: BorderSide(color: ColorManager.divider),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _sets.length <= 1 ? null : _removeSetRow,
              icon: Icon(Icons.delete, size: 18.sp),
              label: const Text('Remove Set'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.surfaceLight,
                foregroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: BorderSide(color: ColorManager.divider),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),

        // Save session button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveWorkoutLog,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Save Session Log',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryPanel(List<WorkoutLog> logs) {
    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: Column(
            children: [
              Icon(Icons.analytics_outlined, size: 48.sp, color: ColorManager.textTertiary),
              SizedBox(height: 12.h),
              Text(
                'No workout history found for this exercise',
                style: TextStyle(color: ColorManager.textTertiary, fontSize: 13.sp),
              ),
            ],
          ),
        ),
      );
    }

    final chronological = List<WorkoutLog>.from(logs)..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress Chart
        Text(
          'Progression (Max Weight)',
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          height: 180.h,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: ColorManager.surfaceLight,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: ColorManager.divider),
          ),
          child: _buildProgressChart(chronological),
        ),
        SizedBox(height: 24.h),

        // Past Log Items
        Text(
          'Workout Logs History',
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          itemBuilder: (context, idx) {
            final log = logs[idx];
            final dateStr = DateFormat('EEEE, MMM d, yyyy').format(log.date);

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: ColorManager.surfaceLight,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: ColorManager.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.replay, color: ColorManager.primary, size: 18.sp),
                            tooltip: 'Reuse these sets',
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            onPressed: () => _reuseSets(log),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: 18.sp),
                            tooltip: 'Delete this log',
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            onPressed: () => _confirmDeleteLog(log),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  SizedBox(height: 4.h),
                  ...log.sets.asMap().entries.map((setEntry) {
                    final setIndex = setEntry.key + 1;
                    final setObj = setEntry.value;
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 3.h),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 10.r,
                            backgroundColor: ColorManager.divider,
                            child: Text(
                              '$setIndex',
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: ColorManager.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            '${setObj.weight.toStringAsFixed(1)} kg x ${setObj.reps} reps',
                            style: TextStyle(
                              color: ColorManager.textPrimary,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // fl_chart plotting logic
  Widget _buildProgressChart(List<WorkoutLog> graphLogs) {
    final List<FlSpot> spots = [];
    final Map<int, String> dateLabels = {};

    for (int i = 0; i < graphLogs.length; i++) {
      final log = graphLogs[i];
      // Max weight logged in this session
      final double maxWeight = log.sets.map((s) => s.weight).fold(0.0, math.max);
      spots.add(FlSpot(i.toDouble(), maxWeight));
      dateLabels[i] = DateFormat('M/d').format(log.date);
    }

    if (spots.isEmpty) {
      return Center(
        child: Text(
          'No chart data',
          style: TextStyle(color: ColorManager.textTertiary, fontSize: 13.sp),
        ),
      );
    }

    final double minY = spots.map((s) => s.y).reduce(math.min);
    final double maxY = spots.map((s) => s.y).reduce(math.max);
    final double paddingY = (maxY - minY) == 0 ? 5.0 : (maxY - minY) * 0.15;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (spots.length - 1).toDouble() + 0.1,
        minY: math.max(0.0, minY - paddingY),
        maxY: maxY + paddingY,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22.h,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (dateLabels.containsKey(idx)) {
                  return Text(
                    dateLabels[idx]!,
                    style: TextStyle(color: ColorManager.textTertiary, fontSize: 9.sp),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28.w,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(0)}kg',
                  style: TextStyle(color: ColorManager.textTertiary, fontSize: 8.sp),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: ColorManager.divider,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: spots.length > 1,
            dotData: FlDotData(show: true),
            color: ColorManager.primary,
            barWidth: 2.5.w,
            belowBarData: BarAreaData(
              show: true,
              color: ColorManager.primary.withOpacity(0.05),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WorkoutLog>>(
      stream: _logsStream,
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        final filteredLogs = logs
            .where((l) => l.exerciseName.toLowerCase() == widget.name.toLowerCase())
            .toList();

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: ColorManager.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
          ),
          child: Column(
            children: [
              // Bottom sheet handle bar
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: ColorManager.divider,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // Title Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.name,
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      key: const Key('close_exercise_detail_button'),
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      color: ColorManager.textSecondary,
                    ),
                  ],
                ),
              ),

              // Rest Timer Display Banner
              if (_isResting)
                Container(
                  width: double.infinity,
                  color: ColorManager.primary.withOpacity(0.15),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer, color: ColorManager.primary, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Rest Timer: ${_restTimerSeconds}s',
                            style: TextStyle(
                              color: ColorManager.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          _restTimer?.cancel();
                          setState(() {
                            _isResting = false;
                            _restTimerSeconds = 0;
                          });
                        },
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: ColorManager.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Tab Selector Row
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: ColorManager.surfaceLight,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: ColorManager.divider),
                ),
                child: Row(
                  children: [
                    _buildTabButton(0, 'Instructions'),
                    _buildTabButton(1, 'Log Set'),
                    _buildTabButton(2, 'History'),
                  ],
                ),
              ),

              // Keep video mounted across tabs so switching to/from Log Set does not dispose or restart playback
              Offstage(
                offstage: _currentTab == 1,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
                  child: Container(
                    height: 180.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: ColorManager.divider),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: Stack(
                        children: [
                          ExerciseVideoPlayer(
                            videoPath: _effectiveVideoPath,
                            height: 180.h,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            autoPlay: true,
                            controllerFactory: widget.videoControllerFactory,
                            videoViewBuilder: widget.videoViewBuilder,
                            onErrorChanged: (hasError) {
                              if (mounted && _hasVideoError != hasError) {
                                setState(() {
                                  _hasVideoError = hasError;
                                });
                              }
                            },
                          ),
                          // Overlay instructions text indicator only when video is valid
                          if (!_hasVideoError &&
                              _effectiveVideoPath.isNotEmpty)
                            Positioned(
                              bottom: 8.h,
                              right: 8.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  'Video Guide',
                                  style: TextStyle(color: Colors.white, fontSize: 10.sp),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Dynamic scrollable panels
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  child: _buildTabContent(filteredLogs),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
