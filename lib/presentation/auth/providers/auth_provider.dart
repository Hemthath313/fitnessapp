import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/services/auth_error_messages.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/utils/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool? _isNewUser;
  bool? _hasAgeParameter;
  bool isDataCompleted = false;
  bool isLoading = true;
  bool _isOfflineFallback = false;

  static const String _onboardingCachePrefix = 'onboarding_completed_';

  /// Generates the persistent, user-scoped cache key for onboarding completion.
  static String getOnboardingCacheKey(String uid) => '$_onboardingCachePrefix$uid';

  /// Persists the onboarding completion status for a specific user to SharedPreferences.
  static Future<void> setCachedOnboardingStatus(String uid, bool completed) async {
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(getOnboardingCacheKey(uid), completed);
    } catch (e) {
      debugPrint('AuthProvider: Failed to cache onboarding status: $e');
    }
  }

  /// Retrieves the user-scoped cached onboarding completion status from SharedPreferences.
  /// Returns null if no cached record exists for this user.
  static Future<bool?> getCachedOnboardingStatus(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(getOnboardingCacheKey(uid));
    } catch (e) {
      debugPrint('AuthProvider: Failed to read cached onboarding status: $e');
      return null;
    }
  }

  /// Clears the cached onboarding completion status for a specific user.
  static Future<void> clearCachedOnboardingStatus(String uid) async {
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(getOnboardingCacheKey(uid));
    } catch (e) {
      debugPrint('AuthProvider: Failed to clear cached onboarding status: $e');
    }
  }

  @visibleForTesting
  User? userOverrideForTesting;

  @visibleForTesting
  bool? hasAgeParameterOverrideForTesting;

  @visibleForTesting
  Future<bool?> Function(String uid)? remoteOnboardingFetcherForTesting;

  @visibleForTesting
  Future<void> Function()? onUserReloadForTesting;

  User? get _currentUser {
    if (userOverrideForTesting != null) return userOverrideForTesting;
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  int _activeSessionId = 0;
  String? _activeUserId;

  void clearState() {
    _activeSessionId++;
    _user = null;
    _activeUserId = null;
    _hasAgeParameter = null;
    _isNewUser = null;
    _isOfflineFallback = false;
    userOverrideForTesting = null;
    userIdOverrideForTesting = null;
    hasAgeParameterOverrideForTesting = null;
    isLoading = false;
    notifyListeners();
  }

  AuthProvider({bool autoInitialize = true}) {
    if (!autoInitialize) {
      isLoading = false;
      return;
    }
    try {
      // Load initial auth state immediately
      _loadUserDataForUser(_currentUser, isInitial: true);

      // Listen to auth state changes
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        final targetUser = userOverrideForTesting ?? user;
        if (targetUser != null) {
          // Avoid duplicate concurrent load if already actively processing this user
          if (targetUser.uid == _activeUserId && (isLoading || _hasAgeParameter != null)) {
            return;
          }
          _loadUserDataForUser(targetUser);
        } else {
          clearState();
        }
      });
    } catch (_) {
      // Firebase not initialized in testing
      isLoading = false;
    }
  }

  Future<void> _loadUserDataForUser(User? targetUser, {bool isInitial = false}) async {
    final sessionId = ++_activeSessionId;
    final currentUser = targetUser ?? _currentUser;

    if (currentUser == null) {
      _user = null;
      _activeUserId = null;
      _hasAgeParameter = null;
      _isNewUser = null;
      _isOfflineFallback = false;
      isLoading = false;
      notifyListeners();
      return;
    }

    _user = currentUser;
    final uid = userIdOverrideForTesting ?? currentUser.uid;
    _activeUserId = uid;

    // Fast path: Instant local cache hydration from SharedPreferences
    if (uid.isNotEmpty) {
      final cached = await getCachedOnboardingStatus(uid);
      if (sessionId != _activeSessionId || _activeUserId != uid) return;

      if (cached != null) {
        _hasAgeParameter = cached;
        _isOfflineFallback = true;
        // Promptly mark initial loading complete as soon as cached status is known
        if (isLoading) {
          isLoading = false;
          notifyListeners();
        }
      }
    }

    // Network sync: Refresh user credentials and fetch latest Firestore status
    try {
      try {
        if (onUserReloadForTesting != null) {
          await onUserReloadForTesting!();
        } else {
          await currentUser.reload().timeout(const Duration(seconds: 2));
        }
        if (sessionId != _activeSessionId || _activeUserId != uid) return;
        if (userOverrideForTesting == null) {
          _user = FirebaseAuth.instance.currentUser ?? currentUser;
        }
      } catch (_) {
        // Reload failed (offline or network timeout) - proceed with current credentials
        if (sessionId != _activeSessionId || _activeUserId != uid) return;
      }

      if (uid.isNotEmpty) {
        bool hasAge;
        if (remoteOnboardingFetcherForTesting != null) {
          final res = await remoteOnboardingFetcherForTesting!(uid);
          if (res == null) {
            throw FirebaseException(
              plugin: 'firestore',
              code: 'unavailable',
              message: 'Offline or Firestore unavailable',
            );
          }
          hasAge = res;
        } else {
          final docSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get()
              .timeout(const Duration(seconds: 2));

          if (docSnapshot.metadata.isFromCache &&
              (!docSnapshot.exists ||
                  docSnapshot.data() == null ||
                  !docSnapshot.data()!.containsKey('age'))) {
            throw FirebaseException(
              plugin: 'firestore',
              code: 'unavailable',
              message: 'User profile verification requires internet connection while offline',
            );
          }

          hasAge = docSnapshot.exists &&
              docSnapshot.data() != null &&
              docSnapshot.data()!.containsKey('age');
        }

        if (sessionId != _activeSessionId || _activeUserId != uid) return;

        _hasAgeParameter = hasAge;
        _isOfflineFallback = false;
        final isCreatedNow =
            _user?.metadata.creationTime == _user?.metadata.lastSignInTime;
        _isNewUser = isCreatedNow && !_hasAgeParameter!;
        await setCachedOnboardingStatus(uid, hasAge);
      }
    } catch (e) {
      debugPrint('AuthProvider: Remote sync failed with exception: $e');
      // Remote sync failed (offline / timeout / unavailable)
      if (sessionId != _activeSessionId || _activeUserId != uid) return;

      final cached = await getCachedOnboardingStatus(uid);
      if (cached != null) {
        _hasAgeParameter = cached;
        _isOfflineFallback = true;
      } else {
        _hasAgeParameter = null;
        _isOfflineFallback = false;
      }
    } finally {
      if (sessionId == _activeSessionId && _activeUserId == uid) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void completeUserData() {
    isDataCompleted = true;
    notifyListeners();
  }

  void callAuth() {
    _loadUserDataForUser(_currentUser);
  }

  User? get user => userOverrideForTesting ?? _user;
  String? get currentUserId => userIdOverrideForTesting ?? _user?.uid;
  bool? get isNewUser => _isNewUser;
  bool? get hasAgeParameter =>
      hasAgeParameterOverrideForTesting ?? _hasAgeParameter;
  bool get isOfflineFallback => _isOfflineFallback;

  Future<void> forgotPassword({
    required String email,
    required BuildContext context,
  }) async {
    LoadingOverlay.show(context, message: 'Sending reset link...');

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }
      // ignore: use_build_context_synchronously
      showDialog(
          context: context,
          builder: (_) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(PaddingManager.p40),
                child: AlertDialog(
                  backgroundColor: ColorManager.background,
                  title: Text(
                    StringsManager.success,
                    textAlign: TextAlign.center,
                    style: StyleManager.forgotPWErrorTextStyle,
                  ),
                  content: Text(
                    StringsManager.pwResetLinkSent,
                    textAlign: TextAlign.center,
                    style: StyleManager.forgotPWErrorContentTextStyle,
                  ),
                ),
              ),
            );
          });

      notifyListeners();
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);

      showDialog(
          context: context,
          builder: (_) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(PaddingManager.p40),
                child: AlertDialog(
                  backgroundColor: ColorManager.background,
                  title: Text(
                    StringsManager.wrongEmail,
                    textAlign: TextAlign.center,
                    style: StyleManager.forgotPWErrorTextStyle,
                  ),
                  content: Text(
                    AuthErrorMessages.from(e),
                    textAlign: TextAlign.center,
                    style: StyleManager.forgotPWErrorContentTextStyle,
                  ),
                ),
              ),
            );
          });
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    LoadingOverlay.show(context, message: 'Signing in...');

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Reload user data after successful login
      await loadUserData();
      
      // Hide loading overlay before navigation
      LoadingOverlay.hide(context);
      
      // Wait a frame to ensure overlay is dismissed
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Notify listeners (this may trigger router redirect)
      notifyListeners();
      
      // After navigation, ensure overlay is hidden
      WidgetsBinding.instance.addPostFrameCallback((_) {
        LoadingOverlay.hide(null);
      });
      
      // Double check after a delay
      Future.delayed(const Duration(milliseconds: 300), () {
        LoadingOverlay.hide(null);
      });
    } on FirebaseAuthException {
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }
      rethrow; // <--- Forward the error back to LoginPage
    } catch (e) {
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }
      rethrow; // Handle any unexpected error
    }
  }

  Future<void> registerAndVerifyEmail({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    LoadingOverlay.show(context, message: 'Creating account...');

    try {
      print("registerAndVerifyEmail");
      UserCredential credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('credential: $credential');

      User? user = credential.user;
      await user?.sendEmailVerification();
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }

      notifyListeners(); // Important: Only notify here; no data storage yet.
      context.push(Routes.emailVerify); // Navigate to email verification page
    } on FirebaseAuthException {
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }
      rethrow;
    }
  }

  @visibleForTesting
  Future<void> Function({
    required String email,
    required String name,
    required String surname,
    required int age,
    required double height,
    required double weight,
    required String gender,
    required String activity,
    required double bmr,
    required String goal,
    required double bmi,
  })? onAddUserDataForTesting;

  @visibleForTesting
  String? userIdOverrideForTesting;

  Future<void> addUserData({
    required String email,
    required String name,
    required String surname,
    required int age,
    required double height,
    required double weight,
    required String gender,
    required String activity,
    required double bmr,
    required String goal,
    required double bmi,
    required BuildContext context,
  }) async {
    LoadingOverlay.show(context, message: 'Saving your data...');
    
    try {
      if (onAddUserDataForTesting != null) {
        await onAddUserDataForTesting!(
          email: email,
          name: name,
          surname: surname,
          age: age,
          height: height,
          weight: weight,
          gender: gender,
          activity: activity,
          bmr: bmr,
          goal: goal,
          bmi: bmi,
        );
        _hasAgeParameter = true;
        _isOfflineFallback = false;
        final uid = userIdOverrideForTesting ?? _currentUser?.uid ?? _user?.uid;
        if (uid != null && uid.isNotEmpty) {
          await setCachedOnboardingStatus(uid, true);
        }
        if (context.mounted) {
          LoadingOverlay.hide(context);
        }
        completeUserData();
        notifyListeners();
        return;
      }

      final currentUser = _currentUser;
      final uid = userIdOverrideForTesting ?? currentUser?.uid ?? _user?.uid;
      if (uid == null) {
        throw Exception('User is not authenticated. Please log in again.');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'email': email,
        'first name': name,
        'surname': surname,
        'age': age,
        'height': height,
        'weight': weight,
        'gender': gender,
        'activity': activity,
        'bmr': bmr,
        'goal': goal,
        'bmi': bmi,
        'chest': 0.0,
        'shoulders': 0.0,
        'biceps': 0.0,
        'foreArm': 0.0,
        'waist': 0.0,
        'hips': 0.0,
        'thigh': 0.0,
        'calf': 0.0,
      });
      
      // Save onboarding completion to user-scoped cache ONLY after Firestore write succeeds
      _hasAgeParameter = true;
      _isOfflineFallback = false;
      await setCachedOnboardingStatus(uid, true);

      // Hide loading overlay before navigation
      if (context.mounted) {
        LoadingOverlay.hide(context);
        // Wait a frame to ensure overlay is dismissed
        await Future.delayed(const Duration(milliseconds: 100));
      }
      completeUserData();
      notifyListeners();
    } catch (e) {
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }
      rethrow;
    }
  }

  static const String googleServerClientId =
      '661343486324-u392bv0p49koqbt3irt5thleflapd234.apps.googleusercontent.com';

  Future<void> signInWithGoogle(BuildContext context) async {
    LoadingOverlay.show(context, message: 'Signing in with Google...');
    
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: googleServerClientId,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (context.mounted) {
          LoadingOverlay.hide(context);
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw FirebaseAuthException(
          code: 'null-id-token',
          message: 'Google Sign-In failed to retrieve ID token.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      // Create Firestore doc if it doesn't exist
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user!.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set({
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Reload user data after successful Google sign in
      await loadUserData();
      
      // Hide loading overlay before navigation
      LoadingOverlay.hide(context);
      
      // Wait a frame to ensure overlay is dismissed
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Notify listeners (this may trigger router redirect)
      notifyListeners();
      
      // After navigation, ensure overlay is hidden
      WidgetsBinding.instance.addPostFrameCallback((_) {
        LoadingOverlay.hide(null);
      });
      
      // Double check after a delay
      Future.delayed(const Duration(milliseconds: 300), () {
        LoadingOverlay.hide(null);
      });
    } catch (e) {
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }
      rethrow;
    }
  }

  Future<void> loadUserData() async {
    if (_hasAgeParameter == null) {
      isLoading = true;
      notifyListeners();
    }
    await _loadUserDataForUser(_currentUser);
  }
}
