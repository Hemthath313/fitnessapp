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
        goalDescription = 'Bulking Phase';
        tips = [
          'High Protein: 2.0g per kg of body weight',
          'Caloric Surplus: Eat more than you burn',
          'Focus on compound movements in gym'
        ];
        goalIcon = Icons.fitness_center;
        break;
      case 'LOSE':
        goalDescription = 'Cutting Phase';
        tips = [
          'Lean Protein: Preserve muscle while losing fat',
          'Caloric Deficit: Strategic meal timing',
          'Increased fiber intake for satiety'
        ];
        goalIcon = Icons.local_fire_department;
        break;
      case 'MAINTAIN':
        goalDescription = 'Maintenance Phase';
        tips = [
          'Balanced Macros: Fuel your performance',
          'Energy Balance: Maintain current weight',
          'Focus on dietary variety and micronutrients'
        ];
        goalIcon = Icons.balance;
        break;
      default:
        goalDescription = 'Set Your Goal';
        tips = ['Set your fitness goal in profile to see plans'];
        goalIcon = Icons.warning;
    }

    return Scaffold(
      backgroundColor: ColorManager.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: ColorManager.black,
        title: const Text(
          'Nutrition Hub',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGoalBanner(goal, goalDescription, goalIcon),
              SizedBox(height: 24),
              Text(
                'Plan Highlights',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              ...tips.map((tip) => _buildTipItem(tip)),
              SizedBox(height: 32),
              Text(
                'Personalized Plans',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 16),
              if (goal == 'GAIN')
                buildDietCard(
                  context,
                  'Open Bulking Plan',
                  ImageManager.bulkingDiet,
                  () => context.push(Routes.bulkingDietRoute),
                )
              else if (goal == 'LOSE')
                buildDietCard(
                  context,
                  'Open Cutting Plan',
                  ImageManager.cuttingDiet,
                  () => context.push(Routes.cuttingDietRoute),
                )
              else if (goal == 'MAINTAIN')
                buildDietCard(
                  context,
                  'Open Maintain Plan',
                  ImageManager.maintainDiet,
                  () => context.push(Routes.maintainDietRoute),
                )
              else
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      'Please set your goal in the Profile tab to unlock your nutrition plan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalBanner(String? goal, String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorManager.primary.withOpacity(0.8),
            ColorManager.primary.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white24,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Sprint',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.bolt, color: ColorManager.primary, size: 16),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:fitness_app/utils/managers/color_manager.dart';
// import 'package:flutter/material.dart';

// class DietMain extends StatelessWidget {
//   const DietMain({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: ColorManager.black54,
//         iconTheme: const IconThemeData(color: Colors.white),
//         // title: const Text(
//         //   'Diet Plans',
//         //   style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         // ),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       backgroundColor: ColorManager.black54, // Dark grey background
//       body: const Center(
//         child: Text(
//           'Coming Soon',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
// }
