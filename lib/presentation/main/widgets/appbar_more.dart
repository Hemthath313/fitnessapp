import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MorePageAppBarWidget extends StatelessWidget {
  const MorePageAppBarWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: SizeManager.s50,
      automaticallyImplyLeading: false,
      elevation: SizeManager.s0,
      title: Text(
        'Profile',
        style: StyleManager.appbarTitleTextStyle,
      ),
    ).animate().fadeIn(
          duration: 500.ms,
        );
  }
}
