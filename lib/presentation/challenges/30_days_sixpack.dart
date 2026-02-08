import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SixPackChallengeSelectionScreen extends StatelessWidget {
  const SixPackChallengeSelectionScreen({super.key});

  Future<Map<String, dynamic>> _fetchProgress() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return snapshot.data()?['progress']?['sixPackChallenge'] ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: const Text('30 Day Abs Challenge', style: TextStyle(color: Colors.white)),
        backgroundColor: ColorManager.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchProgress(),
        builder: (context, snapshot) {
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
              
              final sub = Provider.of<SubscriptionProvider>(context);
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
    );
  }

  Widget _buildDayTile(BuildContext context, int day, bool isCompleted,
      bool isLocked, bool isPremiumLocked, bool isWaitDay) {
    Color bgColor = ColorManager.surface;
    Color borderColor = Colors.transparent;
    Widget icon = Text('$day',
        style: TextStyle(
            color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold));

    if (isCompleted) {
      bgColor = ColorManager.limerGreen2.withOpacity(0.2);
      borderColor = ColorManager.limerGreen2;
      icon = Icon(Icons.check_circle,
          color: ColorManager.limerGreen2, size: 24.sp);
    } else if (isPremiumLocked) {
      icon = Icon(Icons.lock, color: Colors.amber, size: 20.sp);
    } else if (isWaitDay) {
      icon = Icon(Icons.access_time_filled, color: Colors.white24, size: 20.sp);
    } else if (isLocked) {
      icon =
          Text('$day', style: TextStyle(color: Colors.white24, fontSize: 18.sp));
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
          context.push('${Routes.dailyExerciseRoute}?day=$day');
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
        title: const Text('Come back tomorrow!',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'You have already completed a workout today. Rest up and come back tomorrow to keep the streak alive!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('OK', style: TextStyle(color: ColorManager.primary)),
          ),
        ],
      ),
    );
  }
}
