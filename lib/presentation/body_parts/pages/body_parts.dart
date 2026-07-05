import 'package:fitness_app/presentation/body_parts/pages/abs.dart';
import 'package:fitness_app/presentation/body_parts/pages/biceps.dart';
import 'package:fitness_app/presentation/body_parts/pages/chest.dart';
import 'package:fitness_app/presentation/body_parts/pages/lats.dart';
import 'package:fitness_app/presentation/body_parts/pages/legs.dart';
import 'package:fitness_app/presentation/body_parts/pages/shoulder.dart';
import 'package:fitness_app/presentation/body_parts/pages/triceps.dart';
import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';

class BodyPartsScreen extends StatefulWidget {
  const BodyPartsScreen({super.key});

  @override
  State<BodyPartsScreen> createState() => _BodyPartsScreenState();
}

class _BodyPartsScreenState extends State<BodyPartsScreen> {
  final Map<String, String> bodyPartImages = {
    'Chest': ImageManager.chestWorkout,
    'Biceps': ImageManager.bicepsWorkout,
    'Triceps': ImageManager.tricepsWorkout,
    'Shoulders': ImageManager.shoulderWorkout,
    'Legs': ImageManager.legWorkout,
    'Back': ImageManager.backWorkout,
    'Abs': ImageManager.absWorkout,
  };

  final Map<String, Widget Function()> bodyPartScreens = {
    'Chest': () => ChestExercisesPage(),
    'Biceps': () => BicepsExercisesPage(),
    'Triceps': () => TricepsExercisesPage(),
    'Shoulders': () => ShoulderExercisesPage(),
    'Legs': () => LegExercisesPage(),
    'Back': () => LatExercisesPage(),
    'Abs': () => AbsExercisesPage(),
  };
  List<bool> isVisible = [];

  @override
  void initState() {
    super.initState();
    isVisible = List.generate(bodyPartImages.length, (index) => false);
    _triggerAnimations();
  }

  void _triggerAnimations() {
    for (int i = 0; i < isVisible.length; i++) {
      Future.delayed(Duration(milliseconds: i * 120), () {
        if (mounted) {
          setState(() {
            isVisible[i] = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        backgroundColor: ColorManager.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: ColorManager.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Bold header section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Body Focus',
                      style: TextStyle(
                        color: ColorManager.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select a muscle group to target and begin your training session',
                      style: TextStyle(
                        color: ColorManager.textSecondary,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Redesigned modern category cards grid
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.85, // Modern taller cards
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    String bodyPart = bodyPartImages.keys.elementAt(index);
                    String imagePath = bodyPartImages[bodyPart]!;

                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 350),
                      opacity: isVisible[index] ? 1.0 : 0.0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        transform: isVisible[index]
                            ? Matrix4.identity()
                            : Matrix4.translationValues(0, 20, 0),
                        curve: Curves.easeOutCubic,
                        child: GestureDetector(
                          onTap: () {
                            if (bodyPartScreens.containsKey(bodyPart)) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => bodyPartScreens[bodyPart]!(),
                                ),
                              );
                            }
                          },
                          child: Container(
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
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Background Image
                                  Image.asset(
                                    imagePath,
                                    fit: BoxFit.cover,
                                  ),
                                  // Gradient Overlay
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withOpacity(0.85),
                                          Colors.black.withOpacity(0.3),
                                          Colors.transparent,
                                        ],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        stops: const [0.0, 0.45, 1.0],
                                      ),
                                    ),
                                  ),
                                  // Text & details
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          bodyPart,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20.0,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              'View exercises',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.7),
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: ColorManager.primary.withOpacity(0.85),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                color: Colors.white,
                                                size: 10,
                                              ),
                                            ),
                                          ],
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
                  },
                  childCount: bodyPartImages.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
