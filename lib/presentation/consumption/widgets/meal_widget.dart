import 'package:fitness_app/presentation/consumption/widgets/percent_value_of_meal.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:flutter/material.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:swipeable_tile/swipeable_tile.dart';

class MealWidget extends StatelessWidget {
  const MealWidget({
    super.key,
    required this.title,
    required this.amount,
    required this.calories,
    required this.carbs,
    required this.fats,
    required this.proteins,
    required this.onPressed,
    required this.id,
  });

  final String title;
  final double amount;
  final double calories;
  final double fats;
  final double carbs;
  final double proteins;
  final Function(BuildContext)? onPressed;
  final String id;

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(
        top: PaddingManager.p8,
        left: PaddingManager.p1,
        right: PaddingManager.p1,
      ),
      child: SwipeableTile(
        key: Key(id), // Unique key for the SwipeableTile
        color: ColorManager.surfaceDark,
        swipeThreshold: 0.2,
        direction: SwipeDirection.endToStart, // Swipe left to delete
        onSwiped: (direction) {
          if (direction == SwipeDirection.endToStart && onPressed != null) {
            onPressed!(context);
          }
        },
        backgroundBuilder: (context, direction, progress) {
          if (direction == SwipeDirection.endToStart) {
            return Container(
              color: ColorManager.darkGrey,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: PaddingManager.p16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    StringsManager.delete,
                    style: TextStyle(color: ColorManager.limerGreen2),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.delete, color: ColorManager.limerGreen2),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
        child: Container(
          width: deviceWidth,
          height: SizeManager.s150.h,
          decoration: BoxDecoration(
            color: ColorManager.surfaceDark,
            border: Border(
              bottom: BorderSide(
                color: ColorManager.limerGreen2,
                width: SizeManager.s1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              left: PaddingManager.p12,
              right: PaddingManager.p12,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: PaddingManager.p28,
                    left: PaddingManager.p28,
                    bottom: PaddingManager.p12,
                    right: PaddingManager.p28,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          right: PaddingManager.p12,
                        ),
                        child: Icon(
                          Icons.done_all_rounded,
                          color: ColorManager.limerGreen2,
                        ),
                      ),
                      Text(
                        title,
                        style: StyleManager.mealWidgetTitleTextStyle,
                      ),
                      const Expanded(
                        child: SizedBox(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: PaddingManager.p28,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        '🔥${calories.round()} kcal',
                        style: StyleManager.mealWidgetDataTextStyle,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: PaddingManager.p12,
                          right: PaddingManager.p12,
                        ),
                        child: Container(
                          width: SizeManager.s10.w,
                          height: SizeManager.s3.h,
                          decoration: BoxDecoration(
                            color: ColorManager.limerGreen2,
                            borderRadius: BorderRadius.circular(
                              RadiusManager.r100.r,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        '${amount.round()} G',
                        style: StyleManager.mealWidgetDataTextStyle,
                      ),
                    ],
                  ),
                ),
                const Expanded(child: SizedBox()),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    PercentValueOfMeal(
                      value: fats,
                      amount: amount,
                      title: StringsManager.fats,
                    ),
                    PercentValueOfMeal(
                      value: carbs,
                      amount: amount,
                      title: StringsManager.carbs,
                    ),
                    PercentValueOfMeal(
                      value: proteins,
                      amount: amount,
                      title: StringsManager.proteins,
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
