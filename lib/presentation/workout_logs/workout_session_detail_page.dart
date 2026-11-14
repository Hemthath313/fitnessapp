import 'package:fitness_app/utils/units.dart';
import 'package:fitness_app/utils/managers/layout_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/workout_logs/widgets/repeat_workout_widgets.dart';
import 'package:fitness_app/services/session_edit.dart';
import 'package:fitness_app/services/strength_service.dart';
import 'package:fitness_app/utils/app_feedback.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class WorkoutSessionDetailPage extends StatefulWidget {
  final WorkoutSession? session;
  final String? sessionId;

  const WorkoutSessionDetailPage({
    super.key,
    this.session,
    this.sessionId,
  });

  @override
  State<WorkoutSessionDetailPage> createState() => _WorkoutSessionDetailPageState();
}

class _WorkoutSessionDetailPageState extends State<WorkoutSessionDetailPage> {
  WorkoutSession? _currentSession;
  bool _isLoading = false;
  bool _editing = false;
  final WorkoutLogService _logService = WorkoutLogService();

  @override
  void initState() {
    super.initState();
    if (widget.session != null) {
      _currentSession = widget.session;
    } else if (widget.sessionId != null) {
      _loadSession(widget.sessionId!);
    }
  }

  Future<void> _loadSession(String id) async {
    setState(() => _isLoading = true);
    final session = await _logService.getSessionById(id);
    if (mounted) {
      setState(() {
        _currentSession = session;
        _isLoading = false;
      });
    }
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '—';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins >= 60) {
      final hours = mins ~/ 60;
      final remMins = mins % 60;
      return '${hours}h ${remMins}m';
    }
    return secs > 0 ? '${mins}m ${secs}s' : '$mins min';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorManager.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Delete Workout Session?',
          style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will remove this session from your history. This action cannot be undone.',
          style: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: ColorManager.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: ColorManager.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && _currentSession != null) {
      await _logService.deleteSession(_currentSession!.id);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout session deleted')),
        );
      }
    }
  }

  Future<void> _editSet(int exerciseIndex, int setIndex) async {
    final session = _currentSession;
    if (session == null) return;
    final set = session.exercises[exerciseIndex].sets[setIndex];
    final result = await showDialog<_SetEditResult>(
      context: context,
      builder: (_) => _SetEditDialog(weight: set.weight, reps: set.reps),
    );
    if (result == null || !mounted) return;

    final WorkoutSession edited;
    if (result.delete) {
      edited = SessionEdit.removeSet(
        session,
        exerciseIndex: exerciseIndex,
        setIndex: setIndex,
      );
      if (edited.exercises.isEmpty) {
        AppFeedback.info(
          context,
          'That was the last set. Delete the whole session instead.',
        );
        return;
      }
    } else {
      edited = SessionEdit.updateSet(
        session,
        exerciseIndex: exerciseIndex,
        setIndex: setIndex,
        weight: result.weight ?? set.weight,
        reps: result.reps ?? set.reps,
      );
    }

    try {
      await _logService.updateSession(session, edited);
      if (!mounted) return;
      setState(() => _currentSession = edited);
      AppFeedback.success(context, result.delete ? 'Set removed' : 'Set updated');
    } catch (_) {
      if (!mounted) return;
      AppFeedback.error(context, "Couldn't save that change. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: ColorManager.background,
        appBar: AppBar(backgroundColor: ColorManager.background),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final session = _currentSession;
    if (session == null) {
      return Scaffold(
        backgroundColor: ColorManager.background,
        appBar: AppBar(
          backgroundColor: ColorManager.background,
          iconTheme: IconThemeData(color: ColorManager.textPrimary),
        ),
        body: Center(
          child: Text(
            'Workout session not found',
            style: TextStyle(color: ColorManager.textTertiary, fontSize: 16.sp),
          ),
        ),
      );
    }

    final sessionDate = session.completedAt ?? session.startedAt;
    final isPartial = session.isPartial;

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        backgroundColor: ColorManager.background,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
        title: Text(
          session.workoutName.isNotEmpty ? session.workoutName : session.dayName,
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: AppText.appBarTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            key: const Key('edit_session_button'),
            onPressed: () => setState(() => _editing = !_editing),
            child: Text(
              _editing ? 'Done' : 'Edit',
              style: TextStyle(
                color: ColorManager.primaryText,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          PopupMenuButton<String>(
            key: const Key('session_more_menu'),
            tooltip: 'More',
            color: ColorManager.surface,
            icon: Icon(Icons.more_vert_rounded, color: ColorManager.textPrimary),
            onSelected: (value) {
              if (value == 'delete') _confirmDelete(context);
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                key: const Key('session_delete_menu_item'),
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: ColorManager.errorText),
                    SizedBox(width: 10.w),
                    Text('Delete workout', style: TextStyle(color: ColorManager.errorText)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
          child: RepeatWorkoutButton(session: session, expanded: true),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Date and Status Badge Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14.sp, color: ColorManager.textTertiary),
                    SizedBox(width: 6.w),
                    Text(
                      DateFormat('EEEE, MMM d, yyyy • h:mm a').format(sessionDate),
                      style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isPartial ? ColorManager.warning.withValues(alpha: 0.15) : ColorManager.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isPartial ? ColorManager.warning.withValues(alpha: 0.4) : ColorManager.success.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    isPartial ? 'Partial Session' : 'Completed',
                    style: TextStyle(
                      color: isPartial ? ColorManager.warningText : ColorManager.successText,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Hero Summary Stats Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: ColorManager.surface,
                boxShadow: ColorManager.cardShadow,
                borderRadius: BorderRadius.circular(AppRadius.tile.r),
                border: Border.all(color: ColorManager.divider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: _formatDuration(session.durationSeconds),
                    color: ColorManager.info,
                  ),
                  Container(width: 1, height: 40.h, color: ColorManager.divider),
                  _buildSummaryItem(
                    icon: Icons.fitness_center_rounded,
                    label: 'Total Volume',
                    value: '${Units.intOf(session.totalVolume)} ${Units.label}',
                    color: ColorManager.primary,
                  ),
                  Container(width: 1, height: 40.h, color: ColorManager.divider),
                  _buildSummaryItem(
                    icon: Icons.checklist_rounded,
                    label: 'Exercises',
                    value: '${session.exercises.length}',
                    color: ColorManager.violetText,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Exercises Breakdown Header
            Text(
              'Exercise Log (${session.exercises.length})',
              style: TextStyle(
                color: ColorManager.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),

            if (_editing) ...[
              Container(
                key: const Key('edit_session_banner'),
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: ColorManager.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Tap a set to fix its weight or reps, or remove it.',
                  style: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp),
                ),
              ),
            ],

            // Exercise Cards
            ...session.exercises
                .asMap()
                .entries
                .map((e) => _buildExerciseCard(e.value, e.key)),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20.sp),
        SizedBox(height: 6.h),
        Text(
          value,
          style: TextStyle(
            color: ColorManager.white,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(SessionExercise exercise, int exerciseIndex) {
    final cleanName = ExerciseIdentity.cleanDisplayName(exercise.exerciseName);

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise Header Row with Progression Link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  cleanName,
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.analytics_outlined, color: ColorManager.primaryText, size: 20.sp),
                tooltip: 'View Progression',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => context.push(
                  '${Routes.exerciseTracker}?exerciseName=${Uri.encodeComponent(cleanName)}',
                ),
              ),
            ],
          ),
          if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              exercise.notes!,
              style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp, fontStyle: FontStyle.italic),
            ),
          ],
          SizedBox(height: 10.h),

          // Sets Table Header
          Container(
            padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
            decoration: BoxDecoration(
              color: ColorManager.surfaceDark,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                SizedBox(width: 32.w, child: Text('SET', style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp, fontWeight: FontWeight.bold))),
                Expanded(child: Text('TYPE', style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp, fontWeight: FontWeight.bold))),
                SizedBox(width: 70.w, child: Text('WEIGHT', style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp, fontWeight: FontWeight.bold))),
                SizedBox(width: 50.w, child: Text('REPS', style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp, fontWeight: FontWeight.bold))),
                SizedBox(width: 65.w, child: Text('EST. 1RM', style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp, fontWeight: FontWeight.bold))),
                SizedBox(width: 30.w, child: const SizedBox.shrink()),
              ],
            ),
          ),
          SizedBox(height: 6.h),

          // Sets Rows
          ...exercise.sets.asMap().entries.map((entry) {
            final setIndex = entry.key + 1;
            final set = entry.value;
            final est1RM = StrengthService.calculateEstimated1RM(set);

            return InkWell(
              key: Key('set_row_${exerciseIndex}_${entry.key}'),
              onTap: _editing ? () => _editSet(exerciseIndex, entry.key) : null,
              borderRadius: BorderRadius.circular(8.r),
              child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
              child: Row(
                children: [
                  SizedBox(
                    width: 32.w,
                    child: Text(
                      '$setIndex',
                      style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _buildSetTypeBadge(set.type),
                    ),
                  ),
                  SizedBox(
                    width: 70.w,
                    child: Text(
                      '${Units.fmtSmart(set.weight)} ${Units.label}',
                      style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    width: 50.w,
                    child: Text(
                      '${set.reps}',
                      style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(
                    width: 65.w,
                    child: Text(
                      est1RM > 0 ? '${Units.fmt(est1RM, 1)} ${Units.label}' : '—',
                      style: TextStyle(color: ColorManager.primaryText, fontSize: 12.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    width: 30.w,
                    child: Icon(
                      _editing
                          ? Icons.edit_outlined
                          : (set.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked),
                      size: 16.sp,
                      color: _editing
                          ? ColorManager.primaryText
                          : (set.isCompleted ? ColorManager.success : ColorManager.textTertiary),
                    ),
                  ),
                ],
              ),
            ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSetTypeBadge(SetType type) {
    Color bg;
    Color text;
    String label;

    switch (type) {
      case SetType.warmup:
        bg = ColorManager.premium.withValues(alpha: 0.15);
        text = ColorManager.premium;
        label = 'Warmup';
        break;
      case SetType.drop:
        bg = ColorManager.violet.withValues(alpha: 0.15);
        text = ColorManager.violetText;
        label = 'Drop';
        break;
      case SetType.failure:
        bg = ColorManager.error.withValues(alpha: 0.15);
        text = ColorManager.error;
        label = 'Failure';
        break;
      case SetType.normal:
        bg = ColorManager.surfaceLight;
        text = ColorManager.textSecondary;
        label = 'Normal';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 12.sp, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SetEditResult {
  const _SetEditResult({this.weight, this.reps, this.delete = false});
  final double? weight;
  final int? reps;
  final bool delete;
}

class _SetEditDialog extends StatefulWidget {
  const _SetEditDialog({required this.weight, required this.reps});
  final double weight;
  final int reps;

  @override
  State<_SetEditDialog> createState() => _SetEditDialogState();
}

class _SetEditDialogState extends State<_SetEditDialog> {
  late final TextEditingController _weight;
  late final TextEditingController _reps;
  String? _error;

  @override
  void initState() {
    super.initState();
    _weight = TextEditingController(text: Units.fmtSmart(widget.weight));
    _reps = TextEditingController(text: '${widget.reps}');
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  void _save() {
    final w = Units.parseToKg(_weight.text);
    final r = int.tryParse(_reps.text.trim());
    if (w == null || w < 0 || r == null || r <= 0) {
      setState(() => _error = 'Enter a weight of 0 or more and at least 1 rep.');
      return;
    }
    Navigator.pop(context, _SetEditResult(weight: w, reps: r));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorManager.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Text(
        'Edit set',
        style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('edit_set_weight'),
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: ColorManager.textPrimary),
            decoration: InputDecoration(labelText: 'Weight (${Units.label})'),
          ),
          SizedBox(height: 12.h),
          TextField(
            key: const Key('edit_set_reps'),
            controller: _reps,
            keyboardType: TextInputType.number,
            style: TextStyle(color: ColorManager.textPrimary),
            decoration: const InputDecoration(labelText: 'Reps'),
          ),
          if (_error != null) ...[
            SizedBox(height: 8.h),
            Text(_error!, style: TextStyle(color: ColorManager.errorText, fontSize: 12.sp)),
          ],
        ],
      ),
      actions: [
        TextButton(
          key: const Key('edit_set_delete'),
          onPressed: () => Navigator.pop(context, const _SetEditResult(delete: true)),
          child: Text('Remove set', style: TextStyle(color: ColorManager.errorText)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: ColorManager.textTertiary)),
        ),
        ElevatedButton(
          key: const Key('edit_set_save'),
          onPressed: _save,
          style: ElevatedButton.styleFrom(backgroundColor: ColorManager.primary),
          child: Text('Save', style: TextStyle(color: ColorManager.onMint)),
        ),
      ],
    );
  }
}
