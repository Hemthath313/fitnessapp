import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';

class BodyPartsScreen extends StatelessWidget {
  final Map<String, String> bodyPartImages = {
    'Chest': ImageManager.chestWorkout,
    'Biceps': ImageManager.bicepsWorkout,
    'Triceps': ImageManager.tricepsWorkout,
    'Shoulders': ImageManager.shoulderWorkout,
    'Legs': ImageManager.legWorkout,
    'Back': ImageManager.backWorkout,
    'Abs': ImageManager.absWorkout,
  };

  BodyPartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.black,
      appBar: AppBar(
        backgroundColor: ColorManager.black,
        title: Text('Select a Body Part',style: TextStyle(color: ColorManager.white),),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
        ),
        itemCount: bodyPartImages.length,
        itemBuilder: (context, index) {
          String bodyPart = bodyPartImages.keys.elementAt(index);
          String imagePath = bodyPartImages[bodyPart]!;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkoutListScreen(bodyPart: bodyPart),
                ),
              );
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
                    colors: [Colors.black.withValues(), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    bodyPart,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
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

class WorkoutListScreen extends StatelessWidget {
  final String bodyPart;

  WorkoutListScreen({required this.bodyPart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$bodyPart Workouts'),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Workout list for $bodyPart coming soon!',
          style: TextStyle(fontSize: 18.0),
        ),
      ),
    );
  }
}
