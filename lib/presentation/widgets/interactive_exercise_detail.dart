import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';

class SetLogInput {
  final TextEditingController weightController;
  final TextEditingController repsController;
  bool isCompleted;

  SetLogInput({
    required String defaultWeight,
    required String defaultReps,
    this.isCompleted = false,
  })  : weightController = TextEditingController(text: defaultWeight),
        repsController = TextEditingController(text: defaultReps);

  void dispose() {
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
  });

  @override
  State<InteractiveExerciseDetailWidget> createState() =>
      _InteractiveExerciseDetailWidgetState();
}

class _InteractiveExerciseDetailWidgetState
    extends State<InteractiveExerciseDetailWidget> {
  int _currentTab = 0; // 0 = Instructions, 1 = Log Set, 2 = History
  final List<SetLogInput> _sets = [];
  final WorkoutLogService _logService = WorkoutLogService();
  
  // Previous log caching
  WorkoutLog? _previousLog;
  double _historicMaxWeight = 0.0;
  bool _isLoadingPrevious = true;

  // Rest Timer State
  Timer? _restTimer;
  int _restTimerSeconds = 0;
  bool _isResting = false;

  @override
  void initState() {
    super.initState();
    _loadPreviousLogAndMax();
    _parseAndInitializeSets();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    for (var set in _sets) {
      set.dispose();
    }
    super.dispose();
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
    for (int i = 0; i < defaultSetsCount; i++) {
      _sets.add(SetLogInput(defaultWeight: "", defaultReps: defaultReps));
    }
  }

  // Fetch Firestore history for previous sets and personal records
  Future<void> _loadPreviousLogAndMax() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workout_logs')
          .orderBy('date', descending: true)
          .get();

      final logs = snapshot.docs
          .map((doc) => WorkoutLog.fromMap(doc.data(), doc.id))
          .where((log) => log.exerciseName.toLowerCase() == widget.name.toLowerCase())
          .toList();

      if (logs.isNotEmpty) {
        setState(() {
          _previousLog = logs.first; // Most recent log
          
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

          // Pre-fill log input controllers with previous values
          for (int i = 0; i < _sets.length; i++) {
            if (i < _previousLog!.sets.length) {
              _sets[i].weightController.text =
                  _previousLog!.sets[i].weight.toString();
              _sets[i].repsController.text =
                  _previousLog!.sets[i].reps.toString();
            } else if (_previousLog!.sets.isNotEmpty) {
              // Fallback to prefill using last set info
              _sets[i].weightController.text =
                  _previousLog!.sets.last.weight.toString();
              _sets[i].repsController.text =
                  _previousLog!.sets.last.reps.toString();
            }
          }
        });
      } else {
        setState(() {
          _previousLog = null;
          _historicMaxWeight = 0.0;
          for (var set in _sets) {
            set.weightController.text = "";
          }
        });
      }
    } catch (_) {} finally {
      setState(() {
        _isLoadingPrevious = false;
      });
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
  }

  // Add Set row dynamically
  void _addSetRow() {
    setState(() {
      String weight = "";
      String reps = "10";
      if (_sets.isNotEmpty) {
        weight = _sets.last.weightController.text;
        reps = _sets.last.repsController.text;
      }
      _sets.add(SetLogInput(defaultWeight: weight, defaultReps: reps));
    });
  }

  // Remove Set row
  void _removeSetRow() {
    if (_sets.length <= 1) return;
    setState(() {
      final removed = _sets.removeLast();
      removed.dispose();
    });
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
          ),
        );
      }
      
      _currentTab = 1; // Navigate to Log Set tab
    });

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
                        controller: setInput.weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

                  // Reps Field
                  Expanded(
                    child: Container(
                      height: 38.h,
                      margin: EdgeInsets.symmetric(horizontal: 6.w),
                      child: TextField(
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
      stream: _logService.getLogs(),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
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

              // Video player (fixed at top if Instructions or History is active, hide inside Log Set to save space!)
              if (_currentTab != 1)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
                  child: Container(
                    height: 180.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: ColorManager.divider),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: Stack(
                        children: [
                          ExerciseVideoPlayer(
                            videoPath: widget.videoPath,
                            height: 180.h,
                            width: double.infinity,
                            autoPlay: true,
                          ),
                          // Overlay instructions text indicator
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
