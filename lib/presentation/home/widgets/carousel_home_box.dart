import 'package:fitness_app/presentation/home/widgets/gradient_hero_card.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A card in the dashboard Challenges shelf (30-Day Six-Pack, Exercise of the
/// Week...). Same gradient + illustration style as the programme cards so the
/// whole shelf reads as one family.
class CarouselHomeBox extends StatelessWidget {
  const CarouselHomeBox({
    super.key,
    this.deviceWidth,
    this.image,
    required this.onTap,
    required this.title,
    this.badge = 'CHALLENGE',
    this.subtitle,
    this.progress,
    this.actionText,
    this.heroKey = 'abs',
    this.tone = HeroTone.teal,
    this.photoAsset,
  });

  /// Legacy parameter, no longer used (cards size to the shelf).
  final double? deviceWidth;

  /// Legacy photo path, no longer used (cards use the hero illustrations).
  final String? image;

  final VoidCallback onTap;
  final String title;
  final String badge;
  final String? subtitle;
  final double? progress;
  final String? actionText;

  /// Body-part illustration key, see [HeroImages.forKey].
  final String heroKey;
  final HeroTone tone;

  /// Optional transparent cut-out photo; replaces the illustration when set.
  final String? photoAsset;

  /// Fixed height shared by every card in the shelf.
  static double get height => 232.h;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: GradientHeroCard(
        tone: tone,
        imageAsset: HeroImages.forKey(heroKey),
        photoAsset: photoAsset,
        imageSize: 130.w,
        imageTop: 40.h,
        height: height,
        padding: EdgeInsets.all(18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(child: HeroBadge(text: badge.toUpperCase())),
              ],
            ),
            SizedBox(height: 14.h),
            Padding(
              padding: EdgeInsets.only(right: GradientHeroCard.textInset),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  height: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 6.h),
              Padding(
                padding: EdgeInsets.only(right: GradientHeroCard.textInset),
                child: Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
            if (progress != null) ...[
              SizedBox(height: 10.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: progress!.clamp(0.0, 1.0),
                  minHeight: 5.h,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
            const Spacer(),
            if (actionText != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onTap,
                  icon: Icon(Icons.arrow_forward_rounded,
                      size: 16.sp, color: ColorManager.onMint),
                  label: Text(
                    actionText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ColorManager.onMint,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
