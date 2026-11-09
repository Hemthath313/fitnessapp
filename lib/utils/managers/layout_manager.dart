import 'package:fitness_app/utils/managers/app_font.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Screen spacing shared by every page.
class AppSpacing {
  AppSpacing._();

  /// Left / right gutter of a page's content (unscaled; use [gutter] with
  /// ScreenUtil, or this value directly where ScreenUtil is not used).
  static const double pageGutter = 20;

  /// Scaled page gutter.
  static double get gutter => pageGutter.w;

  /// Gap between sections on a page.
  static const double section = 16;

  /// Gap between cards in a list or grid.
  static const double card = 12;
}

/// Role-based sizes on top of the app type scale ([AppType]). Use these for
/// text roles so a screen's title, section headings and body text match the
/// rest of the app.
class AppText {
  AppText._();

  /// Title in a pushed screen's app bar.
  static double get appBarTitle => AppType.headline.sp;

  /// Big heading at the top of a page ("Progress", "Body Focus").
  static double get pageTitle => AppType.display.sp;

  /// Heading of a section on a page ("Workout Plan", "Challenges").
  static double get sectionTitle => AppType.title.sp;

  /// Title inside a card.
  static double get cardTitle => AppType.bodyLarge.sp;

  /// Body text.
  static double get body => AppType.body.sp;

  /// Secondary text and metadata.
  static double get secondary => AppType.caption.sp;

  /// Smallest allowed text: badges, chart labels.
  static double get caption => AppType.micro.sp;
}
