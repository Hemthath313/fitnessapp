import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/config/legal_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// Pro screen: what you get (Free vs Pro), then one clear plan choice.
///
/// Layout, top to bottom:
///  1. Short headline that speaks to the user's goal.
///  2. Free vs Pro comparison table.
///  3. Plan cards (radio style). Yearly is pre-selected and shows the
///     monthly equivalent and the saving when store prices allow it.
///  4. One "Continue" button for the selected plan, Restore, legal text.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  _PremiumScreenState createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  String? _selectedPlanId;
  bool _buying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sub = Provider.of<SubscriptionProvider>(context, listen: false);
      if (!sub.isPremium) {
        sub.restorePurchases();
      }
    });
  }

  // ── Copy ──────────────────────────────────────────────────────────────

  /// Headline subtitle tailored to the goal saved at onboarding.
  String _goalLine(BuildContext context) {
    final home = Provider.of<HomeProvider?>(context, listen: false);
    final goal = (home?.userData['goal'] ?? '').toString().toLowerCase();
    if (goal.contains('lose') || goal.contains('cut') || goal.contains('fat')) {
      return 'Meal plans, calorie tracking and a guided fat-loss programme to keep you on track.';
    }
    if (goal.contains('gain') || goal.contains('bulk') || goal.contains('muscle')) {
      return 'Structured muscle-building programmes, bulking meal plans and strength analytics.';
    }
    return 'Personal plans, full history, meal tracking and no ads, so every workout counts.';
  }

  static const List<_CompareRow> _rows = [
    _CompareRow('Log workouts and track your streak', free: '✓', pro: '✓'),
    _CompareRow('Streak freezes', free: '1 / month', pro: '3 / month'),
    _CompareRow('Plan builder and pro splits (PPL, Upper/Lower)', free: 'Basic', pro: 'Unlimited'),
    _CompareRow('Transformation programmes', free: '—', pro: '✓'),
    _CompareRow('Meal plans and calorie tracking', free: '—', pro: '✓'),
    _CompareRow('Export history to CSV', free: '—', pro: '✓'),
    _CompareRow('Ads', free: 'Yes', pro: 'None'),
  ];

  // ── Plans ─────────────────────────────────────────────────────────────

  List<SubscriptionPlan> _getSortedPlans(List<SubscriptionPlan> plans) {
    final list = List<SubscriptionPlan>.from(plans);
    list.sort((a, b) {
      int getRank(SubscriptionPlan plan) {
        if (plan.isLifetime ||
            plan.id.toLowerCase().contains('lifetime') ||
            plan.title.toLowerCase().contains('lifetime')) {
          return 2;
        }
        if (plan.isYearly ||
            plan.id.toLowerCase().contains('yearly') ||
            plan.title.toLowerCase().contains('yearly') ||
            plan.title.toLowerCase().contains('annual')) {
          return 1;
        }
        return 0; // monthly
      }

      return getRank(a).compareTo(getRank(b));
    });
    return list;
  }

  SubscriptionPlan? _selected(List<SubscriptionPlan> plans) {
    if (plans.isEmpty) return null;
    for (final p in plans) {
      if (p.id == _selectedPlanId) return p;
    }
    // Default: yearly, else the first plan.
    return plans.firstWhere((p) => p.isYearly, orElse: () => plans.first);
  }

  /// Monthly equivalent and saving for the yearly plan, when the store gives
  /// us usable raw prices. Returns null when the numbers look unreliable.
  ({String perMonth, int savePercent})? _yearlyMaths(
      SubscriptionPlan yearly, List<SubscriptionPlan> plans) {
    SubscriptionPlan? monthly;
    for (final p in plans) {
      if (p.isMonthly) monthly = p;
    }
    if (monthly == null) return null;
    final y = yearly.productDetails.rawPrice;
    final m = monthly.productDetails.rawPrice;
    if (y <= 0 || m <= 0) return null;
    // Guard against both plans reporting the same base price.
    if (y <= m * 3 || y >= m * 12) return null;
    final save = ((1 - y / (m * 12)) * 100).round();
    final symbol = yearly.productDetails.currencySymbol;
    return (perMonth: '$symbol${(y / 12).toStringAsFixed(2)}', savePercent: save);
  }

  Future<void> _buy(SubscriptionProvider provider, SubscriptionPlan plan) async {
    if (_buying) return;
    setState(() => _buying = true);
    try {
      await provider.buyPlan(plan);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Couldn't complete the purchase: ${e.toString().replaceAll('Exception:', '').trim()}",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: ColorManager.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _buying = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final plans = _getSortedPlans(subProvider.plans);
    final selected = _selected(plans);

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
        title: Text('Gym Buddy Pro', style: TextStyle(color: ColorManager.textPrimary)),
      ),
      bottomNavigationBar: (subProvider.isPremium || selected == null)
          ? null
          : SafeArea(
              minimum: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
              child: SizedBox(
                height: 52.h,
                child: ElevatedButton(
                  key: const Key('premium_continue_button'),
                  onPressed: subProvider.isLoading || _buying
                      ? null
                      : () => _buy(subProvider, selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.primary,
                    foregroundColor: ColorManager.onMint,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button.r),
                    ),
                  ),
                  child: _buying
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          selected.isLifetime
                              ? 'Get lifetime access'
                              : (selected.isYearly
                                  ? 'Continue with yearly'
                                  : 'Continue with monthly'),
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
      body: subProvider.isLoading && plans.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Headline
                  Text(
                    'Train smarter with Pro',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    _goalLine(context),
                    style: TextStyle(fontSize: 14.sp, color: ColorManager.textSecondary, height: 1.4),
                  ),
                  SizedBox(height: SizeManager.s20.h),

                  // 2. Free vs Pro
                  _buildComparison(),
                  SizedBox(height: SizeManager.s24.h),

                  // 3. Plans
                  if (subProvider.isPremium)
                    _buildAlreadyPro()
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Choose your plan',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: ColorManager.textPrimary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: subProvider.isLoading
                              ? null
                              : () => subProvider.restorePurchases(),
                          child: Text(
                            'Restore',
                            style: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp),
                          ),
                        ),
                      ],
                    ),
                    if (subProvider.error != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        subProvider.error!,
                        style: TextStyle(color: ColorManager.errorText, fontSize: 12.sp),
                      ),
                    ],
                    SizedBox(height: 8.h),
                    ...plans.map((plan) => _buildPlanCard(
                          plan,
                          isSelected: plan.id == selected?.id,
                          maths: plan.isYearly ? _yearlyMaths(plan, plans) : null,
                        )),
                  ],
                  SizedBox(height: 12.h),

                  // 4. Trust + legal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, color: ColorManager.textTertiary, size: 14.sp),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          'Secure checkout with App Store / Play Store · Cancel anytime',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.sp, color: ColorManager.textTertiary),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  // Store requirement: auto-renew disclosure + working links.
                  Text(
                    'Subscriptions renew automatically until cancelled. Cancel anytime in Google Play / App Store settings at least 24 hours before renewal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.sp, color: ColorManager.textTertiary),
                  ),
                  SizedBox(height: 4.h),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton(
                        key: const Key('premium_terms_link'),
                        onPressed: () => LegalLinks.open(context, LegalLinks.termsUrl),
                        style: TextButton.styleFrom(
                          foregroundColor: ColorManager.textSecondary,
                          textStyle: TextStyle(fontSize: 12.sp, decoration: TextDecoration.underline),
                        ),
                        child: const Text('Terms of Use'),
                      ),
                      Text('·', style: TextStyle(fontSize: 12.sp, color: ColorManager.textTertiary)),
                      TextButton(
                        key: const Key('premium_privacy_link'),
                        onPressed: () => LegalLinks.open(context, LegalLinks.privacyPolicyUrl),
                        style: TextButton.styleFrom(
                          foregroundColor: ColorManager.textSecondary,
                          textStyle: TextStyle(fontSize: 12.sp, decoration: TextDecoration.underline),
                        ),
                        child: const Text('Privacy Policy'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildComparison() {
    TextStyle head(Color c) =>
        TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: c, letterSpacing: 0.4);
    return Container(
      key: const Key('premium_compare_table'),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        border: Border.all(color: ColorManager.divider),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: SizedBox()),
              SizedBox(width: 64.w, child: Center(child: Text('FREE', style: head(ColorManager.textTertiary)))),
              SizedBox(width: 76.w, child: Center(child: Text('PRO', style: head(ColorManager.primaryText)))),
            ],
          ),
          for (final r in _rows) ...[
            Divider(height: 14.h, color: ColorManager.divider),
            Row(
              children: [
                Expanded(
                  child: Text(r.label,
                      style: TextStyle(fontSize: 13.sp, color: ColorManager.textPrimary)),
                ),
                SizedBox(
                  width: 64.w,
                  child: Center(
                    child: Text(r.free,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.sp, color: ColorManager.textTertiary)),
                  ),
                ),
                SizedBox(
                  width: 76.w,
                  child: Center(
                    child: Text(r.pro,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: ColorManager.primaryText,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlreadyPro() {
    return Container(
      padding: EdgeInsets.all(SizeManager.s16.w),
      decoration: BoxDecoration(
        color: ColorManager.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        border: Border.all(color: ColorManager.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: ColorManager.primaryText),
          SizedBox(width: SizeManager.s12.w),
          Expanded(
            child: Text(
              "You're a Pro member. Thanks for your support!",
              style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    SubscriptionPlan plan, {
    required bool isSelected,
    ({String perMonth, int savePercent})? maths,
  }) {
    final String? badge = plan.isYearly
        ? (maths != null ? 'Save ${maths.savePercent}%' : 'Best value')
        : (plan.isLifetime ? 'One-time' : null);
    final String periodLine = plan.isLifetime
        ? 'Pay once, keep Pro forever'
        : (plan.isYearly
            ? (maths != null ? 'Just ${maths.perMonth} a month, billed yearly' : 'Billed yearly')
            : 'Billed monthly');

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        key: Key('premium_plan_${plan.id}'),
        borderRadius: BorderRadius.circular(AppRadius.tile.r),
        onTap: () => setState(() => _selectedPlanId = plan.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isSelected
                ? ColorManager.primary.withValues(alpha: 0.08)
                : ColorManager.surface,
            borderRadius: BorderRadius.circular(AppRadius.tile.r),
            border: Border.all(
              color: isSelected ? ColorManager.primary : ColorManager.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? ColorManager.primaryText : ColorManager.textTertiary,
                size: 22.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            plan.title,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: ColorManager.textPrimary,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: plan.isYearly
                                  ? ColorManager.success.withValues(alpha: 0.16)
                                  : ColorManager.premium.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: plan.isYearly
                                    ? ColorManager.successText
                                    : ColorManager.warningText,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      periodLine,
                      style: TextStyle(fontSize: 12.sp, color: ColorManager.textSecondary),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                plan.price,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompareRow {
  const _CompareRow(this.label, {required this.free, required this.pro});
  final String label;
  final String free;
  final String pro;
}
