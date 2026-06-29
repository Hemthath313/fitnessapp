import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/services/workout_export_service.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class WorkoutHistoryScreen extends StatelessWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logService = WorkoutLogService();
    final subProvider = Provider.of<SubscriptionProvider>(context);

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text('Workout History', style: TextStyle(color: ColorManager.textPrimary)),
        backgroundColor: ColorManager.background,
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.file_download, color: ColorManager.primary),
            onPressed: () {
              if (subProvider.isPremium) {
                _exportLogs(context, logService);
              } else {
                _showProFeatureDialog(context);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<WorkoutLog>>(
        stream: logService.getLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64.sp, color: ColorManager.textTertiary),
                  SizedBox(height: 16.h),
                  Text('No workout logs yet', style: TextStyle(color: ColorManager.textTertiary, fontSize: 18.sp)),
                ],
              ),
            );
          }

          final logs = snapshot.data!;
          return ListView.builder(
            itemCount: logs.length,
            padding: EdgeInsets.all(16.w),
            itemBuilder: (context, index) {
              return WorkoutHistoryCard(
                log: logs[index],
                logService: logService,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.workoutLogRoute),
        backgroundColor: ColorManager.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _exportLogs(BuildContext context, WorkoutLogService logService) async {
    final logs = await logService.getLogs().first;
    final csv = WorkoutExportService.generateCSV(logs);
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: ColorManager.surface,
          title: Text('Export Complete', style: TextStyle(color: ColorManager.textPrimary)),
          content: Text('CSV successfully generated with ${logs.length} entries.', style: TextStyle(color: ColorManager.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showProFeatureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorManager.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 24.sp),
            SizedBox(width: 8.w),
            Text('Pro Feature', style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Exporting workout history as CSV is a Premium feature. Upgrade to unlock full access!',
          style: TextStyle(color: ColorManager.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(Routes.premiumScreen);
            },
            style: ElevatedButton.styleFrom(backgroundColor: ColorManager.primary),
            child: const Text('Go Premium', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class WorkoutHistoryCard extends StatefulWidget {
  final WorkoutLog log;
  final WorkoutLogService logService;

  const WorkoutHistoryCard({
    super.key,
    required this.log,
    required this.logService,
  });

  @override
  State<WorkoutHistoryCard> createState() => _WorkoutHistoryCardState();
}

class _WorkoutHistoryCardState extends State<WorkoutHistoryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    return Card(
      color: ColorManager.surface,
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: ColorManager.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Tappable to expand/collapse)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.exerciseName,
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${DateFormat('MMM dd, yyyy').format(log.date)} • ${log.category}',
                          style: TextStyle(
                            color: ColorManager.textSecondary,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.analytics_outlined, color: ColorManager.primary, size: 22.sp),
                    tooltip: 'View Progression',
                    onPressed: () => context.push(
                      '${Routes.exerciseTracker}?exerciseName=${Uri.encodeComponent(log.exerciseName)}',
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: ColorManager.textSecondary,
                    size: 24.sp,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sets list
                  ...log.sets.asMap().entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10.r,
                                backgroundColor: ColorManager.primary.withOpacity(0.15),
                                child: Text(
                                  '${entry.key + 1}',
                                  style: TextStyle(
                                    color: ColorManager.primary,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                'Set ${entry.key + 1}',
                                style: TextStyle(
                                  color: ColorManager.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${entry.value.reps} reps @ ${entry.value.weight} kg',
                            style: TextStyle(
                              color: ColorManager.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (log.notes != null && log.notes!.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Divider(color: ColorManager.divider),
                    Text(
                      'Notes:',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      log.notes!,
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _confirmDelete(context, log.id),
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                        label: const Text(
                          'Delete Log',
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String logId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ColorManager.background,
        title: Text('Delete Log?', style: TextStyle(color: ColorManager.textPrimary)),
        content: const Text(
          'Are you sure you want to delete this workout log permanently?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      widget.logService.deleteLog(logId);
    }
  }
}
