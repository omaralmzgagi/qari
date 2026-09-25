import 'package:flutter/material.dart';

import '../../../../localization/app_localization_ext.dart';
import '../../domain/failures/auth_failure.dart';

/// Maps an [AuthFailure] to a localized, user-presentable message.
String authFailureMessage(BuildContext context, AuthFailure failure) {
  final l10n = context.l10n;
  switch (failure.code) {
    case AuthFailureCode.userDisabled:
      return l10n.authErrorUserDisabled;
    case AuthFailureCode.tooManyRequests:
      return l10n.authErrorTooManyRequests;
    case AuthFailureCode.networkRequestFailed:
      return l10n.authErrorNetwork;
    case AuthFailureCode.invalidCredential:
      return l10n.authErrorInvalidCredential;
    case AuthFailureCode.accountExistsWithDifferentCredential:
      return l10n.authErrorAccountExistsDifferent;
    case AuthFailureCode.operationNotAllowed:
      return l10n.authErrorOperationNotAllowed;
    case AuthFailureCode.googleSignInCancelled:
      return l10n.authErrorGoogleCancelled;
    case AuthFailureCode.googleSignInFailed:
      return l10n.authErrorGoogleFailed;
    case AuthFailureCode.unknown:
      return l10n.authErrorUnknown;
  }
}
