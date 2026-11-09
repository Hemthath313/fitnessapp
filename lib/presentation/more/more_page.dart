import 'package:fitness_app/utils/managers/layout_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/achievements_widget.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/profile/profile_data.dart';
import 'package:fitness_app/presentation/theme/providers/theme_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/utils/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/presentation/widgets/feedback_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  String _version = '';
  int? _reminderCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  /// One refresh of the profile data and the app version. This used to be a
  /// FutureBuilder inside build() under a Consumer<HomeProvider>: each fetch
  /// notified listeners, which rebuilt the page, which fetched again - an
  /// endless loop of Firestore reads.
  Future<void> _loadReminderCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = ReminderSummary.enabledCount(prefs.getBool);
      if (mounted) setState(() => _reminderCount = count);
    } catch (_) {
      // Summary is cosmetic; keep the generic subtitle if prefs fail.
    }
  }

  Future<void> _load() async {
    _loadReminderCount();
    try {
      await Provider.of<HomeProvider>(context, listen: false).fetchUserData();
    } catch (e) {
      debugPrint('Profile: could not refresh user data: $e');
    }
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = ProfileData.versionLabel(info.version, info.buildNumber);
        });
      }
    } catch (_) {
      // Version label is cosmetic; leave it blank if unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscription = Provider.of<SubscriptionProvider>(context);
    return Consumer3<HomeProvider, ThemeProvider, StatisticsProvider>(
      builder: (context, homeProvider, themeProvider, statsProvider, _) {
        return SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter, vertical: SizeManager.s16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Builder(
                  builder: (context) {
                    final userData = homeProvider.userData;
                    final rawFirst = (userData['first name'] ?? '').toString().trim();
                    final firstName =
                        rawFirst.isEmpty ? ProfileData.fallbackName : rawFirst;
                    final surname = (userData['surname'] ?? '').toString().trim();
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
                                color: ColorManager.primaryText,
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
                                  '$firstName $surname'.trim(),
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
                SizedBox(height: SizeManager.s12.h),
                _buildStatsStrip(statsProvider),
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
                  title: subscription.isPremium ? 'Premium active' : 'Go Premium',
                  subtitle: subscription.isPremium
                      ? (subscription.isLifetime
                          ? 'Lifetime access - thank you!'
                          : 'Manage your subscription')
                      : 'Ad-free, workout splits, diet plans & more',
                  color: ColorManager.primaryText,
                  onTap: () => context.push(Routes.premiumScreen),
                ),
                SizedBox(height: SizeManager.s24.h),

                // Body & Goals
                _buildSectionTitle('Body & Goals'),
                SizedBox(height: SizeManager.s12.h),
                _buildMenuCard(
                  context,
                  icon: Icons.monitor_weight_outlined,
                  title: 'Log Weight',
                  subtitle: 'Weigh-ins and your goal weight',
                  color: Colors.teal,
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
                SizedBox(height: SizeManager.s12.h),
                _buildMenuCard(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile',
                  subtitle: 'Name, age, height and gender',
                  color: Colors.blueAccent,
                  onTap: () => context.push(Routes.editProfileRoute),
                ),
                SizedBox(height: SizeManager.s24.h),

                // Account Settings Section
                _buildSectionTitle('Account Settings'),
                SizedBox(height: SizeManager.s12.h),

                // Theme
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeManager.s16.w,
                    vertical: SizeManager.s8.h,
                  ),
                  decoration: BoxDecoration(
                    color: ColorManager.surface,
                    borderRadius: BorderRadius.circular(AppRadius.tile.r),
                    border: Border.all(color: ColorManager.divider),
                    boxShadow: ColorManager.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(SizeManager.s12.w),
                        decoration: BoxDecoration(
                          color: ColorManager.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(SizeManager.s12.r),
                        ),
                        child: Icon(
                          themeProvider.isDarkMode
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: ColorManager.primaryText,
                          size: SizeManager.s24.sp,
                        ),
                      ),
                      SizedBox(width: SizeManager.s16.w),
                      Expanded(
                        child: Text(
                          'Dark mode',
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (_) => themeProvider.toggleTheme(),
                        activeColor: ColorManager.primary,
                        activeTrackColor:
                            ColorManager.primary.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: SizeManager.s12.h),
                _buildMenuCard(
                  context,
                  icon: Icons.notifications_active_rounded,
                  title: 'Reminders',
                  subtitle: _reminderCount == null
                      ? 'Workouts, streaks, hydration and more'
                      : ReminderSummary.label(_reminderCount!),
                  color: Colors.orange,
                  onTap: () async {
                    await context.push(Routes.remindersRoute);
                    _loadReminderCount();
                  },
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
                  subtitle: 'Email ${ProfileData.supportEmail}',
                  color: Colors.blueAccent,
                  onTap: () async {
                    final Uri emailLaunchUri = ProfileData.supportMailUri();
                    final fallbackMessage =
                        'Could not open email client. Please email ${ProfileData.supportEmail}';
                    try {
                      final bool launched = await launchUrl(
                        emailLaunchUri,
                        mode: LaunchMode.externalApplication,
                      );
                      if (!launched && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(fallbackMessage)),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(fallbackMessage)),
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
                        borderRadius: BorderRadius.circular(AppRadius.button.r),
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
                      if (_version.isNotEmpty)
                        Text(
                          'Version $_version',
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

  String _getInitials(String firstName, String surname) =>
      ProfileData.initials(firstName, surname);

  Widget _buildAchievementsSection(StatisticsProvider statsProvider) {
    final unlocked = statsProvider.unlockedAchievements;
    // Grow with the user's text size so two-line titles are never clipped.
    final textScale =
        (MediaQuery.textScalerOf(context).scale(10) / 10).clamp(1.0, 1.6);
    return SizedBox(
      height: 90.h * textScale,
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
                          : ColorManager.textSecondary,
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

  Widget _buildStatsStrip(StatisticsProvider stats) {
    DateTime? joined;
    try {
      joined = FirebaseAuth.instance.currentUser?.metadata.creationTime;
    } catch (_) {
      joined = null;
    }
    final streak = stats.currentStreak;
    Widget tile(String value, String label) => Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
            decoration: BoxDecoration(
              color: ColorManager.surface,
              borderRadius: BorderRadius.circular(AppRadius.tile.r),
              border: Border.all(color: ColorManager.divider),
              boxShadow: ColorManager.cardShadow,
            ),
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  label,
                  style: TextStyle(
                    color: ColorManager.textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        );

    return Row(
      children: [
        tile(ProfileData.memberSinceLabel(joined), 'Member since'),
        SizedBox(width: 10.w),
        tile('${stats.totalWorkouts}', 'Workouts'),
        SizedBox(width: 10.w),
        tile(streak == 1 ? '1 day' : '$streak days', 'Streak'),
      ],
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
          boxShadow: isDangerous ? null : ColorManager.cardShadow,
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

    final parent = widget.parentContext;
    setState(() => _isLoading = true);

    // Close the confirmation dialog, then give it one beat to leave the tree
    // before the loading overlay opens on the same navigator.
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!parent.mounted) return;

    LoadingOverlay.show(parent, message: 'Logging out...');

    try {
      await FirebaseAuth.instance.signOut();
      // hide(null) uses the overlay's own stored context, so it still works
      // if the auth change has already rebuilt the page behind it.
      LoadingOverlay.hide(null);
      if (parent.mounted) {
        parent.go(Routes.boardingRoute);
      }
    } catch (e) {
      debugPrint('Logout failed: $e');
      LoadingOverlay.hide(null);
      if (parent.mounted) {
        ScaffoldMessenger.of(parent).showSnackBar(
          SnackBar(
            content: const Text('Could not log out. Please try again.'),
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
