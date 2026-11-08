import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DeleteAccountPageAppBar extends StatelessWidget {
  const DeleteAccountPageAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ColorManager.background,
      elevation: SizeManager.s0,
      leading: Padding(
        padding: const EdgeInsets.only(left: PaddingManager.p12),
        child: Container(
          height: SizeManager.s40.h,
          width: SizeManager.s40.w,
          decoration: BoxDecoration(
            color: ColorManager.grey3,
            borderRadius: BorderRadius.circular(
              RadiusManager.r40.r,
            ),
          ),
          child: IconButton(tooltip: 'Back', 
            splashColor: ColorManager.grey3,
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon:  Icon(
              Icons.arrow_back_ios_new,
              size: SizeManager.s26,
              color: ColorManager.white,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(
          duration: 500.ms,
        );
  }
}
