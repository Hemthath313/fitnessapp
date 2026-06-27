import 'package:fitness_app/presentation/in_app_purchases/premimum_screen.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/diet_nutrition/diet_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:go_router/go_router.dart';
import 'package:fitness_app/presentation/diet_nutrition/widgets/weekly_progress_card.dart';
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

  void _handlePlanTap(VoidCallback navigationAction) {
    final isPremium = Provider.of<SubscriptionProvider>(context, listen: false).isPremium;
    if (isPremium) {
      navigationAction();
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal =
        Provider.of<HomeProvider>(context).userData['goal']?.toUpperCase();
    final isPremium = Provider.of<SubscriptionProvider>(context).isPremium;

    String goalDescription = '';
    List<String> tips = [];
    IconData goalIcon = Icons.info;
    String? currentPlanImage;
    VoidCallback? currentPlanAction;
    String currentPlanTitle = '';

    switch (goal) {
      case 'GAIN':
        goalDescription = 'Bulking Phase';
        tips = [
          'High Protein: 2.0g per kg of body weight',
          'Caloric Surplus: Eat more than you burn',
          'Focus on compound movements in gym'
        ];
        goalIcon = Icons.fitness_center;
        currentPlanImage = ImageManager.bulkingDiet;
        currentPlanTitle = 'Bulking Protocol';
        currentPlanAction = () => context.push(Routes.bulkingDietRoute);
        break;
      case 'LOSE':
        goalDescription = 'Cutting Phase';
        tips = [
          'Lean Protein: Preserve muscle while losing fat',
          'Caloric Deficit: Strategic meal timing',
          'Increased fiber intake for satiety'
        ];
        goalIcon = Icons.local_fire_department;
        currentPlanImage = ImageManager.cuttingDiet;
        currentPlanTitle = 'Shredding Protocol';
        currentPlanAction = () => context.push(Routes.cuttingDietRoute);
        break;
      case 'MAINTAIN':
        goalDescription = 'Maintenance Phase';
        tips = [
          'Balanced Macros: Fuel your performance',
          'Energy Balance: Maintain current weight',
          'Focus on dietary variety and micronutrients'
        ];
        goalIcon = Icons.balance;
        currentPlanImage = ImageManager.maintainDiet;
        currentPlanTitle = 'Maintenance Protocol';
        currentPlanAction = () => context.push(Routes.maintainDietRoute);
        break;
      default:
        goalDescription = 'Set Your Goal';
        tips = ['Set your fitness goal in profile to see plans'];
        goalIcon = Icons.warning;
    }

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
        backgroundColor: ColorManager.background,
        title: Text(
          'Nutrition Hub',
          style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (!isPremium)
            IconButton(
              icon: const Icon(Icons.star, color: Colors.amber),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen())),
            )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGoalBanner(goal, goalDescription, goalIcon),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Active Plan',
                    style: TextStyle(
                      color: ColorManager.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.lock, color: Colors.amber, size: 12),
                          SizedBox(width: 4),
                          Text('PREMIUM', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (currentPlanImage != null && currentPlanAction != null)
                Stack(
                  children: [
                    Opacity(
                      opacity: isPremium ? 1.0 : 0.6,
                      child: buildDietCard(
                        context,
                        currentPlanTitle,
                        currentPlanImage,
                        () => _handlePlanTap(currentPlanAction!),
                      ),
                    ),
                    if (!isPremium)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.amber, width: 2),
                                    ),
                                    child: const Icon(Icons.lock, color: Colors.amber, size: 32),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to Unlock',
                                    style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      'Please set your goal in the Profile tab to unlock your nutrition plan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ColorManager.textSecondary, fontSize: 14),
                    ),
                  ),
                ),

              const SizedBox(height: 32),
              Text(
                'Strategy Highlights',
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorManager.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ColorManager.divider),
                ),
                child: Column(
                  children: tips.map((tip) => _buildTipItem(tip)).toList(),
                ),
              ),
              const SizedBox(height: 40),
             
              Text(
                'Tools & Resources',
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              InkWell(
                onTap: () => context.push(Routes.proteinChartRoute),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ColorManager.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ColorManager.primary.withOpacity(0.3)),
                    gradient: LinearGradient(
                      colors: [
                        ColorManager.surface,
                        ColorManager.primary.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ColorManager.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.menu_book, color: ColorManager.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Food Library',
                              style: TextStyle(
                                color: ColorManager.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Browse protein sources & nutritional info',
                              style: TextStyle(
                                color: ColorManager.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: ColorManager.divider, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalBanner(String? goal, String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
            child: Icon(icon, color: ColorManager.textPrimary, size: 30),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Sprint',
                style: TextStyle(color: ColorManager.textSecondary, fontSize: 12),
              ),
              Text(
                title,
                style: TextStyle(
                  color: ColorManager.textPrimary,
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: ColorManager.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: ColorManager.textSecondary, fontSize: 14, height: 1.4),
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
//         iconTheme: IconThemeData(color: ColorManager.textPrimary),
//         // title: const Text(
//         //   'Diet Plans',
//         //   style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold),
//         // ),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       backgroundColor: ColorManager.black54, // Dark grey background
//       body: const Center(
//         child: Text(
//           'Coming Soon',
//           style: TextStyle(
//             color: ColorManager.textPrimary,
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
// }
