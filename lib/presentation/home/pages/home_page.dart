import 'package:fitness_app/presentation/banner_ads/banner_ad_service.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_slider_home_widget.dart';
import 'package:fitness_app/presentation/home/widgets/fitness_data_widget.dart';
import 'package:fitness_app/presentation/home/widgets/home_page_text_spacer_widget.dart';
import 'package:fitness_app/presentation/home/widgets/quick_actions_widget.dart';
import 'package:fitness_app/presentation/home/widgets/achievements_widget.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/widgets/home_ai_routine_card.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    Provider.of<ConsumptionProvider>(context, listen: false)
        .getConsumedCalories();
    Provider.of<StatisticsProvider>(context, listen: false).getWeeklyStats();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForNewAchievements();
    });
  }

  void _checkForNewAchievements() {
    final stats = Provider.of<StatisticsProvider>(context, listen: false);
    final newlyUnlocked = stats.consumeNewlyUnlocked();
    for (final id in newlyUnlocked) {
      try {
        final def = allAchievements.firstWhere((a) => a.id == id);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) showAchievementUnlockDialog(context, def);
        });
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: SizeManager.s8.h),

            // AI Routine Hero Banner — Primary action for today's workout
            const HomeAiRoutineCard(),
            SizedBox(height: SizeManager.s12.h),

            // Quick Actions — Fast utilities below primary workout focus
            const QuickActionsWidget(),
            SizedBox(height: SizeManager.s16.h),

            // Today's Progress — Calories, Water, BMI
            FitnessDataWidget(),
            SizedBox(height: SizeManager.s16.h),

            // Challenges Carousel
            const HomePageTextSpacerWidget(
              title: StringsManager.challenges,
            ),
            const CarouselSliderHomeWidget(),

            const PremiumAwareBannerAd(pageName: 'home', bottomMargin: 60.0),
            SizedBox(height: SizeManager.s16.h),
          ],
        ),
      ),
    );
  }
}
