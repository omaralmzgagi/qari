import 'package:flutter/material.dart';

import '../../../../localization/app_localization_ext.dart';
import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_typography.dart';
import '../../domain/failures/auth_failure.dart';

/// Maps an [AuthFailure] to a localized, user-presentable message.
String authFailureMessage(BuildContext context, AuthFailure failure) {
  final l10n = context.l10n;
  switch (failure.code) {
    case AuthFailureCode.invalidEmail:
      return l10n.authErrorInvalidEmail;
    case AuthFailureCode.userNotFound:
      return l10n.authErrorUserNotFound;
    case AuthFailureCode.wrongPassword:
      return l10n.authErrorWrongPassword;
    case AuthFailureCode.emailAlreadyInUse:
      return l10n.authErrorEmailAlreadyInUse;
    case AuthFailureCode.weakPassword:
      return l10n.authErrorWeakPassword;
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

/// Maps a validation key from `AuthValidators` to a localized message.
String authValidationMessage(BuildContext context, String key) {
  final l10n = context.l10n;
  switch (key) {
    case 'invalidEmail':
      return l10n.authErrorInvalidEmail;
    case 'passwordRequired':
      return l10n.authErrorPasswordRequired;
    case 'passwordTooShort':
      return l10n.authErrorPasswordTooShort;
    case 'passwordMismatch':
      return l10n.authErrorPasswordMismatch;
    default:
      return l10n.authErrorUnknown;
  }
}

/// Inline form error text (red caption under fields / above submit).
class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        message,
        key: const Key('auth-error-text'),
        style: AppTypography.caption(theme.brightness).copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

/// Success feedback banner (e.g. password-reset email sent).
class AuthSuccessBanner extends StatelessWidget {
  const AuthSuccessBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('auth-success-banner'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightSuccessContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
