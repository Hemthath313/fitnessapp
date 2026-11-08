import 'package:fitness_app/data/transformation_plans_data.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/radius_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Colour family of a [GradientHeroCard].
enum HeroTone { teal, coral, green, purple }

/// Picks the mint body-part cut-out used on hero cards.
class HeroImages {
  HeroImages._();

  static const _base = 'assets/images/anatomy_mint/mint_';

  /// `key` is one of: chest, back, shoulders, biceps, triceps, legs, abs, cardio.
  static String forKey(String key) => '$_base$key.png';

  /// Optional transparent-background PNG of a person for a body-part key.
  /// Drop files named `<key>.png` into `assets/images/hero/`; when a file is
  /// missing the mint illustration is shown instead.
  static String personForKey(String key) => 'assets/images/hero/$key.png';

  /// Derives the person image path from an illustration path
  /// (`.../mint_chest.png` -> `assets/images/hero/chest.png`).
  static String? personForIllustration(String illustrationAsset) {
    final m = RegExp(r'mint_([a-z]+)\.png$').firstMatch(illustrationAsset);
    return m == null ? null : personForKey(m.group(1)!);
  }

  /// Image key used for a transformation programme.
  static String keyForPlan(String planId) {
    if (planId == TransformationPlansData.beginnerFitness30.id) return 'abs';
    if (planId == TransformationPlansData.weightLoss60.id) return 'cardio';
    if (planId == TransformationPlansData.muscleBuilding90.id) return 'chest';
    if (planId == TransformationPlansData.strength12Week.id) return 'back';
    return 'shoulders';
  }

  /// Card colour used for a programme everywhere it appears.
  static HeroTone toneForPlan(String planId) {
    if (planId == TransformationPlansData.beginnerFitness30.id) {
      return HeroTone.green;
    }
    if (planId == TransformationPlansData.weightLoss60.id) {
      return HeroTone.coral;
    }
    if (planId == TransformationPlansData.muscleBuilding90.id) {
      return HeroTone.teal;
    }
    return HeroTone.purple;
  }

  /// Cut-out photo for the 30-Day Six-Pack challenge card.
  static const String sixPackPhoto = 'assets/images/hero/six_pack_athlete.png';

  /// Cut-out photo for the Exercise of the Week card.
  static const String weeklyTechniquePhoto =
      'assets/images/hero/weekly_pullup_athlete.png';

  /// Full photo used as the banner artwork for a programme, if it has one.
  static String? photoForPlan(String planId) {
    if (planId == TransformationPlansData.muscleBuilding90.id) {
      return 'assets/images/hero/muscle_building_athlete.png';
    }
    if (planId == TransformationPlansData.weightLoss60.id) {
      return 'assets/images/hero/weight_loss_athlete.png';
    }
    if (planId == TransformationPlansData.beginnerFitness30.id) {
      return 'assets/images/hero/beginner_standing_man.png';
    }
    if (planId == TransformationPlansData.strength12Week.id) {
      return 'assets/images/hero/strength_building_athlete.png';
    }
    return null;
  }

  /// Maps a free-text fitness goal ("Lose weight", "Build muscle"...) to an image.
  static String forGoal(String? goal) {
    final g = (goal ?? '').toLowerCase();
    if (g.contains('lose') ||
        g.contains('fat') ||
        g.contains('weight') ||
        g.contains('cut')) {
      return forKey('cardio');
    }
    if (g.contains('strength')) return forKey('back');
    if (g.contains('tone') || g.contains('abs')) return forKey('abs');
    return forKey('chest');
  }
}

/// Shared "hero" surface for the dashboard: gradient background, soft glow and
/// a body-part illustration anchored top-right (as in the reference design).
///
/// Keep text out of the illustration area by giving it a right inset of about
/// `imageSize * 0.6`; full-width controls (buttons) may sit across the bottom.
class GradientHeroCard extends StatelessWidget {
  const GradientHeroCard({
    super.key,
    required this.child,
    required this.imageAsset,
    this.tone = HeroTone.teal,
    this.padding,
    this.imageSize,
    this.imageTop,
    this.radius,
    this.personAsset,
    this.photoAsset,
    this.height,
  });

  final Widget child;
  final String imageAsset;
  final HeroTone tone;
  final EdgeInsetsGeometry? padding;
  final double? imageSize;
  final double? imageTop;
  final double? radius;

  /// Transparent PNG of a person. Defaults to the file matching [imageAsset]
  /// under `assets/images/hero/`; the illustration is the fallback.
  final String? personAsset;

  /// Transparent cut-out photo (see [HeroImages.photoForPlan]). When set it
  /// replaces the illustration.
  final String? photoAsset;

  /// Fixed card height (e.g. inside a horizontal shelf). Null = size to content.
  final double? height;

