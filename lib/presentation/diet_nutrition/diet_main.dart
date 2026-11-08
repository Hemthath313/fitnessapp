import 'package:fitness_app/presentation/in_app_purchases/premimum_screen.dart';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/presentation/diet_nutrition/diet_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitness_app/utils/managers/asset_manager.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:go_router/go_router.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

  // Macro Calculator State
  double _calculatorWeight = 70.0;
  String _calculatorActivity = 'MODERATE';
  bool _isCalculatorExpanded = false;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final homeProvider = Provider.of<HomeProvider>(context, listen: false);
        final userData = homeProvider.userData;
        setState(() {
          _calculatorWeight = (userData['weight'] ?? 70.0) as double;
          _calculatorActivity = userData['activity']?.toString().toUpperCase() ?? 'MODERATE';
          if (_calculatorWeight <= 0) {
            _calculatorWeight = 70.0;
          }
        });
      }
    });
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
              tooltip: 'Go Premium',
              icon: const Icon(Icons.star, color: Colors.amber),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen())),
            )
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
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
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Row(
                        children:  [
                          Icon(Icons.lock, color: Colors.amber, size: 12),
                          SizedBox(width: 4),
                          Text('PREMIUM', style: TextStyle(color: Colors.amber, fontSize: 11.sp, fontWeight: FontWeight.bold)),
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
                              color: Colors.black.withValues(alpha: 0.4),
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
                      style: TextStyle(color: ColorManager.textSecondary, fontSize: 14.sp),
                    ),
                  ),
                ),

              const SizedBox(height: 32),
              _buildMacroCalculator(goal, Provider.of<HomeProvider>(context).userData['bmr']?.toDouble()),

              const SizedBox(height: 32),
              Text(
                'Strategy Highlights',
                style: TextStyle(
                  color: ColorManager.textPrimary,
                  fontSize: 18.sp,
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
                  fontSize: 18.sp,
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
                    border: Border.all(color: ColorManager.primary.withValues(alpha: 0.3)),
                    gradient: LinearGradient(
                      colors: [
                        ColorManager.surface,
                        ColorManager.primary.withValues(alpha: 0.1),
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
                          color: ColorManager.primary.withValues(alpha: 0.2),
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
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Browse protein sources & nutritional info',
                              style: TextStyle(
                                color: ColorManager.textSecondary,
                                fontSize: 13.sp,
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
          colors: [ColorManager.heroTealStart, ColorManager.heroTealMid],
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
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Sprint',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.sp),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
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
              style: TextStyle(color: ColorManager.textSecondary, fontSize: 14.sp, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCalculator(String? goal, double? cachedBMR) {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final userData = homeProvider.userData;
    final gender = userData['gender']?.toString() ?? 'Male';
    final height = (userData['height'] ?? 170.0) as double;
    final age = (userData['age'] ?? 25) as int;

    double basicBmr;
    if (gender.toLowerCase() == 'female') {
      basicBmr = 447.593 + (9.247 * _calculatorWeight) + (3.098 * height) - (4.330 * age);
    } else {
      basicBmr = 88.362 + (13.397 * _calculatorWeight) + (4.799 * height) - (5.677 * age);
    }

    double activityFactor = 1.2;
    if (_calculatorActivity == 'LIGHT') {
      activityFactor = 1.375;
    } else if (_calculatorActivity == 'MODERATE') {
      activityFactor = 1.55;
    } else if (_calculatorActivity == 'HIGH' || _calculatorActivity == 'VERY HIGH') {
      activityFactor = 1.725;
    }

    double usersBmr = basicBmr * activityFactor;

    double calculatedCaloriesDouble;
    if (goal == 'LOSE') {
      calculatedCaloriesDouble = usersBmr - (usersBmr * 0.2);
    } else if (goal == 'GAIN') {
      calculatedCaloriesDouble = usersBmr + (usersBmr * 0.2);
    } else {
      calculatedCaloriesDouble = usersBmr;
    }

    int calculatedCalories = calculatedCaloriesDouble.round();
    if (calculatedCalories < 1200) {
      calculatedCalories = 1200;
    }

    double proteinMultiplier = 1.6;
    if (goal == 'GAIN') {
      proteinMultiplier = 2.0;
    } else if (goal == 'LOSE') {
      proteinMultiplier = 2.2;
    }
    int calculatedProtein = (_calculatorWeight * proteinMultiplier).round();

    int calculatedFats = (_calculatorWeight * 0.9).round();
    if (calculatedFats < 40) {
      calculatedFats = 40;
    }

    int caloriesFromProtein = calculatedProtein * 4;
    int caloriesFromFats = calculatedFats * 9;
    int remainingCals = calculatedCalories - (caloriesFromProtein + caloriesFromFats);
    int calculatedCarbs = (remainingCals / 4).round();
    if (calculatedCarbs < 50) {
      calculatedCarbs = 50;
    }

    int totalGramsCaloric = (calculatedCarbs * 4) + (calculatedProtein * 4) + (calculatedFats * 9);
    double carbsPercent = totalGramsCaloric > 0 ? (calculatedCarbs * 4) / totalGramsCaloric : 0.0;
    double proteinPercent = totalGramsCaloric > 0 ? (calculatedProtein * 4) / totalGramsCaloric : 0.0;
    double fatsPercent = totalGramsCaloric > 0 ? (calculatedFats * 9) / totalGramsCaloric : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorManager.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _isCalculatorExpanded = !_isCalculatorExpanded;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calculate_outlined, color: ColorManager.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Macro & Calorie Estimator',
                        style: TextStyle(
                          color: ColorManager.textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isCalculatorExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: ColorManager.textSecondary,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              AnimatedCrossFade(
                firstChild: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _collapsedMetric('Calories', '$calculatedCalories kcal'),
                    _collapsedMetric('Carbs', '${calculatedCarbs}g'),
                    _collapsedMetric('Protein', '${calculatedProtein}g'),
                    _collapsedMetric('Fats', '${calculatedFats}g'),
                  ],
                ),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Adjust Weight:',
                          style: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp),
                        ),
                        Text(
                          '${_calculatorWeight.toStringAsFixed(1)} kg',
                          style: TextStyle(color: ColorManager.primary, fontWeight: FontWeight.bold, fontSize: 14.sp),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: ColorManager.primary,
                        inactiveTrackColor: ColorManager.divider,
                        thumbColor: ColorManager.primary,
                        overlayColor: ColorManager.primary.withValues(alpha: 0.2),
                        valueIndicatorColor: ColorManager.primary,
                      ),
                      child: Slider(
                        value: _calculatorWeight,
                        min: 40.0,
                        max: 150.0,
                        divisions: 220,
                        label: '${_calculatorWeight.toStringAsFixed(1)} kg',
                        onChanged: (val) {
                          setState(() {
                            _calculatorWeight = val;
                          });
                        },
                      ),
                    ),
                    
                    Text(
                      'Activity Level:',
                      style: TextStyle(color: ColorManager.textSecondary, fontSize: 13.sp),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _activityChip('LOW', 'Low', 'Low'),
                        _activityChip('MODERATE', 'Moderate', 'Moderate'),
                        _activityChip('HIGH', 'Active', 'Active'),
                      ],
                    ),
                    
                    const Divider(height: 32),
                    
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Estimated Daily Caloric Needs',
                            style: TextStyle(color: ColorManager.textSecondary, fontSize: 12.sp),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$calculatedCalories kcal',
                            style: TextStyle(
                              color: ColorManager.textPrimary,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            goal == 'GAIN' 
                                ? 'Includes +300 kcal bulking surplus'
                                : (goal == 'LOSE' ? 'Includes -400 kcal shredding deficit' : 'Maintenance balance'),
                            style: TextStyle(color: ColorManager.primary, fontSize: 11.sp, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 12,
                        width: double.infinity,
                        child: Row(
                          children: [
                            if (carbsPercent > 0)
                              Expanded(
                                flex: (carbsPercent * 100).round(),
                                child: Container(color: Colors.teal),
                              ),
                            if (proteinPercent > 0)
                              Expanded(
                                flex: (proteinPercent * 100).round(),
                                child: Container(color: Colors.orange),
                              ),
                            if (fatsPercent > 0)
                              Expanded(
                                flex: (fatsPercent * 100).round(),
                                child: Container(color: Colors.purple),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _macroLabel('Carbs', '${calculatedCarbs}g', Colors.teal, '${(carbsPercent * 100).toInt()}%'),
                        _macroLabel('Protein', '${calculatedProtein}g', Colors.orange, '${(proteinPercent * 100).toInt()}%'),
                        _macroLabel('Fats', '${calculatedFats}g', Colors.purple, '${(fatsPercent * 100).toInt()}%'),
                      ],
                    ),
                  ],
                ),
                crossFadeState: _isCalculatorExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _collapsedMetric(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: ColorManager.textPrimary,
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _activityChip(String code, String label, String tooltip) {
    final isSelected = _calculatorActivity == code;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12.sp)),
      selected: isSelected,
      selectedColor: ColorManager.primary.withValues(alpha: 0.2),
      checkmarkColor: ColorManager.primary,
      labelStyle: TextStyle(
        color: isSelected ? ColorManager.primary : ColorManager.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: ColorManager.surface,
      side: BorderSide(color: isSelected ? ColorManager.primary : ColorManager.divider),
      onSelected: (val) {
        if (val) {
          setState(() {
            _calculatorActivity = code;
          });
        }
      },
    );
  }

  Widget _macroLabel(String title, String grams, Color color, String pct) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title ($pct)',
              style: TextStyle(color: ColorManager.textSecondary, fontSize: 11.sp),
            ),
            Text(
              grams,
              style: TextStyle(color: ColorManager.textPrimary, fontWeight: FontWeight.bold, fontSize: 13.sp),
            ),
          ],
        ),
      ],
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
