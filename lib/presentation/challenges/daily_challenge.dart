import 'dart:async';

import 'package:fitness_app/presentation/challenges/challenge_progress.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/data/challenge_data.dart';
import 'package:go_router/go_router.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:provider/provider.dart';

class DailyExercisePage extends StatefulWidget {
  final int day;
  final VoidCallback onComplete;

  /// Storage seam; defaults to Firestore. Overridden in tests.
  final SixPackProgressStore? store;

  /// Runs after the day is saved, off the critical path. Defaults to
  /// [StatisticsProvider.updateStreak].
  final Future<void> Function()? updateStreak;

  const DailyExercisePage({
    super.key,
    required this.day,
    required this.onComplete,
    this.store,
    this.updateStreak,
  });

  @override
  State<DailyExercisePage> createState() => _DailyExercisePageState();
}

class _DailyExercisePageState extends State<DailyExercisePage> {
  final List<bool> _completionStatus = [false, false, false];
  late final SixPackProgressStore _store =
      widget.store ?? const FirestoreSixPackProgressStore();
  ChallengeProgress? _progress;
  bool _isSaving = false;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  bool get _isRepeat => _progress?.isCompleted(widget.day) ?? false;

  @override
  void initState() {
    super.initState();
    _loadInitialProgress();
  }

  Future<void> _loadInitialProgress() async {
    try {
      final progress = await _store.load();
      if (!mounted) return;
      setState(() {
        _progress = progress;
        if (progress.isCompleted(widget.day)) {
          for (var i = 0; i < _completionStatus.length; i++) {
            _completionStatus[i] = true;
          }
        }
      });
    } catch (e) {
      // Non-fatal: the day can still be done; completion re-checks progress.
      debugPrint('Six-pack day: could not load progress: $e');
    }
  }

