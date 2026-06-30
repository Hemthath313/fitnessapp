import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io' show Platform;

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final TextEditingController _feedbackController = TextEditingController();
  int _selectedStars = 5;
  bool _isSubmitting = false;
  String _errorMessage = '';

  Future<void> _submitFeedback() async {
    final feedbackText = _feedbackController.text.trim();
    if (feedbackText.length < 5) {
      setState(() {
        _errorMessage = 'Please write at least 5 characters.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final packageInfo = await PackageInfo.fromPlatform();
      
      String os = 'Web';
      if (!kIsWeb) {
        if (Platform.isAndroid) os = 'Android';
        if (Platform.isIOS) os = 'iOS';
      }

      final Map<String, dynamic> feedbackData = {
        'rating': _selectedStars,
        'comments': feedbackText,
        'submitted_at': FieldValue.serverTimestamp(),
        'user_id': user?.uid ?? 'anonymous',
        'app_version': packageInfo.version,
        'app_build': packageInfo.buildNumber,
        'platform': os,
      };

      await FirebaseFirestore.instance.collection('feedback').add(feedbackData);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true on success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Thank you! Your feedback helps us improve.'),
            backgroundColor: ColorManager.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to submit feedback. Please try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusManager.r24),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(RadiusManager.r24),
          border: Border.all(
            color: ColorManager.divider,
            width: 1.5,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 20.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ColorManager.gradientStart, ColorManager.gradientEnd],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(RadiusManager.r24 - 1.5),
                    topRight: Radius.circular(RadiusManager.r24 - 1.5),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      color: Colors.white,
                      size: SizeManager.s35.w,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'RATE & FEEDBACK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'How is your experience with GymBuddy?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Interactive Stars Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starNumber = index + 1;
                        final isSelected = starNumber <= _selectedStars;
                        return IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedStars = starNumber;
                            });
                          },
                          icon: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                            color: isSelected ? Colors.amber : ColorManager.textTertiary,
                            size: SizeManager.s40.w,
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 16.h),

                    // Text Input
                    TextField(
                      controller: _feedbackController,
                      maxLines: 4,
                      maxLength: 500,
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 13.sp,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts, report issues, or suggest improvements...',
                        hintStyle: TextStyle(color: ColorManager.textTertiary),
                        fillColor: ColorManager.background,
                        filled: true,
                        counterStyle: TextStyle(color: ColorManager.textSecondary),
                        contentPadding: EdgeInsets.all(12.w),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(RadiusManager.r15),
                          borderSide: BorderSide(color: ColorManager.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(RadiusManager.r15),
                          borderSide: const BorderSide(color: ColorManager.primary, width: 1.5),
                        ),
                      ),
                    ),

                    if (_errorMessage.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Text(
                        _errorMessage,
                        style: TextStyle(
                          color: ColorManager.red,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],

                    SizedBox(height: 16.h),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                            child: Text(
                              'CANCEL',
                              style: TextStyle(
                                color: ColorManager.textSecondary,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [ColorManager.gradientStart, ColorManager.gradientEnd],
                              ),
                              borderRadius: BorderRadius.circular(RadiusManager.r15),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isSubmitting ? null : _submitFeedback,
                                borderRadius: BorderRadius.circular(RadiusManager.r15),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  child: Center(
                                    child: _isSubmitting
                                        ? SizedBox(
                                            width: 16.w,
                                            height: 16.w,
                                            child: const CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            'SUBMIT',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.bold,
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
