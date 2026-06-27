import 'package:flutter/material.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TodaysMotivationWidget extends StatelessWidget {
  const TodaysMotivationWidget({super.key});

  final List<String> quotes = const [
    "Push yourself, because no one else is going to do it for you.",
    "Success doesn’t come from what you do occasionally, it comes from what you do consistently.",
    "Your only limit is you!",
    "Every workout counts, even the ones you don’t feel like doing.",
    "Sweat is just fat crying!",
    "The body achieves what the mind believes.",
    "It’s not about having time, it’s about making time.",
    "You don’t have to be extreme, just consistent.",
    "Discipline is choosing between what you want now and what you want most.",
    "Strive for progress, not perfection.",
    "Success is the sum of small efforts, repeated day in and day out.",
    "A one-hour workout is just 4% of your day. No excuses!",
    "Don’t stop when you’re tired. Stop when you’re done.",
    "The pain you feel today will be the strength you feel tomorrow.",
    "Dream big, work hard, stay focused, and surround yourself with good people.",
    "Nothing will work unless you do.",
    "When you feel like quitting, think about why you started.",
    "No pain, no gain. Stay focused!",
    "The secret of getting ahead is getting started.",
    "Doubt kills more dreams than failure ever will.",
    "Make today so awesome that yesterday gets jealous.",
    "What seems impossible today will one day be your warm-up.",
    "Don’t let the weekend become your weak end!",
    "Be stronger than your excuses.",
    "If you get tired, learn to rest, not quit.",
    "A year from now, you’ll wish you had started today.",
    "The hardest lift is lifting yourself up when you want to quit.",
    "Consistency beats intensity. Show up daily!",
    "Sweat, smile, repeat!",
    "Your future self will thank you for what you do today."
  ];

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    int dayOfMonth = DateTime.now().day;
    String dailyQuote = quotes[(dayOfMonth - 1) % 30];

    return Padding(
      padding: const EdgeInsets.only(
        top: 20,
        left: 25,
        right: 25,
      ),
      child: Container(
        width: deviceWidth,
        decoration: BoxDecoration(
          color: ColorManager.surfaceDark,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Motivation of the day",
                style: TextStyle(
                  color: ColorManager.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: PaddingManager.p12),
              Text(
                '"$dailyQuote"',
                style: StyleManager.homePageS14RegularWhite2L1,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
