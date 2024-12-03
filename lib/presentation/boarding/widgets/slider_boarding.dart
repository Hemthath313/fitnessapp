import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';


class SliderBoardingWidget extends StatelessWidget {
  const SliderBoardingWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(PaddingManager.p28),
      child: SlideAction(
        outerColor: ColorManager.black87,
        innerColor: ColorManager.limeGreen,
        sliderButtonIcon: const Icon(Icons.double_arrow_sharp),
        text: StringsManager.swipeToPrc,
        onSubmit: () {
          Navigator.of(context).pushReplacementNamed(Routes.authRoute);
          return null;
        },
      ),
    );
  }
}
