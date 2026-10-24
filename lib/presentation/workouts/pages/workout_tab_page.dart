import 'package:fitness_app/presentation/explore/explore_page.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/journal/widgets/weekly_schedule_widget.dart';
import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class WorkoutTabPage extends StatefulWidget {
  const WorkoutTabPage({super.key});

  static const List<Map<String, dynamic>> exerciseLibraryCategories = [
    {
      'label': 'Chest',
      'icon': Icons.fitness_center_rounded,
      'image': ImageManager.anatomyChest,
      'route': Routes.chestExerciseRoute,
    },
    {
      'label': 'Back',
      'icon': Icons.rowing_rounded,
      'image': ImageManager.anatomyBack,
      'route': Routes.backRoute,
    },
    {
      'label': 'Legs',
      'icon': Icons.directions_run_rounded,
      'image': ImageManager.anatomyLegs,
      'route': Routes.legsRoute,
    },
    {
      'label': 'Shoulders',
      'icon': Icons.accessibility_new_rounded,
      'image': ImageManager.anatomyShoulders,
      'route': Routes.shouldersRoute,
    },
    {
      'label': 'Biceps',
      'icon': Icons.sports_mma_rounded,
      'image': ImageManager.anatomyBiceps,
      'route': Routes.bicepsRoute,
    },
    {
      'label': 'Triceps',
      'icon': Icons.sports_gymnastics_rounded,
      'image': ImageManager.anatomyTriceps,
      'route': Routes.tricepsRoute,
    },
    {
      'label': 'Abs',
      'icon': Icons.table_rows_rounded,
      'image': ImageManager.anatomyAbs,
      'route': Routes.absRoute,
    },
    {
      'label': 'Cardio',
      'icon': Icons.directions_bike_rounded,
      'image': ImageManager.anatomyCardio,
      'route': Routes.cardioRoute,
    },
  ];

  @override
  State<WorkoutTabPage> createState() => _WorkoutTabPageState();
}

class _WorkoutTabPageState extends State<WorkoutTabPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<Map<String, dynamic>> _categories =
      WorkoutTabPage.exerciseLibraryCategories;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);
    final userData = homeProvider.userData;
    final firstName = userData['first name'] ?? 'User';

    return Scaffold(
      backgroundColor: ColorManager.background,
      body: SafeArea(
        bottom: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
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
                  ),
                  GestureDetector(
                    onTap: () => context.push(Routes.workoutGeneratorRoute),
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: ColorManager.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: ColorManager.primary.withValues(alpha: 0.2)),
                      ),
                      child: Icon(Icons.auto_awesome_rounded, color: ColorManager.primary, size: 24.sp),
                    ),
                  ),
                ],
              ),
            ),

            // My Plan / Explore Segmented Sub-tab bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                height: 48.h,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: ColorManager.surface,
                  borderRadius: BorderRadius.circular(26.r),
                  border: Border.all(color: ColorManager.divider),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: ColorManager.primary,
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: ColorManager.textSecondary,
                  labelStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('My Plan'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.explore_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Explore'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _MyPlanTabView(categories: _categories),
                  const ExploreWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyPlanTabView extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  const _MyPlanTabView({required this.categories});

  @override
  State<_MyPlanTabView> createState() => _MyPlanTabViewState();
}

class _MyPlanTabViewState extends State<_MyPlanTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Weekly Schedule Section (Prominently at the Top)
          const WeeklyScheduleWidget(),
          SizedBox(height: 28.h),

          // Exercise Library Categories
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercise Library',
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
            itemCount: widget.categories.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.05,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
            ),
            itemBuilder: (context, index) {
              final cat = widget.categories[index];
              final imageAsset = cat['image'] as String?;
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
                      if (imageAsset != null)
                        Image.asset(
                          imageAsset,
                          width: 44.w,
                          height: 44.h,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            cat['icon'] as IconData,
                            color: ColorManager.primary,
                            size: 26.sp,
                          ),
                        )
                      else
                        Icon(
                          cat['icon'] as IconData,
                          color: ColorManager.primary,
                          size: 26.sp,
                        ),
                      SizedBox(height: 6.h),
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
          SizedBox(height: 80.h), // Safe spacing for bottom navigation
        ],
      ),
    );
  }
}
