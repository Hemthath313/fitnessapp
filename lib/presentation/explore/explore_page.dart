import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:fitness_app/presentation/banner_ads/banner_ad_service.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/interstitial_ads/interstitial_ad_service.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:go_router/go_router.dart';

class ExploreWidget extends StatefulWidget {
  const ExploreWidget({super.key});

  @override
  State<ExploreWidget> createState() => _ExploreWidgetState();
}

class _ExploreWidgetState extends State<ExploreWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final List<Map<String, dynamic>> cards;
  late final List<Animation<Offset>> animations;

  @override
  void initState() {
    super.initState();

    cards = [
      {
        'image': ImageManager.strengthWorkout,
        'title': StringsManager.strengh,
        'description': 'Build strength and endurance with tailored workouts.',
        'onTap': () async {
          final sub = Provider.of<SubscriptionProvider>(context, listen: false);
          if (!sub.isPremium) {
            await InterstitialAdService.showStrengthWorkoutAd();
          }
          context.push(Routes.bodypartsPage);
        },
      },
      {
        'image': ImageManager.postWorkout,
        'title': 'Pain Relief & Mobility',
        'description': 'Targeted exercises to reduce pain and improve flexibility.',
        'onTap': () => context.push(Routes.recoveryRoute),
      },
      {
        'image': ImageManager.dietAndNutrition,
        'title': StringsManager.diet,
        'description': 'Nutritional guidance for better performance.',
        'onTap': () {
          context.push(Routes.dietRoute);
        },
      },
      {
        'image': ImageManager.cardioWorkout,
        'title': StringsManager.cardio,
        'description': 'Improve heart health with effective cardio routines.',
        'onTap': () => context.push(Routes.cardioRoute),
      },
    ];

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    animations = List.generate(cards.length, (index) {
      final start = index * 0.1;
      final end = start + 0.5;
      return Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut),
        ),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 12.0, bottom: 80.0),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                return RepaintBoundary(
                  child: ExploreCard(
                    animation: animations[index],
                    image: cards[index]['image'],
                    title: cards[index]['title'],
                    description: cards[index]['description'],
                    onTap: cards[index]['onTap'],
                  ),
                );
              },
            ),
          ),
          const PremiumAwareBannerAd(pageName: 'explore'),
        ],
      ),
    );
  }
}

class ExploreCard extends StatelessWidget {
  final Animation<Offset> animation;
  final String image;
  final String title;
  final String description;
  final VoidCallback onTap;

  const ExploreCard({
    super.key,
    required this.animation,
    required this.image,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: animation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: ColorManager.divider.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.5),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                children: [
                  Image.asset(
                    image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 210,
                  ),
                  Container(
                    height: 210,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.85),
                          Colors.black.withOpacity(0.35),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: ColorManager.primary.withOpacity(0.85),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
