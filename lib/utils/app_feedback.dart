import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum FeedbackKind { success, error, info }

/// One consistent snackbar for success / error / info messages.
class AppFeedback {
  const AppFeedback._();

  static void success(BuildContext context, String message) =>
      show(context, message, FeedbackKind.success);

  static void error(BuildContext context, String message) =>
      show(context, message, FeedbackKind.error);

  static void info(BuildContext context, String message) =>
      show(context, message, FeedbackKind.info);

  static Color colorFor(FeedbackKind kind) {
    switch (kind) {
      case FeedbackKind.success:
        return ColorManager.primary;
      case FeedbackKind.error:
        return ColorManager.error;
      case FeedbackKind.info:
        return ColorManager.surfaceLight;
    }
  }

  static IconData iconFor(FeedbackKind kind) {
    switch (kind) {
      case FeedbackKind.success:
        return Icons.check_circle_rounded;
      case FeedbackKind.error:
        return Icons.error_outline_rounded;
      case FeedbackKind.info:
        return Icons.info_outline_rounded;
    }
  }

  static void show(BuildContext context, String message, FeedbackKind kind) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final onColor =
        kind == FeedbackKind.info ? ColorManager.textPrimary : Colors.white;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colorFor(kind),
          margin: EdgeInsets.all(16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          content: Row(
            children: [
              Icon(iconFor(kind), color: onColor, size: 20.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: onColor, fontSize: 14.sp),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
