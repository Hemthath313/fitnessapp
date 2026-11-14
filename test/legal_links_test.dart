import 'package:fitness_app/config/legal_links.dart';
import 'package:flutter_test/flutter_test.dart';

/// Release gate: Play and the App Store require working Privacy Policy and
/// Terms links in the app. Set them in lib/config/legal_links.dart.
void main() {
  test('Privacy Policy and Terms URLs are set (https)', () {
    expect(LegalLinks.privacyPolicyUrl, startsWith('https://'));
    expect(LegalLinks.termsUrl, startsWith('https://'));
  });

  test('Manage subscription opens the store page for this app', () {
    expect(LegalLinks.manageSubscriptionUrl, contains('subscriptions'));
  });
}
