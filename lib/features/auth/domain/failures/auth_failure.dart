import 'package:flutter/foundation.dart';

/// Categorized, user-presentable authentication failures.
///
/// Every [code] maps to a localized message (see `authError*` keys in
/// `app_{en,ar}.arb` and `auth_messages.dart`) so the UI never shows
/// raw Firebase internals.
@immutable
class AuthFailure {
  const AuthFailure({required this.code, this.cause});

  final AuthFailureCode code;
  final Object? cause;

  bool get isCancelled => code == AuthFailureCode.googleSignInCancelled;

  @override
  bool operator ==(Object other) => other is AuthFailure && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'AuthFailure(${code.name})';
}

/// The exhaustive set of failure kinds QARI can surface.
///
/// Google Sign-In is the only session entry point, so no e-mail/password
/// failure kinds exist.
enum AuthFailureCode {
  userDisabled,
  tooManyRequests,
  networkRequestFailed,
  invalidCredential,
  accountExistsWithDifferentCredential,
  operationNotAllowed,
  googleSignInCancelled,
  googleSignInFailed,
  unknown,
}
