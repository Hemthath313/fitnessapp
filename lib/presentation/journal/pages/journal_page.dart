import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/workout_logs/workout_history_screen.dart';
import 'package:fitness_app/services/workout_log_service.dart';
import 'package:fitness_app/presentation/banner_ads/banner_ad_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/data/warmup_data.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  WarmupRoutine? _selectedWarmup;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(SizeManager.s16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My AI Hub',
              style: TextStyle(
                color: ColorManager.white,
                fontSize: SizeManager.s24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: SizeManager.s4.h),
            Text(
              'Hyper-personalized fitness intelligence',
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: SizeManager.s14.sp,
              ),
            ),
            SizedBox(height: SizeManager.s24.h),

            if (!Provider.of<SubscriptionProvider>(context).isPremium)
              _buildPremiumUpgradeCard(),

            SizedBox(height: SizeManager.s20.h),
            _buildAIInsightCard(),
            SizedBox(height: SizeManager.s20.h),
            _buildAICoachCard(),
            SizedBox(height: SizeManager.s20.h),

            // Tools Section
            Text(
              'Smart Tools',
              style: TextStyle(
                color: ColorManager.white,
                fontSize: SizeManager.s18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: SizeManager.s16.h),

            // Smart Warmup Generator Card
            _buildSmartWarmupGenerator(),

            SizedBox(height: SizeManager.s20.h),

            // Navigation Cards
            Row(
              children: [
                Expanded(
                  child: _buildNavigationCard(
                    title: 'Workout History',
                    subtitle: 'Review your progress',
                    icon: Icons.history_toggle_off_rounded,
                    color: Colors.teal,
                    onTap: () => context.push(Routes.workoutHistoryRoute),
                  ),
                ),
                SizedBox(width: SizeManager.s12.w),
                Expanded(
                  child: _buildNavigationCard(
                    title: 'Transformation',
                    subtitle: '30-Day Progress',
                    icon: Icons.auto_graph_rounded,
                    color: Colors.blue,
                    onTap: () => context.push(Routes.sixPackChallengeRoute),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: SizeManager.s20.h),
            _buildNutritionAnalysisCard(),
            SizedBox(height: SizeManager.s40.h),
            const PremiumAwareBannerAd(pageName: 'journal', bottomMargin: 60.0),
            SizedBox(height: SizeManager.s16.h),
          ],
        ),
      ),
    );
  }

  // ... (keep previous methods like _buildPremiumUpgradeCard, _buildAIInsightCard, _buildNutritionAnalysisCard)

  Widget _buildSmartWarmupGenerator() {
    return Container(
      padding: EdgeInsets.all(SizeManager.s20.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(SizeManager.s20.r),
        border: Border.all(
          color: ColorManager.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_run, color: Colors.orangeAccent),
              SizedBox(width: SizeManager.s8.w),
              Text(
                'Smart Warmup Generator',
                style: TextStyle(
                  color: ColorManager.white,
                  fontSize: SizeManager.s18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeManager.s8.h),
          Text(
            'Target specific muscle groups with dynamic mobility routines.',
            style: TextStyle(color: ColorManager.white70, fontSize: SizeManager.s12.sp),
          ),
          SizedBox(height: SizeManager.s20.h),

          // Dropdown Input
           Container(
             padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
             decoration: BoxDecoration(
               color: ColorManager.background,
               borderRadius: BorderRadius.circular(12.r),
               border: Border.all(color: Colors.white10),
             ),
             child: DropdownButtonHideUnderline(
               child: DropdownButton<WarmupRoutine>(
                 value: _selectedWarmup,
                 hint: Text('Select Target (e.g. Leg Day)', style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
                 dropdownColor: ColorManager.background,
                 isExpanded: true,
                 icon: Icon(Icons.keyboard_arrow_down, color: ColorManager.primary),
                 style: TextStyle(color: Colors.white, fontSize: 14.sp),
                 items: WarmupData.routines.map((WarmupRoutine routine) {
                   return DropdownMenuItem<WarmupRoutine>(
                     value: routine,
                     child: Text(routine.target),
                   );
                 }).toList(),
                 onChanged: (newValue) => setState(() => _selectedWarmup = newValue),
               ),
             ),
          ),

          if (_selectedWarmup != null) ...[
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Routine:',
                  style: TextStyle(color: ColorManager.primary, fontSize: 14.sp, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _selectedWarmup = null),
                  icon: Icon(Icons.refresh, size: 14.sp, color: Colors.white70),
                  label: Text('Reset', style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ..._selectedWarmup!.exercises.map((exercise) => _buildWarmupItem(exercise)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildWarmupItem(WarmupExercise exercise) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.timer_outlined, color: Colors.orangeAccent, size: 16.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
                    ),
                    Text(
                      exercise.durationOrReps,
                      style: TextStyle(color: ColorManager.primary, fontWeight: FontWeight.bold, fontSize: 12.sp),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  exercise.description,
                  style: TextStyle(color: Colors.white60, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumUpgradeCard() {
    return Container(
      margin: EdgeInsets.only(top: SizeManager.s12.h),
      padding: EdgeInsets.all(SizeManager.s16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorManager.secondary.withOpacity(0.8),
            ColorManager.secondaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(SizeManager.s20.r),
        boxShadow: [
          BoxShadow(
            color: ColorManager.secondary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upgrade to Pro!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: SizeManager.s18.sp,
                  ),
                ),
                SizedBox(height: SizeManager.s4.h),
                Text(
                  'Ads-free, AI Coach, Pro Tools & More.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: SizeManager.s12.sp,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push(Routes.premiumScreen),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ColorManager.secondary,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Get Pro',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightCard() {
    return Container(
      padding: EdgeInsets.all(SizeManager.s20.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(SizeManager.s20.r),
        border: Border.all(
          color: ColorManager.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorManager.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.psychology, color: ColorManager.primary, size: 22.sp),
              ),
              SizedBox(width: SizeManager.s12.w),
              Text(
                'AI Daily Insight',
                style: TextStyle(
                  color: ColorManager.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: SizeManager.s16.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeManager.s16.h),
          Text(
            'Muscle recovery is peak between 7-9 hours of sleep. Gemini says: Rest is your secret weapon! Tracking your consistency leads to 2x faster results.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: SizeManager.s14.sp,
              height: 1.4,
            ),
          ),
          SizedBox(height: SizeManager.s12.h),
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber, size: 14.sp),
              SizedBox(width: 4.w),
              Text(
                'AI Analysis based on your activity',
                style: TextStyle(
                  color: ColorManager.textTertiary,
                  fontSize: 10.sp,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionAnalysisCard() {
    final isPremium = Provider.of<SubscriptionProvider>(context).isPremium;

    return Container(
      padding: EdgeInsets.all(SizeManager.s20.w),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(SizeManager.s20.r),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu, color: Colors.orange),
              SizedBox(width: SizeManager.s8.w),
              Text(
                'Smart Nutrition Analysis',
                style: TextStyle(
                  color: ColorManager.white,
                  fontSize: SizeManager.s18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (!isPremium)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: SizeManager.s12.h),
          Text(
            isPremium
                ? 'Your macro distribution is optimal for muscle gain. Try increasing protein by 10g in your morning meal.'
                : 'Unlock intelligent meal analysis and macro tracking suggestions.',
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: SizeManager.s12.sp,
            ),
          ),
          if (!isPremium) ...[
            SizedBox(height: SizeManager.s16.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push(Routes.premiumScreen),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.orange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Analyze My Nutrition',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }



  Widget _buildNavigationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SizeManager.s16.r),
      child: Container(
        padding: EdgeInsets.all(SizeManager.s16.w),
        height: SizeManager.s150.h,
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(SizeManager.s16.r),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(SizeManager.s10.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: SizeManager.s28.sp),
            ),
            SizedBox(height: SizeManager.s12.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorManager.white,
                fontSize: SizeManager.s14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: SizeManager.s4.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorManager.white70,
                fontSize: SizeManager.s11.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAICoachCard() {
    final sub = Provider.of<SubscriptionProvider>(context);
    final isPremium = sub.isPremium;

    return Container(
      padding: EdgeInsets.all(SizeManager.s20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorManager.surface,
            isPremium ? Colors.purple.withOpacity(0.1) : ColorManager.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(SizeManager.s20.r),
        border: Border.all(
          color: isPremium
              ? Colors.purple.withOpacity(0.3)
              : ColorManager.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  color: isPremium ? Colors.purpleAccent : ColorManager.primary),
              SizedBox(width: SizeManager.s8.w),
              Text(
                'AI Personal Coach',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: SizeManager.s18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (!isPremium)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'PREMIUM',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          SizedBox(height: SizeManager.s8.h),
          Text(
            isPremium
                ? 'Your coach is ready! Ask for meal ideas, exercise tips, and more.'
                : 'Unlock your AI Coach for 24/7 fitness and nutrition guidance.',
            style: TextStyle(
                color: ColorManager.white70, fontSize: SizeManager.s12.sp),
          ),
          SizedBox(height: SizeManager.s20.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (isPremium) {
                  context.push(Routes.aiChatRoute);
                } else {
                  context.push(Routes.premiumScreen);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isPremium ? Colors.purpleAccent : ColorManager.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SizeManager.s12.r)),
              ),
              child: Text(
                isPremium ? 'Chat Now' : 'Unlock Now',
                style: TextStyle(
                    color: isPremium ? Colors.white : ColorManager.darkGrey,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
