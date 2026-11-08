import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Gently pulsing placeholder shown while content loads, so the screen keeps
/// its shape instead of showing a lone spinner. Pulses with a plain opacity
/// animation (no extra package). Honors "reduce motion".
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, required this.child});

  final Widget child;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      _c.stop();
      _started = false;
    } else if (!_started) {
      _c.repeat(reverse: true);
      _started = true;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) =>
            Opacity(opacity: 0.55 + 0.45 * _c.value, child: child),
        child: widget.child,
      ),
    );
  }
}

/// A rounded grey block, the building piece of skeleton layouts.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height.h,
      decoration: BoxDecoration(
        color: ColorManager.surfaceLight,
        borderRadius: BorderRadius.circular(radius.r),
      ),
    );
  }
}

/// Stack of card-shaped placeholders (e.g. history feed, lists).
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 84,
    this.padding,
  });

  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Padding(
        padding: padding ?? EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        child: Column(
          children: [
            for (var i = 0; i < itemCount; i++) ...[
              Container(
                key: Key('skeleton_item_$i'),
                height: itemHeight.h,
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: ColorManager.surface,
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Row(
                  children: [
                    SkeletonBox(width: 44.w, height: 44, radius: 12),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SkeletonBox(height: 14),
                          SizedBox(height: 10.h),
                          SkeletonBox(width: 120.w, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (i != itemCount - 1) SizedBox(height: 10.h),
            ],
          ],
        ),
      ),
    );
  }
}
