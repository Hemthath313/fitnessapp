import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared card sizes so shelves and grids look like one family everywhere.
///
/// Radii live in `AppRadius`; this file owns heights, grid proportions and the
/// padding / artwork sizes of the gradient hero cards.
class AppCardSize {
  AppCardSize._();

  /// Height of a card in a horizontal hero shelf (Home workout plan, Home
  /// Challenges, Challenges hub). Grows with the system text size so large
  /// text never overflows, but never gets smaller than the base height.
  static double shelfHeight(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    final growth = scale > 1.0 ? 1.0 + (scale - 1.0) * 0.8 : 1.0;
    return 204.h * growth;
  }

  /// Inner padding of a gradient hero card.
  static double get heroPadding => 16.w;

  /// Body-part artwork size and top offset on a shelf hero card.
  static double get heroImageSize => 116.w;
  static double get heroImageTop => 36.h;

  /// Title size on a shelf hero card.
  static double get heroTitleSize => 18.sp;

  /// Vertical padding of the white call-to-action button on a hero card.
  static double get heroButtonPadding => 11.h;

  /// Category grids (Workouts tab, Body Focus): width / height of a tile.
  static const double gridAspectRatio = 1.05;

  /// Gap between tiles in a category grid.
  static double get gridSpacing => 12.w;
}
