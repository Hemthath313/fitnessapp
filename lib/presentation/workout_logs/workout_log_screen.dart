import 'package:fitness_app/utils/units.dart';
import 'package:fitness_app/utils/managers/layout_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/data/exercise_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/workout_tools/plate_calculator_sheet.dart';
import 'package:fitness_app/services/progression_service.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// One exercise that has been filled in and added to the workout being
/// logged, waiting for "Save Workout".
class _DraftExercise {
  _DraftExercise({
    required this.name,
    required this.category,
    required this.sets,
    required this.notes,
  });

  final String name;
  final String category;
  final List<WorkoutSet> sets;
  final String notes;
  bool saved = false;

  double get volume =>
      sets.fold(0.0, (sum, s) => sum + s.weight * s.reps);
}

class WorkoutLogScreen extends StatefulWidget {
  const WorkoutLogScreen({super.key, this.initialDate});

  /// Pre-selected day (e.g. a day tapped in History). Defaults to today.
  final DateTime? initialDate;

  static List<String> get suggestedExercises => ExerciseData.allExerciseNames;

  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen> {
  final _exerciseController = TextEditingController();
  TextEditingController? _autocompleteController;
  final _notesController = TextEditingController();
  final List<WorkoutSet> _sets = [WorkoutSet(weight: 0, reps: 0)];
  final List<TextEditingController> _weightControllers = [TextEditingController()];
  final List<TextEditingController> _repControllers = [TextEditingController()];
  final List<bool> _isWeightUserEdited = [false];
  final List<String> _lastWeightTexts = [''];
  bool _isProgrammaticWeightUpdate = false;
  
  String _category = 'Strength';
  final _logService = WorkoutLogService();
  bool _isSaving = false;

  /// The day the workout happened. Defaults to today; can be moved back.
  late DateTime _date = _dateOnly(
      (widget.initialDate != null && !widget.initialDate!.isAfter(DateTime.now()))
          ? widget.initialDate!
          : DateTime.now());

  /// Exercises already filled in for this workout.
  final List<_DraftExercise> _added = [];

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool get _isToday => _dateOnly(_date) == _dateOnly(DateTime.now());

  String get _dateLabel {
    final today = _dateOnly(DateTime.now());
    final diff = today.difference(_dateOnly(_date)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEE, MMM d, yyyy').format(_date);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(2020, 1, 1),
      lastDate: _dateOnly(now),
      helpText: 'When did you train?',
    );
    if (picked != null && mounted) {
      setState(() => _date = _dateOnly(picked));
    }
  }

  List<String> get _suggestedExercises => WorkoutLogScreen.suggestedExercises;


  static const List<String> _popularQuickChips = [
    'Barbell Bench Press',
    'Barbell Squat',
    'Deadlift',
    'Overhead Press',
    'Barbell Row',
    'Pull-Ups',
  ];

  @override
  void initState() {
    super.initState();
    _attachWeightListener(0);
  }

  void _attachWeightListener(int index) {
    final ctrl = _weightControllers[index];
    ctrl.addListener(() {
      if (_isProgrammaticWeightUpdate) return;
      final idx = _weightControllers.indexOf(ctrl);
      if (idx != -1 && ctrl.text != _lastWeightTexts[idx]) {
        _lastWeightTexts[idx] = ctrl.text;
        _isWeightUserEdited[idx] = true;
      }
    });
  }

  void _setProgrammaticWeight(int index, String value) {
    if (index < 0 || index >= _weightControllers.length) return;
    _isProgrammaticWeightUpdate = true;
    _lastWeightTexts[index] = value;
    _weightControllers[index].text = value;
    _isProgrammaticWeightUpdate = false;
  }

  /// "Last time · Mar 3: 60 kg × 8 · 3 sets" for the chosen exercise.
  String? _lastTimeText;
  String? _lastTimeFor;

  static String? _describeLastLog(WorkoutLog? log) {
    if (log == null || log.sets.isEmpty) return null;
    final best = log.sets.reduce((a, b) =>
        (b.weight > a.weight || (b.weight == a.weight && b.reps > a.reps)) ? b : a);
    final when = DateFormat('MMM d').format(log.date);
    final setWord = log.sets.length == 1 ? 'set' : 'sets';
    final load = best.weight > 0
        ? '${Units.fmtSmart(best.weight)} ${Units.label} × ${best.reps}'
        : '${best.reps} reps';
    return 'Last time · $when: $load · ${log.sets.length} $setWord';
  }

  Future<void> _selectExerciseAndSeedWeight(String rawName) async {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) return;

    final cachedLog = WorkoutLogService.getCachedLastLog(trimmed);
    _lastTimeText = _describeLastLog(cachedLog);
    _lastTimeFor = trimmed;
    final initialProgression = ProgressionService.calculateNextTarget(
      exerciseName: trimmed,
      previousLog: cachedLog,
      category: _category,
    );
    final initialWeightStr = initialProgression.formattedWeight;

    setState(() {
      _exerciseController.text = trimmed;
      if (_autocompleteController != null &&
          _autocompleteController!.text != trimmed) {
        _autocompleteController!.text = trimmed;
      }
      for (int i = 0; i < _weightControllers.length; i++) {
        if (!_isWeightUserEdited[i]) {
          _setProgrammaticWeight(i, initialWeightStr);
        }
      }
    });

    try {
      final fetchedLog = await _logService.getLastExerciseLog(trimmed);
      if (!mounted || _exerciseController.text.trim() != trimmed) return;
      if (fetchedLog != null) {
        _lastTimeText = _describeLastLog(fetchedLog);
        final progression = ProgressionService.calculateNextTarget(
          exerciseName: trimmed,
          previousLog: fetchedLog,
          category: _category,
        );
        final weightStr = progression.formattedWeight;
        setState(() {
          for (int i = 0; i < _weightControllers.length; i++) {
            if (!_isWeightUserEdited[i]) {
              _setProgrammaticWeight(i, weightStr);
            }
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _notesController.dispose();
    for (var c in _weightControllers) {
      c.dispose();
    }
    for (var c in _repControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addSet() {
    setState(() {
      String initialWeight = '';
      if (_weightControllers.isNotEmpty &&
          _weightControllers.last.text.trim().isNotEmpty) {
        initialWeight = _weightControllers.last.text.trim();
      } else if (_exerciseController.text.trim().isNotEmpty) {
        final exName = _exerciseController.text.trim();
        final cached = WorkoutLogService.getCachedLastLog(exName);
        final prog = ProgressionService.calculateNextTarget(
          exerciseName: exName,
          previousLog: cached,
          category: _category,
        );
        initialWeight = prog.formattedWeight;
      }
      final newIdx = _weightControllers.length;
      _sets.add(WorkoutSet(weight: 0, reps: 0));
      _weightControllers.add(TextEditingController(text: initialWeight));
      _repControllers.add(TextEditingController());
      _isWeightUserEdited.add(false);
      _lastWeightTexts.add(initialWeight);
      _attachWeightListener(newIdx);
    });
  }

  void _removeSet(int index) {
    if (_sets.length > 1) {
      setState(() {
        _sets.removeAt(index);
        _weightControllers[index].dispose();
        _weightControllers.removeAt(index);
        _repControllers[index].dispose();
        _repControllers.removeAt(index);
        _isWeightUserEdited.removeAt(index);
        _lastWeightTexts.removeAt(index);
      });
    }
  }

  /// Reads the form. Returns null when the sets have no reps.
  _DraftExercise? _readForm() {
    final List<WorkoutSet> finalSets = [];
    for (int i = 0; i < _sets.length; i++) {
      // Typed in the user's unit; stored in kg.
      final weight = Units.parseToKg(_weightControllers[i].text) ?? 0.0;
      final reps = int.tryParse(_repControllers[i].text.trim()) ?? 0;
      // Only sets with reps are real sets; they are stored as completed so
      // progress charts and strength insights count them.
      if (reps > 0) {
        finalSets.add(WorkoutSet(weight: weight, reps: reps, isCompleted: true));
      }
    }
    if (finalSets.isEmpty) return null;
    return _DraftExercise(
      name: _exerciseController.text.trim(),
      category: _category,
      sets: finalSets,
      notes: _notesController.text.trim(),
    );
  }

  void _resetForm() {
    _lastTimeText = null;
    _lastTimeFor = null;
    for (final c in _weightControllers) {
      c.dispose();
    }
    for (final c in _repControllers) {
      c.dispose();
    }
    _sets
      ..clear()
      ..add(WorkoutSet(weight: 0, reps: 0));
    _weightControllers
      ..clear()
      ..add(TextEditingController());
    _repControllers
      ..clear()
      ..add(TextEditingController());
    _isWeightUserEdited
      ..clear()
      ..add(false);
    _lastWeightTexts
      ..clear()
      ..add('');
    _attachWeightListener(0);
    _notesController.clear();
    _exerciseController.clear();
    _autocompleteController?.clear();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Validates the form and moves it into the "added" list. Returns false
  /// (after telling the user why) when the form is not ready.
  bool _commitCurrentExercise() {
    if (_exerciseController.text.trim().isEmpty) {
      _toast('Please enter an exercise name');
      return false;
    }
    final draft = _readForm();
    if (draft == null) {
      _toast('Please enter at least 1 rep for your sets');
      return false;
    }
    setState(() {
      _added.add(draft);
      _resetForm();
    });
    return true;
  }

  Future<void> _saveLog() async {
    if (_isSaving) return;

    // Anything typed into the form counts as the last exercise. An empty form
    // is fine when exercises were already added.
    final formHasName = _exerciseController.text.trim().isNotEmpty;
    if (formHasName || _added.isEmpty) {
      if (!_commitCurrentExercise()) return;
    }

    setState(() => _isSaving = true);

    try {
      final pending = _added.where((e) => !e.saved).toList();
      final now = DateTime.now();
      final when = _isToday
          ? now
          : DateTime(_date.year, _date.month, _date.day, now.hour, now.minute);

      // Two or more strength exercises become one session so History shows a
      // single card. Everything else is saved as its own quick log.
      final strength = pending.where((e) => e.category == 'Strength').toList();
      final asSession = strength.length >= 2;

      if (asSession) {
        String uid = '';
        try {
          uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        } catch (_) {}
        final exercises = <SessionExercise>[
          for (int i = 0; i < strength.length; i++)
            SessionExercise(
              exerciseName: strength[i].name,
              order: i,
              sets: strength[i].sets,
              notes: strength[i].notes.isEmpty ? null : strength[i].notes,
              isCompleted: true,
            ),
        ];
        final volume = exercises.fold<double>(0, (sum, e) => sum + e.totalVolume);
        await _logService.saveWorkoutSession(WorkoutSession(
          id: 'session_${when.millisecondsSinceEpoch}',
          userId: uid,
          workoutName: 'Logged Workout',
          dayName: 'Logged Workout',
          startedAt: when,
          completedAt: when,
          durationSeconds: 0,
          status: 'completed',
          totalVolume: volume,
          exercises: exercises,
        ));
        for (final e in strength) {
          e.saved = true;
        }
      }

      for (final e in pending.where((e) => !e.saved)) {
        await _logService.addLog(WorkoutLog(
          id: '',
          exerciseName: e.name,
          date: when,
          sets: e.sets,
          notes: e.notes,
          category: e.category,
        ));
        e.saved = true;
      }

      // Refresh streak and counts. Today uses the usual path. A past date
      // must not credit today, so it reloads from the saved history instead.
      try {
        if (mounted) {
          final stats = Provider.of<StatisticsProvider>(context, listen: false);
          if (_isToday) {
            await stats.updateStreak();
          } else {
            await stats.loadStreakData();
          }
        }
      } catch (_) {}

      if (mounted) {
        Navigator.pop(context);
        _toast(_isToday
            ? 'Workout saved & streak updated!'
            : 'Workout saved for $_dateLabel');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _toast('Error saving log: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text('Log past workout', style: TextStyle(color: ColorManager.textPrimary)),
        backgroundColor: ColorManager.background,
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              key: const Key('log_date_row'),
              onTap: _isSaving ? null : _pickDate,
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: ColorManager.surface,
                  boxShadow: ColorManager.cardShadow,
                  borderRadius: BorderRadius.circular(AppRadius.small.r),
                  border: Border.all(color: ColorManager.divider),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_rounded, color: ColorManager.primaryText),
                    SizedBox(width: 10.w),
                    Text(
                      'When',
                      style: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp),
                    ),
                    const Spacer(),
                    Text(
                      _dateLabel,
                      key: const Key('log_date_label'),
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(Icons.chevron_right_rounded, color: ColorManager.textTertiary, size: 20.sp),
                  ],
                ),
              ),
            ),
            if (_added.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                key: const Key('log_added_list'),
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: ColorManager.surface,
                  boxShadow: ColorManager.cardShadow,
                  borderRadius: BorderRadius.circular(AppRadius.small.r),
                  border: Border.all(color: ColorManager.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'In this workout (${_added.length})',
                      style: TextStyle(
                        color: ColorManager.textTertiary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    for (int i = 0; i < _added.length; i++)
                      Padding(
                        key: Key('log_added_$i'),
                        padding: EdgeInsets.only(top: 6.h),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: ColorManager.primaryText, size: 18.sp),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                _added[i].name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: ColorManager.textPrimary,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${_added[i].sets.length} sets'
                              '${_added[i].volume > 0 ? ' · ${Units.intOf(_added[i].volume)} ${Units.label}' : ''}',
                              style: TextStyle(
                                color: ColorManager.textTertiary,
                                fontSize: 12.sp,
                              ),
                            ),
                            if (!_added[i].saved)
                              IconButton(
                                key: Key('log_added_remove_$i'),
                                tooltip: 'Remove exercise',
                                visualDensity: VisualDensity.compact,
                                icon: Icon(Icons.close_rounded,
                                    color: ColorManager.textTertiary, size: 18.sp),
                                onPressed: _isSaving
                                    ? null
                                    : () => setState(() => _added.removeAt(i)),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 16.h),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _exerciseController.text),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return _suggestedExercises.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                _selectExerciseAndSeedWeight(selection);
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                if (_autocompleteController != controller) {
                  _autocompleteController = controller;
                  controller.addListener(() {
                    _exerciseController.text = controller.text;
                  });
                }
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: TextStyle(color: ColorManager.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Exercise Name',
                    hintText: 'e.g. Barbell Bench Press...',
                    hintStyle: TextStyle(color: ColorManager.textTertiary, fontSize: 13.sp),
                    labelStyle: TextStyle(color: ColorManager.textSecondary),
                    prefixIcon: Icon(Icons.fitness_center_rounded, color: ColorManager.primaryText),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: ColorManager.primary, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: ColorManager.divider),
                    ),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12.r),
                    color: ColorManager.surface,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 200.h,
                        maxWidth: MediaQuery.of(context).size.width - 32.w,
                      ),
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (context, _) => Divider(color: ColorManager.divider.withValues(alpha: 0.3), height: 1),
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                              child: Row(
                                children: [
                                  Icon(Icons.sports_gymnastics_rounded, size: 16.sp, color: ColorManager.primaryText),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        color: ColorManager.textPrimary,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_lastTimeText != null && _exerciseController.text.trim() == _lastTimeFor) ...[
              SizedBox(height: 8.h),
              Row(
                key: const Key('log_last_time_hint'),
                children: [
                  Icon(Icons.history_rounded, size: 15.sp, color: ColorManager.textSecondary),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      _lastTimeText!,
                      style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 10.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _popularQuickChips.map((chip) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: ActionChip(
                      label: Text(chip),
                      labelStyle: TextStyle(
                        color: _exerciseController.text == chip ? Colors.white : ColorManager.textSecondary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: _exerciseController.text == chip ? ColorManager.primary : ColorManager.surface,
                      side: BorderSide(color: ColorManager.divider.withValues(alpha: 0.5)),
                      onPressed: () {
                        _selectExerciseAndSeedWeight(chip);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Text('Category: ', style: TextStyle(color: ColorManager.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                SizedBox(width: 12.w),
                DropdownButton<String>(
                  value: _category,
                  dropdownColor: ColorManager.surface,
                  style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold, fontSize: 16.sp),
                  items: ['Strength', 'Cardio', 'Mobility', 'Other']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setState(() => _category = val!),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sets', style: TextStyle(color: ColorManager.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () {
                    final firstWeight = double.tryParse(_weightControllers.first.text) ?? 60.0;
                    PlateCalculatorSheet.show(
                      context,
                      initialWeight: firstWeight > 0 ? firstWeight : 60.0,
                      onWeightApplied: (w) {
                        final formatted = w % 1 == 0 ? w.toInt().toString() : w.toStringAsFixed(1);
                        setState(() {
                          for (var c in _weightControllers) {
                            if (c.text.isEmpty || c.text == '0') {
                              c.text = formatted;
                            }
                          }
                          if (_weightControllers.isNotEmpty) {
                            _weightControllers.first.text = formatted;
                          }
                        });
                      },
                    );
                  },
                  icon: Icon(Icons.fitness_center_rounded, size: 16, color: ColorManager.primaryText),
                  label: Text('Plate Math', style: TextStyle(color: ColorManager.primaryText, fontSize: 13.sp, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            
            // Sets Table (Weight, Reps Input Form matching workout execution)
            Card(
              color: ColorManager.surface,
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTableHeaderCell('Set'),
                        _buildTableHeaderCell('Weight (${Units.label})'),
                        _buildTableHeaderCell('Reps'),
                        _buildTableHeaderCell('Action'),
                      ],
                    ),
                    const Divider(),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _sets.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Set Number Badge
                              Expanded(
                                child: Center(
                                  child: CircleAvatar(
                                    radius: 12.r,
                                    backgroundColor: ColorManager.primary.withValues(alpha: 0.15),
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: ColorManager.primaryText,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Weight input field
                              Expanded(
                                child: Center(
                                  child: SizedBox(
                                    width: 65.w,
                                    height: 32.h,
                                    child: TextField(
                                      key: Key('quick_log_weight_input_$index'),
                                      controller: _weightControllers[index],
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.zero,
                                        filled: true,
                                        fillColor: ColorManager.divider.withValues(alpha: 0.3),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Reps input field
                              Expanded(
                                child: Center(
                                  child: SizedBox(
                                    width: 65.w,
                                    height: 32.h,
                                    child: TextField(
                                      key: Key('quick_log_reps_input_$index'),
                                      controller: _repControllers[index],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.zero,
                                        filled: true,
                                        fillColor: ColorManager.divider.withValues(alpha: 0.3),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide.none),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Delete Button
                              Expanded(
                                child: Center(
                                  child: IconButton(
                                    tooltip: 'Remove set',
                                    icon: Icon(Icons.remove_circle_outline, color: ColorManager.errorText),
                                    onPressed: () => _removeSet(index),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    TextButton.icon(
                      onPressed: _addSet,
                      icon: Icon(Icons.add, color: ColorManager.primaryText),
                      label: Text('Add Set', style: TextStyle(color: ColorManager.primaryText, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20.h),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: TextStyle(color: ColorManager.textPrimary),
              decoration: InputDecoration(
                labelText: 'Notes',
                labelStyle: TextStyle(color: ColorManager.textSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: ColorManager.divider)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: ColorManager.divider)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: ColorManager.primary, width: 2),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('log_add_another_button'),
                onPressed: _isSaving ? null : _commitCurrentExercise,
                icon: Icon(Icons.add_rounded, color: ColorManager.primaryText),
                label: Text(
                  'Add another exercise',
                  style: TextStyle(
                    color: ColorManager.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  side: BorderSide(color: ColorManager.primary.withValues(alpha: 0.6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button.r)),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('log_save_button'),
                onPressed: _isSaving ? null : _saveLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  foregroundColor: ColorManager.onMint,
                  disabledBackgroundColor: ColorManager.primary.withValues(alpha: 0.6),
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button.r)),
                  elevation: 4,
                ),
                child: _isSaving
                    ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColorManager.onMint,
                        ),
                      )
                    : Text(
                        () {
                          final total = _added.length +
                              (_exerciseController.text.trim().isNotEmpty ? 1 : 0);
                          return total > 1
                              ? 'Save Workout ($total exercises)'
                              : 'Save Workout';
                        }(),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String label) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: ColorManager.textTertiary,
          fontWeight: FontWeight.bold,
          fontSize: 12.sp,
        ),
      ),
    );
  }
}
