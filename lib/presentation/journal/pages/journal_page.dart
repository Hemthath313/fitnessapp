import 'package:fitness_app/presentation/banner_ads/banner_ad_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  double? _oneRepMax;

  void _calculate1RM() {
    final weight = double.tryParse(_weightController.text);
    final reps = double.tryParse(_repsController.text);

    if (weight != null && reps != null && reps > 0) {
      setState(() {
        // Using Epley Formula: 1RM = weight * (1 + reps/30)
        _oneRepMax = weight * (1 + reps / 30);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(SizeManager.s16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Journal',
              style: TextStyle(
                color: ColorManager.white,
                fontSize: SizeManager.s24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: SizeManager.s24.h),

            // 1RM Calculator Card
            _build1RMCalculator(),

            SizedBox(height: SizeManager.s24.h),

            // Navigation Cards
            Row(
              children: [
                Expanded(
                  child: _buildNavigationCard(
                    title: 'Workout History',
                    subtitle: 'View your logs',
                    icon: Icons.history,
                    color: Colors.teal,
                    onTap: () => context.push(Routes.workoutHistoryRoute),
                  ),
                ),
                // SizedBox(width: SizeManager.s12.w),
                // Expanded(
                //   child: _buildNavigationCard(
                //     title: 'Progress Photos',
                //     subtitle: 'Visual tracking',
                //     icon: Icons.photo_library,
                //     color: Colors.pink,
                //     onTap: () => context.push(Routes.progressPhotosRoute),
                //   ),
                // ),
              ],
            ),
            
            SizedBox(height: SizeManager.s40.h),
            const PremiumAwareBannerAd(pageName: 'journal'),
            SizedBox(height: SizeManager.s16.h),
          ],
        ),
      ),
    );
  }

  Widget _build1RMCalculator() {
    return Container(
      padding: EdgeInsets.all(SizeManager.s20.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(SizeManager.s20.r),
        border: Border.all(
          color: ColorManager.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorManager.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: ColorManager.primary),
              SizedBox(width: SizeManager.s8.w),
              Text(
                '1RM Calculator',
                style: TextStyle(
                  color: ColorManager.white,
                  fontSize: SizeManager.s18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeManager.s4.h),
          Text(
            'Estimate your One Rep Max for any exercise',
            style: TextStyle(
              color: ColorManager.white70,
              fontSize: SizeManager.s12.sp,
            ),
          ),
          SizedBox(height: SizeManager.s20.h),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _weightController,
                  label: 'Weight (kg)',
                  hint: 'e.g. 100',
                ),
              ),
              SizedBox(width: SizeManager.s12.w),
              Expanded(
                child: _buildTextField(
                  controller: _repsController,
                  label: 'Reps',
                  hint: 'e.g. 5',
                ),
              ),
            ],
          ),
          SizedBox(height: SizeManager.s20.h),
          if (_oneRepMax != null)
            Center(
              child: Column(
                children: [
                  Text(
                    'Your Estimated 1RM',
                    style: TextStyle(
                      color: ColorManager.white70,
                      fontSize: SizeManager.s14.sp,
                    ),
                  ),
                  Text(
                    '${_oneRepMax!.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      color: ColorManager.primary,
                      fontSize: SizeManager.s32.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: SizeManager.s16.h),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _calculate1RM,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                padding: EdgeInsets.symmetric(vertical: SizeManager.s12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SizeManager.s12.r),
                ),
              ),
              child: Text(
                'Calculate',
                style: TextStyle(
                  color: ColorManager.darkGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ColorManager.white70,
            fontSize: SizeManager.s12.sp,
          ),
        ),
        SizedBox(height: SizeManager.s8.h),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: ColorManager.white2, fontSize: SizeManager.s14.sp),
            filled: true,
            fillColor: ColorManager.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SizeManager.s12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: SizeManager.s16.w,
              vertical: SizeManager.s12.h,
            ),
          ),
          onChanged: (_) {
            if (_oneRepMax != null) setState(() => _oneRepMax = null);
          },
        ),
      ],
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SizeManager.s16.r),
      child: Container(
        padding: EdgeInsets.all(SizeManager.s16.w),
        height: SizeManager.s150.h,
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(SizeManager.s16.r),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(SizeManager.s10.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: SizeManager.s28.sp),
            ),
            SizedBox(height: SizeManager.s12.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorManager.white,
                fontSize: SizeManager.s14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: SizeManager.s4.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorManager.white70,
                fontSize: SizeManager.s1.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
