/// Route path constants for QARI | قارئ.
abstract final class RoutePaths {
  static const String splash = '/splash';
  static const String welcome = '/welcome';

  /// PHASE 03 auth routes (public pre-login + gated verify step).
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String emailVerification = '/auth/verify-email';

  /// Root shell (StatefulShellRoute) branches.
  static const String home = '/home';
  static const String library = '/library';
  static const String settings = '/settings';

  /// Info pages pushed inside the settings branch.
  static const String about = '/settings/about';
  static const String privacy = '/settings/privacy';
  static const String terms = '/settings/terms';
  static const String help = '/settings/help';
  static const String aboutUs = '/settings/about-us';

  /// Routes reachable before a user is authenticated.
  static const Set<String> publicRoutes = {
    splash,
    welcome,
    login,
    register,
    forgotPassword,
  };

  /// Routes only reachable while signed-in but email-unverified.
  static const Set<String> verificationRoutes = {emailVerification};

  /// Whether [location] is a public (pre-auth) route.
  static bool isPublic(String location) => publicRoutes.contains(location);

  /// Whether [location] requires an unverified signed-in session.
  static bool isVerification(String location) =>
      verificationRoutes.contains(location);

  /// Auth entry points that a verified user should not stay on.
  static const Set<String> authEntryRoutes = {
    welcome,
    login,
    register,
    forgotPassword,
    emailVerification,
  };
}
