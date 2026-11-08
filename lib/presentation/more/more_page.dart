import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/achievements_widget.dart';
import 'package:fitness_app/presentation/theme/providers/theme_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/utils/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/presentation/profile/widgets/gym_alarm_setting_widget.dart';
import 'package:fitness_app/presentation/widgets/feedback_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<HomeProvider, ThemeProvider, StatisticsProvider>(
      builder: (context, homeProvider, themeProvider, statsProvider, _) {
        return SafeArea(
          bottom: false,
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
                            ColorManager.primary.withValues(alpha: themeProvider.isDarkMode ? 0.2 : 0.3),
                            ColorManager.primary.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(SizeManager.s20.r),
                        border: Border.all(
                          color: ColorManager.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar with initials instead of generic icon
                          CircleAvatar(
                            radius: SizeManager.s40.r,
                            backgroundColor: ColorManager.primary.withValues(alpha: 0.25),
                            child: Text(
                              _getInitials(firstName, surname),
                              style: TextStyle(
                                color: ColorManager.primary,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                              ),
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
                                    color: ColorManager.textPrimary,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: SizeManager.s4.h),
                                Text(
                                  email,
                                  style: TextStyle(
                                    color: ColorManager.textSecondary,
                                    fontSize: 14.sp,
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

                // My Stats & Progress shortcuts
                _buildSectionTitle('My Activity'),
                SizedBox(height: SizeManager.s12.h),

                _buildMenuCard(
                  context,
                  icon: Icons.history_rounded,
                  title: 'Workout History',
                  subtitle: 'View all your past workouts',
                  color: Colors.teal,
                  onTap: () => context.push(Routes.workoutHistoryRoute),
                ),
                SizedBox(height: SizeManager.s24.h),

                // Achievements Showcase
                _buildSectionTitle('Achievements'),
                SizedBox(height: SizeManager.s12.h),
                _buildAchievementsSection(statsProvider),
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
                  icon: Icons.straighten,
                  title: 'Body Measurements',
                  subtitle: 'Update body measurements',
                  color: Colors.purple,
                  onTap: () => context.push(Routes.changeMeasurementsRoute),
                ),
                // Reminders & Notifications Section
                _buildSectionTitle('Reminders & Notifications'),
                SizedBox(height: SizeManager.s12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeManager.s4.w),
                  child: const GymAlarmSettingWidget(),
                ),
                SizedBox(height: SizeManager.s24.h),

                // Account Settings Section
                _buildSectionTitle('Account Settings'),
                SizedBox(height: SizeManager.s12.h),

                // Theme Toggle
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeManager.s4.w),
                  child: GestureDetector(
                    onTap: () => themeProvider.toggleTheme(),
                    child: Container(
                      padding: EdgeInsets.all(SizeManager.s16.w),
                      decoration: BoxDecoration(
                        color: ColorManager.surface,
                        borderRadius: BorderRadius.circular(SizeManager.s16.r),
                        border: Border.all(
                          color: ColorManager.primary.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ColorManager.primary.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(SizeManager.s12.w),
                            decoration: BoxDecoration(
                              color: ColorManager.primary.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(SizeManager.s12.r),
                            ),
                            child: Icon(
                              themeProvider.isDarkMode
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              color: ColorManager.primary,
                              size: SizeManager.s24.sp,
                            ),
                          ),
                          SizedBox(width: SizeManager.s16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  themeProvider.isDarkMode
                                      ? 'Dark Mode'
                                      : 'Light Mode',
                                  style: TextStyle(
                                    color: ColorManager.textPrimary,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: SizeManager.s4.h),
                                Text(
                                  'Tap to switch theme',
                                  style: TextStyle(
                                    color: ColorManager.textSecondary,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (value) => themeProvider.toggleTheme(),
                            activeColor: ColorManager.primary,
                            activeTrackColor:
                                ColorManager.primary.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

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
                  icon: Icons.rate_review_outlined,
                  title: 'Feedback & Support',
                  subtitle: 'Rate your experience or suggest features',
                  color: Colors.teal,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const FeedbackDialog(),
                    );
                  },
                ),
                SizedBox(height: SizeManager.s12.h),
                _buildMenuCard(
                  context,
                  icon: Icons.support_agent_rounded,
                  title: 'Contact Support',
                  subtitle: 'Email buddyspps204@gmail.com',
                  color: Colors.blueAccent,
                  onTap: () async {
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'buddyspps204@gmail.com',
                      queryParameters: {
                        'subject': 'Support Request - Fitness App',
                      },
                    );
                    try {
                      final bool launched = await launchUrl(
                        emailLaunchUri,
                        mode: LaunchMode.externalApplication,
                      );
                      if (!launched && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open email client. Please email buddyspps204@gmail.com')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open email client. Please email buddyspps204@gmail.com')),
                        );
                      }
                    }
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
                        fontSize: 16.sp,
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
                        'Gym Buddy',
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 14.sp,
                        ),
                      ),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          color: ColorManager.textTertiary,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getInitials(String firstName, String surname) {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = surname.isNotEmpty ? surname[0].toUpperCase() : '';
    return '$first$last'.isEmpty ? '?' : '$first$last';
  }

  Widget _buildAchievementsSection(StatisticsProvider statsProvider) {
    final unlocked = statsProvider.unlockedAchievements;
    return SizedBox(
      height: 90.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: allAchievements.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (context, i) {
          final def = allAchievements[i];
          final isUnlocked = unlocked.contains(def.id);
          return Tooltip(
            message: isUnlocked ? def.desc : 'Locked: ${def.desc}',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 72.w,
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? def.color.withValues(alpha: 0.12)
                    : ColorManager.surfaceLight,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isUnlocked
                      ? def.color.withValues(alpha: 0.4)
                      : ColorManager.divider,
                  width: 1.5,
                ),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: def.color.withValues(alpha: 0.2),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isUnlocked ? def.emoji : '🔒',
                    style: TextStyle(fontSize: 24.sp),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    def.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isUnlocked
                          ? ColorManager.textPrimary
                          : ColorManager.textTertiary,
                      fontSize: 11.sp,
                      fontWeight: isUnlocked
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: ColorManager.textPrimary,
        fontSize: 18.sp,
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
              ? ColorManager.red.withValues(alpha: 0.1)
              : ColorManager.surface,
          borderRadius: BorderRadius.circular(SizeManager.s16.r),
          border: Border.all(
            color: isDangerous ? ColorManager.red : color.withValues(alpha: 0.3),
            width: isDangerous ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(SizeManager.s12.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
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
                      color: ColorManager.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: SizeManager.s4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: ColorManager.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: ColorManager.textSecondary,
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
        backgroundColor: ColorManager.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SizeManager.s16.r),
        ),
        title: Text(
          'Logout',
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: ColorManager.textSecondary,
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: ColorManager.textSecondary),
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
        disabledBackgroundColor: Colors.red.withValues(alpha: 0.6),
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
                valueColor: AlwaysStoppedAnimation<Color>(ColorManager.textPrimary),
              ),
            )
          : Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
