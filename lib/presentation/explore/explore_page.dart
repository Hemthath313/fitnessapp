import 'package:flutter/material.dart';
import 'package:fitness_app/presentation/home/widgets/carousel_home_box.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> cards = [
      {
        'image': ImageManager.strengthWorkout,
        'title': StringsManager.strengh,
        'description': 'Build strength and endurance with tailored workouts.',
        'onTap': () => context.push(Routes.bodypartsPage)
      },
      {
        'image': ImageManager.postWorkout,
        'title': StringsManager.workoutRecovery,
        'description': 'Enhance muscle recovery with post-workout tips.',
        'onTap': () {}
      },
      {
        'image': ImageManager.dietAndNutrition,
        'title': StringsManager.diet,
        'description': 'Nutritional guidance for better performance.',
        'onTap': () => context.push(Routes.dietRoute)
      },
      {
        'image': ImageManager.cardioWorkout,
        'title': StringsManager.cardio,
        'description': 'Improve heart health with effective cardio routines.',
        'onTap': () => context.push(Routes.cardioRoute)
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final animation = Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval((index / cards.length), 1.0, curve: Curves.easeOut),
          ),
        );

        return SlideTransition(
          position: animation,
          child: Card(
            elevation: 10,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            shadowColor: Colors.blueAccent.withOpacity(0.5),
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: cards[index]['onTap'],
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      cards[index]['image'],
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
                          Colors.transparent
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
                          cards[index]['title'],
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cards[index]['description'],
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
