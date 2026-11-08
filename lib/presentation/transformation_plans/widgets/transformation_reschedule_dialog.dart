import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:fitness_app/model/transformation_plan_model.dart';
import 'package:fitness_app/presentation/transformation_plans/providers/transformation_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';

/// Interactive dialog for flexible workout rescheduling or skipping
class TransformationRescheduleDialog extends StatelessWidget {
  final int dayNumber;
  final String dayName;
  final TransformationProvider provider;
  final UserTransformationState state;

  const TransformationRescheduleDialog({
    super.key,
    required this.dayNumber,
    required this.dayName,
    required this.provider,
    required this.state,
  });

  static Future<void> show(
    BuildContext context, {
    required int dayNumber,
    required String dayName,
    required TransformationProvider provider,
    required UserTransformationState state,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransformationRescheduleDialog(
        dayNumber: dayNumber,
        dayName: dayName,
        provider: provider,
        state: state,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final originalDate = state.getOriginalDateForDay(dayNumber);
    final scheduledDate = state.getScheduledDateForDay(dayNumber);
    final isRescheduled = state.isDayRescheduled(dayNumber);
    final isSkipped = state.isDaySkipped(dayNumber);

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final normalizedTomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    return Container(
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: ColorManager.divider,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit_calendar_rounded, color: ColorManager.primary, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Schedule — Day $dayNumber',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dayName,
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Current schedule details
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: ColorManager.surfaceDark,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: ColorManager.divider),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Original Date:', style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp)),
                    Text(DateFormat('EEE, MMM d, yyyy').format(originalDate),
                        style: TextStyle(color: ColorManager.textPrimary, fontSize: 11.sp, fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Scheduled Date:', style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp)),
                    Text(DateFormat('EEE, MMM d, yyyy').format(scheduledDate),
                        style: TextStyle(
                          color: isRescheduled ? ColorManager.primary : ColorManager.textPrimary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
                if (isSkipped) ...[
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status:', style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp)),
                      Text('Skipped (Not Completed)',
                          style: TextStyle(color: ColorManager.accent, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Action 1: Reschedule to Tomorrow
          ListTile(
            key: const Key('reschedule_tomorrow_tile'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.next_plan_rounded, color: ColorManager.primary, size: 22.sp),
            title: Text(
              'Reschedule to Tomorrow',
              style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              DateFormat('EEEE, MMM d').format(normalizedTomorrow),
              style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
            ),
            trailing: Icon(Icons.arrow_forward_ios_rounded, color: ColorManager.textTertiary, size: 14.sp),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await provider.rescheduleDay(
                dayNumber: dayNumber,
                newDate: normalizedTomorrow,
              );
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Day $dayNumber rescheduled to tomorrow (${DateFormat('MMM d').format(normalizedTomorrow)})'),
                  backgroundColor: ColorManager.primary,
                ),
              );
            },
          ),
          Divider(color: ColorManager.divider, height: 1),

          // Action 2: Choose Another Date
          ListTile(
            key: const Key('reschedule_pick_date_tile'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.calendar_month_rounded, color: ColorManager.secondary, size: 22.sp),
            title: Text(
              'Choose Another Available Date',
              style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Pick a suitable day that fits your weekly recovery',
              style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
            ),
            trailing: Icon(Icons.arrow_forward_ios_rounded, color: ColorManager.textTertiary, size: 14.sp),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: scheduledDate.isAfter(DateTime.now()) ? scheduledDate : DateTime.now(),
                firstDate: state.startDate,
                lastDate: state.startDate.add(Duration(days: state.totalDays + 60)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: ColorManager.primary,
                        surface: ColorManager.surface,
                        onSurface: ColorManager.textPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (pickedDate != null) {
                await provider.rescheduleDay(
                  dayNumber: dayNumber,
                  newDate: pickedDate,
                );
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Day $dayNumber moved to ${DateFormat('EEE, MMM d').format(pickedDate)}'),
                    backgroundColor: ColorManager.primary,
                  ),
                );
              }
            },
          ),
          Divider(color: ColorManager.divider, height: 1),

          // Action 3: Skip this workout
          ListTile(
            key: const Key('skip_workout_tile'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.skip_next_rounded, color: ColorManager.accent, size: 22.sp),
            title: Text(
              'Skip This Workout',
              style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Remains recorded as skipped (never marked completed)',
              style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
            ),
            trailing: Icon(Icons.arrow_forward_ios_rounded, color: ColorManager.textTertiary, size: 14.sp),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              // Show confirmation modal as required by specification
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: ColorManager.surface,
                  title: Text(
                    'Skip Day $dayNumber?',
                    style: TextStyle(color: ColorManager.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    'This workout will remain recorded as skipped, NOT completed. Your programme sequence will continue cleanly without creating an unrealistic catch-up backlog.',
                    style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp, height: 1.4),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancel', style: TextStyle(color: ColorManager.textTertiary)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: ColorManager.accent),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Confirm Skip', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                navigator.pop();
                await provider.skipDay(dayNumber: dayNumber);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Day $dayNumber marked as skipped.'),
                    backgroundColor: ColorManager.accent,
                  ),
                );
              }
            },
          ),

          if (isRescheduled || isSkipped) ...[
            Divider(color: ColorManager.divider, height: 1),
            // Action 4: Keep Original Schedule / Reset
            ListTile(
              key: const Key('reset_schedule_tile'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.restart_alt_rounded, color: ColorManager.textSecondary, size: 22.sp),
              title: Text(
                'Reset to Original Schedule',
                style: TextStyle(color: ColorManager.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Restore ${DateFormat('MMM d').format(originalDate)}',
                style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
              ),
              trailing: Icon(Icons.arrow_forward_ios_rounded, color: ColorManager.textTertiary, size: 14.sp),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                await provider.resetDaySchedule(dayNumber: dayNumber);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Day $dayNumber restored to original date.'),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
