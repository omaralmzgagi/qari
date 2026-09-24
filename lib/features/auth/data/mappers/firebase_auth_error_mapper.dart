import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/failures/auth_failure.dart';

/// Maps Firebase Auth / Google Sign-In exceptions to [AuthFailure].
///
/// The UI only ever sees [AuthFailureCode] — never raw Firebase codes.
abstract final class FirebaseAuthErrorMapper {
  static AuthFailure fromFirebaseException(Object error) {
    if (error is fb.FirebaseAuthException) {
      return AuthFailure(code: _mapCode(error.code), cause: error);
    }
    return AuthFailure(code: AuthFailureCode.unknown, cause: error);
  }

  static AuthFailure fromGoogleSignInError(Object error) {
    final message = error.toString();
    if (message.contains('Canceled') || message.contains('cancelled')) {
      return AuthFailure(
        code: AuthFailureCode.googleSignInCancelled,
        cause: error,
      );
    }
    if (error is fb.FirebaseAuthException) {
      return fromFirebaseException(error);
    }
    return AuthFailure(code: AuthFailureCode.googleSignInFailed, cause: error);
  }

  static AuthFailureCode _mapCode(String code) {
    switch (code) {
      case 'invalid-email':
        return AuthFailureCode.invalidEmail;
      case 'user-not-found':
        return AuthFailureCode.userNotFound;
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-mismatch':
        return AuthFailureCode.wrongPassword;
      case 'email-already-in-use':
        return AuthFailureCode.emailAlreadyInUse;
      case 'weak-password':
        return AuthFailureCode.weakPassword;
      case 'user-disabled':
        return AuthFailureCode.userDisabled;
      case 'too-many-requests':
        return AuthFailureCode.tooManyRequests;
      case 'network-request-failed':
        return AuthFailureCode.networkRequestFailed;
      case 'account-exists-with-different-credential':
        return AuthFailureCode.accountExistsWithDifferentCredential;
      case 'operation-not-allowed':
        return AuthFailureCode.operationNotAllowed;
      default:
        return AuthFailureCode.unknown;
    }
  }
}
