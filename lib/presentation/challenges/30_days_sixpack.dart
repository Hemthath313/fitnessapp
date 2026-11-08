import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SixPackChallengeSelectionScreen extends StatefulWidget {
  const SixPackChallengeSelectionScreen({super.key});

  @override
  State<SixPackChallengeSelectionScreen> createState() => _SixPackChallengeSelectionScreenState();
}

class _SixPackChallengeSelectionScreenState extends State<SixPackChallengeSelectionScreen> {
  Future<Map<String, dynamic>>? _progressFuture;

  @override
  void initState() {
    super.initState();
    _refreshProgress();
  }

  void _refreshProgress() {
    setState(() {
      _progressFuture = _fetchProgress();
    });
  }

  Future<Map<String, dynamic>> _fetchProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};
    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return snapshot.data()?['progress']?['sixPackChallenge'] ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final sub = Provider.of<SubscriptionProvider>(context);

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text('30 Day Abs Challenge', style: TextStyle(color: ColorManager.textPrimary)),
        backgroundColor: ColorManager.background,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _progressFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final progress = snapshot.data ?? {};
          final lastDay = progress['lastCompletedDay'] ?? 0;
          final completionDateStr = progress['completionDate'] ?? '';
          final completionDate = DateTime.tryParse(completionDateStr)?.toLocal();
          
          final today = DateTime.now();
          final isCompletedToday = completionDate != null &&
              completionDate.year == today.year &&
              completionDate.month == today.month &&
              completionDate.day == today.day;

          final currentDay = lastDay + 1;

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
              final isPremiumLocked = day > 3 && !sub.isPremium;

              return _buildDayTile(
                context, 
                day, 
                isCompleted, 
                isLocked, 
                isPremiumLocked, 
                isCompletedToday && day == currentDay
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
      bool isLocked, bool isPremiumLocked, bool isWaitDay) {
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
          context.push(Routes.premiumScreen);
        } else if (isWaitDay) {
          _showWaitDialog(context);
        } else if (isLocked && !isCompleted) {
          // If locked because it's in the future and not the 1-per-day slot
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Complete previous days first!')),
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

  void _showWaitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorManager.surface,
        title: Text('Come back tomorrow!',
            style: TextStyle(color: ColorManager.textPrimary)),
        content: Text(
          'You have already completed a workout today. Rest up and come back tomorrow to keep the streak alive!',
          style: TextStyle(color: ColorManager.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('OK', style: TextStyle(color: ColorManager.primary)),
          ),
        ],
      ),
    );
  }
}
