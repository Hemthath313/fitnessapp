/// Corner-radius tokens for the dashboard design system.
///
/// Use with ScreenUtil, e.g. `BorderRadius.circular(AppRadius.card.r)`.
class AppRadius {
  AppRadius._();

  /// Gradient hero cards (plan, featured challenge, day cards).
  static const double hero = 24;

  /// Standard surface cards (snapshot, weekly bars, quick actions, challenges).
  static const double card = 22;

  /// Small tiles and inner panels.
  static const double tile = 16;

  /// Pills, chips and badges.
  static const double pill = 20;
}
