import 'package:flutter/material.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';

class CarouselHomeBox extends StatelessWidget {
  const CarouselHomeBox({
    super.key,
    required this.deviceWidth,
    required this.image,
    required this.onTap,
    required this.title,
  });

  final double deviceWidth;
  final String image;
  final VoidCallback onTap;
  final String title;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(PaddingManager.p12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: ColorManager.grey3),
                color: ColorManager.grey3,
                borderRadius: BorderRadius.circular(
                  RadiusManager.r15.r,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ColorManager.black,
                    blurRadius: 5,
                    spreadRadius: 1,
                    offset: Offset(4, 4),
                  ),
                  BoxShadow(
                    color: ColorManager.darkGrey,
                    blurRadius: 5,
                    spreadRadius: 1,
                    offset: Offset(-4, -4),
                  ),
                ],
              ),
              width: deviceWidth,
              height: SizeManager.s250.h,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  RadiusManager.r15.r,
                ),
                child: Stack(
                  children: [
                    Image.asset(
                      image,
                      fit: BoxFit.cover,
                      width: deviceWidth,
                      height: SizeManager.s250.h,
                    ),
                    // Gradient Overlay
                    Container(
                      width: deviceWidth,
                      height: SizeManager.s250.h,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(RadiusManager.r15.r),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    // Centered Text with Padding
                    Positioned(
                      bottom: 20.h, // Adjust positioning
                      left: 20.w,
                      right: 20.w,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: StyleManager.homePageCarouselTitle.copyWith(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 5.0,
                              color: Colors.black.withOpacity(0.7),
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
