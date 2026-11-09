import 'package:fitness_app/data/challenge_data.dart';
import 'package:fitness_app/presentation/challenges/challenge_progress.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SixPackChallengeSelectionScreen extends StatefulWidget {
  const SixPackChallengeSelectionScreen({super.key, this.store});

  /// Storage seam; defaults to Firestore. Overridden in tests.
  final SixPackProgressStore? store;

  @override
  State<SixPackChallengeSelectionScreen> createState() => _SixPackChallengeSelectionScreenState();
}

class _SixPackChallengeSelectionScreenState extends State<SixPackChallengeSelectionScreen> {
  Future<ChallengeProgress>? _progressFuture;
  late final SixPackProgressStore _store =
      widget.store ?? const FirestoreSixPackProgressStore();

  @override
  void initState() {
    super.initState();
    _refreshProgress();
  }

  void _refreshProgress() {
    setState(() {
      _progressFuture = _store.load();
    });
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48.sp, color: ColorManager.textTertiary),
            SizedBox(height: 12.h),
            Text(
              "Couldn't load your challenge progress",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorManager.textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              key: const Key('sixpack_retry_button'),
              onPressed: _refreshProgress,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                foregroundColor: ColorManager.onMint,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sub = Provider.of<SubscriptionProvider?>(context);

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text('30 Day Abs Challenge', style: TextStyle(color: ColorManager.textPrimary)),
        backgroundColor: ColorManager.background,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
      ),
      body: FutureBuilder<ChallengeProgress>(
        future: _progressFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) return _buildLoadError();

          final progress = snapshot.data ?? const ChallengeProgress();
          final lastDay = progress.lastCompletedDay;
          final isCompletedToday = progress.isCompletedToday(DateTime.now());
          final currentDay = progress.currentDay;

          return GridView.builder(
            padding: EdgeInsets.all(20.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
            ),
            itemCount: 30,
            itemBuilder: (context, index) {
              final day = index + 1;
              final isCompleted = day <= lastDay;
              final isLocked = day > currentDay || (day == currentDay && isCompletedToday);
              final isPremiumLocked = day > 3 && !(sub?.isPremium ?? false);

              return _buildDayTile(
                context, 
                day, 
                isCompleted, 
                isLocked, 
                isPremiumLocked, 
                isCompletedToday && day == currentDay,
                progress,
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: ColorManager.surface,
            border: Border(top: BorderSide(color: ColorManager.divider)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5E36).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child:  Text('🔥', style: TextStyle(fontSize: 16.sp)),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Core vs. Fat Loss Tip',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Combine abs training with overall fat loss.',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const Key('sixpack_to_weight_loss_button'),
                onPressed: () => context.push(
                  '${Routes.transformationPlanDetailRoute}?planId=weight_loss_60',
                ),
                child: const Text(
                  'Explore 60-Day',
                  style: TextStyle(color: Color(0xFFFF5E36), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayTile(BuildContext context, int day, bool isCompleted,
      bool isLocked, bool isPremiumLocked, bool isWaitDay,
      ChallengeProgress progress) {
    Color bgColor = ColorManager.surface;
    Color borderColor = Colors.transparent;
    Widget icon = Text('$day',
        style: TextStyle(
            color: ColorManager.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.bold));

    if (isCompleted) {
      bgColor = ColorManager.limerGreen2.withValues(alpha: 0.2);
      borderColor = ColorManager.limerGreen2;
      icon = Icon(Icons.check_circle,
          color: ColorManager.limerGreen2, size: 24.sp);
    } else if (isPremiumLocked) {
      icon = Icon(Icons.lock, color: Colors.amber, size: 20.sp);
    } else if (isWaitDay) {
      icon = Icon(Icons.access_time_filled, color: ColorManager.divider, size: 20.sp);
    } else if (isLocked) {
      icon =
          Text('$day', style: TextStyle(color: ColorManager.divider, fontSize: 18.sp));
    }

    return InkWell(
      onTap: () {
        if (isPremiumLocked) {
          final membership =
              Provider.of<SubscriptionProvider?>(context, listen: false);
          if (membership?.isLoading ?? false) {
            // Don't send a Pro member to the paywall while we're still
            // confirming their membership.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Checking your membership… try again in a moment.'),
              ),
            );
          } else {
            _showProPreview(context, day);
          }
        } else if (isWaitDay) {
          _showWaitDialog(context);
        } else if (isLocked && !isCompleted) {
          // Future day: say which day is next instead of a generic refusal.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(progress.lockedMessage(day, DateTime.now())),
            ),
          );
        } else {
          context.push('${Routes.dailyExerciseRoute}?day=$day').then((_) {
            if (mounted) _refreshProgress();
          });
        }
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Center(child: icon),
      ),
    );
  }

  /// Shows what a Pro day contains before sending the user to the paywall.
  void _showProPreview(BuildContext context, int day) {
    final exercises = ChallengeData.sixPackCurriculum[day] ?? const [];
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorManager.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock, color: ColorManager.premium, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Day $day is a Pro day',
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                'Days 1–3 are free. Pro unlocks all 30 days. Here is what '
                'you will do:',
                style: TextStyle(
                  color: ColorManager.textSecondary,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 12.h),
              for (final exercise in exercises)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    children: [
                      Icon(Icons.fitness_center,
                          size: 16.sp, color: ColorManager.primary),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      Text(
                        exercise.setsReps,
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('sixpack_pro_preview_cta'),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push(Routes.premiumScreen);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.primary,
                    foregroundColor: ColorManager.onMint,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: const Text('See Pro plans'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(
                    'Not now',
                    style: TextStyle(color: ColorManager.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWaitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorManager.surface,
        title: Text('Come back tomorrow!',
            style: TextStyle(color: ColorManager.textPrimary)),
        content: Text(
          "You've finished today's workout. Rest up: the next day unlocks "
          'tomorrow, and finishing it keeps your streak alive.',
          style: TextStyle(color: ColorManager.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('OK', style: TextStyle(color: ColorManager.primaryText)),
          ),
        ],
      ),
    );
  }
}
