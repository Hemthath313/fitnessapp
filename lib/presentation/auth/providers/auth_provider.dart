import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:fitness_app/utils/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool? _isNewUser;
  bool? _hasAgeParameter;
  bool isDataCompleted = false;
  bool isLoading = true;

  AuthProvider() {
    // Load initial auth state immediately
    _loadInitialAuthState();
    
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      _user = user;
      if (_user != null) {
        // Reload user to get latest data including emailVerified status
        try {
          await _user!.reload();
          _user = FirebaseAuth.instance.currentUser;
        } catch (e) {
          // If reload fails, continue with current user
        }
        
        FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get()
            .timeout(const Duration(seconds: 5))
            .then((docSnapshot) {
          _hasAgeParameter =
              docSnapshot.exists && docSnapshot.data()!.containsKey('age');
          _isNewUser =
              _user!.metadata.creationTime == _user!.metadata.lastSignInTime &&
                  !_hasAgeParameter!;
          isLoading = false;
          notifyListeners();
        }).catchError((error) {
          isLoading = false;
          notifyListeners();
        });
      } else {
        // User logged out - clear all state
        _hasAgeParameter = null;
        _isNewUser = null;
        isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadInitialAuthState() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
        _user = currentUser;

        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get()
            .timeout(const Duration(seconds: 5));

        _hasAgeParameter =
            docSnapshot.exists && docSnapshot.data()!.containsKey('age');
        _isNewUser =
            _user!.metadata.creationTime == _user!.metadata.lastSignInTime &&
                !_hasAgeParameter!;
      } else {
        _user = null;
        _hasAgeParameter = null;
        _isNewUser = null;
      }
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
  }
  void completeUserData() {
    isDataCompleted = true;
    notifyListeners();
  }

  void callAuth() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      if (_user != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get()
            .timeout(const Duration(seconds: 5))
            .then((docSnapshot) {
          _hasAgeParameter =
              docSnapshot.exists && docSnapshot.data()!.containsKey('age');
          _isNewUser =
              _user!.metadata.creationTime == _user!.metadata.lastSignInTime &&
                  !_hasAgeParameter!;
          notifyListeners();
        }).catchError((error) {
          // Ignore error silently
        });
      } else {
        _hasAgeParameter = null;
        _isNewUser = null;
        notifyListeners();
      }
    });
  }

  User? get user => _user;
  bool? get isNewUser => _isNewUser;
  bool? get hasAgeParameter => _hasAgeParameter;

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
                    e.message.toString(),
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
    } on FirebaseAuthException catch (e) {
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
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }
      rethrow;
    }
  }

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
      User? user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
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
      
      // Hide loading overlay before navigation
      if (context.mounted) {
        LoadingOverlay.hide(context);
        // Wait a frame to ensure overlay is dismissed
        await Future.delayed(const Duration(milliseconds: 100));
      }
      notifyListeners();
    } catch (e) {
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }
      rethrow;
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    LoadingOverlay.show(context, message: 'Signing in with Google...');
    
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        if (context.mounted) {
          LoadingOverlay.hide(context);
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

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
    isLoading = true;
    notifyListeners();
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Reload user to get latest data including emailVerified status
        await currentUser.reload();
        _user = FirebaseAuth.instance.currentUser;

        if (_user != null) {
          final docSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .get()
              .timeout(const Duration(seconds: 5));

          _hasAgeParameter =
              docSnapshot.exists && docSnapshot.data()!.containsKey('age');
          _isNewUser =
              _user!.metadata.creationTime == _user!.metadata.lastSignInTime &&
                  !_hasAgeParameter!;
        }
      } else {
        _user = null;
        _hasAgeParameter = null;
        _isNewUser = null;
      }
    } catch (e) {
      // Handle error silently
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
