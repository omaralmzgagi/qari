/// Client-side validation for auth forms (Firebase-compatible rules).
abstract final class AuthValidators {
  /// Same lower bound Firebase uses before `weak-password`.
  static const int minPasswordLength = 6;

  static final RegExp _email = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
  );

  static bool isValidEmail(String email) {
    final value = email.trim();
    return value.isNotEmpty && _email.hasMatch(value);
  }

  /// Returns `null` when valid, otherwise a stable key for l10n lookup.
  static String? emailError(String email) =>
      isValidEmail(email) ? null : 'invalidEmail';

  /// Returns `null` when valid, otherwise a stable key for l10n lookup.
  static String? passwordError(String password) {
    if (password.isEmpty) return 'passwordRequired';
    if (password.length < minPasswordLength) return 'passwordTooShort';
    return null;
  }

  static bool isStrongEnoughPassword(String password) =>
      passwordError(password) == null;
}
