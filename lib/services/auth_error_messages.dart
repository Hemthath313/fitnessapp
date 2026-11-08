import 'package:firebase_auth/firebase_auth.dart';

/// Turns Firebase auth failures into short, human, actionable sentences.
class AuthErrorMessages {
  const AuthErrorMessages._();

  static const _fallback =
      'Something went wrong. Please check your details and try again.';

  /// Codes we have specific copy for.
  static const Map<String, String> _byCode = {
    'invalid-credential':
        'That email and password don\'t match. Check them and try again.',
    'invalid-login-credentials':
        'That email and password don\'t match. Check them and try again.',
    'wrong-password': 'That password isn\'t right. Try again or reset it.',
    'user-not-found':
        'We couldn\'t find an account with that email. Try signing up instead.',
    'invalid-email': 'That email address doesn\'t look right.',
    'email-already-in-use':
        'This email already has an account. Sign in instead.',
    'weak-password': 'Choose a stronger password (at least 6 characters).',
    'user-disabled':
        'This account has been disabled. Contact support if that\'s a surprise.',
    'too-many-requests':
        'Too many attempts. Wait a few minutes, then try again.',
    'network-request-failed':
        'No connection. Check your internet and try again.',
    'operation-not-allowed':
        'This sign-in method isn\'t available right now.',
    'requires-recent-login':
        'For your security, please sign in again to continue.',
    'account-exists-with-different-credential':
        'This email is linked to a different sign-in method. Try that one.',
  };

  /// Extracts a known code from a [FirebaseAuthException] or from any error
  /// text (older call sites pass `e.toString()`), or null if none is found.
  static String? codeOf(Object error) {
    if (error is FirebaseAuthException) return error.code;
    final text = error.toString();
    for (final code in _byCode.keys) {
      if (text.contains(code)) return code;
    }
    // Message Firebase sends for bad email/password on newer SDKs.
    if (text.contains('supplied auth credential is incorrect')) {
      return 'invalid-credential';
    }
    return null;
  }

  static String from(Object error) {
    final code = codeOf(error);
    return (code != null ? _byCode[code] : null) ?? _fallback;
  }
}
