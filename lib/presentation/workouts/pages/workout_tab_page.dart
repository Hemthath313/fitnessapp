import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/presentation/explore/explore_page.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/journal/widgets/weekly_schedule_widget.dart';
import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/card_size_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/presentation/custom_workouts/day_workout_session_page.dart';
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

    return Scaffold(
      backgroundColor: ColorManager.background,
      body: SafeArea(
        bottom: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title (Home already greets the user by name).
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
              child: Text(
                'Workouts',
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // One main action: start a live workout. Logging after the fact
            // is a quiet secondary link, so only one blue button competes.
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: ElevatedButton.icon(
                key: const Key('workouts_start_workout_button'),
                onPressed: () => DayWorkoutSessionPage.startQuickWorkout(context),
                icon: Icon(Icons.play_arrow_rounded, size: 22.sp, color: ColorManager.onMint),
                label: Text('Start workout',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  foregroundColor: ColorManager.onMint,
                  elevation: 0,
                  minimumSize: Size.fromHeight(50.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button.r),
                  ),
                ),
              ),
            ),
            Center(
              child: TextButton(
                key: const Key('workouts_log_past_button'),
                onPressed: () => context.push(Routes.workoutLogRoute),
                child: Text.rich(
                  TextSpan(
                    text: 'or ',
                    style: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp),
                    children: [
                      TextSpan(
                        text: 'log a past workout',
                        style: TextStyle(
                          color: ColorManager.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 4.h),

            // My Plan / Explore Segmented Sub-tab bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                height: 42.h,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  // Quiet segmented control: grey track, no blue, so it never
                  // looks like a second primary button.
                  color: ColorManager.surfaceDark,
                  borderRadius: BorderRadius.circular(AppRadius.card.r),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: ColorManager.surfaceLight,
                    borderRadius: BorderRadius.circular(AppRadius.card.r - 3),
                    boxShadow: ColorManager.cardShadow,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: ColorManager.textPrimary,
                  unselectedLabelColor: ColorManager.textSecondary,
                  labelStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'My Plan'),
                    Tab(text: 'Explore'),
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
                    color: ColorManager.primaryText,
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
              childAspectRatio: AppCardSize.gridAspectRatio,
              crossAxisSpacing: AppCardSize.gridSpacing,
              mainAxisSpacing: AppCardSize.gridSpacing,
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
                    boxShadow: ColorManager.cardShadow,
                    borderRadius: BorderRadius.circular(AppRadius.tile.r),
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
                            color: ColorManager.primaryText,
                            size: 26.sp,
                          ),
                        )
                      else
                        Icon(
                          cat['icon'] as IconData,
                          color: ColorManager.primaryText,
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
