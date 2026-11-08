import 'package:flutter/material.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final String? fallbackMessage;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallbackMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (error, stackTrace) {
          // Log the error
          debugPrint('ErrorBoundary caught error: $error');
          debugPrint('Stack trace: $stackTrace');

          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: ColorManager.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  fallbackMessage ?? 'Something went wrong',
                  style:  TextStyle(
                    color: ColorManager.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try refreshing the page',
                  style: TextStyle(
                    color: ColorManager.grey2,
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Try to rebuild the widget
                    (context as Element).markNeedsBuild();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.limerGreen2,
                    foregroundColor: ColorManager.darkGrey,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
