import '../../localization/app_locale.dart';
import '../../theme/app_theme_mode.dart';

/// Global runtime configuration switches.
///
/// Everything here is intentionally overridable (via Riverpod overrides) so
/// the app remains testable while the same defaults are used in production.
abstract final class AppConfig {
  static const String appVersion = '0.1.0';

  static const Duration splashDelay = Duration(milliseconds: 1800);

  /// How long the Google sign-in transition screen stays up.
  static const Duration authLoadingDuration = Duration(seconds: 3);

  static const AppLocale defaultLocale = AppLocale.arabic;

  static const AppThemeMode defaultThemeMode = AppThemeMode.system;

  /// Whether real Google Sign-In is active (`false` disables the button).
  static const bool authEnabled = true;

  /// Whether Firebase has been configured in this build.
  ///
  /// `true` only once `google-services.json` (Android) /
  /// `GoogleService-Info.plist` (iOS) are present and [AppFirebaseOptions]
  /// points at real credentials (project `qari-4e344`).
  static const bool firebaseConfigured = true;
}