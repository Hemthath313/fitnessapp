import 'package:fitness_app/model/workout_log.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/services/workout_export_service.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        title: const Text('Workout History', style: TextStyle(color: Colors.white)),
        backgroundColor: ColorManager.background,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: ColorManager.primary),
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
              final log = logs[index];
              return Card(
                color: ColorManager.surface,
                margin: EdgeInsets.only(bottom: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                child: ExpansionTile(
                  iconColor: ColorManager.primary,
                  collapsedIconColor: Colors.white,
                  title: Text(log.exerciseName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${DateFormat('MMM dd, yyyy').format(log.date)} • ${log.category}',
                    style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...log.sets.asMap().entries.map((entry) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.h),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Set ${entry.key + 1}', style: const TextStyle(color: Colors.white70)),
                                  Text('${entry.value.reps} reps @ ${entry.value.weight} kg', style: const TextStyle(color: Colors.white)),
                                ],
                              ),
                            );
                          }),
                          if (log.notes != null && log.notes!.isNotEmpty) ...[
                            const Divider(color: Colors.white10),
                            Text('Notes:', style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp)),
                            Text(log.notes!, style: const TextStyle(color: Colors.white70)),
                          ],
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => logService.deleteLog(log.id),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.workoutLogRoute),
        backgroundColor: ColorManager.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  void _exportLogs(BuildContext context, WorkoutLogService logService) async {
    // Collect all logs once
    final logs = await logService.getLogs().first;
    final csv = WorkoutExportService.generateCSV(logs);
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: ColorManager.surface,
          title: const Text('Export Logs (CSV)', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Text(csv, style: TextStyle(color: ColorManager.textSecondary, fontSize: 10.sp, fontFamily: 'monospace')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: csv));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV copied to clipboard')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: ColorManager.primary),
              child: const Text('Copy to Clipboard', style: TextStyle(color: Colors.black)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 10.w),
            Text('Pro Feature', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Exporting workout logs to CSV is a Pro feature. Upgrade now to download your progress!',
          style: TextStyle(color: ColorManager.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Not Now', style: TextStyle(color: ColorManager.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(Routes.premiumScreen);
            },
            style: ElevatedButton.styleFrom(backgroundColor: ColorManager.primary),
            child: Text('Unlock Pro', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
