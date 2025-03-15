import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/string_manager.dart';
import 'package:fitness_app/utils/managers/style_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:fitness_app/utils/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool? _isNewUser;
  bool? _hasAgeParameter;
  bool isDataCompleted = false;
  bool isLoading = true;

  AuthProvider() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      if (_user != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get()
            .then((docSnapshot) {
          _hasAgeParameter =
              docSnapshot.exists && docSnapshot.data()!.containsKey('age');
          _isNewUser =
              _user!.metadata.creationTime == _user!.metadata.lastSignInTime &&
                  !_hasAgeParameter!;
          notifyListeners();
        });
      } else {
        _hasAgeParameter = null;
        _isNewUser = null;
        notifyListeners();
      }
    });
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
            .then((docSnapshot) {
          _hasAgeParameter =
              docSnapshot.exists && docSnapshot.data()!.containsKey('age');
          _isNewUser =
              _user!.metadata.creationTime == _user!.metadata.lastSignInTime &&
                  !_hasAgeParameter!;
          notifyListeners();
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
    showDialog(
        context: context,
        builder: (_) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(50),
              child: SpinKitSpinningLines(color: ColorManager.limerGreen2),
            ),
          );
        });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      // ignore: use_build_context_synchronously
      showDialog(
          context: context,
          builder: (_) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(PaddingManager.p40),
                child: AlertDialog(
                  backgroundColor: ColorManager.darkGrey,
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
                  backgroundColor: ColorManager.darkGrey,
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
    showDialog(
      context: context,
      builder: (_) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(50),
            child: SpinKitSpinningLines(color: ColorManager.limerGreen2),
          ),
        );
      },
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Navigator.pop(context); // Close loading dialog
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Close loading dialog
      rethrow; // <--- Forward the error back to LoginPage
    } catch (e) {
      Navigator.pop(context);
      rethrow; // Handle any unexpected error
    }
  }

  Future<void> registerAndVerifyEmail({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    showDialog(
      context: context,
      builder: (_) => Center(
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: SpinKitSpinningLines(color: ColorManager.limerGreen2),
        ),
      ),
    );

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
      Navigator.pop(context);

      notifyListeners(); // Important: Only notify here; no data storage yet.
      context.push(Routes.emailVerify); // Navigate to email verification page
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Close the dialog immediately
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
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      return;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      await currentUser.reload();
      _user = currentUser;

      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

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

    notifyListeners();
  }
}
