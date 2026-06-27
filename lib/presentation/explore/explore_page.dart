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
          final sub = Provider.of<SubscriptionProvider>(context, listen: false);
          if (sub.isPremium) {
            context.push(Routes.dietRoute);
          } else {
            context.push(Routes.premiumScreen);
          }
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
      bottom: true,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
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
          const PremiumAwareBannerAd(pageName: 'explore', bottomMargin: 60.0),
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
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadowColor: Colors.blueAccent.withOpacity(0.5),
        margin: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 210,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 4.0,
                                color: Colors.black.withOpacity(0.8),
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black.withOpacity(0.8),
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
