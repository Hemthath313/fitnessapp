import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:swipeable_tile/swipeable_tile.dart';

class ExerciseWidget extends StatelessWidget {
  const ExerciseWidget({
    super.key,
    required this.name,
    required this.repNumber,
    required this.setNumber,
    required this.onDeleted,
    required this.onFinished,
    required this.id,
    this.onTap,
  });

  final String name;
  final int setNumber;
  final int repNumber;
  final Function(BuildContext)? onDeleted;
  final Function(BuildContext)? onFinished;
  final String id;
  final VoidCallback? onTap;

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
        key: Key(id),
        color: ColorManager.surfaceDark,
        swipeThreshold: 0.2,
        direction: SwipeDirection.horizontal,
        onSwiped: (direction) {
          if (direction == SwipeDirection.startToEnd && onFinished != null) {
            onFinished!(context);
          } else if (direction == SwipeDirection.endToStart &&
              onDeleted != null) {
            onDeleted!(context);
          }
        },
        backgroundBuilder: (context, direction, progress) {
          if (direction == SwipeDirection.startToEnd) {
            return Container(
              color: ColorManager.limerGreen2,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: PaddingManager.p16),
              child: Row(
                children: [
                  Icon(Icons.done_all_sharp, color: ColorManager.darkGrey),
                  const SizedBox(width: 8),
                  Text(
                    StringsManager.finished,
                    style: TextStyle(color: ColorManager.darkGrey),
                  ),
                ],
              ),
            );
          } else if (direction == SwipeDirection.endToStart) {
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
          height: SizeManager.s100.h,
          decoration: BoxDecoration(
            color: ColorManager.surfaceDark,
            border: Border(
              bottom: BorderSide(
                color: ColorManager.limerGreen2,
                width: SizeManager.s1,
              ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                debugPrint("ExerciseWidget tapped: $name");
                if (onTap != null) onTap!();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: PaddingManager.p28, vertical: PaddingManager.p12).copyWith(top: PaddingManager.p28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.play_circle_fill, color: ColorManager.primaryText, size: 30.sp),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              name,
                              style: StyleManager.exerciseNameTextStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${setNumber.round()}',
                              style: StyleManager.exerciseRepAndSetNumberTextStyle,
                            ),
                            SizedBox(width: SizeManager.s3.w),
                            Text(
                              StringsManager.setNumberHint,
                              style: StyleManager.exerciseRepAndSetHintTextStyle,
                            ),
                          ],
                        ),
                        SizedBox(height: SizeManager.s10.h),
                        Row(
                          children: [
                            Text(
                              '${repNumber.round()}',
                              style: StyleManager.exerciseRepAndSetNumberTextStyle,
                            ),
                            SizedBox(width: SizeManager.s3.w),
                            Text(
                              StringsManager.repNumberHint,
                              style: StyleManager.exerciseRepAndSetHintTextStyle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
