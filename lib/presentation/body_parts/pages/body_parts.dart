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
      Future.delayed(Duration(milliseconds: i * 150), () {
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
      backgroundColor: ColorManager.black,
      appBar: AppBar(
        iconTheme: IconThemeData(color: ColorManager.white),
        backgroundColor: ColorManager.black,
        title: Text(
          'Select a Body Part',
          style: TextStyle(color: ColorManager.white),
        ),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
        ),
        itemCount: bodyPartImages.length,
        itemBuilder: (context, index) {
          String bodyPart = bodyPartImages.keys.elementAt(index);
          String imagePath = bodyPartImages[bodyPart]!;

          return AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: isVisible[index] ? 1.0 : 0.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              transform: isVisible[index]
                  ? Matrix4.identity()
                  : Matrix4.diagonal3Values(0.8, 0.8, 1),
              curve: Curves.easeOutBack,
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
                    borderRadius: BorderRadius.circular(12.0),
                    image: DecorationImage(
                      image: AssetImage(imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    alignment: Alignment.bottomCenter,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        bodyPart,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
