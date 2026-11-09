import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/services/notification_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared logic for the "remind me" opt-in. Uses the same Daily Gym Alarm
/// settings as Profile, so the Profile toggle always reflects what was chosen.
class ReminderOptIn {
  ReminderOptIn._();

  static const String dismissedKey = 'reminder_prompt_dismissed';
  static const TimeOfDay defaultTime = TimeOfDay(hour: 18, minute: 30);

  /// True when we should still offer the prompt: no permission yet, no alarm
  /// already set, and the user has not said "Not now".
  static Future<bool> shouldPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(dismissedKey) ?? false) return false;
      if (prefs.getBool('gym_alarm_enabled') ?? false) return false;
      final hasPermission = await NotificationService().hasNotificationPermission();
      return !hasPermission;
    } catch (_) {
      return false;
    }
  }

  /// Asks for permission (with the benefit already explained on screen) and
  /// schedules the reminder. Returns whether reminders are now active.
  static Future<bool> enable(TimeOfDay time) async {
    try {
      final service = NotificationService();
      var granted = await service.hasNotificationPermission();
      if (!granted) granted = await service.requestNotificationPermissions();

      final prefs = await SharedPreferences.getInstance();
      if (!granted) {
        // Asked once; do not nag. Settings remain available in Profile.
        await prefs.setBool(dismissedKey, true);
        return false;
      }
      await prefs.setBool('gym_alarm_enabled', true);
      await prefs.setInt('gym_alarm_hour', time.hour);
      await prefs.setInt('gym_alarm_minute', time.minute);
      await service.scheduleDailyGymAlarm(time);
      await service.scheduleStreakReminder();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> dismiss() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(dismissedKey, true);
    } catch (_) {}
  }
}

/// "Never miss a session" card: states the benefit, lets the user pick a time,
/// then asks for the notification permission. Hides itself when not needed.
class ReminderOptInCard extends StatefulWidget {
  const ReminderOptInCard({
    super.key,
    this.shouldPrompt,
    this.onEnable,
    this.onDismiss,
    this.initialTime = ReminderOptIn.defaultTime,
  });

  /// Overrides for tests; default to [ReminderOptIn].
  final Future<bool> Function()? shouldPrompt;
  final Future<bool> Function(TimeOfDay time)? onEnable;
  final Future<void> Function()? onDismiss;
  final TimeOfDay initialTime;

  @override
  State<ReminderOptInCard> createState() => _ReminderOptInCardState();
}

enum _OptInState { checking, hidden, ask, done, denied }

class _ReminderOptInCardState extends State<ReminderOptInCard> {
  _OptInState _state = _OptInState.checking;
  late TimeOfDay _time;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _time = widget.initialTime;
    _check();
  }

  Future<void> _check() async {
    final show = await (widget.shouldPrompt ?? ReminderOptIn.shouldPrompt)();
    if (!mounted) return;
    setState(() => _state = show ? _OptInState.ask : _OptInState.hidden);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _enable() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await (widget.onEnable ?? ReminderOptIn.enable)(_time);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _state = ok ? _OptInState.done : _OptInState.denied;
    });
  }

  Future<void> _dismiss() async {
    await (widget.onDismiss ?? ReminderOptIn.dismiss)();
    if (mounted) setState(() => _state = _OptInState.hidden);
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _OptInState.checking:
      case _OptInState.hidden:
        return const SizedBox.shrink();
      case _OptInState.done:
        return _shell(
          key: const Key('reminder_opt_in_done'),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: ColorManager.primaryText, size: 20.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Reminder set for ${_time.format(context)}. Change it any time in Profile.',
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      case _OptInState.denied:
        return _shell(
          key: const Key('reminder_opt_in_denied'),
          child: Text(
            'No problem. You can turn reminders on later in Profile > Reminders.',
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 13.sp,
            ),
          ),
        );
      case _OptInState.ask:
        return _shell(
          key: const Key('reminder_opt_in_card'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorManager.primary.withValues(alpha: 0.16),
                    ),
                    child: Icon(Icons.notifications_active_rounded,
                        color: ColorManager.primary, size: 18.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Never miss a session',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'Get one nudge a day at the time you pick, so your streak survives busy days.',
                style: TextStyle(
                  color: ColorManager.textSecondary,
                  fontSize: 13.sp,
                  height: 1.35,
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  ActionChip(
                    key: const Key('reminder_time_chip'),
                    avatar: Icon(Icons.schedule_rounded,
                        size: 16.sp, color: ColorManager.primary),
                    label: Text(
                      _time.format(context),
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: ColorManager.surfaceLight,
                    side: BorderSide(color: ColorManager.divider),
                    onPressed: _pickTime,
                  ),
                  const Spacer(),
                  TextButton(
                    key: const Key('reminder_not_now'),
                    onPressed: _dismiss,
                    child: Text(
                      'Not now',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  ElevatedButton(
                    key: const Key('reminder_enable'),
                    onPressed: _busy ? null : _enable,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      foregroundColor: ColorManager.onMint,
                      elevation: 0,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button.r),
                      ),
                    ),
                    child: Text(
                      'Remind me',
                      style: TextStyle(
                        color: ColorManager.onMint,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }

  Widget _shell({required Key key, required Widget child}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        border: Border.all(color: ColorManager.divider),
      ),
      child: child,
    );
  }
}
