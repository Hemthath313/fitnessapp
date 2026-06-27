import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:fitness_app/utils/ad_config.dart';

class InterstitialAdService {
  static InterstitialAd? _interstitialAd;
  static bool _isAdLoaded = false;
  static int _adLoadAttempts = 0;
  static const int _maxLoadAttempts = 3;
  static Completer<void>? _loadCompleter;

  static Future<void> loadInterstitialAd({String? adUnitId}) async {
    if (_isAdLoaded) {
      print('Interstitial ad already loaded');
      return;
    }

    final String unitId = adUnitId ?? AdConfig.interstitialAdUnitId;

    // If already loading, wait for it to complete
    if (_loadCompleter != null && !_loadCompleter!.isCompleted) {
      print('Interstitial ad already loading, waiting...');
      return _loadCompleter!.future;
    }

    _loadCompleter = Completer<void>();

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

            // Complete the completer when ad is loaded
            if (!_loadCompleter!.isCompleted) {
              _loadCompleter!.complete();
            }
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

            // Complete the completer even on failure
            if (_loadCompleter != null && !_loadCompleter!.isCompleted) {
              _loadCompleter!.complete();
            }
          },
        ),
      );

      // Wait for the loading to complete (either success or failure)
      await _loadCompleter!.future;
    } catch (e) {
      print('Error loading interstitial ad: $e');
      _isAdLoaded = false;
      if (_loadCompleter != null && !_loadCompleter!.isCompleted) {
        _loadCompleter!.complete();
      }
    }
  }

  static Future<void> showInterstitialAd({bool forceShow = false}) async {
    // If ad is not loaded, try to load and wait for it
    if (!_isAdLoaded) {
      print('Interstitial ad not loaded, loading now...');
      await loadInterstitialAd();
    }

    // Wait a bit for the ad to be ready (if it just finished loading)
    if (!_isAdLoaded) {
      print('Interstitial ad still not loaded after loading attempt');
      return;
    }

    if (_interstitialAd != null) {
      try {
        await _interstitialAd!.show();
        print('Interstitial ad shown successfully');
      } catch (e) {
        print('Error showing interstitial ad: $e');
        _isAdLoaded = false;
        _interstitialAd = null;
      }
    } else {
      print('Interstitial ad is null');
    }
  }

  // Specific method for strength workout access
  static Future<void> showStrengthWorkoutAd() async {
    print('Attempting to show strength workout ad...');
    // Wait for ad to load
    await loadInterstitialAd(
        adUnitId: AdConfig.getInterstitialAdUnitIdForContext('strength'));
    // Then show it
    await showInterstitialAd();
  }

  // Specific method for workout completion
  static Future<void> showWorkoutCompletionAd() async {
    print('Attempting to show workout completion ad...');
    // Wait for ad to load
    await loadInterstitialAd(
        adUnitId: AdConfig.getInterstitialAdUnitIdForContext('workout'));
    // Then show it
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
    // Session tracking removed - ads can show multiple times
  }
}
