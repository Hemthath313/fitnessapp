import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:fitness_app/presentation/auth/providers/auth_provider.dart';
import 'package:fitness_app/presentation/consumption/providers/consumption_provider.dart';
import 'package:fitness_app/presentation/home/providers/home_provider.dart';
import 'package:fitness_app/presentation/splash_screen/splashscreen.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeUserMetadata extends Fake implements UserMetadata {
  @override
  final DateTime creationTime;
  @override
  final DateTime lastSignInTime;

  _FakeUserMetadata({DateTime? creationTime, DateTime? lastSignInTime})
      : creationTime = creationTime ?? DateTime(2026, 1, 1),
        lastSignInTime = lastSignInTime ?? DateTime(2026, 1, 1);
}

class _FastFakeUser extends Fake implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final bool emailVerified;
  @override
  final UserMetadata metadata;

  final Future<void> Function()? onReload;

  _FastFakeUser({
    required this.uid,
    this.emailVerified = true,
    this.onReload,
    UserMetadata? metadata,
  })  : email = 'runner@example.com',
        metadata = metadata ?? _FakeUserMetadata();

  @override
  Future<void> reload() async {
    if (onReload != null) {
      await onReload!();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Offline Fast Startup & Session Safety Tests', () {
    test('1. Instant cache hydration resolves hasAgeParameter and isLoading without waiting for slow network', () async {
      const uid = 'fast_cached_user';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AuthProvider.getOnboardingCacheKey(uid), true);

      final completer = Completer<bool?>();

      final user = _FastFakeUser(
        uid: uid,
        emailVerified: true,
        onReload: () async {
          // Simulate network delay
          await Future.delayed(const Duration(milliseconds: 500));
          throw Exception('SocketException: Network unreachable');
        },
      );

      final authProvider = AuthProvider(autoInitialize: false)
        ..userOverrideForTesting = user
        ..remoteOnboardingFetcherForTesting = (_) => completer.future;

      // Start loading
      final loadFuture = authProvider.loadUserData();

      // Immediately after start, before remote completes, cache is hydrated
      await Future.delayed(const Duration(milliseconds: 20));
      expect(authProvider.hasAgeParameter, isTrue,
          reason: 'Cached onboarding status must be hydrated immediately');
      expect(authProvider.isLoading, isFalse,
          reason: 'isLoading must promptly resolve once cached status is hydrated');
      expect(authProvider.isOfflineFallback, isTrue);

      // Now complete remote with failure
      completer.complete(null);
      await loadFuture;

      expect(authProvider.hasAgeParameter, isTrue);
      expect(authProvider.isLoading, isFalse);
    });

    test('2. Stale in-flight request from previous user does not overwrite newly switched user session', () async {
      const userAId = 'user_A';
      const userBId = 'user_B';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AuthProvider.getOnboardingCacheKey(userAId), true);
      // User B has incomplete onboarding (false)
      await prefs.setBool(AuthProvider.getOnboardingCacheKey(userBId), false);

      final userACompleter = Completer<bool?>();

      final userA = _FastFakeUser(uid: userAId, emailVerified: true);
      final userB = _FastFakeUser(uid: userBId, emailVerified: true);

      final authProvider = AuthProvider(autoInitialize: false)
        ..userOverrideForTesting = userA
        ..remoteOnboardingFetcherForTesting = (uid) {
          if (uid == userAId) return userACompleter.future;
          return Future.value(false);
        };

      // User A starts loading (slow remote)
      final loadAFuture = authProvider.loadUserData();
      await Future.delayed(const Duration(milliseconds: 10));

      // User switches to User B before User A remote completes
      authProvider.userOverrideForTesting = userB;
      await authProvider.loadUserData();

      expect(authProvider.hasAgeParameter, isFalse,
          reason: 'Active user is now User B (cached false)');

      // User A's slow request completes with 'true'
      userACompleter.complete(true);
      await loadAFuture;

      // Ensure User B's state was NOT contaminated by User A's delayed response
      expect(authProvider.hasAgeParameter, isFalse,
          reason: 'Delayed response from user A must not overwrite user B state');
    });

    test('3. Sign-out clears state and invalidates any pending background requests', () async {
      const uid = 'user_to_sign_out';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AuthProvider.getOnboardingCacheKey(uid), true);

      final completer = Completer<bool?>();
      final user = _FastFakeUser(uid: uid, emailVerified: true);

      final authProvider = AuthProvider(autoInitialize: false)
        ..userOverrideForTesting = user
        ..remoteOnboardingFetcherForTesting = (_) => completer.future;

      final loadFuture = authProvider.loadUserData();
      await Future.delayed(const Duration(milliseconds: 10));

      // User logs out
      authProvider.clearState();

      expect(authProvider.user, isNull);
      expect(authProvider.hasAgeParameter, isNull);
      expect(authProvider.isLoading, isFalse);

      // Delayed remote returns later
      completer.complete(true);
      await loadFuture;

      // State remains cleared
      expect(authProvider.user, isNull);
      expect(authProvider.hasAgeParameter, isNull);
    });

    test('4. ConsumptionProvider getConsumedCalories does not throw when offline or user is null', () async {
      final consumptionProvider = ConsumptionProvider();

      // When user is null, should execute safely and reset consumedCalories to 0 without throwing
      await consumptionProvider.getConsumedCalories();
      expect(consumptionProvider.consumedCalories, equals(0));

      // clearAllWater should complete safely without throwing
      await consumptionProvider.clearAllWater();
      expect(consumptionProvider.waterADay, equals(0.0));

      // getLastClearedDate should return null safely without throwing
      final date = await consumptionProvider.getLastClearedDate();
      expect(date, isNull);
    });

    test('5. HomeProvider fetchUserData preserves in-memory cached data when offline', () async {
      final homeProvider = HomeProvider();
      // Pre-populate in-memory data
      homeProvider.userData['first name'] = 'Alex';
      homeProvider.userData['age'] = 28;

      // Calling fetchUserData when offline (or with no user) catches error and does not wipe userData
      await homeProvider.fetchUserData();

      expect(homeProvider.userData['first name'], equals('Alex'),
          reason: 'Offline failure must preserve available in-memory user data');
      expect(homeProvider.userData['age'], equals(28));
    });

    testWidgets('6. SplashScreen with pre-hydrated cache navigates to mainRoute immediately without extra loadUserData wait', (tester) async {
      const uid = 'user_prompt_nav';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AuthProvider.getOnboardingCacheKey(uid), true);

      final user = _FastFakeUser(uid: uid, emailVerified: true);

      final authProvider = AuthProvider(autoInitialize: false)
        ..userOverrideForTesting = user;

      // Hydrate from cache beforehand (simulating _loadInitialAuthState)
      await authProvider.loadUserData();
      expect(authProvider.hasAgeParameter, isTrue);

      String? navigatedRoute;
      final testRouter = GoRouter(
        initialLocation: Routes.splashScreen,
        routes: [
          GoRoute(
            path: Routes.splashScreen,
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: Routes.mainRoute,
            builder: (context, state) {
              navigatedRoute = Routes.mainRoute;
              return const Scaffold(body: Text('Main Screen'));
            },
          ),
          GoRoute(
            path: Routes.boardingRoute,
            builder: (context, state) => const Scaffold(body: Text('Boarding')),
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: MaterialApp.router(routerConfig: testRouter),
        ),
      );

      // Advance through splash delay (3 seconds)
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(navigatedRoute, equals(Routes.mainRoute),
          reason: 'SplashScreen should navigate smoothly to mainRoute');
    });
  });
}
