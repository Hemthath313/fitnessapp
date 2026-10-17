import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/services/strength_service.dart';
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
    if (seconds <= 0) return '0 min';
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete Session',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                    color: isPartial ? Colors.orange.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isPartial ? Colors.orange.withOpacity(0.4) : Colors.green.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    isPartial ? 'Partial Session' : 'Completed',
                    style: TextStyle(
                      color: isPartial ? Colors.orange : Colors.greenAccent,
                      fontSize: 11.sp,
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
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: ColorManager.divider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: _formatDuration(session.durationSeconds),
                    color: Colors.blueAccent,
                  ),
                  Container(width: 1, height: 40.h, color: ColorManager.divider),
                  _buildSummaryItem(
                    icon: Icons.fitness_center_rounded,
                    label: 'Total Volume',
                    value: '${session.totalVolume.toInt()} kg',
                    color: ColorManager.primary,
                  ),
                  Container(width: 1, height: 40.h, color: ColorManager.divider),
                  _buildSummaryItem(
                    icon: Icons.checklist_rounded,
                    label: 'Exercises',
                    value: '${session.exercises.length}',
                    color: Colors.purpleAccent,
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

            // Exercise Cards
            ...session.exercises.map((exercise) => _buildExerciseCard(exercise)),
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
            fontSize: 15.sp,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(SessionExercise exercise) {
    final cleanName = ExerciseIdentity.cleanDisplayName(exercise.exerciseName);

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(14.r),
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
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.analytics_outlined, color: ColorManager.primary, size: 20.sp),
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
              style: TextStyle(color: ColorManager.textTertiary, fontSize: 11.sp, fontStyle: FontStyle.italic),
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
                SizedBox(width: 32.w, child: Text('SET', style: TextStyle(color: ColorManager.textTertiary, fontSize: 10.sp, fontWeight: FontWeight.bold))),
                Expanded(child: Text('TYPE', style: TextStyle(color: ColorManager.textTertiary, fontSize: 10.sp, fontWeight: FontWeight.bold))),
                SizedBox(width: 70.w, child: Text('WEIGHT', style: TextStyle(color: ColorManager.textTertiary, fontSize: 10.sp, fontWeight: FontWeight.bold))),
                SizedBox(width: 50.w, child: Text('REPS', style: TextStyle(color: ColorManager.textTertiary, fontSize: 10.sp, fontWeight: FontWeight.bold))),
                SizedBox(width: 65.w, child: Text('EST. 1RM', style: TextStyle(color: ColorManager.textTertiary, fontSize: 10.sp, fontWeight: FontWeight.bold))),
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

            return Padding(
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
                      '${set.weight.toStringAsFixed(set.weight % 1 == 0 ? 0 : 1)} kg',
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
                      est1RM > 0 ? '${est1RM.toStringAsFixed(1)} kg' : '—',
                      style: TextStyle(color: ColorManager.primary, fontSize: 12.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    width: 30.w,
                    child: Icon(
                      set.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                      size: 16.sp,
                      color: set.isCompleted ? Colors.greenAccent : ColorManager.textTertiary,
                    ),
                  ),
                ],
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
        bg = Colors.amber.withOpacity(0.15);
        text = Colors.amber;
        label = 'Warmup';
        break;
      case SetType.drop:
        bg = Colors.purple.withOpacity(0.15);
        text = Colors.purpleAccent;
        label = 'Drop';
        break;
      case SetType.failure:
        bg = Colors.red.withOpacity(0.15);
        text = Colors.redAccent;
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
        style: TextStyle(color: text, fontSize: 10.sp, fontWeight: FontWeight.w600),
      ),
    );
  }
}
