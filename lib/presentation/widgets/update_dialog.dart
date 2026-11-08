import 'dart:io' show Platform;
import 'package:fitness_app/services/update_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:in_app_update/in_app_update.dart' as play;

class UpdateDialog extends StatelessWidget {
  final bool isForceUpdate;
  final bool isRecommended;
  final String releaseNotes;
  final String updateUrl;
  final bool canUsePlayStoreImmediateUpdate;
  final bool canUsePlayStoreFlexibleUpdate;

  const UpdateDialog({
    super.key,
    required this.isForceUpdate,
    this.isRecommended = false,
    required this.releaseNotes,
    required this.updateUrl,
    this.canUsePlayStoreImmediateUpdate = false,
    this.canUsePlayStoreFlexibleUpdate = false,
  });

  Future<void> _launchUpdateUrl(BuildContext context) async {
    // 1. Mandatory update: Try Google Play native immediate in-app update if allowed
    if (!kIsWeb && Platform.isAndroid && isForceUpdate && canUsePlayStoreImmediateUpdate) {
      try {
        final result = await play.InAppUpdate.performImmediateUpdate();
        if (result == play.AppUpdateResult.success) {
          return;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Play Store native immediate update skipped or failed: $e');
        }
      }
    }

    // 2. Optional update: Try Google Play native flexible in-app update if allowed
    if (!kIsWeb && Platform.isAndroid && !isForceUpdate && canUsePlayStoreFlexibleUpdate) {
      try {
        final result = await play.InAppUpdate.startFlexibleUpdate();
        if (result == play.AppUpdateResult.success) {
          await play.InAppUpdate.completeFlexibleUpdate();
          return;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Play Store native flexible update skipped or failed: $e');
        }
      }
    }

    // 3. Fallback: Open Google Play Store listing via market:// or web URL
    try {
      final success = await UpdateService().openStore(
        customUrl: updateUrl,
      );

      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Play Store.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e')),
        );
      }
    }
  }

  /// Builds formatted multiline release notes supporting bullet points and paragraphs
  Widget _buildReleaseNotes(String notes) {
    final lines = notes.split('\n');

    // If it's a single line without bullet markers, render simple text
    if (lines.length == 1 &&
        !lines.first.trim().startsWith('•') &&
        !lines.first.trim().startsWith('-') &&
        !lines.first.trim().startsWith('*')) {
      return Text(
        lines.first.trim(),
        style: TextStyle(
          color: ColorManager.textSecondary,
          fontSize: 13.sp,
          height: 1.4,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: lines.map((line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          return SizedBox(height: 6.h);
        }

        final isBullet = trimmed.startsWith('•') ||
            trimmed.startsWith('- ') ||
            trimmed.startsWith('* ');

        final text = isBullet
            ? trimmed.replaceFirst(RegExp(r'^(•|\-|\*)\s*'), '')
            : trimmed;

        if (isBullet) {
          return Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 6.h, right: 8.w),
                  child: Container(
                    width: 5.w,
                    height: 5.w,
                    decoration: BoxDecoration(
                      color: ColorManager.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontSize: 13.sp,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: 6.h),
          child: Text(
            trimmed,
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 13.sp,
              height: 1.4,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    // Prevent dismissing dialog if it's a mandatory update
    return PopScope(
      canPop: !isForceUpdate,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isForceUpdate) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please update Gym Buddy on Google Play to continue.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusManager.r24),
        ),
        elevation: 10,
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400.w,
            maxHeight: screenHeight * 0.85,
          ),
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
                  color: ColorManager.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Header with Icon & Dynamic Title (height reduced by ~20%)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 18.h),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: ColorManager.onMint.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isForceUpdate
                              ? Icons.system_update_rounded
                              : Icons.system_update_alt_rounded,
                          color: ColorManager.onMint,
                          size: 32.w,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        isForceUpdate
                            ? 'Update Required'
                            : (isRecommended ? 'Update Recommended' : 'Update Available'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ColorManager.onMint,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Content Area (Scrollable if screen or content is constrained)
                Flexible(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isForceUpdate
                              ? 'The installed version of Gym Buddy is no longer supported. Please update to the latest version on Google Play to continue.'
                              : 'A new version of Gym Buddy is available on Google Play! Upgrade today for the latest workouts, features, and improvements.',
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 14.sp,
                            height: 1.4,
                          ),
                        ),

                        if (releaseNotes.isNotEmpty) ...[
                          SizedBox(height: 14.h),
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
                            constraints: BoxConstraints(
                              maxHeight: 140.h,
                              minHeight: 40.h,
                            ),
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: ColorManager.background,
                              borderRadius: BorderRadius.circular(RadiusManager.r15),
                              border: Border.all(
                                color: ColorManager.divider.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Scrollbar(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: _buildReleaseNotes(releaseNotes),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 3. Divider
                Divider(
                  color: ColorManager.divider,
                  height: 1,
                ),

                // 4. Action Button Area (Permanently visible and fixed at bottom)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // "Later" / Cancel button - only if NOT force update with improved contrast
                      if (!isForceUpdate) ...[
                        TextButton(
                          key: const Key('update_later_button'),
                          onPressed: () {
                            UpdateService().markOptionalUpdateDismissed();
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withValues(alpha: 0.85),
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(RadiusManager.r15),
                            ),
                          ),
                          child: Text(
                            'LATER',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
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
                                color: ColorManager.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              key: const Key('update_now_button'),
                              onTap: () => _launchUpdateUrl(context),
                              borderRadius: BorderRadius.circular(RadiusManager.r15),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                child: Center(
                                  child: Text(
                                    'UPDATE NOW',
                                    style: TextStyle(
                                      color: ColorManager.onMint,
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
      ),
    );
  }
}
