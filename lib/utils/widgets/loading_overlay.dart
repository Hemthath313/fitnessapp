import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingOverlay {
  static BuildContext? _overlayContext;

  static void show(BuildContext context, {String? message}) {
    _overlayContext = context;
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        _overlayContext = dialogContext;
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: ColorManager.darkGrey,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpinKitSpinningLines(
                    color: ColorManager.primary,
                    size: 50.sp,
                  ),
                  if (message != null) ...[
                    SizedBox(height: 16.h),
                    Text(
                      message,
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 14.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void hide(BuildContext? context) {
    try {
      // Try to use the stored overlay context first
      if (_overlayContext != null && _overlayContext!.mounted) {
        try {
          Navigator.of(_overlayContext!, rootNavigator: true).pop();
        } catch (_) {}
        _overlayContext = null;
        return;
      }
      
      // Fallback to provided context
      if (context != null && context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
        _overlayContext = null;
        return;
      }
      
      // Try to pop any dialog on root navigator using any available context
      // This is a last resort when context is null
      if (context != null && context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }
    } catch (e) {
      // If all else fails, try to pop until we find the dialog
      if (_overlayContext != null && _overlayContext!.mounted) {
        try {
          Navigator.of(_overlayContext!, rootNavigator: true)
              .popUntil((route) => route.isFirst || route.settings.name == null);
        } catch (_) {}
      }
    } finally {
      _overlayContext = null;
    }
  }
  
  /// Force hide overlay - useful for cleanup after navigation
  static void forceHide() {
    _overlayContext = null;
  }
}

