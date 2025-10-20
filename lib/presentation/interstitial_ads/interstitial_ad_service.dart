import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:fitness_app/utils/ad_config.dart';

class InterstitialAdService {
  static InterstitialAd? _interstitialAd;
  static bool _isAdLoaded = false;
  static int _adLoadAttempts = 0;
  static const int _maxLoadAttempts = 3;
  static bool _hasShownAdForSession =
      false; // Track if ad shown in current session

  static Future<void> loadInterstitialAd({String? adUnitId}) async {
    if (_isAdLoaded) return;

    final String unitId = adUnitId ?? AdConfig.interstitialAdUnitId;

    try {
      await InterstitialAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            print('Interstitial ad loaded successfully');
            _interstitialAd = ad;
            _isAdLoaded = true;
            _adLoadAttempts = 0;

            // Set up ad callbacks
            _interstitialAd!.fullScreenContentCallback =
                FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                print('Interstitial ad showed full screen content');
              },
              onAdDismissedFullScreenContent: (ad) {
                print('Interstitial ad dismissed');
                ad.dispose();
                _isAdLoaded = false;
                _interstitialAd = null;
                // Load next ad for future use
                loadInterstitialAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                print('Interstitial ad failed to show: $error');
                ad.dispose();
                _isAdLoaded = false;
                _interstitialAd = null;
                // Retry loading
                if (_adLoadAttempts < _maxLoadAttempts) {
                  _adLoadAttempts++;
                  Future.delayed(const Duration(seconds: 2), () {
                    loadInterstitialAd(adUnitId: unitId);
                  });
                }
              },
            );
          },
          onAdFailedToLoad: (error) {
            print('Failed to load interstitial ad: $error');
            _isAdLoaded = false;
            _interstitialAd = null;

            // Retry loading
            if (_adLoadAttempts < _maxLoadAttempts) {
              _adLoadAttempts++;
              Future.delayed(const Duration(seconds: 2), () {
                loadInterstitialAd(adUnitId: unitId);
              });
            }
          },
        ),
      );
    } catch (e) {
      print('Error loading interstitial ad: $e');
      _isAdLoaded = false;
    }
  }

  static Future<void> showInterstitialAd({bool forceShow = false}) async {
    // If not forced and already shown in session, don't show again
    if (!forceShow && _hasShownAdForSession) {
      print('Ad already shown in this session, skipping');
      return;
    }

    if (_isAdLoaded && _interstitialAd != null) {
      try {
        await _interstitialAd!.show();
        _hasShownAdForSession = true; // Mark as shown for this session
      } catch (e) {
        print('Error showing interstitial ad: $e');
        _isAdLoaded = false;
        _interstitialAd = null;
      }
    } else {
      print('Interstitial ad not loaded yet');
      // Try to load and show
      await loadInterstitialAd();
    }
  }

  // Specific method for strength workout access
  static Future<void> showStrengthWorkoutAd() async {
    await loadInterstitialAd(
        adUnitId: AdConfig.getInterstitialAdUnitIdForContext('strength'));
    await showInterstitialAd(forceShow: true);
  }

  // Specific method for workout completion
  static Future<void> showWorkoutCompletionAd() async {
    await loadInterstitialAd(
        adUnitId: AdConfig.getInterstitialAdUnitIdForContext('workout'));
    await showInterstitialAd();
  }

  static bool get isAdLoaded => _isAdLoaded;

  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
  }

  // Reset session flag (call this when app restarts or user logs out)
  static void resetSession() {
    _hasShownAdForSession = false;
  }
}