  /// Horizontal space text should leave free for the artwork.
  static double get textInset => 120.w;

  List<Color> get _colors {
    switch (tone) {
      case HeroTone.coral:
        return [ColorManager.coralStart, ColorManager.coralEnd];
      case HeroTone.green:
        return const [Color(0xFF2F7A5C), Color(0xFF1E4331)];
      case HeroTone.purple:
        return const [Color(0xFF6A3FA0), Color(0xFF3F2766)];
      case HeroTone.teal:
        return [ColorManager.heroTealStart, ColorManager.heroTealMid];
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = imageSize ?? 140.w;
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _colors,
        ),
        borderRadius: BorderRadius.circular(radius ?? AppRadius.hero.r),
      ),
      child: Stack(
        children: [
          if (photoAsset != null)
            HeroPhoto(asset: photoAsset!)
          else
            Positioned.fill(
              child: HeroArt(
                illustrationAsset: imageAsset,
                personAsset:
                    personAsset ?? HeroImages.personForIllustration(imageAsset),
                size: size,
                top: imageTop ?? 8.h,
              ),
            ),
          Padding(
            padding: padding ?? EdgeInsets.all(16.w),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Transparent cut-out photo anchored top-right on a hero surface and cropped
/// at the bottom edge; its left and bottom edges fade into the card gradient.
/// Must be a direct child of a [Stack].
class HeroPhoto extends StatelessWidget {
  const HeroPhoto({
    super.key,
    required this.asset,
    this.widthFactor = 0.55,
    this.fadeLeft = 0.24,
    this.fadeBottom = 0.12,
  });

  final String asset;

  /// Share of the surface width the photo covers.
  final double widthFactor;

  /// Share of the photo width (from its left edge) that melts into the card
  /// gradient. 0 disables the fade.
  final double fadeLeft;

  /// Share of the photo height (from its bottom edge) that melts into the
  /// card gradient. 0 disables the fade.
  final double fadeBottom;

  static const Color _clear = Color(0x00FFFFFF);
  static const Color _solid = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    Widget photo = Image.asset(
      asset,
      fit: BoxFit.cover,
      alignment: const Alignment(0.7, -1),
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );

    // Soft left edge so the cut-out merges into the card instead of ending on
    // a hard line.
    if (fadeLeft > 0) {
      final inner = photo;
      photo = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [_clear, Color(0x4DFFFFFF), _solid, _solid],
          stops: [0, fadeLeft * 0.5, fadeLeft, 1],
        ).createShader(rect),
        child: inner,
      );
    }

    // Soft bottom edge so the photo dissolves behind the call-to-action.
    if (fadeBottom > 0) {
      final inner = photo;
      photo = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [_solid, _solid, Color(0x4DFFFFFF), _clear],
          stops: [0, 1 - fadeBottom, 1 - fadeBottom * 0.5, 1],
        ).createShader(rect),
        child: inner,
      );
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: widthFactor,
            heightFactor: 1,
            child: photo,
          ),
        ),
      ),
    );
  }
}

/// Small translucent label used on hero cards (e.g. "AI WORKOUT ROUTINE").
class HeroBadge extends StatelessWidget {
  const HeroBadge({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppRadius.pill.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 12.sp),
            SizedBox(width: 5.w),
          ],
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill showing a fact such as "~45 min" with a leading icon.
class HeroMetaChip extends StatelessWidget {
  const HeroMetaChip({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12.sp),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Artwork layer for hero surfaces: a transparent person photo anchored to the
/// bottom-right when available, otherwise the mint body-part illustration with
/// a soft glow. Place inside a [Stack] (e.g. `Positioned.fill`).
class HeroArt extends StatelessWidget {
  const HeroArt({
    super.key,
    required this.illustrationAsset,
    this.personAsset,
    required this.size,
    required this.top,
  });

  final String illustrationAsset;
  final String? personAsset;
  final double size;
  final double top;

  Widget _illustration() {
    return Stack(
      children: [
        // Soft glow behind the illustration
        Positioned(
          right: -size * 0.35,
          top: top - size * 0.25,
          child: IgnorePointer(
            child: Container(
              width: size * 1.5,
              height: size * 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -size * 0.12,
          top: top,
          width: size,
          height: size,
          child: IgnorePointer(
            child: Image.asset(
              illustrationAsset,
              fit: BoxFit.contain,
              alignment: Alignment.topRight,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final person = personAsset;
    if (person == null) return _illustration();

    return Stack(
      children: [
        Positioned(
          right: -6.w,
          top: 0,
          bottom: 0,
          width: size,
          child: IgnorePointer(
            child: Image.asset(
              person,
              fit: BoxFit.contain,
              alignment: Alignment.bottomRight,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => _illustration(),
            ),
          ),
        ),
      ],
    );
  }
}
