import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomePageTextSpacerWidget extends StatelessWidget {
  const HomePageTextSpacerWidget({
    required this.title,
    super.key,
  });
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: PaddingManager.p12.w,
        bottom: PaddingManager.p12.h,
        top: PaddingManager.p12.h,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          textAlign: TextAlign.left,
          style: StyleManager.homePageTextSpacerTextStyle,
        ),
      ),
    );
  }
}
