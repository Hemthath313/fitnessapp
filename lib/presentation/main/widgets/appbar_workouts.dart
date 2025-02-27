import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';

class ChatPageAppBarWidget extends StatelessWidget {
  const ChatPageAppBarWidget({
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
        StringsManager.askYourDoubt,
        style: StyleManager.appbarTitleTextStyle,
      ),
    ).animate().fadeIn(
          duration: 500.ms,
        );
  }
}
