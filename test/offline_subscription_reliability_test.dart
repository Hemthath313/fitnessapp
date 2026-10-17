import 'dart:convert';
import 'package:fitness_app/presentation/in_app_purchases/providers/subscription_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 3B Batch 2: Offline Subscription Reliability', () {
    test('Scenario 1: Firestore failure ends loading rather than leaving isLoading true', () async {
      final provider = SubscriptionProvider(autoInitialize: false)
        ..userIdOverrideForTesting = 'user_err_1';

      provider.remoteUserDocFetcherForTesting = (_) async {
        throw Exception('Cloud Firestore unavailable (offline)');
      };

      expect(provider.isLoading, isTrue);

      await provider.loadPremiumStatus();

      expect(provider.isLoading, isFalse, reason: 'isLoading must be false after Firestore failure');
      expect(provider.error, isNotNull);
      expect(provider.isPremium, isFalse);
    });

    test('Scenario 2: Previously confirmed Pro entitlement is restored after an offline launch', () async {
      const uid = 'user_pro_offline';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        SubscriptionProvider.getCacheKey(uid),
        jsonEncode({
          'isPremium': true,
          'isLifetime': false,
          'cachedAt': DateTime.now().toIso8601String(),
        }),
      );

      final provider = SubscriptionProvider(autoInitialize: false)
        ..userIdOverrideForTesting = uid;

      provider.remoteUserDocFetcherForTesting = (_) async {
        throw Exception('SocketException: OS error: Network is unreachable');
      };

      await provider.loadPremiumStatus();

      expect(provider.isLoading, isFalse);
      expect(provider.isPremium, isTrue, reason: 'Previously confirmed Pro must be available offline');
      expect(provider.isLifetime, isFalse);
      expect(provider.isOfflineFallback, isTrue);
      expect(provider.isServerConfirmed, isFalse);
    });

    test('Scenario 3: Previously confirmed lifetime entitlement is restored correctly', () async {
      const uid = 'user_lifetime_offline';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        SubscriptionProvider.getCacheKey(uid),
        jsonEncode({
          'isPremium': true,
          'isLifetime': true,
          'cachedAt': DateTime.now().toIso8601String(),
        }),
      );

      final provider = SubscriptionProvider(autoInitialize: false)
        ..userIdOverrideForTesting = uid;

      provider.remoteUserDocFetcherForTesting = (_) async {
        throw Exception('Network timeout');
      };

      await provider.loadPremiumStatus();

      expect(provider.isLoading, isFalse);
      expect(provider.isPremium, isTrue);
      expect(provider.isLifetime, isTrue, reason: 'Lifetime license must be restored offline');
      expect(provider.isOfflineFallback, isTrue);
    });

    test('Scenario 4: Successful authoritative response updates the cache', () async {
      const uid = 'user_authoritative_sync';
      final prefs = await SharedPreferences.getInstance();
      // Pre-populate with stale Pro
      await prefs.setString(
        SubscriptionProvider.getCacheKey(uid),
        jsonEncode({
          'isPremium': true,
          'isLifetime': false,
        }),
      );

      final provider = SubscriptionProvider(autoInitialize: false)
        ..userIdOverrideForTesting = uid;

      // Server authoritatively returns downgraded/expired subscription
      provider.remoteUserDocFetcherForTesting = (_) async {
        return {
          'isPremium': false,
          'isLifetime': false,
        };
      };

      await provider.loadPremiumStatus();

      expect(provider.isLoading, isFalse);
      expect(provider.isPremium, isFalse);
      expect(provider.isServerConfirmed, isTrue);
      expect(provider.isOfflineFallback, isFalse);

      // Verify that SharedPreferences cache was updated to false
      final cachedJson = prefs.getString(SubscriptionProvider.getCacheKey(uid));
      expect(cachedJson, isNotNull);
      final decoded = jsonDecode(cachedJson!);
      expect(decoded['isPremium'], isFalse);

      // Subsequent offline launch should NOT grant Pro
      final offlineProvider = SubscriptionProvider(autoInitialize: false)
        ..userIdOverrideForTesting = uid;
      offlineProvider.remoteUserDocFetcherForTesting = (_) async {
        throw Exception('Offline');
      };
      await offlineProvider.loadPremiumStatus();
      expect(offlineProvider.isPremium, isFalse);
    });

    test('Scenario 5: Missing or malformed cache does not grant Pro access', () async {
      const uidMissing = 'user_no_cache';
      final provider1 = SubscriptionProvider(autoInitialize: false)
        ..userIdOverrideForTesting = uidMissing;

      provider1.remoteUserDocFetcherForTesting = (_) async {
        throw Exception('Offline');
      };

      await provider1.loadPremiumStatus();
      expect(provider1.isPremium, isFalse);
      expect(provider1.isLoading, isFalse);

      const uidMalformed = 'user_bad_cache';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SubscriptionProvider.getCacheKey(uidMalformed), '{invalid json!!!');

      final provider2 = SubscriptionProvider(autoInitialize: false)
        ..userIdOverrideForTesting = uidMalformed;

      provider2.remoteUserDocFetcherForTesting = (_) async {
        throw Exception('Offline');
      };

      await provider2.loadPremiumStatus();
      expect(provider2.isPremium, isFalse);
      expect(provider2.isLoading, isFalse);
    });

    test('Scenario 6: Switching accounts does not expose another user cached entitlement', () async {
      const userA = 'user_account_a_pro';
      const userB = 'user_account_b_free';

      final prefs = await SharedPreferences.getInstance();
      // User A is Pro
      await prefs.setString(
        SubscriptionProvider.getCacheKey(userA),
        jsonEncode({'isPremium': true, 'isLifetime': false}),
      );

      // Provider signed in as User B
      final provider = SubscriptionProvider(autoInitialize: false)
        ..userIdOverrideForTesting = userB;

      provider.remoteUserDocFetcherForTesting = (_) async {
        throw Exception('Offline');
      };

      await provider.loadPremiumStatus();

      // User B must NOT have User A's Pro status
      expect(provider.isPremium, isFalse);
      expect(provider.isLifetime, isFalse);

      // Switch to User A offline
      provider.userIdOverrideForTesting = userA;
      await provider.loadPremiumStatus();

      // User A gets their own Pro status restored
      expect(provider.isPremium, isTrue);
    });

    test('Scenario 7: Existing purchase and restore behavior remains intact and updates cache', () async {
      const uid = 'user_purchase_test';
      final provider = SubscriptionProvider(autoInitialize: false)
        ..userIdOverrideForTesting = uid;

      // Purchase monthly premium
      await provider.setPremiumStatus(true, isLifetime: false);
      expect(provider.isPremium, isTrue);
      expect(provider.isLifetime, isFalse);

      final prefs = await SharedPreferences.getInstance();
      var cachedJson = prefs.getString(SubscriptionProvider.getCacheKey(uid));
      expect(cachedJson, isNotNull);
      var decoded = jsonDecode(cachedJson!);
      expect(decoded['isPremium'], isTrue);
      expect(decoded['isLifetime'], isFalse);

      // Upgrade to lifetime
      await provider.setPremiumStatus(true, isLifetime: true);
      expect(provider.isPremium, isTrue);
      expect(provider.isLifetime, isTrue);

      cachedJson = prefs.getString(SubscriptionProvider.getCacheKey(uid));
      decoded = jsonDecode(cachedJson!);
      expect(decoded['isPremium'], isTrue);
      expect(decoded['isLifetime'], isTrue);

      // Downgrade / cancel
      await provider.setPremiumStatus(false);
      expect(provider.isPremium, isFalse);
      expect(provider.isLifetime, isFalse);

      cachedJson = prefs.getString(SubscriptionProvider.getCacheKey(uid));
      decoded = jsonDecode(cachedJson!);
      expect(decoded['isPremium'], isFalse);
      expect(decoded['isLifetime'], isFalse);
    });

    test('Scenario 8: Expired cached entitlement does not grant Pro access', () async {
      const uid = 'user_expired_pro';
      final prefs = await SharedPreferences.getInstance();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await prefs.setString(
        SubscriptionProvider.getCacheKey(uid),
        jsonEncode({
          'isPremium': true,
          'isLifetime': false,
          'expirationDate': yesterday.toIso8601String(),
        }),
      );

      final provider = SubscriptionProvider(autoInitialize: false)
        ..userIdOverrideForTesting = uid;

      provider.remoteUserDocFetcherForTesting = (_) async {
        throw Exception('Offline');
      };

      await provider.loadPremiumStatus();

      expect(provider.isPremium, isFalse, reason: 'Expired subscription in cache must not grant Pro');
      expect(provider.isLoading, isFalse);
    });

    test('Scenario 9: Stale asynchronous response does not overwrite switched user entitlement', () async {
      final provider = SubscriptionProvider(autoInitialize: false);

      provider.userIdOverrideForTesting = 'user_slow';

      // Start slow request for user_slow
      provider.remoteUserDocFetcherForTesting = (_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return {'isPremium': true, 'isLifetime': false};
      };

      final slowFuture = provider.loadPremiumStatus();

      // Immediately switch to user_new (free) and load
      provider.userIdOverrideForTesting = 'user_new';
      provider.remoteUserDocFetcherForTesting = (_) async {
        return {'isPremium': false, 'isLifetime': false};
      };

      await provider.loadPremiumStatus();
      expect(provider.isPremium, isFalse);

      // Wait for slow future to finish
      await slowFuture;

      // Must still be user_new's state (false), not overwritten by user_slow's response
      expect(provider.isPremium, isFalse);
    });
  });
}
