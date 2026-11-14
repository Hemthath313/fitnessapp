import 'package:fitness_app/presentation/in_app_purchases/premimum_screen.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/utils/managers/app_font.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Product rule: logging and tracking meals is a Pro-only feature.
///
/// Wrap any meal-logging / meal-tracking screen in this gate. Free users see an
/// upgrade prompt instead of the screen, even if they reach it through a deep
/// link or an old entry point. When no [SubscriptionProvider] is available
/// (for example in isolated widget tests) the child is shown.
class ProFeatureGate extends StatelessWidget {
  const ProFeatureGate({
    super.key,
    required this.child,
    this.title = 'Meal tracking',
  });

  final Widget child;

  /// Name of the locked feature, used in the prompt.
  final String title;

  @override
  Widget build(BuildContext context) {
    final subscription = Provider.of<SubscriptionProvider?>(context);
    if (subscription == null || subscription.isPremium) return child;

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        backgroundColor: ColorManager.background,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ColorManager.premium.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_rounded,
                    color: ColorManager.warningText, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                '$title is a Pro feature',
                key: const Key('pro_gate_title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: AppType.title,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upgrade to Pro to log your meals and track your calories and macros.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColorManager.textSecondary,
                  fontSize: AppType.body,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('pro_gate_upgrade_button'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  foregroundColor: ColorManager.onMint,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: const Text(
                  'Go Premium',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
