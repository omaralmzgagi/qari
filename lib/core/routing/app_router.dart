import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/info/presentation/info_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/welcome/presentation/welcome_screen.dart';
import '../../widgets/navigation/app_navigation_shell.dart';
import 'app_routes.dart';

/// Builds the application router with an authentication-aware redirect.
///
/// The redirect is a safety net: the Splash screen drives the initial
/// navigation after restoring the session. Call `router.refresh()` whenever
/// `authStateProvider` changes from app-level listeners.
///
/// Authenticated experience lives inside a [StatefulShellRoute.indexedStack]
/// shell so future features (Library, Reader, etc.) can be added as new
/// branches or nested routes without touching navigation logic.
GoRouter buildAppRouter(Ref ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppNavigationShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.library,
                name: 'library',
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.settings,
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
              GoRoute(
                path: RoutePaths.about,
                name: 'about',
                builder: (context, state) => InfoScreen.info(
                  info: InfoPage.about,
                ),
              ),
              GoRoute(
                path: RoutePaths.privacy,
                name: 'privacy',
                builder: (context, state) => InfoScreen.info(
                  info: InfoPage.privacy,
                ),
              ),
              GoRoute(
                path: RoutePaths.terms,
                name: 'terms',
                builder: (context, state) => InfoScreen.info(
                  info: InfoPage.terms,
                ),
              ),
              GoRoute(
                path: RoutePaths.help,
                name: 'help',
                builder: (context, state) => InfoScreen.info(
                  info: InfoPage.help,
                ),
              ),
              GoRoute(
                path: RoutePaths.aboutUs,
                name: 'aboutUs',
                builder: (context, state) => InfoScreen.info(
                  info: InfoPage.aboutUs,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      if (auth.isUnknown) return null;

      final location = state.matchedLocation;

      if (auth.isAuthenticated) {
        if (location == RoutePaths.welcome) return RoutePaths.home;
        return null;
      }

      // Unauthenticated users are kept out of private pages.
      if (!RoutePaths.isPublic(location)) return RoutePaths.welcome;
      return null;
    },
  );
}