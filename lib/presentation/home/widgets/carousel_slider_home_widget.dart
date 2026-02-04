import 'package:carousel_slider/carousel_slider.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_home_box.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CarouselSliderHomeWidget extends StatelessWidget {
  const CarouselSliderHomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    final List<_CarouselItem> carouselItems = [
      _CarouselItem(
        image: ImageManager.absWorkout,
        title: StringsManager.sixPackChallenge,
        route: Routes.sixPackChallengeRoute,
      ),
      _CarouselItem(
        image: ImageManager.dumbels,
        title: StringsManager.workoutsplit,
        route: Routes.workoutSplitsRoute,
      ),
      _CarouselItem(
        image: ImageManager.shoulderWorkout,
        title: StringsManager.exerciseOfWeek,
        route: Routes.exerciseOfTheWeekRoute,
      ),
    ];

    return Consumer<SubscriptionProvider>(
      builder: (context, subProvider, _) {
        return CarouselSlider(
          items: carouselItems.map((item) {
            return CarouselHomeBox(
              deviceWidth: deviceWidth,
              image: item.image,
              title: item.title,
              onTap: () {
                if (item.route == Routes.workoutSplitsRoute &&
                    !subProvider.isPremium) {
                  context.push(Routes.premiumScreen);
                } else {
                  context.push(item.route);
                }
              },
            );
          }).toList(),
          options: CarouselOptions(
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: deviceWidth < 400 ? 0.9 : 0.8,
          ),
        );
      },
    );
  }
}

class _CarouselItem {
  final String image;
  final String title;
  final String route;

  const _CarouselItem({
    required this.image,
    required this.title,
    required this.route,
  });
}
