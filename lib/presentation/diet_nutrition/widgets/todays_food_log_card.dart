import 'package:fitness_app/model/meal_model.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/utils/managers/app_font.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// "Today's Food Log": the meals the user logged by hand today, with totals.
/// Everything here counts toward the Home calorie ring.
///
/// Product rule: logging and tracking meals is Pro-only. Free users do not see
/// this card at all (no locked teaser, no upgrade nag).
class TodaysFoodLogCard extends StatelessWidget {
  const TodaysFoodLogCard({super.key});

  @override
  Widget build(BuildContext context) {
    final subscription = Provider.of<SubscriptionProvider?>(context);
    final isPro = subscription == null || subscription.isPremium;
    final hasLog = Provider.of<ConsumptionProvider?>(context) != null;
    if (!isPro || !hasLog) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        boxShadow: ColorManager.cardShadow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: ColorManager.divider),
      ),
      child: const _FoodLogBody(),
    );
  }
}

class _FoodLogBody extends StatelessWidget {
  const _FoodLogBody();

  Future<void> _confirmDelete(
    BuildContext context,
    ConsumptionProvider provider,
    MealModel meal,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: ColorManager.surface,
        title: Text('Remove "${meal.title}"?',
            style: TextStyle(color: ColorManager.textPrimary)),
        content: Text(
          'This takes ${meal.calories.round()} kcal off today\'s total.',
          style: TextStyle(color: ColorManager.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
            key: const Key('food_log_confirm_delete'),
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: ColorManager.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await provider.deleteMeal(meal.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove the meal. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ConsumptionProvider>(context);
    final meals = provider.todaysMeals
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Today's Food Log",
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: AppType.bodyLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton.icon(
              key: const Key('food_log_add_button'),
              onPressed: () => context.push(Routes.newMealRoute),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Log a meal'),
              style: TextButton.styleFrom(
                foregroundColor: ColorManager.primaryText,
              ),
            ),
          ],
        ),
        if (meals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No meals logged yet today.',
              key: const Key('food_log_empty'),
              style: TextStyle(
                color: ColorManager.textSecondary,
                fontSize: AppType.small,
              ),
            ),
          )
        else ...[
          Text(
            '${provider.manualCaloriesToday.round()} kcal  ·  '
            '${provider.manualProteinToday.round()}g P  ·  '
            '${provider.manualCarbsToday.round()}g C  ·  '
            '${provider.manualFatsToday.round()}g F',
            key: const Key('food_log_totals'),
            style: TextStyle(
              color: ColorManager.primaryText,
              fontSize: AppType.small,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          for (final meal in meals)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ColorManager.textPrimary,
                            fontSize: AppType.body,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${meal.calories.round()} kcal  ·  ${meal.proteins.round()}g P',
                          style: TextStyle(
                            color: ColorManager.textSecondary,
                            fontSize: AppType.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove ${meal.title}',
                    onPressed: () => _confirmDelete(context, provider, meal),
                    icon: Icon(Icons.delete_outline_rounded,
                        color: ColorManager.textSecondary, size: 20),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
