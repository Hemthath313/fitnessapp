import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Public links the stores require inside the app.
///
/// RELEASE: fill in both URLs (any public page works: your website, a Google
/// Site, Notion page...). The same Privacy Policy URL goes into Play Console.
/// test/legal_links_test.dart fails until they are set.
class LegalLinks {
  LegalLinks._();

  static const String privacyPolicyUrl =
      'https://hemthath313.github.io/fitnessapp/privacy-policy.html';
  static const String termsUrl =
      'https://hemthath313.github.io/fitnessapp/terms-of-use.html';

  static const String androidPackage = 'com.gymbuddy.fitnessapp';

  /// Store page where the user can cancel or change their subscription.
  static String get manageSubscriptionUrl =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? 'https://apps.apple.com/account/subscriptions'
          : 'https://play.google.com/store/account/subscriptions?package=$androidPackage';

  static bool get isConfigured =>
      privacyPolicyUrl.startsWith('https://') && termsUrl.startsWith('https://');

  /// Opens [url] in the browser, with a friendly message if it can't.
  static Future<void> open(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final uri = Uri.tryParse(url);
    var ok = false;
    if (url.isNotEmpty && uri != null) {
      try {
        ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
    if (!ok) {
      messenger?.showSnackBar(
        const SnackBar(content: Text("Couldn't open the page. Please try again later.")),
      );
    }
  }
}
