import '../../localization/app_locale.dart';
import '../../theme/app_theme_mode.dart';

/// Global runtime configuration switches.
///
/// Everything here is intentionally overridable (via Riverpod overrides) so
/// the app remains testable while the same defaults are used in production.
abstract final class AppConfig {
  static const String appVersion = '0.1.0';

  static const Duration splashDelay = Duration(milliseconds: 1800);

  static const AppLocale defaultLocale = AppLocale.arabic;

  static const AppThemeMode defaultThemeMode = AppThemeMode.system;

  /// Whether to show real login UI (PHASE 02+) or the placeholder button.
  static const bool authEnabled = false;

  /// Whether Firebase has been configured in this build.
  ///
  /// Keep `true` only once `google-services.json` (Android) /
  /// `GoogleService-Info.plist` (iOS) are present and `AppFirebaseOptions`
  /// contains real credentials.
  static const bool firebaseConfigured = false;
}