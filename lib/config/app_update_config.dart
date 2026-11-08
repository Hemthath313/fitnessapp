/// Central Update Configuration for Gym Buddy.
///
/// Defines the Firestore collection and document names, hardcoded minimum version safeguards,
/// and store URLs.
class AppUpdateConfig {
  /// Firestore collection for remote configuration
  static const String firestoreConfigCollection = 'config';

  /// Firestore document ID for app version configuration
  static const String firestoreConfigDocument = 'app_version';

  /// Hardcoded minimum required semantic version to run Gym Buddy (local safeguard).
  /// Any installed app with a version below this will trigger a mandatory update.
  static String minimumRequiredVersion = '1.0.10';

  /// Hardcoded minimum required build number.
  /// If installed version equals [minimumRequiredVersion], the build number must be >= this.
  static int minimumRequiredBuildNumber = 32;

  /// Default baseline matching current app build in pubspec.yaml
  static const String defaultMinimumRequiredVersion = '1.0.10';
  static const int defaultMinimumRequiredBuildNumber = 32;

  /// SharedPreferences key for caching the last successfully fetched remote config
  static const String cachedRemoteConfigKey = 'gym_buddy_cached_remote_update_config';

  /// Gym Buddy application package name on Google Play Store
  static const String playStorePackageName = 'com.gymbuddy.fitnessapp';

  /// Primary market URI to open Google Play Store directly in the Play Store app
  static String get marketUrl => 'market://details?id=$playStorePackageName';

  /// Web fallback URL for Google Play Store listing
  static String get webPlayStoreUrl =>
      'https://play.google.com/store/apps/details?id=$playStorePackageName';

  /// Resets configuration back to defaults (primarily for test teardown)
  static void reset() {
    minimumRequiredVersion = defaultMinimumRequiredVersion;
    minimumRequiredBuildNumber = defaultMinimumRequiredBuildNumber;
  }
}
