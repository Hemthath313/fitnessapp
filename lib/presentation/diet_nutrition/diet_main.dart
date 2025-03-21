import 'package:fitness_app/presentation/diet_nutrition/diet_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:go_router/go_router.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';

class DietMain extends StatefulWidget {
  const DietMain({super.key});

  @override
  State<DietMain> createState() => _DietMainState();
}

class _DietMainState extends State<DietMain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2), // Slide from bottom
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutExpo,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
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
    final goal =
        Provider.of<HomeProvider>(context).userData['goal']?.toUpperCase();

    String goalDescription = '';
    List<String> tips = [];
    IconData goalIcon = Icons.info;

    switch (goal) {
      case 'GAIN':
        goalDescription =
            '💪 Bulking means consuming more calories than you burn to build muscle.';
        tips = [
          '🥩 Eat calorie-dense foods like nuts, avocados, and whole grains.',
          '🏋️‍♂️ Increase protein intake to support muscle growth.',
          '🛌 Prioritize recovery with proper rest.'
        ];
        goalIcon = Icons.fitness_center;
        break;
      case 'LOSE':
        goalDescription =
            '🔥 Cutting means maintaining a calorie deficit to reduce body fat.';
        tips = [
          '🥗 Focus on lean protein sources to preserve muscle.',
          '🚴 Include cardio exercises for better fat burning.',
          '📊 Track your calories to stay within your target.'
        ];
        goalIcon = Icons.local_fire_department;
        break;
      case 'MAINTAIN':
        goalDescription =
            '⚖️ Maintaining means balancing your calorie intake with your energy expenditure.';
        tips = [
          '🥦 Eat a variety of nutrient-rich foods.',
          '🏃 Maintain a consistent workout routine.',
          '💧 Stay hydrated to support overall health.'
        ];
        goalIcon = Icons.balance;
        break;
      default:
        goalDescription = '❗ Please set your goal to view tailored diet plans.';
        tips = [];
        goalIcon = Icons.warning;
    }

    return Scaffold(
      backgroundColor: ColorManager.black,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: ColorManager.black,
        title: const Text(
          'Diet Plans',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Opacity(
          opacity: _fadeAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(goalIcon, size: 50, color: Colors.orangeAccent),
                  const SizedBox(height: 12),
                  Text(
                    goalDescription,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(
                      color: Colors.orangeAccent, thickness: 1.5, height: 30),
                  if (tips.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: tips
                          .map(
                            (tip) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 20),
                  if (goal == 'GAIN')
                    buildDietCard(
                      context,
                      'Bulking Diet',
                      ImageManager.bulkingDiet,
                      () => context.push(Routes.bulkingDietRoute),
                    ),
                  if (goal == 'LOSE')
                    buildDietCard(
                      context,
                      'Cutting Diet',
                      ImageManager.cuttingDiet,
                      () => context.push(Routes.cuttingDietRoute),
                    ),
                  if (goal == 'MAINTAIN')
                    buildDietCard(
                      context,
                      'Maintain Diet',
                      ImageManager.maintainDiet,
                      () => context.push(Routes.maintainDietRoute),
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
