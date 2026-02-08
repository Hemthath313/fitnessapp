import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/utils/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);

    return SafeArea(
      bottom: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(SizeManager.s16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            FutureBuilder<Map<String, dynamic>>(
              future: homeProvider.fetchUserData(),
              builder: (context, snapshot) {
                final userData = snapshot.data ?? {};
                final firstName = userData['first name'] ?? 'User';
                final surname = userData['surname'] ?? '';
                final email = FirebaseAuth.instance.currentUser?.email ?? '';

                return Container(
                  padding: EdgeInsets.all(SizeManager.s20.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ColorManager.limerGreen2.withOpacity(0.3),
                        ColorManager.limerGreen2.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(SizeManager.s20.r),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: SizeManager.s40.r,
                        backgroundColor: ColorManager.limerGreen2,
                        child: Icon(
                          Icons.person,
                          size: SizeManager.s40.sp,
                          color: ColorManager.darkGrey,
                        ),
                      ),
                      SizedBox(width: SizeManager.s16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$firstName $surname',
                              style: TextStyle(
                                color: ColorManager.white,
                                fontSize: SizeManager.s20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: SizeManager.s4.h),
                            Text(
                              email,
                              style: TextStyle(
                                color: ColorManager.white70,
                                fontSize: SizeManager.s14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: SizeManager.s24.h),

            // Premium Section
            _buildSectionTitle('Premium'),
            SizedBox(height: SizeManager.s12.h),
            _buildMenuCard(
              context,
              icon: Icons.workspace_premium,
              title: 'Go Premium',
              subtitle: 'Ad-free, workout splits, diet plans & more',
              color: ColorManager.primary,
              onTap: () => context.push(Routes.premiumScreen),
            ),
            SizedBox(height: SizeManager.s24.h),

            // Body & Measurements Section
            _buildSectionTitle('Body & Measurements'),
            SizedBox(height: SizeManager.s12.h),
            _buildMenuCard(
              context,
              icon: Icons.monitor_weight,
              title: 'Update Weight',
              subtitle: 'Track your weight progress',
              color: Colors.blue,
              onTap: () => context.push(Routes.changeWeightRoute),
            ),
            SizedBox(height: SizeManager.s12.h),
            _buildMenuCard(
              context,
              icon: Icons.straighten,
              title: 'Body Measurements',
              subtitle: 'Update body measurements',
              color: Colors.purple,
              onTap: () => context.push(Routes.changeMeasurementsRoute),
            ),
            SizedBox(height: SizeManager.s24.h),

            // Account Settings Section
            _buildSectionTitle('Account Settings'),
            SizedBox(height: SizeManager.s12.h),
            _buildMenuCard(
              context,
              icon: Icons.lock_outline,
              title: 'Change Password',
              subtitle: 'Update your account password',
              color: Colors.orange,
              onTap: () => context.push(Routes.changePasswordRoute),
            ),
            SizedBox(height: SizeManager.s12.h),
            _buildMenuCard(
              context,
              icon: Icons.email_outlined,
              title: 'Change Email',
              subtitle: 'Update your email address',
              color: Colors.teal,
              onTap: () => context.push(Routes.changeEmailRoute),
            ),
            SizedBox(height: SizeManager.s12.h),
            _buildMenuCard(
              context,
              icon: Icons.settings_outlined,
              title: 'App Settings',
              subtitle: 'Preferences and notifications',
              color: Colors.grey,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Settings coming soon!'),
                    backgroundColor: ColorManager.limerGreen2,
                  ),
                );
              },
            ),
            SizedBox(height: SizeManager.s24.h),

            // Danger Zone
            _buildSectionTitle('Danger Zone'),
            SizedBox(height: SizeManager.s12.h),
            _buildMenuCard(
              context,
              icon: Icons.delete_outline,
              title: 'Delete Account',
              subtitle: 'Permanently remove your account',
              color: ColorManager.red,
              isDangerous: true,
              onTap: () => context.push(Routes.deleteAccRoute),
            ),
            SizedBox(height: SizeManager.s28.h),

            // Logout Button
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: Icon(Icons.logout, color: ColorManager.red),
                label: Text(
                  'Logout',
                  style: TextStyle(
                    color: ColorManager.red,
                    fontSize: SizeManager.s16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ColorManager.red, width: 2),
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeManager.s28.w,
                    vertical: SizeManager.s16.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SizeManager.s12.r),
                  ),
                ),
              ),
            ),

            SizedBox(height: SizeManager.s40.h),

            // App Info
            Center(
              child: Column(
                children: [
                  Text(
                    'Fitness App',
                    style: TextStyle(
                      color: ColorManager.white70,
                      fontSize: SizeManager.s14.sp,
                    ),
                  ),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: ColorManager.white70,
                      fontSize: SizeManager.s12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: ColorManager.white,
        fontSize: SizeManager.s18.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDangerous = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SizeManager.s16.r),
      child: Container(
        padding: EdgeInsets.all(SizeManager.s16.w),
        decoration: BoxDecoration(
          color: isDangerous
              ? ColorManager.red.withOpacity(0.1)
              : ColorManager.black87,
          borderRadius: BorderRadius.circular(SizeManager.s16.r),
          border: Border.all(
            color: isDangerous ? ColorManager.red : color.withOpacity(0.3),
            width: isDangerous ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(SizeManager.s12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(SizeManager.s12.r),
              ),
              child: Icon(
                icon,
                color: color,
                size: SizeManager.s24.sp,
              ),
            ),
            SizedBox(width: SizeManager.s16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: ColorManager.white,
                      fontSize: SizeManager.s16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: SizeManager.s4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: ColorManager.white70,
                      fontSize: SizeManager.s12.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: ColorManager.white70,
              size: SizeManager.s16.sp,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ColorManager.darkGrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SizeManager.s16.r),
        ),
        title: Text(
          'Logout',
          style: TextStyle(
            color: ColorManager.white,
            fontSize: SizeManager.s18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: ColorManager.white70,
            fontSize: SizeManager.s14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: ColorManager.white70),
            ),
          ),
          _LogoutButton(parentContext: context),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  final BuildContext parentContext;

  const _LogoutButton({required this.parentContext});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _isLoading = false;

  Future<void> _handleLogout() async {
    if (_isLoading) return; // Prevent multiple clicks

    setState(() => _isLoading = true);

    // Close dialog first
    Navigator.of(context).pop();

    // Wait a frame to ensure dialog is closed
    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;

    // Use parent context (from MorePage) for loading overlay and navigation
    LoadingOverlay.show(widget.parentContext, message: 'Logging out...');

    try {
      await FirebaseAuth.instance.signOut();

      // Wait for auth state to update
      await Future.delayed(const Duration(milliseconds: 100));

      if (widget.parentContext.mounted) {
        // Hide loading overlay first
        LoadingOverlay.hide(widget.parentContext);

        // Wait to ensure overlay is fully dismissed before navigation
        await Future.delayed(const Duration(milliseconds: 200));

        // Double check to hide overlay
        LoadingOverlay.hide(null);

        // Wait one more frame
        await Future.delayed(const Duration(milliseconds: 100));

        // Now navigate to boarding route (router will handle redirect)
        if (widget.parentContext.mounted) {
          widget.parentContext.go(Routes.boardingRoute);

          // Ensure overlay is hidden after navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            LoadingOverlay.hide(null);
          });

          // Final check after delay
          Future.delayed(const Duration(milliseconds: 500), () {
            LoadingOverlay.hide(null);
          });
        }
      }
    } catch (e) {
      if (widget.parentContext.mounted) {
        LoadingOverlay.hide(widget.parentContext);
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: ColorManager.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleLogout,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        disabledBackgroundColor: Colors.red.withOpacity(0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SizeManager.s8.r),
        ),
      ),
      child: _isLoading
          ? SizedBox(
              height: 16.h,
              width: 16.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(ColorManager.white),
              ),
            )
          : Text(
              'Logout',
              style: TextStyle(
                color: ColorManager.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
