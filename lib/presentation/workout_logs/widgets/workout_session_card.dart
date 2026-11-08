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

  const WorkoutSessionCard({
    super.key,
    required this.session,
  });

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0 min';
    final mins = seconds ~/ 60;
    if (mins >= 60) {
      final hours = mins ~/ 60;
      final remMins = mins % 60;
      return '${hours}h ${remMins}m';
    }
    return '$mins min';
  }

  @override
  Widget build(BuildContext context) {
    final sessionDate = session.completedAt ?? session.startedAt;
    final isPartial = session.isPartial;
    final title = session.workoutName.isNotEmpty ? session.workoutName : session.dayName;

    // Extract first 3 clean exercise names for preview
    final exerciseNames = session.exercises
        .map((e) => ExerciseIdentity.cleanDisplayName(e.exerciseName))
        .take(3)
        .toList();
    final remainingCount = session.exercises.length - exerciseNames.length;

    return Card(
      color: ColorManager.surface,
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 0,
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
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Title & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          DateFormat('EEE, MMM d, yyyy • h:mm a').format(sessionDate),
                          style: TextStyle(
                            color: ColorManager.textTertiary,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isPartial ? Colors.orange.withValues(alpha: 0.12) : Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isPartial ? Colors.orange.withValues(alpha: 0.35) : Colors.green.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      isPartial ? 'Partial' : 'Completed',
                      style: TextStyle(
                        color: isPartial ? Colors.orange : Colors.greenAccent,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Metrics Chips Row: Duration, Volume, Exercises
              Row(
                children: [
                  _buildMetricBadge(
                    icon: Icons.timer_outlined,
                    text: _formatDuration(session.durationSeconds),
                    color: Colors.blueAccent,
                  ),
                  SizedBox(width: 8.w),
                  _buildMetricBadge(
                    icon: Icons.fitness_center_rounded,
                    text: '${session.totalVolume.toInt()} kg',
                    color: ColorManager.primary,
                  ),
                  SizedBox(width: 8.w),
                  _buildMetricBadge(
                    icon: Icons.checklist_rounded,
                    text: '${session.exercises.length} exercises',
                    color: Colors.purpleAccent,
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Exercises List Preview
              if (exerciseNames.isNotEmpty) ...[
                Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  children: [
                    ...exerciseNames.map((name) => Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: ColorManager.surfaceDark,
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: ColorManager.divider.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            name,
                            style: TextStyle(
                              color: ColorManager.textSecondary,
                              fontSize: 11.sp,
                            ),
                          ),
                        )),
                    if (remainingCount > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: ColorManager.surfaceDark,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          '+$remainingCount more',
                          style: TextStyle(
                            color: ColorManager.textTertiary,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              SizedBox(height: 10.h),
              Align(
                alignment: Alignment.centerRight,
                child: RepeatWorkoutButton(session: session),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
