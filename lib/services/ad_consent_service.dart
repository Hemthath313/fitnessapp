import 'dart:async';

import 'package:fitness_app/utils/ad_config.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google UMP consent (required by AdMob for EEA / UK / Switzerland users)
/// and the single place that starts the Mobile Ads SDK.
///
/// Flow: ask Google whether this user needs a consent form, show it if so,
/// then start the ads SDK only when ads may be requested. Banners and
/// interstitials listen to [adsReady] and never load before that.
///
/// AdMob console: Privacy & messaging -> GDPR -> create and publish a message
/// for this app, otherwise no form is shown and EU users get limited ads.
class AdConsentService {
  AdConsentService._();

  /// True once consent is resolved and the Mobile Ads SDK is initialised.
  static final ValueNotifier<bool> adsReady = ValueNotifier<bool>(false);

  /// True when the user must be able to change their choice later
  /// (shows the "Privacy choices" row in More).
  static final ValueNotifier<bool> privacyOptionsRequired =
      ValueNotifier<bool>(false);

  static Completer<void>? _running;

  /// Call once after runApp. Safe to call again; later calls reuse the first.
  static Future<void> initialize() {
    if (_running != null) return _running!.future;
    final done = _running = Completer<void>();

    final params = ConsentRequestParameters(
      consentDebugSettings: kDebugMode
          ? ConsentDebugSettings(testIdentifiers: AdConfig.testDeviceIds)
          : null,
    );

    void finish() {
      _startAdsIfAllowed().whenComplete(() {
        if (!done.isCompleted) done.complete();
      });
    }

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () {
          ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
            if (error != null) {
              debugPrint('AdConsent: form error ${error.errorCode} ${error.message}');
            }
            finish();
          });
        },
        (FormError error) {
          // Offline or misconfigured: fall back to the last stored choice.
          debugPrint('AdConsent: update failed ${error.errorCode} ${error.message}');
          finish();
        },
      );
    } catch (e) {
      debugPrint('AdConsent: unavailable: $e');
      if (!done.isCompleted) done.complete();
    }
    return done.future;
  }

  static Future<void> _startAdsIfAllowed() async {
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      privacyOptionsRequired.value =
          status == PrivacyOptionsRequirementStatus.required;

      if (!await ConsentInformation.instance.canRequestAds()) return;
      if (adsReady.value) return;

      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: AdConfig.testDeviceIds),
      );
      await MobileAds.instance.initialize();
      adsReady.value = true;
    } catch (e) {
      debugPrint('AdConsent: could not start ads: $e');
    }
  }

  /// "Privacy choices" in More: lets the user change their consent.
  static Future<void> showPrivacyOptions() async {
    final completer = Completer<void>();
    try {
      ConsentForm.showPrivacyOptionsForm((FormError? error) {
        if (error != null) {
          debugPrint('AdConsent: privacy form error ${error.message}');
        }
        _startAdsIfAllowed().whenComplete(() {
          if (!completer.isCompleted) completer.complete();
        });
      });
    } catch (e) {
      debugPrint('AdConsent: privacy form unavailable: $e');
      if (!completer.isCompleted) completer.complete();
    }
    return completer.future;
  }
}
