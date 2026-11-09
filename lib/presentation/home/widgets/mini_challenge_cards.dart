import 'package:fitness_app/data/challenge_data.dart';
import 'package:fitness_app/presentation/challenges/challenge_progress.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_home_box.dart';
import 'package:fitness_app/presentation/home/widgets/gradient_hero_card.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 30-Day Six-Pack challenge card. Loads its own progress from Firestore and
/// refreshes it after the user returns from the challenge screen, so it can be
/// dropped into any list (dashboard shelf, Transformation Plans hub).
class SixPackChallengeCard extends StatefulWidget {
  const SixPackChallengeCard({super.key});

  @override
  State<SixPackChallengeCard> createState() => _SixPackChallengeCardState();
}

class _SixPackChallengeCardState extends State<SixPackChallengeCard>
    with AutomaticKeepAliveClientMixin {
  late Future<Map<String, dynamic>> _progressFuture;

  // Keep the loaded progress while the card scrolls out of a PageView/ListView.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _progressFuture = _fetchProgress();
  }

  Future<Map<String, dynamic>> _fetchProgress() async {
    try {
      // Same loader as the challenge screen: server first, saved copy when
      // offline, so a slow connection doesn't reset the card to "Start Day 1".
      final progress = await const FirestoreSixPackProgressStore().load();
      return {'lastCompletedDay': progress.lastCompletedDay};
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _progressFuture,
      builder: (context, snapshot) {
        final progress = snapshot.data ?? {};
        final int lastDay = (progress['lastCompletedDay'] as num?)?.toInt() ?? 0;

        final String subtitle = lastDay > 0
            ? '$lastDay of 30 days completed'
            : '30-Day progressive core curriculum';
        final double fraction = (lastDay / 30.0).clamp(0.0, 1.0);
        final String action = lastDay > 0
            ? (lastDay >= 30 ? 'Completed 🏆' : 'Continue Day ${lastDay + 1}')
            : 'Start Day 1';

        final String badge;
        if (lastDay >= 30) {
          badge = 'COMPLETED';
        } else if (lastDay > 0) {
          badge = 'ACTIVE';
        } else {
          badge = '30-DAY CHALLENGE';
        }

        return CarouselHomeBox(
          heroKey: 'abs',
          photoAsset: HeroImages.sixPackPhoto,
          title: StringsManager.sixPackChallenge,
          badge: badge,
          subtitle: subtitle,
          progress: fraction > 0 ? fraction : null,
          actionText: action,
          onTap: () {
            context.push(Routes.sixPackChallengeRoute).then((_) {
              if (mounted) {
                setState(() {
                  _progressFuture = _fetchProgress();
                });
              }
            });
          },
        );
      },
    );
  }
}

/// Weekly technique card (single featured exercise with form tips).
class ExerciseOfWeekCard extends StatelessWidget {
  const ExerciseOfWeekCard({super.key});

  @override
  Widget build(BuildContext context) {
    final weeklyExercise = ChallengeData.weeklyFeaturedExercise;
    return CarouselHomeBox(
      heroKey: 'shoulders',
      photoAsset: HeroImages.weeklyTechniquePhoto,
      tone: HeroTone.purple,
      title: StringsManager.exerciseOfWeek,
      badge: 'WEEKLY TECHNIQUE',
      subtitle: '${weeklyExercise.name} • ${weeklyExercise.target}',
      actionText: 'View Guide',
      onTap: () => context.push(Routes.exerciseOfTheWeekRoute),
    );
  }
}
