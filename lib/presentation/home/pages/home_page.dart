import 'package:fitness_app/presentation/banner_ads/banner_ad_service.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/achievements_widget.dart';
import 'package:fitness_app/presentation/home/widgets/home_ai_routine_card.dart';
import 'package:fitness_app/presentation/home/widgets/next_badge_card.dart';
import 'package:fitness_app/presentation/home/widgets/quick_actions_widget.dart';
import 'package:fitness_app/presentation/home/widgets/today_health_snapshot_widget.dart';
import 'package:fitness_app/presentation/home/widgets/weekly_activity_bars.dart';
import 'package:fitness_app/presentation/home/widgets/weekly_recap_card.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/dashboard_challenge_section.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    Provider.of<ConsumptionProvider>(context, listen: false)
        .getConsumedCalories();
    Provider.of<StatisticsProvider>(context, listen: false).getWeeklyStats();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForNewAchievements();
    });
  }

  /// Pull-to-refresh: reloads today's calories and water, the weekly stats and
  /// the profile data behind the snapshot. One failing source (for example
  /// offline) never blocks the others, and the spinner always completes.
  Future<void> refresh() async {
    final consumption =
        Provider.of<ConsumptionProvider>(context, listen: false);
    final stats = Provider.of<StatisticsProvider>(context, listen: false);
    final home = Provider.of<HomeProvider>(context, listen: false);

    Future<void> safely(Future<dynamic> Function() load) async {
      try {
        await load();
      } catch (e) {
        debugPrint('Home refresh skipped a source: $e');
      }
    }

    await Future.wait([
      safely(consumption.getConsumedCalories),
      safely(consumption.fetchAndSetWater),
      safely(stats.getWeeklyStats),
      safely(home.fetchUserData),
    ]);
    if (mounted) _checkForNewAchievements();
  }

  void _checkForNewAchievements() {
    final stats = Provider.of<StatisticsProvider>(context, listen: false);
    final newlyUnlocked = stats.consumeNewlyUnlocked();
    for (final id in newlyUnlocked) {
      try {
        final def = allAchievements.firstWhere((a) => a.id == id);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) showAchievementUnlockDialog(context, def);
        });
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) => _buildFocusedCompanionLayout();

  Widget _sectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 10.h),
      child: Text(
        title,
        style: TextStyle(
          color: ColorManager.textPrimary,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Focused Daily Companion Dashboard
  Widget _buildFocusedCompanionLayout() {
    return SafeArea(
      bottom: true,
      child: RefreshIndicator(
        color: ColorManager.primary,
        backgroundColor: ColorManager.surface,
        onRefresh: refresh,
        child: SingleChildScrollView(
          // Always scrollable so the pull gesture works even when the content
          // happens to fit on a tall screen.
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: SizeManager.s8.h),

              // 1. Today's snapshot — progress rings (calories & water)
              const TodayHealthSnapshotWidget(),
              SizedBox(height: SizeManager.s12.h),

              // 2. Workout plan — the single hero answering "what do I do today?"
              _sectionHeader('Workout Plan'),
              const HomeAiRoutineCard(),
              SizedBox(height: SizeManager.s8.h),

              // 2a. Sunday/Monday week in review (renders nothing other days)
              const WeeklyRecapCard(),

              // 2b. Next badge — a near goal to pull the user back tomorrow.
              // (The streak itself stays in the app-bar chip: one indicator.)
              const NextBadgeCard(),
              SizedBox(height: SizeManager.s8.h),

              // 3. Weekly activity bars — progress at a glance
              const WeeklyActivityBars(),
              SizedBox(height: SizeManager.s8.h),

              // 4. Compact Quick Actions — Log Meal, Log Lift, AI Plan
              const QuickActionsWidget(),
              SizedBox(height: SizeManager.s16.h),

              // 5. Discovery Shelf — Transformation Challenges & Technique Hub
              const DashboardChallengeSection(),
              SizedBox(height: SizeManager.s16.h),

              const PremiumAwareBannerAd(pageName: 'home', bottomMargin: 60.0),
              SizedBox(height: SizeManager.s16.h),
            ],
          ),
        ),
      ),
    );
  }
}
