import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/screens/auth_loading_page.dart';
import '../../features/files/presentation/file_import_screen.dart';
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
/// Flow: `splash` → (`authLoading` | `welcome`) → Google sign-in →
/// `authLoading` → `home`.
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
      GoRoute(
        path: RoutePaths.authLoading,
        name: 'authLoading',
        builder: (context, state) => const AuthLoadingPage(),
      ),
      GoRoute(
        path: RoutePaths.fileImport,
        name: 'fileImport',
        builder: (context, state) => const FileImportScreen(),
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
      if (auth.isUnknown || auth.isError) return null;

      final location = state.matchedLocation;

      if (auth.isAuthenticated) {
        // An auth entry screen is a dead end once a session exists.
        if (RoutePaths.authEntryRoutes.contains(location)) {
          return RoutePaths.authLoading;
        }
        return null;
      }

      // Unauthenticated: only splash + the Google sign-in screen are public.
      if (!RoutePaths.isPublic(location)) return RoutePaths.welcome;
      return null;
    },
  );
}
