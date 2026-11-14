import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'dart:async';

import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/haptics.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// A simple timer plus "Log cardio" for one cardio exercise.
///
/// A logged session is saved as a normal workout log (category "Cardio", one
/// set whose reps are the minutes) and updates the streak, so cardio counts as
/// a workout day just like a lifting log does.
class CardioLogPanel extends StatefulWidget {
  const CardioLogPanel({super.key, required this.exerciseName, this.onLogged});

  final String exerciseName;
  final VoidCallback? onLogged;

  @override
  State<CardioLogPanel> createState() => _CardioLogPanelState();
}

class _CardioLogPanelState extends State<CardioLogPanel> {
  // A Stopwatch reads the system clock, so it stays right if the app is
  // backgrounded while the timer runs.
  final Stopwatch _watch = Stopwatch();
  Timer? _ticker;
  bool _saving = false;
  String? _message;
  bool _messageIsError = false;

  int get _seconds => _watch.elapsed.inSeconds;

  /// Whole minutes, rounded, never less than 1 once the timer has started.
  int get _minutes {
    final m = (_seconds / 60).round();
    return m < 1 ? 1 : m;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _format(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  void _toggle() {
    Haptics.light();
    setState(() {
      _message = null;
      if (_watch.isRunning) {
        _watch.stop();
        _ticker?.cancel();
      } else {
        _watch.start();
        _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  void _reset() {
    _ticker?.cancel();
    _watch
      ..stop()
      ..reset();
    setState(() => _message = null);
  }

  Future<void> _log() async {
    if (_saving || _seconds == 0) return;
    final minutes = _minutes;
    _watch.stop();
    _ticker?.cancel();
    setState(() {
      _saving = true;
      _message = null;
    });

    try {
      await WorkoutLogService().addLog(WorkoutLog(
        id: '',
        exerciseName: widget.exerciseName,
        date: DateTime.now(),
        sets: [WorkoutSet(weight: 0, reps: minutes, isCompleted: true)],
        notes: 'Duration: $minutes min',
        category: 'Cardio',
      ));
      // The log is saved; the streak update is best effort.
      try {
        if (mounted) {
          await Provider.of<StatisticsProvider?>(context, listen: false)
              ?.updateStreak();
        }
      } catch (_) {}
      Haptics.medium();
      _watch.reset();
      if (!mounted) return;
      setState(() {
        _saving = false;
        _messageIsError = false;
        _message = 'Logged $minutes min of ${widget.exerciseName}';
      });
      widget.onLogged?.call();
    } catch (e) {
      debugPrint('Could not log cardio: $e');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _messageIsError = true;
        _message = "Couldn't log cardio. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final running = _watch.isRunning;
    final canLog = _seconds > 0 && !_saving;

    return Container(
      key: const Key('cardio_log_panel'),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(
            color: ColorManager.limerGreen2.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _format(_seconds),
                  key: const Key('cardio_timer_text'),
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              TextButton(
                key: const Key('cardio_timer_reset'),
                onPressed: (_seconds > 0 && !_saving) ? _reset : null,
                child: const Text('Reset'),
              ),
              SizedBox(width: 6.w),
              ElevatedButton(
                key: const Key('cardio_timer_toggle'),
                onPressed: _saving ? null : _toggle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.limerGreen2,
                  minimumSize: Size(96.w, 44.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button)),
                ),
                child: Text(
                  running ? 'Pause' : (_seconds > 0 ? 'Resume' : 'Start'),
                  style: TextStyle(
                      color: ColorManager.onMint, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          OutlinedButton(
            key: const Key('cardio_log_button'),
            onPressed: canLog ? _log : null,
            style: OutlinedButton.styleFrom(
              minimumSize: Size.fromHeight(46.h),
              side: BorderSide(
                  color: canLog
                      ? ColorManager.limerGreen2
                      : ColorManager.divider),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button)),
            ),
            child: _saving
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    _seconds > 0 ? 'Log cardio ($_minutes min)' : 'Log cardio',
                    style: TextStyle(
                      color: canLog
                          ? ColorManager.primaryText
                          : ColorManager.textTertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          if (_message != null) ...[
            SizedBox(height: 8.h),
            Text(
              _message!,
              key: const Key('cardio_log_message'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _messageIsError
                    ? ColorManager.errorText
                    : ColorManager.primaryText,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
