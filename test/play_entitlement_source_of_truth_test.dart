import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:fitness_app/services/iap_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake Play billing: returns [past] from queryPastPurchases (null = Play
/// could not answer).
class _FakeIap implements IAPService {
  List<PurchaseDetails>? past;
  _FakeIap(this.past);

  @override
  Future<List<PurchaseDetails>?> getAndroidPastPurchases() async => past;

  @override
  Stream<PurchaseDetails> get purchaseStream => const Stream.empty();

  @override
  Future<void> restorePurchases() async {}

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PurchaseDetails _owned(String id) => PurchaseDetails(
      productID: id,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: '',
        source: 'google_play',
      ),
      transactionDate: null,
      status: PurchaseStatus.purchased,
    );

SubscriptionProvider _provider(_FakeIap iap, {Map<String, dynamic>? firestoreDoc}) {
  return SubscriptionProvider(autoInitialize: false, iapService: iap)
    ..userIdOverrideForTesting = 'user_1'
    ..playIsSourceOfTruthForTesting = true
    ..remoteUserDocFetcherForTesting = (_) async => firestoreDoc;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Android: Google Play decides Pro, not Firestore', () {
    test('a self-written isPremium / isLifetime in Firestore unlocks nothing',
        () async {
      final p = _provider(_FakeIap(const []),
          firestoreDoc: {'isPremium': true, 'isLifetime': true});

      await p.loadPremiumStatus();
      expect(p.isPremium, isFalse);
      expect(p.isLifetime, isFalse);

      await p.verifySubscriptionStatus();
      expect(p.isPremium, isFalse, reason: 'Play owns nothing for this user');
      expect(p.isLifetime, isFalse);
    });

    test('an active Play subscription unlocks Pro', () async {
      final p = _provider(_FakeIap([_owned('gymbuddy_premium_monthly')]));
      await p.verifySubscriptionStatus();
      expect(p.isPremium, isTrue);
      expect(p.isLifetime, isFalse);
    });

    test('an owned one-time product unlocks lifetime', () async {
      final p = _provider(_FakeIap([_owned('premium_yearly')]));
      await p.verifySubscriptionStatus();
      expect(p.isPremium, isTrue);
      expect(p.isLifetime, isTrue);
    });

    test('Play unavailable keeps the last Play answer (no false downgrade)',
        () async {
      final iap = _FakeIap([_owned('gymbuddy_premium_monthly')]);
      final first = _provider(iap);
      await first.verifySubscriptionStatus();
      expect(first.isPremium, isTrue);

      // Next app start: Play billing is down.
      iap.past = null;
      final second = _provider(iap);
      await second.loadPremiumStatus();
      await second.verifySubscriptionStatus();
      expect(second.isPremium, isTrue);
    });

    test('an expired subscription is switched off when Play answers', () async {
      final iap = _FakeIap([_owned('gymbuddy_premium_monthly')]);
      final p = _provider(iap);
      await p.verifySubscriptionStatus();
      expect(p.isPremium, isTrue);

      iap.past = const [];
      await p.verifySubscriptionStatus();
      expect(p.isPremium, isFalse);
    });
  });
}
