import 'package:carousel_slider/carousel_slider.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_home_box.dart';
import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CarouselSliderHomeWidget extends StatelessWidget {
  const CarouselSliderHomeWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    return CarouselSlider(
      items: [
        CarouselHomeBox(
          deviceWidth: deviceWidth,
          image: ImageManager.absWorkout,
          onTap: () {
            context.push(Routes.absRoute);
          },
          title: StringsManager.sixPackChallenge,
        ),
        CarouselHomeBox(
          deviceWidth: deviceWidth,
          image: ImageManager.dumbels,
          onTap: () {
            context.push(Routes.workoutSplitsRoute);
          },
          title: StringsManager.workoutsplit,
        ),
        // CarouselHomeBox(
        //   deviceWidth: deviceWidth,
        //   image: ImageManager.dietAndNutrition,
        //   onTap: () {
        //     context.push(Routes.dietRoute);
        //   },
        //   title: StringsManager.diet,
        // ),
        // CarouselHomeBox(
        //   deviceWidth: deviceWidth,
        //   image: ImageManager.cardioWorkout,
        //   onTap: () {
        //     context.push(Routes.cardioRoute);
        //     //TODO
        //   },
        //   title: StringsManager.cardio,
        // ),
        // CarouselHomeBox(
        //   deviceWidth: deviceWidth,
        //   image: ImageManager.carousel5WP,
        //   onTap: () {
        //     //TODO
        //   },
        //   title: StringsManager.confidence,
        // ),
      ],
      options: CarouselOptions(
        autoPlay: true,
        enlargeCenterPage: true,
      ),
    );
  }
}
