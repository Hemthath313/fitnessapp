import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fitness_app/data/db.dart';
import 'package:fitness_app/presentation/auth/providers/auth_provider.dart' as app_auth;
import 'package:fitness_app/utils/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  var currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> changePassword({
    required BuildContext context,
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    LoadingOverlay.show(context, message: 'Changing password...');

    try {
      var credential =
          EmailAuthProvider.credential(email: email, password: oldPassword);
      await currentUser!.reauthenticateWithCredential(credential).then((value) {
        currentUser!.updatePassword(newPassword);
      });

      if (context.mounted) {
        LoadingOverlay.hide(context);
      }
      notifyListeners();
    } catch (e) {
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }
      rethrow;
    }
  }

  Future<void> changeEmail({
    required BuildContext context,
    required String oldEmail,
    required String newEmail,
    required String password,
  }) async {
    LoadingOverlay.show(context, message: 'Changing email...');

    try {
      var credential =
          EmailAuthProvider.credential(email: oldEmail, password: password);
      await currentUser!.reauthenticateWithCredential(credential).then((value) {
        currentUser!.updateEmail(newEmail);
      });

      if (context.mounted) {
        LoadingOverlay.hide(context);
      }
      notifyListeners();
    } catch (e) {
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }
      rethrow;
    }
  }

  Future<void> deleteUser({
    required String email,
    required String password,
    required BuildContext context,
    bool isGoogleUser = false,
  }) async {
    LoadingOverlay.show(context, message: 'Deleting account...');

    try {
      User? user = _auth.currentUser;

      if (isGoogleUser) {
        // Firebase refuses user.delete() unless the sign-in is recent
        // (requires-recent-login), so confirm the Google account first.
        final googleAccount = await GoogleSignIn().signIn();
        if (googleAccount == null) {
          throw FirebaseAuthException(
            code: 'cancelled',
            message: 'Google sign-in was cancelled. Your account was not deleted.',
          );
        }
        final googleAuth = await googleAccount.authentication;
        await user!.reauthenticateWithCredential(GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        ));
        await DataBase(user.uid).deleteUserData();
        await app_auth.AuthProvider.clearCachedOnboardingStatus(user.uid);
        await user.delete();
      } else {
        // For regular users, reauthenticate first
        AuthCredential credential =
            EmailAuthProvider.credential(email: email, password: password);
        UserCredential result =
            await user!.reauthenticateWithCredential(credential);
        await DataBase(result.user!.uid).deleteUserData();
        await app_auth.AuthProvider.clearCachedOnboardingStatus(result.user!.uid);
        await result.user!.delete();
      }

      if (context.mounted) {
        LoadingOverlay.hide(context);
      }
      notifyListeners();
    } catch (e) {
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }
      rethrow;
    }
  }

  Future<void> signOut({
    required BuildContext context,
  }) async {
    LoadingOverlay.show(context, message: 'Logging out...');

    try {
      await FirebaseAuth.instance.signOut();

      // Wait for auth state to update
      await Future.delayed(const Duration(milliseconds: 100));

      if (context.mounted) {
        LoadingOverlay.hide(context);
      }

      notifyListeners();
    } on FirebaseAuthException catch (_) {
      if (context.mounted) {
        LoadingOverlay.hide(context);
      }
      notifyListeners();
    }
  }
}
