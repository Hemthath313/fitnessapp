import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Model for an in-app notification entry
class _AppNotification {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final DateTime time;
  bool isRead;

  _AppNotification({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.time,
    this.isRead = false,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // In a real app, these would come from SharedPreferences or Firestore
  late List<_AppNotification> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = _buildDemoNotifications();
  }

  List<_AppNotification> _buildDemoNotifications() {
    final now = DateTime.now();
    return [
      _AppNotification(
        title: '🔥 Streak check-in',
        body:
            'A quick session today keeps your streak going. Even 15 minutes counts!',
        icon: Icons.local_fire_department_rounded,
        color: ColorManager.warning,
        time: now.subtract(const Duration(minutes: 23)),
      ),
      _AppNotification(
        title: '💧 Hydration Reminder',
        body: 'How\'s your water today? Log a glass to stay on target.',
        icon: Icons.water_drop_rounded,
        color: ColorManager.info,
        time: now.subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      _AppNotification(
        title: '🏆 Achievement Unlocked!',
        body: 'You earned the "First Flame" badge for logging your first workout!',
        icon: Icons.emoji_events_rounded,
        color: ColorManager.premium,
        time: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      _AppNotification(
        title: '📊 Weekly Summary',
        body:
            'Great week! You logged 4 workouts and burned 1,800 kcal. Keep pushing!',
        icon: Icons.bar_chart_rounded,
        color: ColorManager.primary,
        time: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
      _AppNotification(
        title: '💪 New Challenge Available',
        body:
            'The 30-Day Push-Up Challenge is now available. Start today and build serious strength!',
        icon: Icons.fitness_center_rounded,
        color: ColorManager.success,
        time: now.subtract(const Duration(days: 5)),
        isRead: true,
      ),
    ];
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _dismissNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return SafeArea(
      bottom: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 16.w, 8.h),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (unreadCount > 0)
                      Text(
                        '$unreadCount unread',
                        style: TextStyle(
                          color: ColorManager.primaryText,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                if (unreadCount > 0)
                  TextButton.icon(
                    onPressed: _markAllRead,
                    icon: Icon(Icons.done_all_rounded,
                        size: 16.sp, color: ColorManager.primaryText),
                    label: Text(
                      'Mark all read',
                      style: TextStyle(
                        color: ColorManager.primaryText,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          if (_notifications.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 64.sp,
                      color: ColorManager.textTertiary,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'All caught up!',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'No new notifications right now.',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms).scale(
                    begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _notifications.length,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                itemBuilder: (context, index) {
                  final notif = _notifications[index];
                  return Dismissible(
                    key: ValueKey('$index${notif.title}'),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _dismissNotification(index),
                    background: Container(
                      margin: EdgeInsets.only(bottom: 10.h),
                      padding: EdgeInsets.only(right: 20.w),
                      decoration: BoxDecoration(
                        color: ColorManager.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.delete_rounded,
                          color: ColorManager.errorText, size: 24.sp),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => notif.isRead = true);
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 10.h),
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: notif.isRead
                              ? ColorManager.surfaceLight
                              : notif.color.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: notif.isRead
                                ? ColorManager.divider
                                : notif.color.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon badge
                            Container(
                              width: 42.w,
                              height: 42.w,
                              decoration: BoxDecoration(
                                color: notif.color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(notif.icon,
                                  color: notif.color, size: 20.sp),
                            ),
                            SizedBox(width: 12.w),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notif.title,
                                          style: TextStyle(
                                            color: ColorManager.textPrimary,
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (!notif.isRead)
                                        Container(
                                          width: 8.w,
                                          height: 8.w,
                                          decoration: BoxDecoration(
                                            color: notif.color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    notif.body,
                                    style: TextStyle(
                                      color: ColorManager.textSecondary,
                                      fontSize: 12.sp,
                                      height: 1.4,
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    _formatTime(notif.time),
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
                      )
                          .animate(
                              delay: Duration(milliseconds: 60 * index))
                          .fadeIn(duration: 350.ms)
                          .slideX(begin: 0.05, end: 0),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
