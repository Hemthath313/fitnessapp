import 'package:fitness_app/utils/managers/layout_manager.dart';
import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/presentation/workout_logs/widgets/repeat_workout_widgets.dart';
import 'package:fitness_app/services/strength_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class WorkoutSessionCard extends StatelessWidget {
  final WorkoutSession session;

  /// Overridable for tests; defaults to the current time.
  final DateTime? now;

  const WorkoutSessionCard({
    super.key,
    required this.session,
    this.now,
  });

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final mins = seconds ~/ 60;
    if (mins >= 60) {
      final hours = mins ~/ 60;
      final remMins = mins % 60;
      return '${hours}h ${remMins}m';
    }
    return '${mins < 1 ? 1 : mins} min';
  }

  /// "45 min · 3,200 kg · 5 exercises". Parts with no data are left out.
  String _summaryLine() {
    final parts = <String>[];
    final duration = _formatDuration(session.durationSeconds);
    if (duration.isNotEmpty) parts.add(duration);
    if (session.totalVolume >= 1) {
      parts.add('${NumberFormat('#,###').format(session.totalVolume.round())} kg');
    }
    final n = session.exercises.length;
    parts.add('$n ${n == 1 ? 'exercise' : 'exercises'}');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final sessionDate = session.completedAt ?? session.startedAt;
    final isPartial = session.isPartial;
    final title = session.workoutName.isNotEmpty ? session.workoutName : session.dayName;
    final reference = now ?? DateTime.now();
    final dateText = DateFormat(
      sessionDate.year == reference.year ? 'EEE, MMM d' : 'EEE, MMM d, yyyy',
    ).format(sessionDate);
    final timeText = DateFormat('h:mm a').format(sessionDate);

    // One-line preview of the exercises; the full list is on the detail page.
    final names = session.exercises
        .map((e) => ExerciseIdentity.cleanDisplayName(e.exerciseName))
        .toList();
    final preview = names.take(3).join(', ');
    final remaining = names.length - 3;
    final previewText = remaining > 0 ? '$preview +$remaining more' : preview;

    return Card(
      color: ColorManager.surface,
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: ColorManager.divider),
      ),
      child: InkWell(
        onTap: () {
          context.push(
            Routes.workoutSessionDetailRoute,
            extra: session,
          );
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 12.w, 12.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ColorManager.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                        // Only the exception is flagged; finished is the default.
                        if (isPartial) ...[
                          SizedBox(width: 8.w),
                          Container(
                            key: const Key('session_partial_badge'),
                            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
                            ),
                            child: Text(
                              'Partial',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: AppText.caption,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '$dateText • $timeText',
                      style: TextStyle(color: ColorManager.textTertiary, fontSize: 12.sp),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _summaryLine(),
                      key: const Key('session_summary_line'),
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (previewText.isNotEmpty) ...[
                      SizedBox(height: 3.h),
                      Text(
                        previewText,
                        key: const Key('session_exercise_preview'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              RepeatWorkoutButton(session: session, label: 'Repeat'),
            ],
          ),
        ),
      ),
    );
  }
}
