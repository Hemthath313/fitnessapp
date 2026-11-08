import 'package:fitness_app/presentation/home/widgets/carousel_home_box.dart';
import 'package:fitness_app/presentation/home/widgets/mini_challenge_cards.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Horizontal shelf for the dashboard Challenges section: [leading] cards
/// (e.g. the recommended programme), then the 30-Day Six-Pack, then [middle]
/// cards (other programmes), then the weekly technique. The next card peeks in
/// at the edge so the shelf reads as swipeable.
class CarouselSliderHomeWidget extends StatefulWidget {
  const CarouselSliderHomeWidget({
    super.key,
    this.leading = const [],
    this.middle = const [],
  });

  final List<Widget> leading;
  final List<Widget> middle;

  @override
  State<CarouselSliderHomeWidget> createState() => _CarouselSliderHomeWidgetState();
}

class _CarouselSliderHomeWidgetState extends State<CarouselSliderHomeWidget> {
  int _currentIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.88);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> carouselCards = [
      ...widget.leading,
      // 30-Day Six-Pack Challenge (genuine tracked progression challenge)
      const SixPackChallengeCard(),
      ...widget.middle,
      // Weekly Technique (single exercise form & tips)
      const ExerciseOfWeekCard(),
    ];

    return Column(
      children: [
        SizedBox(
          height: CarouselHomeBox.height + 4.h,
          child: PageView.builder(
            controller: _pageController,
            itemCount: carouselCards.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: carouselCards[index],
            ),
          ),
        ),
        SizedBox(height: 8.h),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(carouselCards.length, (index) {
            final isSelected = _currentIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isSelected ? 16.w : 6.w,
              height: 5.h,
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              decoration: BoxDecoration(
                color: isSelected ? ColorManager.primary : Colors.white24,
                borderRadius: BorderRadius.circular(4.r),
              ),
            );
          }),
        ),
      ],
    );
  }
}
