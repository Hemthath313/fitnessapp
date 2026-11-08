import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/data/challenge_data.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_home_box.dart';
import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class CarouselSliderHomeWidget extends StatefulWidget {
  const CarouselSliderHomeWidget({super.key});

  @override
  State<CarouselSliderHomeWidget> createState() => _CarouselSliderHomeWidgetState();
}

class _CarouselSliderHomeWidgetState extends State<CarouselSliderHomeWidget> {
  int _currentIndex = 0;
  Future<Map<String, dynamic>>? _sixPackProgressFuture;

  @override
  void initState() {
    super.initState();
    _sixPackProgressFuture = _fetchSixPackProgress();
  }

  Future<Map<String, dynamic>> _fetchSixPackProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {};
      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return snapshot.data()?['progress']?['sixPackChallenge'] ?? {};
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final weeklyExercise = ChallengeData.weeklyFeaturedExercise;

    return FutureBuilder<Map<String, dynamic>>(
      future: _sixPackProgressFuture,
      builder: (context, snapshot) {
        final progress = snapshot.data ?? {};
        final int lastDay = (progress['lastCompletedDay'] as num?)?.toInt() ?? 0;

        final String sixPackSubtitle = lastDay > 0
            ? '$lastDay of 30 days completed'
            : '30-Day progressive core curriculum';
        final double sixPackProgress = (lastDay / 30.0).clamp(0.0, 1.0);
        final String sixPackAction = lastDay > 0
            ? (lastDay >= 30 ? 'Completed 🏆' : 'Continue Day ${lastDay + 1}')
            : 'Start Day 1';

        final String sixPackBadge;
        if (lastDay >= 30) {
          sixPackBadge = 'COMPLETED';
        } else if (lastDay > 0) {
          sixPackBadge = 'ACTIVE';
        } else {
          sixPackBadge = '30-DAY CHALLENGE';
        }

        final List<Widget> carouselCards = [
          // 1. 30-Day Six-Pack Challenge (Genuine tracked progression challenge)
          CarouselHomeBox(
            deviceWidth: deviceWidth,
            image: ImageManager.absWorkout,
            title: StringsManager.sixPackChallenge,
            badge: sixPackBadge,
            subtitle: sixPackSubtitle,
            progress: sixPackProgress > 0 ? sixPackProgress : null,
            actionText: sixPackAction,
            onTap: () {
              context.push(Routes.sixPackChallengeRoute).then((_) {
                if (mounted) {
                  setState(() {
                    _sixPackProgressFuture = _fetchSixPackProgress();
                  });
                }
              });
            },
          ),

          // 2. Weekly Technique Challenge (Single exercise form & tips)
          CarouselHomeBox(
            deviceWidth: deviceWidth,
            image: ImageManager.shoulderWorkout,
            title: StringsManager.exerciseOfWeek,
            badge: 'WEEKLY TECHNIQUE',
            subtitle: '${weeklyExercise.name} • ${weeklyExercise.target}',
            actionText: 'View Guide',
            onTap: () => context.push(Routes.exerciseOfTheWeekRoute),
          ),
        ];

        return Column(
          children: [
            CarouselSlider(
              items: carouselCards,
              options: CarouselOptions(
                height: 150.h,
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
                autoPlay: false,
                enlargeCenterPage: false,
                onPageChanged: (index, _) {
                  setState(() => _currentIndex = index);
                },
              ),
            ),
            SizedBox(height: 6.h),
            // Smooth Dot Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(carouselCards.length, (index) {
                final isSelected = _currentIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isSelected ? 16.w : 6.w,
                  height: 5.h,
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  decoration: BoxDecoration(
                    color: isSelected ? ColorManager.primary : Colors.white24,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
