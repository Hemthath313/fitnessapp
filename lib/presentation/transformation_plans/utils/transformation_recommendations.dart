import 'package:fitness_app/model/transformation_plan_model.dart';

/// Recommendation data model for intelligent programme insights
class TransformationInsight {
  final String title;
  final String message;
  final String type; // 'consistency' | 'nutrition' | 'recovery' | 'progression'
  final String iconEmoji;

  const TransformationInsight({
    required this.title,
    required this.message,
    required this.type,
    required this.iconEmoji,
  });
}

/// Computes transparent, evidence-based recommendations from actual recorded progress.
/// Does NOT force automatic parameter changes or aggressive deficits.
class TransformationRecommendations {
  static List<TransformationInsight> generateInsights({
    required UserTransformationState state,
    double? currentWeight,
  }) {
    final insights = <TransformationInsight>[];

    final totalCompleted = state.completedDayIndices.length;
    final totalDays = state.totalDays;
    final planGoal = state.planId.contains('muscle')
        ? 'GAIN'
        : (state.planId.contains('strength') ? 'STRENGTH' : 'LOSE');

    // 1. Workout Consistency Analysis
    final expectedDaysSoFar = state.currentDay.clamp(1, totalDays);
    final completionRatio = expectedDaysSoFar > 0
        ? totalCompleted / expectedDaysSoFar
        : 1.0;

    if (completionRatio >= 0.85 && totalCompleted >= 7) {
      insights.add(
        const TransformationInsight(
          title: 'Optimal Training Consistency',
          message:
              'You have completed 85%+ of your scheduled sessions. To continue progressive overload, aim to add 2–5% load to your compound movements this week while maintaining strict form.',
          type: 'progression',
          iconEmoji: '🔥',
        ),
      );
    } else if (completionRatio < 0.60 && expectedDaysSoFar >= 7) {
      insights.add(
        const TransformationInsight(
          title: 'Schedule Sustainability',
          message:
              'You have missed several scheduled workout days. Do not stress or rush to double up workouts; focus on completing at least 3 priority sessions each week for sustained progress.',
          type: 'consistency',
          iconEmoji: '📅',
        ),
      );
    }

    // 2. Weight Trend Analysis
    final startingWeight = state.startingWeight;
    final latestWeight = currentWeight ??
        (state.weeklyCheckIns.isNotEmpty
            ? state.weeklyCheckIns.last.weight
            : null);

    if (startingWeight != null && latestWeight != null) {
      final netChange = latestWeight - startingWeight;
      final weeksElapsed = (expectedDaysSoFar / 7).ceil().clamp(1, 16);
      final avgWeeklyChange = netChange / weeksElapsed;

      if (planGoal == 'LOSE') {
        if (avgWeeklyChange < -1.2) {
          // Weight dropping too fast (> 1.2 kg / week)
          insights.add(
            const TransformationInsight(
              title: 'Rapid Weight Drop Detected',
              message:
                  'Your weight is decreasing at over 1.2 kg per week. To prevent muscle loss and metabolic fatigue, consider adding 150–200 kcal of complex carbohydrates or healthy fats to your daily targets.',
              type: 'nutrition',
              iconEmoji: '⚠️',
            ),
          );
        } else if (avgWeeklyChange >= 0.0 && weeksElapsed >= 3) {
          // Plateau in weight loss
          insights.add(
            const TransformationInsight(
              title: 'Weight Plateau Observation',
              message:
                  'Weight has remained flat over the last several weeks. Verify that portion sizes and cooking oils are accurately logged in Diet Plans, and ensure your daily step goal is met.',
              type: 'nutrition',
              iconEmoji: '⚖️',
            ),
          );
        }
      } else if (planGoal == 'GAIN') {
        if (avgWeeklyChange > 0.6) {
          insights.add(
            const TransformationInsight(
              title: 'Surplus Calorie Pace',
              message:
                  'You are gaining weight faster than 0.6 kg per week. Consider moderating your surplus slightly to minimize fat accumulation while maximizing lean muscle synthesis.',
              type: 'nutrition',
              iconEmoji: '💪',
            ),
          );
        }
      }
    }

    // 3. Recovery and Fatigue Check
    if (state.weeklyCheckIns.isNotEmpty) {
      final latestCheckIn = state.weeklyCheckIns.last;
      if (latestCheckIn.fatigueLevel == 'High / Fatigued') {
        insights.add(
          const TransformationInsight(
            title: 'Recovery & Fatigue Alert',
            message:
                'You reported elevated fatigue in your latest check-in. Prioritize 7–8 hours of quality sleep, increase daily water intake, and consider taking an active rest day before your next heavy session.',
            type: 'recovery',
            iconEmoji: '💤',
          ),
        );
      }
    }

    // 4. Default baseline insight if no warnings triggered
    if (insights.isEmpty) {
      insights.add(
        const TransformationInsight(
          title: 'Steady Progression',
          message:
              'Stay consistent with your daily calorie target and workout plan. Small daily achievements build extraordinary long-term transformations.',
          type: 'progression',
          iconEmoji: '✨',
        ),
      );
    }

    return insights;
  }
}
