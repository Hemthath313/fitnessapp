import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'dart:async';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vibration/vibration.dart';

class WorkoutTimerWidget extends StatefulWidget {
  final Function(int)? onTimeUpdate;
  final bool isRestTimer;
  final int initialMinutes;

  const WorkoutTimerWidget({
    super.key,
    this.onTimeUpdate,
    this.isRestTimer = false,
    this.initialMinutes = 0,
  });

  @override
  State<WorkoutTimerWidget> createState() => _WorkoutTimerWidgetState();
}

class _WorkoutTimerWidgetState extends State<WorkoutTimerWidget> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  bool _isCountdown = false; // Add countdown mode flag
  int _initialSeconds = 0; // Track initial countdown time

  @override
  void initState() {
    super.initState();
    // If it's a rest timer or has initial minutes, set it up as countdown
    if (widget.isRestTimer || widget.initialMinutes > 0) {
      _seconds = widget.initialMinutes * 60;
      _initialSeconds = _seconds;
      _isCountdown = true;
    }
    // Auto-start rest timer immediately so user doesn't need to press play
    if (widget.isRestTimer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTimer();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;

    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_isCountdown) {
          // Countdown mode
          if (_seconds > 0) {
            _seconds--;
          } else {
            _timer?.cancel();
            _isRunning = false;
            if (widget.isRestTimer) {
              _showRestCompleteNotification();
            }
          }
        } else {
          // Stopwatch mode - count up
          _seconds++;
        }
      });

      if (widget.onTimeUpdate != null) {
        widget.onTimeUpdate!(_seconds);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      if (_isCountdown) {
        _seconds = _initialSeconds; // Reset to initial countdown time
      } else {
        _seconds = 0; // Reset stopwatch
      }
    });
  }

  void _setRestTime(int minutes) {
    setState(() {
      _seconds = minutes * 60;
      _initialSeconds = _seconds;
    });
  }

  void _showRestCompleteNotification() async {
    // Play vibration
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(duration: 500);
      await Future.delayed(const Duration(milliseconds: 200));
      await Vibration.vibrate(duration: 500);
    }

    // Show dialog or snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rest time complete! Time to work out 💪'),
        backgroundColor: ColorManager.limerGreen2,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SizeManager.s16.w),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer display
          Text(
            widget.isRestTimer ? 'Rest Timer' : 'Workout Timer',
            style: StyleManager.appbarTitleTextStyle.copyWith(
              fontSize: 14.sp,
              color: ColorManager.white70,
            ),
          ),
          SizedBox(height: SizeManager.s8.h),

          // Large timer display
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: SizeManager.s20.w,
              vertical: SizeManager.s12.h,
            ),
            decoration: BoxDecoration(
              color: ColorManager.darkGrey,
              borderRadius: BorderRadius.circular(SizeManager.s12.r),
              border: Border.all(
                color: ColorManager.limerGreen2,
                width: 2,
              ),
            ),
            child: Text(
              _formatTime(_seconds),
              style: TextStyle(
                fontSize: SizeManager.s40.sp,
                fontWeight: FontWeight.bold,
                color: ColorManager.limerGreen2,
                fontFamily: 'monospace',
              ),
            ),
          ),
          SizedBox(height: SizeManager.s16.h),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play/Pause button
              IconButton(tooltip: _isRunning ? 'Pause' : 'Start', 
                icon: Icon(
                  _isRunning ? Icons.pause : Icons.play_arrow,
                  color: ColorManager.limerGreen2,
                ),
                onPressed: _isRunning ? _pauseTimer : _startTimer,
                iconSize: SizeManager.s40.sp,
              ),
              SizedBox(width: SizeManager.s16.w),

              // Reset button
              IconButton(tooltip: 'Reset timer', 
                icon: Icon(Icons.stop, color: Colors.red),
                onPressed: _resetTimer,
                iconSize: SizeManager.s28.sp,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(String label, int seconds) {
    return ElevatedButton(
      onPressed: () => _setRestTime(seconds ~/ 60),
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorManager.grey3,
        padding: EdgeInsets.symmetric(
          horizontal: SizeManager.s12.w,
          vertical: SizeManager.s6.h,
        ),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: ColorManager.white, fontSize: 12.sp),
      ),
    );
  }
}
