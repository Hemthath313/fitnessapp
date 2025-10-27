import 'package:flutter/foundation.dart'; // For kDebugMode

class AdConfig {
  // Banner Ad Unit IDs
  static const String homeBannerAdUnitId =
      'ca-app-pub-5975958510203735/1854291738'; // dashboard-banner-ad
  static const String chatBannerAdUnitId =
      'ca-app-pub-5975958510203735/7057489281'; // chat page banner-ad
  static const String settingsBannerAdUnitId =
      'ca-app-pub-5975958510203735/7110487847'; // settings-page-banner-ad

  // Interstitial Ad Unit ID - FIXED: Use proper interstitial ad unit ID
  static const String _interstitialAdUnitId =
      'ca-app-pub-5975958510203735/7217271380'; // intersitial-ad (REPLACE WITH YOUR ACTUAL INTERSTITIAL AD UNIT ID)

  // Test Ad Unit IDs (for development)
  static const String testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  // Check if running in debug mode - FIXED: Use proper debug detection
  static bool get isDebugMode {
    return kDebugMode; // Use Flutter's built-in debug mode detection
  }

  // Get banner ad unit ID based on page
  static String getBannerAdUnitIdForPage(String pageName) {
    if (isDebugMode) {
      return testBannerAdUnitId;
    }

    switch (pageName.toLowerCase()) {
      case 'home':
      case 'dashboard':
        return homeBannerAdUnitId;
      case 'chat':
        return chatBannerAdUnitId;
      case 'settings':
        return settingsBannerAdUnitId;
      default:
        return homeBannerAdUnitId;
    }
  }

  // Get interstitial ad unit ID based on context
  static String getInterstitialAdUnitIdForContext(String context) {
    if (isDebugMode) {
      return testInterstitialAdUnitId;
    }

    switch (context.toLowerCase()) {
      case 'strength':
      case 'workout':
      case 'completion':
      default:
        return _interstitialAdUnitId;
    }
  }

  // Get the main banner ad unit ID
  static String get bannerAdUnitId {
    return isDebugMode ? testBannerAdUnitId : homeBannerAdUnitId;
  }

  // Get the main interstitial ad unit ID
  static String get interstitialAdUnitId {
    return isDebugMode ? testInterstitialAdUnitId : _interstitialAdUnitId;
  }

  // Debug helper method to print current configuration
  static void printAdConfig() {
    print('=== AD CONFIGURATION ===');
    print('Debug Mode: $isDebugMode');
    print(
        'Banner Ad ID: ${isDebugMode ? testBannerAdUnitId : homeBannerAdUnitId}');
    print(
        'Interstitial Ad ID: ${isDebugMode ? testInterstitialAdUnitId : _interstitialAdUnitId}');
    print('========================');
  }
}
