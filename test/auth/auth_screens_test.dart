import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qari/app/app_providers.dart';
import 'package:qari/core/routing/app_routes.dart';
import 'package:qari/core/services/storage/settings_service.dart';
import 'package:qari/features/auth/data/auth_gateway_providers.dart';
import 'package:qari/features/auth/data/gateways/fake_auth_gateway.dart';
import 'package:qari/features/auth/data/session_providers.dart';
import 'package:qari/features/auth/data/session_store.dart';
import 'package:qari/features/auth/domain/entities/auth_user.dart';
import 'package:qari/features/auth/presentation/auth_providers.dart';
import 'package:qari/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:qari/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:qari/features/auth/presentation/screens/login_screen.dart';
import 'package:qari/features/auth/presentation/screens/register_screen.dart';
import 'package:qari/localization/generated/app_localizations.dart';

Future<ProviderContainer> pumpAuthScreen(
  WidgetTester tester,
  Widget screen, {
  FakeAuthGateway? gateway,
  String initialLocation = RoutePaths.login,
}) async {
  final fake = gateway ?? FakeAuthGateway();
  final container = ProviderContainer(
    overrides: [
      authEnabledProvider.overrideWithValue(true),
      authGatewayProvider.overrideWithValue(fake),
      sessionStoreProvider.overrideWithValue(MemorySessionStore()),
      settingsServiceProvider.overrideWithValue(MemorySettingsService()),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(fake.dispose);

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: RoutePaths.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: RoutePaths.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.emailVerification,
        builder: (_, __) => const EmailVerificationScreen(),
      ),
      GoRoute(path: RoutePaths.welcome, builder: (_, __) => const SizedBox()),
      GoRoute(path: RoutePaths.home, builder: (_, __) => const SizedBox()),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      ),
    ),
  );
  return container;
}

void main() {
  testWidgets('login screen shows fields and submit', (tester) async {
    await pumpAuthScreen(tester, const LoginScreen());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byKey(const Key('login-email-field')), findsOneWidget);
    expect(find.byKey(const Key('login-password-field')), findsOneWidget);
    expect(find.byKey(const Key('auth-submit-button')), findsOneWidget);
  });

  testWidgets('login validation shows error on empty submit', (tester) async {
    await pumpAuthScreen(tester, const LoginScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pump();

    expect(find.byKey(const Key('auth-error-text')), findsOneWidget);
  });

  testWidgets('login with valid credentials and registered user succeeds',
      (tester) async {
    final gateway = FakeAuthGateway(autoVerifyEmails: true);
    await gateway.registerWithEmail(email: 'a@b.com', password: 'secret1');
    gateway.clearUser();

    await pumpAuthScreen(tester, const LoginScreen(), gateway: gateway);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login-email-field')),
      'a@b.com',
    );
    await tester.enterText(
      find.byKey(const Key('login-password-field')),
      'secret1',
    );
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth-error-text')), findsNothing);
    expect(gateway.currentUser, isNotNull);
  });

  testWidgets('register screen validates password mismatch', (tester) async {
    await pumpAuthScreen(
      tester,
      const RegisterScreen(),
      initialLocation: RoutePaths.register,
    );
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('register-email-field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register-password-field')),
      'secret1',
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm-field')),
      'secret2',
    );
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pump();

    expect(find.byKey(const Key('auth-error-text')), findsOneWidget);
  });

  testWidgets('register success navigates toward verification or home',
      (tester) async {
    final gateway = FakeAuthGateway(autoVerifyEmails: true);
    await pumpAuthScreen(
      tester,
      const RegisterScreen(),
      gateway: gateway,
      initialLocation: RoutePaths.register,
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('register-name-field')),
      'Test',
    );
    await tester.enterText(
      find.byKey(const Key('register-email-field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register-password-field')),
      'secret1',
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm-field')),
      'secret1',
    );
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(gateway.currentUser, isNotNull);
    expect(gateway.currentUser!.emailVerified, isTrue);
  });

  testWidgets('forgot password shows success banner after send',
      (tester) async {
    final gateway = FakeAuthGateway();
    await gateway.registerWithEmail(email: 'a@b.com', password: 'secret1');
    gateway.clearUser();

    await pumpAuthScreen(
      tester,
      const ForgotPasswordScreen(),
      gateway: gateway,
      initialLocation: RoutePaths.forgotPassword,
    );
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('forgot-email-field')),
      'a@b.com',
    );
    await tester.tap(find.byKey(const Key('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth-success-banner')), findsOneWidget);
  });

  testWidgets('email verification screen shows resend and check buttons',
      (tester) async {
    const user = AuthUserSeed.unverified;
    final gateway = FakeAuthGateway(initialUser: user);
    final container = await pumpAuthScreen(
      tester,
      const EmailVerificationScreen(),
      gateway: gateway,
      initialLocation: RoutePaths.emailVerification,
    );
    await tester.pumpAndSettle();
    await container.read(authStateProvider.notifier).restoreSession();
    await tester.pumpAndSettle();

    expect(find.byType(EmailVerificationScreen), findsOneWidget);
    expect(find.byKey(const Key('verify-resend-button')), findsOneWidget);
    expect(find.byKey(const Key('verify-check-button')), findsOneWidget);
  });
}

/// Seed helpers kept local to this test file.
abstract final class AuthUserSeed {
  static const unverified = AuthUser(
    uid: 'u-verify',
    email: 'verify@example.com',
    emailVerified: false,
  );
}
