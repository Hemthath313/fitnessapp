import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class JournalAppBarWidget extends StatelessWidget {
  const JournalAppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeManager.s8.w),
        child: Text(
          'AI Transformation Hub',
          style: TextStyle(
            color: ColorManager.white,
            fontSize: SizeManager.s20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
