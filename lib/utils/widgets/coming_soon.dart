import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 100,
              color: ColorManager.primaryText,
            ),
            const SizedBox(height: 20),
             Text(
              'Coming Soon',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
             Text(
              'Stay tuned for exciting updates!',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
