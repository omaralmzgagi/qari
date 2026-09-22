/// Central configuration for all brand assets.
///
/// All visual assets are referenced exclusively through this class. To replace
/// a logo, splash image, icon or login artwork later, simply swap the file at
/// the path below (or change the path) — no widget changes are required.
abstract final class BrandAssets {
  static const String _branding = 'assets/branding';
  static const String _login = 'assets/login';

  /// Primary logo (transparent background).
  static const String logo = '$_branding/logo.png';

  /// Logo variant designed for light surfaces (dark mark).
  static const String logoLight = '$_branding/logo_light.png';

  /// Logo variant designed for dark surfaces (light mark).
  static const String logoDark = '$_branding/logo_dark.png';

  /// App icon (filled background).
  static const String appIcon = '$_branding/app_icon.png';

  /// Logo shown on the splash screen.
  static const String splashLogo = '$_branding/splash_logo.png';

  /// Full-bleed artwork for the login screen.
  static const String loginBackground = '$_login/login_background.png';

  /// Optional hero/illustration for the login card (left empty by default).
  static const String loginHero = '$_login/login_hero.png';
}