/// Route path constants for QARI | قارئ.
abstract final class RoutePaths {
  static const String splash = '/splash';

  /// Pre-auth entry: Google-only sign-in screen.
  static const String welcome = '/welcome';

  /// One-shot animated loading shown right after a session becomes available.
  static const String authLoading = '/auth/loading';

  /// Root shell (StatefulShellRoute) branches.
  static const String home = '/home';
  static const String library = '/library';
  static const String settings = '/settings';

  /// File Engine entry point pushed above the shell (PHASE 05).
  static const String fileImport = '/import';

  /// Info pages pushed inside the settings branch.
  static const String about = '/settings/about';
  static const String privacy = '/settings/privacy';
  static const String terms = '/settings/terms';
  static const String help = '/settings/help';
  static const String aboutUs = '/settings/about-us';

  /// Routes reachable before a user is authenticated.
  static const Set<String> publicRoutes = {splash, welcome};

  /// Whether [location] is a public (pre-auth) route.
  static bool isPublic(String location) => publicRoutes.contains(location);

  /// Auth entry points that an authenticated user should not stay on.
  static const Set<String> authEntryRoutes = {welcome};
}
