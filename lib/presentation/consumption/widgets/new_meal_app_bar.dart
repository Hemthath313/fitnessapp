import 'package:fitness_app/utils/managers/layout_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NewMealPageAppBar extends StatelessWidget {
  const NewMealPageAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0.0,
      scrolledUnderElevation: 0.0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      backgroundColor: ColorManager.background,
      leadingWidth: 68.w,
      leading: Padding(
        padding: EdgeInsets.only(left: 20.w),
        child: Center(
          child: Material(
            color: ColorManager.iconChip,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: 44.w,
                height: 44.w,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18.sp,
                  color: ColorManager.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
      title: Text(
        StringsManager.addMealABtitle,
        style: TextStyle(
          color: ColorManager.textPrimary,
          fontSize: AppText.appBarTitle,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
