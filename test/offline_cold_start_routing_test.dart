import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:fitness_app/presentation/auth/providers/auth_provider.dart';
import 'package:fitness_app/presentation/splash_screen/splashscreen.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeUserMetadata extends Fake implements UserMetadata {
  @override
  final DateTime creationTime;
  @override
  final DateTime lastSignInTime;

  FakeUserMetadata({
    DateTime? creationTime,
    DateTime? lastSignInTime,
  })  : creationTime = creationTime ?? DateTime(2026, 1, 1),
        lastSignInTime = lastSignInTime ?? DateTime(2026, 1, 1);
}

class FakeUser extends Fake implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final bool emailVerified;
  @override
  final UserMetadata metadata;

  final Future<void> Function()? onReload;

  FakeUser({
    required this.uid,
    this.email = 'athlete@example.com',
    this.emailVerified = true,
    UserMetadata? metadata,
    this.onReload,
  }) : metadata = metadata ?? FakeUserMetadata();

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

  group('Offline Cold-Start Routing & Onboarding Cache', () {
    test('Scenario 1: Onboarded user launching offline with cached completion flag routes to mainRoute', () async {
      const uid = 'user_onboarded_offline';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AuthProvider.getOnboardingCacheKey(uid), true);

      final user = FakeUser(
        uid: uid,
        emailVerified: true,
        onReload: () async {
          throw Exception('SocketException: OS error: Network is unreachable');
        },
      );

      final authProvider = AuthProvider(autoInitialize: false)
        ..userOverrideForTesting = user
        ..remoteOnboardingFetcherForTesting = (_) async {
          throw Exception('Cloud Firestore unavailable (offline)');
        };

      expect(authProvider.hasAgeParameter, isNull);

      await authProvider.loadUserData();

      expect(authProvider.isLoading, isFalse);
      expect(authProvider.hasAgeParameter, isTrue,
          reason: 'Cached onboarding completion status must be restored during offline cold start');
      expect(authProvider.isOfflineFallback, isTrue);

      final route = SplashScreen.determineInitialRoute(
        user: authProvider.user,
        hasAgeParameter: authProvider.hasAgeParameter,
      );
      expect(route, equals(Routes.mainRoute),
          reason: 'Verified onboarded user must be routed to main app offline');
    });

    test('Scenario 2: User with no cached completion flag offline resolves hasAgeParameter null and routes to boardingRoute', () async {
      const uid = 'user_uncached_offline';
      final user = FakeUser(
        uid: uid,
        emailVerified: true,
        onReload: () async {
          throw Exception('SocketException: Network is unreachable');
        },
      );

      final authProvider = AuthProvider(autoInitialize: false)
        ..userOverrideForTesting = user
        ..remoteOnboardingFetcherForTesting = (_) async {
          throw Exception('Firestore timeout');
        };

      await authProvider.loadUserData();

      expect(authProvider.isLoading, isFalse);
      expect(authProvider.hasAgeParameter, isNull,
          reason: 'Without a cached flag, onboarding status must remain null');
      expect(authProvider.isOfflineFallback, isFalse);

      final route = SplashScreen.determineInitialRoute(
        user: authProvider.user,
        hasAgeParameter: authProvider.hasAgeParameter,
      );
      expect(route, equals(Routes.boardingRoute),
          reason: 'Safe fallback must route to boarding when onboarding status is unknown');
    });

    test('Scenario 3: User with incomplete onboarding (cached false) routes to addDataRoute', () async {
      const uid = 'user_incomplete_offline';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AuthProvider.getOnboardingCacheKey(uid), false);

      final user = FakeUser(
        uid: uid,
        emailVerified: true,
        onReload: () async {
          throw Exception('SocketException: Network is unreachable');
        },
      );

      final authProvider = AuthProvider(autoInitialize: false)
        ..userOverrideForTesting = user
        ..remoteOnboardingFetcherForTesting = (_) async {
          throw Exception('Cloud Firestore unavailable');
        };

      await authProvider.loadUserData();

      expect(authProvider.isLoading, isFalse);
      expect(authProvider.hasAgeParameter, isFalse,
          reason: 'Cached incomplete onboarding status must resolve to false');
      expect(authProvider.isOfflineFallback, isTrue);

      final route = SplashScreen.determineInitialRoute(
        user: authProvider.user,
        hasAgeParameter: authProvider.hasAgeParameter,
      );
      expect(route, equals(Routes.addDataRoute),
          reason: 'User with incomplete onboarding must be routed to addDataRoute');
    });

    test('Scenario 4: Signed-out user (user == null) routes to boardingRoute', () async {
      final authProvider = AuthProvider(autoInitialize: false)
        ..userOverrideForTesting = null;

      await authProvider.loadUserData();

      expect(authProvider.user, isNull);
      expect(authProvider.hasAgeParameter, isNull);

      final route = SplashScreen.determineInitialRoute(
        user: authProvider.user,
        hasAgeParameter: authProvider.hasAgeParameter,
      );
      expect(route, equals(Routes.boardingRoute),
          reason: 'Unauthenticated user must always route to boardingRoute');
    });

    test('Scenario 5: Email-unverified user (emailVerified == false) routes to boardingRoute even with cached completion', () async {
      const uid = 'user_unverified_offline';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AuthProvider.getOnboardingCacheKey(uid), true);

      final user = FakeUser(
        uid: uid,
        emailVerified: false, // Email is unverified
        onReload: () async {
          throw Exception('Network unreachable');
        },
      );

      final authProvider = AuthProvider(autoInitialize: false)
        ..userOverrideForTesting = user
        ..remoteOnboardingFetcherForTesting = (_) async {
          throw Exception('Firestore offline');
        };

      await authProvider.loadUserData();

      expect(authProvider.hasAgeParameter, isTrue);

      final route = SplashScreen.determineInitialRoute(
        user: authProvider.user,
        hasAgeParameter: authProvider.hasAgeParameter,
      );
      expect(route, equals(Routes.boardingRoute),
          reason: 'Cached onboarding completion must NEVER bypass email verification');
    });

    test('Scenario 6: User account switching strictly isolates onboarding cache between UIDs', () async {
      const uidA = 'user_A_completed';
      const uidB = 'user_B_new';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AuthProvider.getOnboardingCacheKey(uidA), true);
      // UID B has no cached flag

      final userB = FakeUser(
        uid: uidB,
        emailVerified: true,
        onReload: () async {
          throw Exception('Network unreachable');
        },
      );

      final authProvider = AuthProvider(autoInitialize: false)
        ..userOverrideForTesting = userB
        ..remoteOnboardingFetcherForTesting = (_) async {
          throw Exception('Firestore offline');
        };

      await authProvider.loadUserData();

      // User B must NOT inherit User A's completion status
      expect(authProvider.hasAgeParameter, isNull,
          reason: "User B must not use User A's cached onboarding status");
      expect(
        SplashScreen.determineInitialRoute(
          user: authProvider.user,
          hasAgeParameter: authProvider.hasAgeParameter,
        ),
        equals(Routes.boardingRoute),
      );

      // Now switch to User A offline
      final userA = FakeUser(
        uid: uidA,
        emailVerified: true,
        onReload: () async {
          throw Exception('Network unreachable');
        },
      );
      authProvider.userOverrideForTesting = userA;
      await authProvider.loadUserData();

      // User A gets their own completion status restored
      expect(authProvider.hasAgeParameter, isTrue,
          reason: "User A must retrieve their own cached onboarding status");
      expect(
        SplashScreen.determineInitialRoute(
          user: authProvider.user,
          hasAgeParameter: authProvider.hasAgeParameter,
        ),
        equals(Routes.mainRoute),
      );
    });

    test('Scenario 7: Temporary Firestore failure does not erase valid cached status', () async {
      const uid = 'user_stable_cache';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AuthProvider.getOnboardingCacheKey(uid), true);

      final user = FakeUser(
        uid: uid,
        emailVerified: true,
        onReload: () async {
          throw Exception('Network unreachable');
        },
      );

      final authProvider = AuthProvider(autoInitialize: false)
        ..userOverrideForTesting = user
        ..remoteOnboardingFetcherForTesting = (_) async {
          throw Exception('Temporary Firestore timeout error');
        };

      // First offline launch
      await authProvider.loadUserData();
      expect(authProvider.hasAgeParameter, isTrue);

      // Verify the cache in SharedPreferences was NOT cleared or overwritten
      final cachedValueAfterFailure =
          prefs.getBool(AuthProvider.getOnboardingCacheKey(uid));
      expect(cachedValueAfterFailure, isTrue,
          reason: 'Network errors must not clear valid cached onboarding status');

      // Second offline launch succeeds using same cache
      await authProvider.loadUserData();
      expect(authProvider.hasAgeParameter, isTrue);
    });

    testWidgets('Scenario 8: Cache is saved only after onboarding data succeeds, not on failure', (tester) async {
      const uid = 'user_save_test';
      final prefs = await SharedPreferences.getInstance();

      final authProvider = AuthProvider(autoInitialize: false)
        ..userIdOverrideForTesting = uid;

      // Simulate failed Firestore save
      authProvider.onAddUserDataForTesting = ({
        required String activity,
        required int age,
        required double bmi,
        required double bmr,
        required String email,
        required String gender,
        required String goal,
        required double height,
        required String name,
        required String surname,
        required double weight,
      }) async {
        throw Exception('Firestore write failed: network timeout');
      };

      late BuildContext testContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              testContext = context;
              return const Scaffold(body: Text('Test'));
            },
          ),
        ),
      );

      await expectLater(
        () => authProvider.addUserData(
          email: 'test@example.com',
          name: 'Bob',
          surname: 'Jones',
          age: 25,
          height: 175,
          weight: 70,
          gender: 'Male',
          activity: 'MODERATE',
          bmr: 1800,
          goal: 'MAINTAIN',
          bmi: 22.8,
          context: testContext,
        ),
        throwsA(isA<Exception>()),
      );
      await tester.pumpAndSettle();

      // Cache must NOT be true after failure
      expect(prefs.getBool(AuthProvider.getOnboardingCacheKey(uid)), isNull,
          reason: 'Failed Firestore writes must not set onboarding cache');

      // Simulate successful Firestore save
      authProvider.onAddUserDataForTesting = ({
        required String activity,
        required int age,
        required double bmi,
        required double bmr,
        required String email,
        required String gender,
        required String goal,
        required double height,
        required String name,
        required String surname,
        required double weight,
      }) async {
        // Success
      };

      await authProvider.addUserData(
        email: 'test@example.com',
        name: 'Bob',
        surname: 'Jones',
        age: 25,
        height: 175,
        weight: 70,
        gender: 'Male',
        activity: 'MODERATE',
        bmr: 1800,
        goal: 'MAINTAIN',
        bmi: 22.8,
        context: testContext,
      );
      await tester.pumpAndSettle();

      // Cache MUST now be true after success
      expect(prefs.getBool(AuthProvider.getOnboardingCacheKey(uid)), isTrue,
          reason: 'Successful Firestore write must persist onboarding cache');
      expect(authProvider.hasAgeParameter, isTrue);
    });

    test('Scenario 9: Explicit clearCachedOnboardingStatus removes the cache entry', () async {
      const uid = 'user_to_delete';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AuthProvider.getOnboardingCacheKey(uid), true);

      expect(await AuthProvider.getCachedOnboardingStatus(uid), isTrue);

      await AuthProvider.clearCachedOnboardingStatus(uid);

      expect(await AuthProvider.getCachedOnboardingStatus(uid), isNull);
      expect(prefs.getBool(AuthProvider.getOnboardingCacheKey(uid)), isNull);
    });
  });

  group('SplashScreen Offline Cold-Start Widget Navigation', () {
    Widget createSplashTestApp({
      required AuthProvider authProvider,
      required void Function(String route) onNavigated,
    }) {
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
              onNavigated(Routes.mainRoute);
              return const Scaffold(body: Text('Main Screen'));
            },
          ),
          GoRoute(
            path: Routes.addDataRoute,
            builder: (context, state) {
              onNavigated(Routes.addDataRoute);
              return const Scaffold(body: Text('Add Data Screen'));
            },
          ),
          GoRoute(
            path: Routes.boardingRoute,
            builder: (context, state) {
              onNavigated(Routes.boardingRoute);
              return const Scaffold(body: Text('Boarding Screen'));
            },
          ),
        ],
      );

      return ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
    }

    testWidgets('SplashScreen navigates to mainRoute for cached onboarded user during offline cold start', (tester) async {
      const uid = 'user_cold_main';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AuthProvider.getOnboardingCacheKey(uid), true);

      final user = FakeUser(
        uid: uid,
        emailVerified: true,
        onReload: () async {
          throw Exception('SocketException: Network unreachable');
        },
      );

      final authProvider = AuthProvider(autoInitialize: false)
        ..userOverrideForTesting = user
        ..remoteOnboardingFetcherForTesting = (_) async {
          throw Exception('Firestore offline');
        };

      String? navigatedRoute;
      await tester.pumpWidget(
        createSplashTestApp(
          authProvider: authProvider,
          onNavigated: (r) => navigatedRoute = r,
        ),
      );

      // Advance through splash animation and delay (3 seconds)
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(navigatedRoute, equals(Routes.mainRoute),
          reason: 'SplashScreen must navigate to mainRoute for verified onboarded user offline');
    });

    testWidgets('SplashScreen navigates to boardingRoute when offline without cached status', (tester) async {
      const uid = 'user_cold_uncached';
      final user = FakeUser(
        uid: uid,
        emailVerified: true,
        onReload: () async {
          throw Exception('Network unreachable');
        },
      );

      final authProvider = AuthProvider(autoInitialize: false)
        ..userOverrideForTesting = user
        ..remoteOnboardingFetcherForTesting = (_) async {
          throw Exception('Firestore offline');
        };

      String? navigatedRoute;
      await tester.pumpWidget(
        createSplashTestApp(
          authProvider: authProvider,
          onNavigated: (r) => navigatedRoute = r,
        ),
      );

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(navigatedRoute, equals(Routes.boardingRoute),
          reason: 'SplashScreen must safely navigate to boardingRoute when onboarding is unknown');
    });

    testWidgets('SplashScreen navigates to addDataRoute when offline with incomplete onboarding', (tester) async {
      const uid = 'user_cold_incomplete';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AuthProvider.getOnboardingCacheKey(uid), false);

      final user = FakeUser(
        uid: uid,
        emailVerified: true,
        onReload: () async {
          throw Exception('Network unreachable');
        },
      );

      final authProvider = AuthProvider(autoInitialize: false)
        ..userOverrideForTesting = user
        ..remoteOnboardingFetcherForTesting = (_) async {
          throw Exception('Firestore offline');
        };

      String? navigatedRoute;
      await tester.pumpWidget(
        createSplashTestApp(
          authProvider: authProvider,
          onNavigated: (r) => navigatedRoute = r,
        ),
      );

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(navigatedRoute, equals(Routes.addDataRoute),
          reason: 'SplashScreen must navigate to addDataRoute when user has incomplete onboarding');
    });

    testWidgets('SplashScreen never bypasses email verification even with cached onboarding status', (tester) async {
      const uid = 'user_cold_unverified';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AuthProvider.getOnboardingCacheKey(uid), true);

      final user = FakeUser(
        uid: uid,
        emailVerified: false, // Email NOT verified
        onReload: () async {
          throw Exception('Network unreachable');
        },
      );

      final authProvider = AuthProvider(autoInitialize: false)
        ..userOverrideForTesting = user
        ..remoteOnboardingFetcherForTesting = (_) async {
          throw Exception('Firestore offline');
        };

      String? navigatedRoute;
      await tester.pumpWidget(
        createSplashTestApp(
          authProvider: authProvider,
          onNavigated: (r) => navigatedRoute = r,
        ),
      );

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(navigatedRoute, equals(Routes.boardingRoute),
          reason: 'SplashScreen must never route to mainRoute if email is unverified');
    });
  });
}
