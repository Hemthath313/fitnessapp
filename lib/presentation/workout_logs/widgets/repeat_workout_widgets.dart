import 'package:fitness_app/model/workout_session_model.dart';
import 'package:fitness_app/services/repeat_workout.dart';
import 'package:fitness_app/utils/app_feedback.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Opens the guided session pre-filled with the exercises of [session].
/// Standalone: it does not attach to a programme, so streaks and badges still
/// count it but no programme day is advanced.
void launchRepeatWorkout(BuildContext context, WorkoutSession session) {
  final exercises = RepeatWorkout.exercisesFor(session);
  if (exercises.isEmpty) {
    AppFeedback.info(context, 'This session has no exercises to repeat.');
    return;
  }
  context.push(
    Routes.dayWorkoutSessionRoute,
    extra: {
      'dayName': session.dayName.isNotEmpty ? session.dayName : 'today',
      'workouts': exercises,
    },
  );
}

/// Compact "Repeat" button for session cards and the detail page.
class RepeatWorkoutButton extends StatelessWidget {
  const RepeatWorkoutButton({
    super.key,
    required this.session,
    this.expanded = false,
    this.label = 'Repeat this workout',
  });

  final WorkoutSession session;

  /// Full-width filled button (detail page) instead of a compact outline.
  final bool expanded;

  /// Button text; the short form is used where space is tight.
  final String label;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.bold,
        color: expanded ? ColorManager.onMint : ColorManager.primary,
      ),
    );
    final icon = Icon(
      Icons.replay_rounded,
      size: 18.sp,
      color: expanded ? ColorManager.onMint : ColorManager.primary,
    );
    final onPressed = () => launchRepeatWorkout(context, session);

    if (expanded) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          key: const Key('repeat_workout_button'),
          onPressed: onPressed,
          icon: icon,
          label: labelText,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorManager.primary,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            elevation: 0,
          ),
        ),
      );
    }
    return OutlinedButton.icon(
      key: const Key('repeat_workout_button'),
      onPressed: onPressed,
      icon: icon,
      label: labelText,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: ColorManager.primary.withValues(alpha: 0.5)),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }
}

/// "Last workout: Push Day, 3 days ago, [Repeat]" strip shown at the top of
/// History. Renders nothing when there is nothing to repeat.
class LastWorkoutStrip extends StatelessWidget {
  const LastWorkoutStrip({super.key, required this.sessions, this.now});

  final List<WorkoutSession> sessions;

  /// Overrides the clock (tests).
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final last = RepeatWorkout.latest(sessions);
    if (last == null) return const SizedBox.shrink();
    final when = RepeatWorkout.whenLabel(
        RepeatWorkout.dateOf(last), now ?? DateTime.now());
    final count = RepeatWorkout.exercisesFor(last).length;

    return Container(
      key: const Key('last_workout_strip'),
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorManager.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LAST WORKOUT',
                  style: TextStyle(
                    color: ColorManager.textTertiary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  RepeatWorkout.titleOf(last),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$when · $count exercise${count == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: ColorManager.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          RepeatWorkoutButton(session: last, label: 'Repeat'),
        ],
      ),
    );
  }
}