  void showExerciseDetails(BuildContext context, ChallengeExercise exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorManager.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ExerciseVideoPlayer(
                videoPath: exercise.videoPath,
                height: 250,
                fit: BoxFit.contain,
                autoPlay: true,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              exercise.name,
              style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.white),
            ),
            SizedBox(height: 10.h),
            Text(
                'Target: ${exercise.target}',
                style: TextStyle(fontSize: 16.sp, color: ColorManager.white)),
            SizedBox(height: 5.h),
            Text(
                'Equipment: ${exercise.equipment}',
                style: TextStyle(fontSize: 16.sp, color: ColorManager.white)),
            SizedBox(height: 10.h),
            Text(
              'Sets & Reps:',
              style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.white),
            ),
            Text(
              exercise.setsReps,
              style: TextStyle(fontSize: 16.sp, color: ColorManager.white),
            ),
            SizedBox(height: 20.h),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.primary),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: ColorManager.onMint),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ChallengeData.sixPackCurriculum[widget.day] ?? [];
    final sub = Provider.of<SubscriptionProvider?>(context);
    final isPremium = sub?.isPremium ?? false;
    final needsPro = widget.day > 3 && !isPremium;
    // Membership is still loading: don't flash the paywall at a Pro user.
    final checkingAccess = needsPro && (sub?.isLoading ?? false);
    final accessAllowed = !needsPro;

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
        backgroundColor: ColorManager.background,
        title: Text('Day ${widget.day} - 3 Workouts',
            style: TextStyle(color: ColorManager.textPrimary)),
      ),
      body: Stack(
        children: [
          if (checkingAccess)
            const Center(child: CircularProgressIndicator())
          else if (exercises.isEmpty)
            Center(
              child: Text('Curriculum not found for this day.',
                  style: TextStyle(color: ColorManager.textPrimary)),
            )
          else
            ListView.builder(
              itemCount: exercises.length + (_isRepeat ? 1 : 0),
              padding: EdgeInsets.only(top: 12.h),
              itemBuilder: (context, listIndex) {
                if (_isRepeat && listIndex == 0) {
                  return _buildCompletedBanner();
                }
                final index = _isRepeat ? listIndex - 1 : listIndex;
                final exercise = exercises[index];
                final isUnlocked = accessAllowed;

                return Card(
                  color: isUnlocked ? ColorManager.surface : ColorManager.surfaceDark,
                  margin:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    side: BorderSide(
                      color: _completionStatus[index]
                          ? ColorManager.limerGreen2
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  elevation: 4,
                  child: ListTile(
                    onTap: isUnlocked
                        ? () => showExerciseDetails(context, exercise)
                        : null,
                    contentPadding: EdgeInsets.all(12.w),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: ExerciseVideoPlayer(
                        videoPath: exercise.videoPath,
                        width: 70.w,
                        height: 70.w,
                        showThumbnailOnly: true,
                      ),
                    ),
                    title: Text(
                      exercise.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                          color: isUnlocked ? ColorManager.textPrimary : ColorManager.textTertiary),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.setsReps,
                          style: TextStyle(
                              fontSize: 14.sp, color: ColorManager.primaryText),
                        ),
                        Text(
                          'Target: ${exercise.target}',
                          style: TextStyle(
                              fontSize: 12.sp, color: ColorManager.textSecondary),
                        ),
                      ],
                    ),
                    trailing: isUnlocked
                        ? Checkbox(
                            value: _completionStatus[index],
                            activeColor: ColorManager.limerGreen2,
                            checkColor: ColorManager.onMint,
                            onChanged: (val) {
                              setState(() {
                                _completionStatus[index] = val ?? false;
                              });
                            },
                          )
                        : Icon(Icons.lock, color: ColorManager.textTertiary),
                  ),
                );
              },
            ),
          if (!accessAllowed && !checkingAccess)
            _buildPremiumLockOverlay(context),
        ],
      ),
      bottomNavigationBar: !accessAllowed
          ? null
          : Padding(
              padding: EdgeInsets.all(20.w),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _allCompleted()
                      ? ColorManager.limerGreen2
                      : ColorManager.textTertiary,
                  disabledBackgroundColor: _isSaving
                      ? ColorManager.limerGreen2
                      : ColorManager.textTertiary,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button.r)),
                ),
                onPressed:
                    _allCompleted() && !_isSaving ? _handleDayCompletion : null,
                child: _isSaving
                    ? SizedBox(
                        key: const Key('sixpack_finish_progress'),
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: ColorManager.onMint,
                        ),
                      )
                    : Text(
                        !_allCompleted()
                            ? 'Complete all 3 workouts'
                            : _isRepeat
                                ? 'Log Day ${widget.day} again'
                                : 'Finish Day ${widget.day}',
                        style: TextStyle(
                            color: _allCompleted()
                                ? ColorManager.onMint
                                : ColorManager.textPrimary,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
    );
  }

  Widget _buildCompletedBanner() {
    return Container(
      key: const Key('sixpack_completed_banner'),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: ColorManager.limerGreen2.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        border: Border.all(color: ColorManager.limerGreen2),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: ColorManager.primaryText, size: 22.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Day ${widget.day} is already complete. You can repeat it for '
              'practice; your challenge progress will not change.',
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _allCompleted() {
    return _completionStatus.every((status) => status);
  }

  /// Saves the day, then shows the celebration straight away. Logging the
  /// workout and the streak/reminder bookkeeping happen in the background so
  /// the user never waits on them.
  Future<void> _handleDayCompletion() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final updateStreak = widget.updateStreak ??
        Provider.of<StatisticsProvider?>(context, listen: false)?.updateStreak;
    final messenger = ScaffoldMessenger.of(context);
    final day = widget.day;
    var syncPending = false;

    try {
      ChallengeProgress? known = _progress;
      if (known == null) {
        try {
          known = await _store.load();
        } catch (_) {
          known = null;
        }
      }

      // Re-doing an earlier day must not rewind progress or re-lock tomorrow.
      if (known == null || known.advancesProgress(day)) {
        try {
          await _store.saveCompletion(day);
        } on TimeoutException {
          // Firestore has queued the write; it syncs when the network returns.
          syncPending = true;
        }
        _progress = ChallengeProgress(
          lastCompletedDay: day,
          completionDate: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('Six-pack day: could not save progress: $e');
      if (mounted) setState(() => _isSaving = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              "Couldn't save your progress. Check your connection and try again."),
        ),
      );
      return;
    }

    unawaited(_recordWorkoutInBackground(day, updateStreak));
    widget.onComplete();

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (syncPending) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              "Slow connection — your progress will sync when you're back online."),
        ),
      );
    }

    if (day == 30) {
      _showCompletionFeedback(context);
    } else {
      _showDayCompletionDialog(context);
    }
  }

  Future<void> _saveFeedbackQuietly(String text) async {
    try {
      await _store.saveFeedback(text);
    } catch (e) {
      debugPrint('Six-pack day: could not save feedback: $e');
    }
  }

  Future<void> _recordWorkoutInBackground(
    int day,
    Future<void> Function()? updateStreak,
  ) async {
    try {
      await _store.recordWorkout(day);
    } catch (e) {
      debugPrint('Six-pack day: could not log workout: $e');
    }
    try {
      await updateStreak?.call();
    } catch (e) {
      debugPrint('Six-pack day: could not update streak: $e');
    }
  }

  void _showDayCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorManager.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        title: Center(
          child: Text(
            '🎉 Day ${widget.day} Done!',
            style: TextStyle(
                color: ColorManager.primaryText, fontWeight: FontWeight.bold),
          ),
        ),
        content: Text(
          'Keep going! Only ${30 - widget.day} days left for your six-pack transformation.',
          textAlign: TextAlign.center,
          style: TextStyle(color: ColorManager.textPrimary),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button.r)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // go back
              },
              child: const Text('Great!', style: TextStyle(color: ColorManager.onMint)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletionFeedback(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ColorManager.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        title: Center(
          child: Text(
            '🏆 CHALLENGE COMPLETE!',
            style: TextStyle(color: ColorManager.warningText, fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Unbelievable! You\'ve crushed the 30-Day Six-Pack Challenge. We\'d love to hear your story!',
              textAlign: TextAlign.center,
              style: TextStyle(color: ColorManager.textPrimary),
            ),
            SizedBox(height: 16.h),
            TextField(
              key: const Key('sixpack_feedback_field'),
              controller: _feedbackController,
              style: TextStyle(color: ColorManager.textPrimary),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your feedback...',
                hintStyle: TextStyle(color: ColorManager.textTertiary),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.premium,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button.r)),
              ),
              onPressed: () {
                final text = _feedbackController.text.trim();
                if (text.isNotEmpty) {
                  unawaited(_saveFeedbackQuietly(text));
                }
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // go back
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(text.isEmpty
                        ? 'Challenge complete. Well done!'
                        : 'Thank you for your feedback!'),
                  ),
                );
              },
              child: const Text('Submit & Finish',
                  style: TextStyle(color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumLockOverlay(BuildContext context) {
    return Container(
      color: ColorManager.background.withValues(alpha: 0.8),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(SizeManager.s24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(SizeManager.s20.w),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock,
                  size: 80.sp,
                  color: ColorManager.primaryText,
                ),
              ),
              SizedBox(height: SizeManager.s24.h),
              Text(
                'Premium Day',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.textPrimary,
                ),
              ),
              SizedBox(height: SizeManager.s12.h),
              Text(
                'Days 4 and beyond are reserved for Pro members. Upgrade now to continue your 30-day transformation!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: ColorManager.textSecondary,
                ),
              ),
              SizedBox(height: SizeManager.s32.h),
              ElevatedButton(
                onPressed: () => context.push(Routes.premiumScreen),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  foregroundColor: ColorManager.onMint,
                  padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 15.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                child: Text(
                  'Go Pro',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

