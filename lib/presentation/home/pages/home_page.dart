import 'package:fitness_app/presentation/banner_ads/banner_ad_service.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_slider_home_widget.dart';
import 'package:fitness_app/presentation/home/widgets/fitness_data_widget.dart';
import 'package:fitness_app/presentation/home/widgets/home_page_text_spacer_widget.dart';
import 'package:fitness_app/presentation/home/widgets/quick_actions_widget.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
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
    // Water data is loaded in MainPage after reset check
    // Load weekly stats
    Provider.of<StatisticsProvider>(context, listen: false).getWeeklyStats();
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
            // Quick Actions
            const QuickActionsWidget(),
            SizedBox(height: SizeManager.s16.h),

            // Today's Progress - Shows BMI, Calories, Water
            FitnessDataWidget(),
            SizedBox(height: SizeManager.s16.h),
            const HomePageTextSpacerWidget(
              title: StringsManager.challenges,
            ),
            const CarouselSliderHomeWidget(),

            BannerAdWidget(pageName: 'home'),
            SizedBox(height: SizeManager.s16.h),
          ],
        ),
      ),
    );
  }
}
