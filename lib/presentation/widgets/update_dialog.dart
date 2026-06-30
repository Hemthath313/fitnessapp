import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatelessWidget {
  final bool isForceUpdate;
  final String releaseNotes;
  final String updateUrl;

  const UpdateDialog({
    super.key,
    required this.isForceUpdate,
    required this.releaseNotes,
    required this.updateUrl,
  });

  Future<void> _launchUpdateUrl(BuildContext context) async {
    final Uri url = Uri.parse(updateUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open update link')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening link: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prevent dismissing the dialog if it's a forced update
    return PopScope(
      canPop: !isForceUpdate,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusManager.r24),
        ),
        elevation: 10,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: ColorManager.surface,
            borderRadius: BorderRadius.circular(RadiusManager.r24),
            border: Border.all(
              color: ColorManager.divider,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: ColorManager.primary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Beautiful Gradient Header with Icon
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 24.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColorManager.gradientStart,
                      ColorManager.gradientEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(RadiusManager.r24 - 1.5),
                    topRight: Radius.circular(RadiusManager.r24 - 1.5),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isForceUpdate ? Icons.system_update_alt_rounded : Icons.rocket_launch_rounded,
                        color: Colors.white,
                        size: SizeManager.s40.w,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      isForceUpdate ? 'CRITICAL UPDATE' : 'NEW UPDATE AVAILABLE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Content Area
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isForceUpdate
                          ? 'A critical update is required to continue using the fitness app. Please update to the latest version to get security fixes and stable features.'
                          : 'A new version of the app is available! Upgrade today to get the latest workouts, features, and improvements.',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 14.sp,
                        height: 1.4,
                      ),
                    ),
                    
                    if (releaseNotes.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      Text(
                        'What\'s New:',
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(maxHeight: 120.h),
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: ColorManager.background,
                          borderRadius: BorderRadius.circular(RadiusManager.r15),
                          border: Border.all(
                            color: ColorManager.divider.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Scrollbar(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              releaseNotes,
                              style: TextStyle(
                                color: ColorManager.textSecondary,
                                fontSize: 13.sp,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Divider
              Divider(
                color: ColorManager.divider,
                height: 1,
              ),

              // Button Area
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // "Later" / Cancel button - only if NOT force update
                    if (!isForceUpdate) ...[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'LATER',
                          style: TextStyle(
                            color: ColorManager.textSecondary,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                    ],

                    // "Update Now" Action Button
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              ColorManager.gradientStart,
                              ColorManager.gradientEnd,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(RadiusManager.r15),
                          boxShadow: [
                            BoxShadow(
                              color: ColorManager.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _launchUpdateUrl(context),
                            borderRadius: BorderRadius.circular(RadiusManager.r15),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              child: Center(
                                child: Text(
                                  isForceUpdate ? 'UPDATE NOW' : 'UPGRADE NOW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
