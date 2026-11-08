import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/services/auth_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps FirebaseAuthException codes', () {
    expect(
      AuthErrorMessages.from(FirebaseAuthException(code: 'email-already-in-use')),
      contains('Sign in instead'),
    );
    expect(
      AuthErrorMessages.from(FirebaseAuthException(code: 'too-many-requests')),
      contains('Wait a few minutes'),
    );
    expect(
      AuthErrorMessages.from(FirebaseAuthException(code: 'network-request-failed')),
      contains('internet'),
    );
  });

  test('finds codes inside plain error text', () {
    expect(
      AuthErrorMessages.from(
          '[firebase_auth/wrong-password] The password is invalid'),
      contains('password isn\'t right'),
    );
    expect(
      AuthErrorMessages.from('The supplied auth credential is incorrect'),
      contains('don\'t match'),
    );
  });

  test('unknown errors get a calm generic message with no raw details', () {
    final msg = AuthErrorMessages.from(Exception('boom 0xDEADBEEF'));
    expect(msg, contains('Something went wrong'));
    expect(msg, isNot(contains('0xDEADBEEF')));
    expect(msg, isNot(contains('Exception')));
  });

  test('every message is a sentence ending with punctuation', () {
    for (final c in [
      'invalid-credential', 'wrong-password', 'user-not-found', 'invalid-email',
      'email-already-in-use', 'weak-password', 'user-disabled',
      'too-many-requests', 'network-request-failed', 'operation-not-allowed',
      'requires-recent-login', 'account-exists-with-different-credential',
    ]) {
      final m = AuthErrorMessages.from(FirebaseAuthException(code: c));
      expect(m.endsWith('.'), isTrue, reason: c);
    }
  });
}
