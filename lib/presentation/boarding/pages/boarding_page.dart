import 'dart:async';
import 'dart:ui';
import 'package:fitness_app/presentation/boarding/widgets/slider_boarding.dart';
import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class BoardingPage extends StatefulWidget {
  const BoardingPage({super.key});

  @override
  State<BoardingPage> createState() => _BoardingPageState();
}

class _BoardingPageState extends State<BoardingPage> {
  final PageController _pageController = PageController(initialPage: 0);
  late Timer _timer;

  List<String> imgList = [
    ImageManager.splashBG1WP,
    ImageManager.splashBG2WP,
    ImageManager.splashBG3WP,
    ImageManager.splashBG5WP,
    ImageManager.splashBG7WP,
  ];

  List<String> textList = [
    "Welcome to Gym Buddy — Your Ultimate Fitness Companion!",
    "Track your daily calories and personalized diet plans.",
    "Achieve your fitness goals with personalized plans.",
    "Access multiple workout splits tailored to your fitness goals!",
    "Let's get started on your fitness journey today!",
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: DurationManager.s5),
        (Timer timer) {
      int nextPage = _pageController.page!.round() + 1;
      _pageController.animateToPage(
        nextPage % imgList.length,
        duration: const Duration(milliseconds: DurationManager.ms300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    for (var item in imgList) {
      precacheImage(ExactAssetImage(item), context);
    }
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: ColorManager.background,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: imgList.length,
            itemBuilder: (context, index) => Center(
              child: Image.asset(
                imgList[index],
                fit: BoxFit.cover,
                height: height,
              ),
            ),
            onPageChanged: (value) {
              if (value == imgList.length - 1) {
                Future.delayed(
                  const Duration(seconds: DurationManager.s5),
                ).then(
                  (value) => _pageController.animateToPage(
                    0,
                    duration:
                        const Duration(milliseconds: DurationManager.ms300),
                    curve: Curves.easeInOut,
                  ),
                );
              }
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(RadiusManager.r30.r),
                topRight: Radius.circular(RadiusManager.r30.r),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: SizeManager.s270.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65), // Sleek dark glass overlay
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(RadiusManager.r30.r),
                      topRight: Radius.circular(RadiusManager.r30.r),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: PaddingManager.p28),
                        child: SmoothPageIndicator(
                          controller: _pageController,
                          count: imgList.length,
                          effect: CustomizableEffect(
                            spacing: SizeManager.s16,
                            dotDecoration: DotDecoration(
                              width: SizeManager.s8.w,
                              height: SizeManager.s8.h,
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(
                                RadiusManager.r24.r,
                              ),
                              dotBorder: DotBorder(
                                width: SizeManager.s1.w,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            activeDotDecoration: DotDecoration(
                              width: SizeManager.s12.w,
                              height: SizeManager.s12.h,
                              borderRadius: BorderRadius.circular(
                                RadiusManager.r24.r,
                              ),
                              color: ColorManager.primary, // Brand blue indicator
                              dotBorder: DotBorder(
                                width: SizeManager.s1_5.w,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding:  EdgeInsets.only(
                          top: PaddingManager.p20,
                          left: PaddingManager.p20,
                          right: PaddingManager.p20,
                        ),
                        child: AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, _) => Text(
                            textList[_pageController.page?.round() ?? 0],
                            style: TextStyle(
                              color: Colors.white, // Highly visible constant white text
                              fontSize: SizeManager.s20.sp, // Elegant sizing
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(duration: 500.ms),
                        ),
                      ),
                      const SliderBoardingWidget(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }
}
