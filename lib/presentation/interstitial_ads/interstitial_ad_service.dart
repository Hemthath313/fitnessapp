import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:fitness_app/utils/ad_config.dart';
import 'package:fitness_app/services/ad_consent_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InterstitialAdService {
  static InterstitialAd? _interstitialAd;
  static bool _isAdLoaded = false;
  static int _adLoadAttempts = 0;
  static const int _maxLoadAttempts = 3;
  static Completer<void>? _loadCompleter;

  static Future<void> loadInterstitialAd({String? adUnitId}) async {
    // Never request an ad before consent is resolved and the SDK started.
    if (!AdConsentService.adsReady.value) return;
    if (_isAdLoaded) {
      debugPrint('Interstitial ad already loaded');
      return;
    }

    final String unitId = adUnitId ?? AdConfig.interstitialAdUnitId;

    // If already loading, wait for it to complete
    if (_loadCompleter != null && !_loadCompleter!.isCompleted) {
      debugPrint('Interstitial ad already loading, waiting...');
      return _loadCompleter!.future;
    }

    _loadCompleter = Completer<void>();

    try {
      await InterstitialAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Interstitial ad loaded successfully');
            _interstitialAd = ad;
            _isAdLoaded = true;
            _adLoadAttempts = 0;

            // Set up ad callbacks
            _interstitialAd!.fullScreenContentCallback =
                FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                debugPrint('Interstitial ad showed full screen content');
              },
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('Interstitial ad dismissed');
                ad.dispose();
                _isAdLoaded = false;
                _interstitialAd = null;
                // No automatic reload: the next one is preloaded only when
                // it will actually be due (keeps the match rate healthy).
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Interstitial ad failed to show: $error');
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
            debugPrint('Failed to load interstitial ad: $error');
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
      debugPrint('Error loading interstitial ad: $e');
      _isAdLoaded = false;
      if (_loadCompleter != null && !_loadCompleter!.isCompleted) {
        _loadCompleter!.complete();
      }
    }
  }

  static Future<void> showInterstitialAd({bool forceShow = false}) async {
    // If ad is not loaded, try to load and wait for it
    if (!_isAdLoaded) {
      debugPrint('Interstitial ad not loaded, loading now...');
      await loadInterstitialAd();
    }

    // Wait a bit for the ad to be ready (if it just finished loading)
    if (!_isAdLoaded) {
      debugPrint('Interstitial ad still not loaded after loading attempt');
      return;
    }

    if (_interstitialAd != null) {
      try {
        await _interstitialAd!.show();
        debugPrint('Interstitial ad shown successfully');
      } catch (e) {
        debugPrint('Error showing interstitial ad: $e');
        _isAdLoaded = false;
        _interstitialAd = null;
      }
    } else {
      debugPrint('Interstitial ad is null');
    }
  }

  // Specific method for strength workout access
  static Future<void> showStrengthWorkoutAd() async {
    debugPrint('Attempting to show strength workout ad...');
    // Wait for ad to load
    await loadInterstitialAd(
        adUnitId: AdConfig.getInterstitialAdUnitIdForContext('strength'));
    // Then show it
    await showInterstitialAd();
  }

  // Specific method for workout completion
  static Future<void> showWorkoutCompletionAd() async {
    debugPrint('Attempting to show workout completion ad...');
    // Wait for ad to load
    await loadInterstitialAd(
        adUnitId: AdConfig.getInterstitialAdUnitIdForContext('workout'));
    // Then show it
    await showInterstitialAd();
  }

  // ---- After-workout placement (free users only) -------------------------
  //
  // Never during a workout and never over the celebration screen: the ad
  // shows once the user taps Done on the summary, at most once every
  // [workoutsPerAd] finished workouts.

  static const int workoutsPerAd = 3;
  static const String _counterKey = 'interstitial_workouts_since_ad';

  /// Call when a workout is saved. Counts it and preloads an ad if one will
  /// be due when the user leaves the summary.
  static Future<void> onWorkoutFinished({required bool isPremium}) async {
    if (isPremium || !AdConsentService.adsReady.value) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = (prefs.getInt(_counterKey) ?? 0) + 1;
      await prefs.setInt(_counterKey, count);
      if (count >= workoutsPerAd) {
        unawaited(loadInterstitialAd(
            adUnitId: AdConfig.getInterstitialAdUnitIdForContext('workout')));
      }
    } catch (_) {}
  }

  /// Call after the summary screen is closed. Shows the ad only if one is
  /// due and already loaded (never waits for a slow ad).
  static Future<void> showIfDueAfterWorkout({required bool isPremium}) async {
    if (isPremium || !AdConsentService.adsReady.value) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_counterKey) ?? 0;
      if (count < workoutsPerAd || !_isAdLoaded || _interstitialAd == null) {
        return;
      }
      await prefs.setInt(_counterKey, 0);
      await _interstitialAd!.show();
    } catch (e) {
      debugPrint('Interstitial after workout failed: $e');
    }
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
