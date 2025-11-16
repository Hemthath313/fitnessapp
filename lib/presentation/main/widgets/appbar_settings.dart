import 'package:fitness_app/presentation/auth/providers/auth_provider.dart';
import 'package:fitness_app/presentation/settings/providers/settings_provider.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';

class SettingsPageAppBarWidget extends StatefulWidget {
  const SettingsPageAppBarWidget({
    super.key,
  });

  @override
  State<SettingsPageAppBarWidget> createState() =>
      _SettingsPageAppBarWidgetState();
}

class _SettingsPageAppBarWidgetState extends State<SettingsPageAppBarWidget> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    Future<void> signOut() async {
      if (_isLoggingOut) return; // Prevent multiple clicks
      
      setState(() => _isLoggingOut = true);
      
      try {
        await settingsProvider.signOut(context: context);
        authProvider.callAuth();

        if (mounted) {
          context.go(Routes.authRoute);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoggingOut = false);
        }
      }
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: SizeManager.s50,
      automaticallyImplyLeading: false,
      elevation: SizeManager.s0,
      title: Text(
        StringsManager.settingsABtitle,
        style: StyleManager.appbarTitleTextStyle,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: PaddingManager.p12),
          child: Container(
            height: SizeManager.s40.h,
            width: SizeManager.s40.w,
            decoration: BoxDecoration(
              color: ColorManager.grey3,
              borderRadius: BorderRadius.circular(
                RadiusManager.r40.r,
              ),
            ),
            child: IconButton(
              splashColor: ColorManager.grey3,
              onPressed: _isLoggingOut ? null : signOut,
              icon: _isLoggingOut
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(ColorManager.white),
                      ),
                    )
                  : const Icon(
                      Icons.logout_sharp,
                      size: SizeManager.s26,
                      color: ColorManager.white,
                    ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(
          duration: 500.ms,
        );
  }
}
