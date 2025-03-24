import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:slide_to_act/slide_to_act.dart';

class SliderBoardingWidget extends StatelessWidget {
  const SliderBoardingWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(PaddingManager.p20), // Reduced padding
      child: SlideAction(
        outerColor: ColorManager.black87,
        innerColor: ColorManager.limeGreen,
        sliderButtonIcon: const Icon(Icons.double_arrow_sharp),
        text: StringsManager.swipeToPrc,
        textStyle: TextStyle(
          // Added custom text styling
          fontSize: SizeManager.s18, // Reduced text size
          fontWeight: FontWeight.w600,
          color: ColorManager.white,
        ),
        onSubmit: () {
          context.go(Routes.authRoute);
          return null;
        },
      ),
    );
  }
}
