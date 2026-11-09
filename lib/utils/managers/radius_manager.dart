/// Corner-radius tokens for the dashboard design system.
///
/// Use with ScreenUtil, e.g. `BorderRadius.circular(AppRadius.card.r)`.
class AppRadius {
  AppRadius._();

  /// Gradient hero cards (plan, featured challenge, day cards).
  static const double hero = 24;

  /// Standard surface cards (snapshot, weekly bars, quick actions, challenges).
  static const double card = 22;

  /// Tiles and inner panels sitting on a card (grid tiles, list rows, stat
  /// boxes).
  static const double tile = 16;

  /// Small inner elements: input boxes, icon chips, compact info rows.
  static const double small = 12;

  /// Buttons (elevated, outlined, text and the shared lime-green button).
  static const double button = 14;

  /// Pills, chips and badges.
  static const double pill = 20;
}
