import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/widgets/exercise_video_player.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/data/challenge_data.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DailyExercisePage extends StatefulWidget {
  final int day;
  final VoidCallback onComplete;

  const DailyExercisePage({
    super.key,
    required this.day,
    required this.onComplete,
  });

  @override
  State<DailyExercisePage> createState() => _DailyExercisePageState();
}

class _DailyExercisePageState extends State<DailyExercisePage> {
  final List<bool> _completionStatus = [false, false, false];

  @override
  void initState() {
    super.initState();
    _loadInitialProgress();
  }

  Future<void> _loadInitialProgress() async {
    final progress = await fetchProgress();
    if (progress['lastCompletedDay'] == widget.day) {
      setState(() {
        _completionStatus[0] = true;
        _completionStatus[1] = true;
        _completionStatus[2] = true;
      });
    }
  }

  Future<Map<String, dynamic>> fetchProgress() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    print('Fetching progress for user ID: $userId');

    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    print('Firestore Snapshot Data: ${snapshot.data()}');

    final progressData = snapshot.data()?['progress'] ?? {};
    print('Six Pack Challenge Progress Data: $progressData');

    return progressData['sixPackChallenge'] ?? {};
  }

  bool isDayUnlocked(Map<String, dynamic> progressData, int day) {
    final completionDateStr = progressData['completionDate'] ?? '';
    final lastCompletedDay = progressData['lastCompletedDay'] ?? 0;

    final completionDate =
        DateTime.tryParse(completionDateStr)?.toLocal() ?? DateTime.now();
    final today = DateTime.now();

    // Compare only the date parts
    final isNewDay = today.year > completionDate.year ||
        today.month > completionDate.month ||
        today.day > completionDate.day;

    return isNewDay || day <= lastCompletedDay + 1;
  }


  void showExerciseDetails(BuildContext context, ChallengeExercise exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
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
                autoPlay: true,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              exercise.name,
              style: TextStyle(
                  fontSize: 22.sp,
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
                    backgroundColor: ColorManager.limerGreen2),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.black),
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

    return Scaffold(
      backgroundColor: ColorManager.darkGrey,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: ColorManager.darkGrey,
        title: Text('Day ${widget.day} - 3 Workouts',
            style: const TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          if (exercises.isEmpty)
            const Center(
              child: Text('Curriculum not found for this day.',
                  style: TextStyle(color: Colors.white)),
            )
          else
            ListView.builder(
              itemCount: exercises.length,
              padding: EdgeInsets.only(top: 12.h),
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                final isUnlocked = _isAccessAllowed(context);

                return Card(
                  color: isUnlocked ? ColorManager.surface : Colors.grey[800],
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
                      ),
                    ),
                    title: Text(
                      exercise.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                          color: isUnlocked ? Colors.white : Colors.white54),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.setsReps,
                          style: TextStyle(
                              fontSize: 14.sp, color: ColorManager.limerGreen2),
                        ),
                        Text(
                          'Target: ${exercise.target}',
                          style: TextStyle(
                              fontSize: 12.sp, color: Colors.white70),
                        ),
                      ],
                    ),
                    trailing: isUnlocked
                        ? Checkbox(
                            value: _completionStatus[index],
                            activeColor: ColorManager.limerGreen2,
                            checkColor: Colors.black,
                            onChanged: (val) {
                              setState(() {
                                _completionStatus[index] = val ?? false;
                              });
                            },
                          )
                        : const Icon(Icons.lock, color: Colors.white24),
                  ),
                );
              },
            ),
          if (!_isAccessAllowed(context)) _buildPremiumLockOverlay(context),
        ],
      ),
      bottomNavigationBar: !_isAccessAllowed(context)
          ? null
          : Padding(
              padding: EdgeInsets.all(20.w),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _allCompleted()
                      ? ColorManager.limerGreen2
                      : Colors.grey[600],
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
                onPressed: _allCompleted() ? _handleDayCompletion : null,
                child: Text(
                  _allCompleted()
                      ? 'Finish Day ${widget.day}'
                      : 'Complete all 3 workouts',
                  style: TextStyle(
                      color: _allCompleted() ? Colors.black : Colors.white54,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
    );
  }

  bool _allCompleted() {
    return _completionStatus.every((status) => status);
  }

  Future<void> _handleDayCompletion() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'progress.sixPackChallenge.lastCompletedDay': widget.day,
      'progress.sixPackChallenge.completionDate':
          DateTime.now().toIso8601String(),
    });

    widget.onComplete();

    if (mounted) {
      if (widget.day == 30) {
        _showCompletionFeedback(context);
      } else {
        _showDayCompletionDialog(context);
      }
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
                color: ColorManager.limerGreen2, fontWeight: FontWeight.bold),
          ),
        ),
        content: Text(
          'Keep going! Only ${30 - widget.day} days left for your six-pack transformation.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.limerGreen2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // go back
              },
              child: const Text('Great!', style: TextStyle(color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletionFeedback(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ColorManager.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        title: const Center(
          child: Text(
            '🏆 CHALLENGE COMPLETE!',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Unbelievable! You\'ve crushed the 30-Day Six-Pack Challenge. We\'d love to hear your story!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16.h),
            TextField(
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your feedback...',
                hintStyle: const TextStyle(color: Colors.white38),
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
                backgroundColor: Colors.amber,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
              onPressed: () {
                // Here you would normally save feedback
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // go back
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you for your feedback!')),
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

  bool _isAccessAllowed(BuildContext context) {
    final subProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    return subProvider.isPremium || widget.day <= 3;
  }

  Widget _buildPremiumLockOverlay(BuildContext context) {
    return Container(
      color: ColorManager.background.withOpacity(0.8),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(SizeManager.s24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(SizeManager.s20.w),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock,
                  size: 80.sp,
                  color: ColorManager.primary,
                ),
              ),
              SizedBox(height: SizeManager.s24.h),
              Text(
                'Premium Day',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
                  foregroundColor: Colors.black,
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

