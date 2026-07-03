import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/journal/widgets/weekly_schedule_widget.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class WorkoutTabPage extends StatefulWidget {
  const WorkoutTabPage({super.key});

  @override
  State<WorkoutTabPage> createState() => _WorkoutTabPageState();
}

class _WorkoutTabPageState extends State<WorkoutTabPage> {
  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);
    
    final userData = homeProvider.userData;
    final firstName = userData['first name'] ?? 'User';

    final categories = [
      {'label': 'Chest', 'icon': Icons.fitness_center_rounded, 'route': Routes.chestExerciseRoute},
      {'label': 'Back', 'icon': Icons.accessibility_new_rounded, 'route': Routes.backRoute},
      {'label': 'Legs', 'icon': Icons.directions_run_rounded, 'route': Routes.legsRoute},
      {'label': 'Shoulders', 'icon': Icons.shield_rounded, 'route': Routes.shouldersRoute},
      {'label': 'Arms', 'icon': Icons.sports_gymnastics_rounded, 'route': Routes.bicepsRoute},
      {'label': 'Abs', 'icon': Icons.grid_view_rounded, 'route': Routes.absRoute},
    ];

    return Scaffold(
      backgroundColor: ColorManager.background,
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $firstName 👋',
                        style: TextStyle(
                          color: ColorManager.white,
                          fontSize: SizeManager.s24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Ready to crush your goals today?',
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: SizeManager.s14.sp,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push(Routes.aiChatRoute),
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: ColorManager.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: ColorManager.primary.withOpacity(0.2)),
                      ),
                      child: Icon(Icons.auto_awesome_rounded, color: ColorManager.primary, size: 24.sp),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 28.h),

              // Categories Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Categories',
                    style: TextStyle(
                      color: ColorManager.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(Routes.bodypartsPage),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        color: ColorManager.primary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                ),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return InkWell(
                    onTap: () => context.push(cat['route'] as String),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      decoration: BoxDecoration(
                        color: ColorManager.surface,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: ColorManager.divider),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            color: ColorManager.primary,
                            size: 26.sp,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            cat['label'] as String,
                            style: TextStyle(
                              color: ColorManager.textPrimary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 28.h),

              // AI Weekly Schedule Section
              const WeeklyScheduleWidget(),
              SizedBox(height: 80.h), // Safe spacing for bottom navigation
            ],
          ),
        ),
      ),
    );
  }
}
