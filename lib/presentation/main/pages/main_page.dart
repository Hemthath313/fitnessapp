import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/explore/explore_page.dart';
import 'package:fitness_app/presentation/home/pages/home_page.dart';
import 'package:fitness_app/presentation/main/widgets/appbar_consumption.dart';
import 'package:fitness_app/presentation/main/widgets/appbar_home.dart';
import 'package:fitness_app/presentation/main/widgets/appbar_custom_workouts.dart';
import 'package:fitness_app/presentation/main/widgets/appbar_more.dart';
import 'package:fitness_app/presentation/more/more_page.dart';
import 'package:fitness_app/presentation/custom_workouts/custom_workouts_page.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/workouts/providers/workout_provider.dart';
import 'package:fitness_app/services/connectivity_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/widgets/error_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  var _currentIndex = 0;
  ontap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  List<Widget> pages = const [
    HomePage(),
    ExploreWidget(),
    CustomWorkoutsPage(),
    MorePage(),
  ];

  appBar() {
    if (isHomePage) {
      return const HomePageAppBarWidget();
    } else if (isExplorePage) {
      return const ConsumptionPageAppBarWidget();
    } else if (isCustomWorkoutsPage) {
      return const CustomWorkoutsAppBarWidget();
    } else if (isMorePage) {
      return const MorePageAppBarWidget();
    }
  }

  bool get isMorePage => _currentIndex == 3;
  bool get isCustomWorkoutsPage => _currentIndex == 2;
  bool get isExplorePage => _currentIndex == 1;
  bool get isHomePage => _currentIndex == 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      NetworkService.initialize();
      final consumptionProvider =
          Provider.of<ConsumptionProvider>(context, listen: false);
      final workoutsProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      final statisticsProvider =
          Provider.of<StatisticsProvider>(context, listen: false);

      // Load statistics
      await statisticsProvider.loadStreakData();

      // FIRST: Check and clear water for new day BEFORE loading data
      await consumptionProvider.clearWaterIfNeeded();

      // THEN: Load fresh data after potential reset
      await consumptionProvider.fetchAndSetMeals();
      await consumptionProvider.fetchAndSetWater();
      await workoutsProvider.fetchAndSetWorkouts();
      await workoutsProvider.getProgressPercent();

      final workouts = workoutsProvider.workouts;
      final meals = consumptionProvider.meals;
      bool isNewDay(DateTime now, DateTime lastDate) {
        return now.year > lastDate.year ||
            now.month > lastDate.month ||
            now.day > lastDate.day;
      }

      if (meals.isNotEmpty) {
        final lastMealDateTime = meals.last.dateTime;
        if (isNewDay(DateTime.now(), lastMealDateTime)) {
          await consumptionProvider.clearMealsIfNeeded();
          await consumptionProvider.fetchAndSetMeals();
        }
      }

      if (workouts.isNotEmpty) {
        final lastWorkoutDateTime = workouts.last.dateTime;
        final now = DateTime.now();
        if (now.year > lastWorkoutDateTime.year ||
            now.month > lastWorkoutDateTime.month ||
            now.day > lastWorkoutDateTime.day) {
          await workoutsProvider.clearWorkoutsIfDayChanges(lastWorkoutDateTime);
          await workoutsProvider.fetchAndSetWorkouts();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> bottomNavItems = [
      Icon(
        Icons.home_outlined,
        color: isHomePage ? ColorManager.limerGreen2 : ColorManager.grey2,
        size: SizeManager.s28,
      ),
      Icon(
        Icons.restaurant,
        color: isExplorePage ? ColorManager.limerGreen2 : ColorManager.grey2,
        size: SizeManager.s28,
      ),
      Icon(
        Icons.fitness_center,
        color: isCustomWorkoutsPage
            ? ColorManager.limerGreen2
            : ColorManager.grey2,
        size: SizeManager.s28,
      ),
      Icon(
        Icons.person_outline,
        color: isMorePage ? ColorManager.limerGreen2 : ColorManager.grey2,
        size: SizeManager.s28,
      ),
    ];
    return Scaffold(
      backgroundColor: ColorManager.darkGrey,
      appBar: PreferredSize(
        preferredSize: Size(
          double.infinity,
          SizeManager.s60.h,
        ),
        child: appBar(),
      ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        minimum: EdgeInsets.zero,
        child: CurvedNavigationBar(
          color: ColorManager.black87,
          buttonBackgroundColor: Colors.transparent,
          backgroundColor: ColorManager.darkGrey,
          onTap: ontap,
          index: _currentIndex,
          items: bottomNavItems,
        ),
      ),
      body: ErrorBoundary(
        child: pages[_currentIndex].animate().fadeIn(duration: 500.ms),
        fallbackMessage: 'Unable to load this page',
      ),
    );
  }
}
