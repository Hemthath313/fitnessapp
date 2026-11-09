import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:fitness_app/presentation/banner_ads/banner_ad_service.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExploreWidget extends StatefulWidget {
  const ExploreWidget({super.key});

  @override
  State<ExploreWidget> createState() => _ExploreWidgetState();
}

class _ExploreWidgetState extends State<ExploreWidget>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _controller;
  late final List<Map<String, dynamic>> cards;
  late final List<Animation<Offset>> animations;

  @override
  void initState() {
    super.initState();

    // The exercise library lives on My Plan. Explore keeps one shortcut card
    // into it (Body Focus) so browsing here still finds it, plus recovery,
    // diet, cardio and the programme splits.
    cards = [
      {
        'image': ImageManager.strengthWorkout,
        'title': 'Strength Training',
        'description': 'Browse every exercise by muscle group.',
        'isPremiumRequired': false,
        'onTap': () => context.push(Routes.bodypartsPage),
      },
      {
        'image': ImageManager.postWorkout,
        'title': 'Pain Relief & Mobility',
        'description': 'Targeted exercises to reduce pain and improve flexibility.',
        'isPremiumRequired': false,
        'onTap': () => context.push(Routes.recoveryRoute),
      },
      {
        'image': ImageManager.dietAndNutrition,
        'title': StringsManager.diet,
        'description': 'Nutritional guidance for better performance.',
        'isPremiumRequired': false,
        'onTap': () => context.push(Routes.dietRoute),
      },
      {
        'image': ImageManager.cardioWorkout,
        'title': StringsManager.cardio,
        'description': 'Improve heart health with effective cardio routines.',
        'isPremiumRequired': false,
        'onTap': () => context.push(Routes.cardioRoute),
      },
      {
        'image': ImageManager.dumbels,
        'title': 'Workout Splits',
        'description': 'PPL, Bro Split, Upper/Lower — structured for real gains.',
        'isPremiumRequired': true,
        'onTap': () {
          final sub = Provider.of<SubscriptionProvider>(context, listen: false);
          if (!sub.isPremium) {
            context.push(Routes.premiumScreen);
          } else {
            context.push(Routes.workoutSplitsRoute);
          }
        },
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
    super.build(context);
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 12.0, bottom: 80.0),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final isPremiumRequired = cards[index]['isPremiumRequired'] as bool? ?? false;
                return Consumer<SubscriptionProvider>(
                  builder: (context, subProvider, _) {
                    final isLocked = isPremiumRequired && !subProvider.isPremium;
                    return RepaintBoundary(
                      child: ExploreCard(
                        animation: animations[index],
                        image: cards[index]['image'],
                        title: cards[index]['title'],
                        description: cards[index]['description'],
                        isPremiumLocked: isLocked,
                        onTap: cards[index]['onTap'],
                      ),
                    );
                  },
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
  final bool isPremiumLocked;
  final VoidCallback onTap;

  const ExploreCard({
    super.key,
    required this.animation,
    required this.image,
    required this.title,
    required this.description,
    required this.onTap,
    this.isPremiumLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: animation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: ColorManager.divider.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
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
                  // Background image with dimming when locked
                  ColorFiltered(
                    colorFilter: isPremiumLocked
                        ? const ColorFilter.mode(
                            Colors.black45, BlendMode.darken)
                        : const ColorFilter.mode(
                            Colors.transparent, BlendMode.multiply),
                    child: Image.asset(
                      image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 210,
                    ),
                  ),
                  Container(
                    height: 210,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.85),
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  // 👑 Premium badge — top right corner
                  if (isPremiumLocked)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 0,
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children:  [
                            Icon(Icons.workspace_premium_rounded,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'PREMIUM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Lock icon overlay in center when premium locked
                  if (isPremiumLocked)
                    Positioned.fill(
                      child: Center(
                        child: Icon(
                          Icons.lock_rounded,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 36,
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
                                style:  TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isPremiumLocked
                                    ? 'Unlock with Premium to access'
                                    : description,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 13.sp,
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
                            color: isPremiumLocked
                                ? Colors.amber.shade700
                                : ColorManager.primary.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPremiumLocked
                                ? Icons.workspace_premium_rounded
                                : Icons.arrow_forward_ios_rounded,
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
