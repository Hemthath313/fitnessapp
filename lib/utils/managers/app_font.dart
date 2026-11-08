/// App-wide font family.
///
/// `null` uses the platform default font. To switch to a bundled font (for
/// example Urbanist): add the .ttf files under `assets/fonts/`, declare them in
/// `pubspec.yaml` under `flutter: fonts:`, then set [family] to the declared
/// family name, e.g. `'Urbanist'`.
class AppFonts {
  AppFonts._();

  static const String? family = null;
}

/// The app-wide type scale. Use these (with `.sp`) instead of ad-hoc sizes so
/// every screen stays consistent. `test/type_scale_consistency_test.dart`
/// fails if a `fontSize:` outside this scale is introduced.
class AppType {
  AppType._();

  static const double micro = 11; // badges, chart labels (minimum size)
  static const double caption = 12; // captions, helper text, chips
  static const double small = 13; // dense body text
  static const double body = 14; // default body text
  static const double bodyLarge = 16; // emphasised body, buttons
  static const double title = 18; // section / card titles
  static const double headline = 20; // screen titles, hero titles
  static const double display = 24; // large headings
  static const double numeral = 32; // big stat numbers

  static const List<double> scale = [
    micro, caption, small, body, bodyLarge, title, headline, display, numeral,
  ];
}
