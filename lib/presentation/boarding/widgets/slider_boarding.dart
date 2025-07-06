import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:shimmer/shimmer.dart';

import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';

class SliderBoardingWidget extends StatefulWidget {
  const SliderBoardingWidget({super.key});

  @override
  State<SliderBoardingWidget> createState() => _SliderBoardingWidgetState();
}

class _SliderBoardingWidgetState extends State<SliderBoardingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideAnimationController;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.05, 0.0), // Slight horizontal slide
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _slideAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(PaddingManager.p20),
      child: SlideAction(
        outerColor: ColorManager.black87,
        innerColor: ColorManager.limeGreen,
        sliderButtonIcon: SlideTransition(
          position: _offsetAnimation,
          child: const Icon(Icons.double_arrow_sharp),
        ),
        text: '',
        onSubmit: () {
          context.go(Routes.authRoute);
          return null;
        },
        child: SlideTransition(
          position: _offsetAnimation,
          child: Shimmer.fromColors(
            baseColor: ColorManager.white,
            highlightColor: Colors.grey.shade400,
            child: Text(
              StringsManager.swipeToPrc,
              style: TextStyle(
                fontSize: SizeManager.s18,
                fontWeight: FontWeight.w600,
                color: ColorManager.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
