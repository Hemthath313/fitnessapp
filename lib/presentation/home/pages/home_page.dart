import 'package:fitness_app/presentation/banner_ads/banner_ad_service.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/statistics_provider.dart';
import 'package:fitness_app/presentation/home/widgets/achievements_widget.dart';
import 'package:fitness_app/presentation/home/widgets/dashboard_ai_workout_generator_card.dart';
import 'package:fitness_app/presentation/home/widgets/fitness_data_widget.dart';
import 'package:fitness_app/presentation/home/widgets/home_ai_routine_card.dart';
import 'package:fitness_app/presentation/home/widgets/quick_actions_widget.dart';
import 'package:fitness_app/presentation/home/widgets/recent_prs_widget.dart';
import 'package:fitness_app/presentation/home/widgets/streak_calendar_widget.dart';
import 'package:fitness_app/presentation/home/widgets/today_health_snapshot_widget.dart';
import 'package:fitness_app/presentation/transformation_plans/widgets/dashboard_challenge_section.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  final bool legacyDetailedView;

  const HomePage({
    super.key,
    this.legacyDetailedView = false,
  });

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
  Widget build(BuildContext context) {
    if (widget.legacyDetailedView) {
      return _buildLegacyLayout();
    }
    return _buildOptionAFocusedCompanionLayout();
  }

  /// Option A: Focused Daily Companion Dashboard
  Widget _buildOptionAFocusedCompanionLayout() {
    return SafeArea(
      bottom: true,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: SizeManager.s8.h),

            // 1. Single Dynamic Workout Hero — Answers "What do I need to do today?"
            const HomeAiRoutineCard(),
            SizedBox(height: SizeManager.s12.h),

            // 2. Compact Quick Actions — Fast utilities: Water, Log Meal, Log Lift, AI Plan
            const QuickActionsWidget(),
            SizedBox(height: SizeManager.s12.h),

            // 3. Today's Health Snapshot — Calories consumed vs valid target & Water vs goal
            const TodayHealthSnapshotWidget(),
            SizedBox(height: SizeManager.s16.h),

            // 4. Discovery Shelf — Transformation Challenges & Technique Hub
            const DashboardChallengeSection(),
            SizedBox(height: SizeManager.s16.h),

            const PremiumAwareBannerAd(pageName: 'home', bottomMargin: 60.0),
            SizedBox(height: SizeManager.s16.h),
          ],
        ),
      ),
    );
  }

  /// Legacy 10-component layout for backward compatibility testing
  Widget _buildLegacyLayout() {
    return SafeArea(
      bottom: true,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: SizeManager.s8.h),

            // 1. Next Workout Hero Banner
            const HomeAiRoutineCard(),
            SizedBox(height: SizeManager.s12.h),

            // 1b. AI Workout Generator Companion
            const DashboardAiWorkoutGeneratorCard(),

            // 2. Weekly Consistency Streak Calendar
            const StreakCalendarWidget(),
            SizedBox(height: SizeManager.s12.h),

            // 3. Quick Actions
            const QuickActionsWidget(),
            SizedBox(height: SizeManager.s16.h),

            // 4. Fitness Data
            const FitnessDataWidget(),
            SizedBox(height: SizeManager.s16.h),

            // 5. Recent PRs
            const RecentPRsWidget(),
            SizedBox(height: SizeManager.s16.h),

            // 6. Transformation Challenges
            const DashboardChallengeSection(),
            SizedBox(height: SizeManager.s16.h),

            const PremiumAwareBannerAd(pageName: 'home', bottomMargin: 60.0),
            SizedBox(height: SizeManager.s16.h),
          ],
        ),
      ),
    );
  }
}
