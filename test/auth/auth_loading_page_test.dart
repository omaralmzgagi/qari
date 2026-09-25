import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qari/app/app_providers.dart';
import 'package:qari/app/qari_app.dart';
import 'package:qari/core/services/storage/settings_service.dart';
import 'package:qari/features/auth/data/auth_gateway_providers.dart';
import 'package:qari/features/auth/data/gateways/fake_auth_gateway.dart';
import 'package:qari/features/auth/data/session_providers.dart';
import 'package:qari/features/auth/data/session_store.dart';
import 'package:qari/features/auth/domain/entities/auth_user.dart';
import 'package:qari/features/auth/domain/failures/auth_failure.dart';
import 'package:qari/features/auth/presentation/auth_providers.dart';
import 'package:qari/features/auth/presentation/screens/auth_loading_page.dart';
import 'package:qari/features/home/presentation/home_screen.dart';
import 'package:qari/features/welcome/presentation/welcome_screen.dart';

void main() {
  Future<void> useTabletViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  ProviderScope buildApp({FakeAuthGateway? gateway}) {
    final fake = gateway ?? FakeAuthGateway();
    addTearDown(fake.dispose);
    return ProviderScope(
      overrides: [
        settingsServiceProvider.overrideWithValue(MemorySettingsService()),
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        authEnabledProvider.overrideWithValue(true),
        authGatewayProvider.overrideWithValue(fake),
      ],
      child: const QariApp(),
    );
  }

  FakeAuthGateway signedInGateway() => FakeAuthGateway(
        initialUser: const AuthUser(
          uid: 'test-user',
          email: 'test@example.com',
          emailVerified: true,
          provider: AuthProviderKind.google,
        ),
      );

  Future<void> pumpToAuthLoading(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.byType(AuthLoadingPage), findsOneWidget);
  }

  testWidgets('shows brand, translated label and a horizontal progress bar',
      (tester) async {
    await useTabletViewport(tester);
    await tester.pumpWidget(buildApp(gateway: signedInGateway()));
    await pumpToAuthLoading(tester);

    expect(find.byKey(const Key('auth-loading-logo')), findsOneWidget);
    final label = tester.widget<Text>(
      find.byKey(const Key('auth-loading-label')),
    );
    expect(label.data, anyOf('Signing in...', 'جارٍ تسجيل الدخول...'));

    final bar = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('auth-loading-progress')),
    );
    expect(bar.value, 0.0);
  });

  testWidgets('progress bar advances linearly until it reaches 1',
      (tester) async {
    await useTabletViewport(tester);
    await tester.pumpWidget(buildApp(gateway: signedInGateway()));
    await pumpToAuthLoading(tester);

    double readBar() {
      final found = find.byKey(const Key('auth-loading-progress'));
      if (found.evaluate().isEmpty) return 1;
      return tester.widget<LinearProgressIndicator>(found).value ?? 0;
    }

    final values = <double>[];
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
      values.add(readBar());
    }

    for (var i = 1; i < values.length; i++) {
      expect(values[i], greaterThanOrEqualTo(values[i - 1]));
    }
    expect(values.first, lessThan(1));
    expect(values.last, 1);
    expect(values, contains(1));
  });

  testWidgets('navigates to home after three seconds', (tester) async {
    await useTabletViewport(tester);
    await tester.pumpWidget(buildApp(gateway: signedInGateway()));
    await pumpToAuthLoading(tester);
    expect(find.byType(HomeScreen), findsNothing);

    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(AuthLoadingPage), findsNothing);
  });

  testWidgets('back button cannot return to the loading page', (tester) async {
    await useTabletViewport(tester);
    await tester.pumpWidget(buildApp(gateway: signedInGateway()));
    await pumpToAuthLoading(tester);

    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    expect(container.read(routerProvider).canPop(), isFalse);
  });

  testWidgets('google sign-in passes through the loading page', (tester) async {
    await useTabletViewport(tester);
    final gateway = FakeAuthGateway();
    await tester.pumpWidget(buildApp(gateway: gateway));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byKey(const Key('welcome-google-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('welcome-google-button')));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(gateway.currentUser, isNotNull);
    expect(find.byType(AuthLoadingPage), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(AuthLoadingPage), findsNothing);
  });

  testWidgets('cancelled google sign-in stays on the welcome screen',
      (tester) async {
    await useTabletViewport(tester);
    final gateway = FakeAuthGateway()
      ..failNextGoogle = AuthFailureCode.googleSignInCancelled;
    await tester.pumpWidget(buildApp(gateway: gateway));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    await tester.tap(find.byKey(const Key('welcome-google-button')));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(AuthLoadingPage), findsNothing);
    expect(find.byType(HomeScreen), findsNothing);
  });
}
