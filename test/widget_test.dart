import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qari/app/app_providers.dart';
import 'package:qari/app/qari_app.dart';
import 'package:qari/core/config/branding/brand_info.dart';
import 'package:qari/core/services/storage/settings_service.dart';
import 'package:qari/features/auth/data/auth_gateway_providers.dart';
import 'package:qari/features/auth/data/gateways/fake_auth_gateway.dart';
import 'package:qari/features/auth/data/session_providers.dart';
import 'package:qari/features/auth/data/session_store.dart';
import 'package:qari/features/auth/domain/entities/auth_user.dart';
import 'package:qari/features/auth/presentation/auth_providers.dart';
import 'package:qari/features/home/presentation/home_screen.dart';
import 'package:qari/features/splash/presentation/splash_screen.dart';
import 'package:qari/features/welcome/presentation/welcome_screen.dart';

void main() {
  // The Welcome card with PHASE 03 buttons (Google + email login + register)
  // needs more vertical space than the default 800x600 test viewport.
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

  testWidgets('splash shows brand identity then routes to welcome',
      (tester) async {
    await useTabletViewport(tester);
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text(BrandInfo.nameLatin), findsWidgets);

    // Advance past the splash delay (1.8s) and settle navigation.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byKey(const Key('welcome-google-button')), findsOneWidget);
    expect(find.byKey(const Key('welcome-email-button')), findsOneWidget);
    expect(find.byKey(const Key('welcome-register-button')), findsOneWidget);
  });

  testWidgets('splash routes authenticated users to home', (tester) async {
    await useTabletViewport(tester);
    await tester.pumpWidget(
      buildApp(
        gateway: FakeAuthGateway(
          initialUser: const AuthUser(
            uid: 'test-user',
            email: 'test@example.com',
            emailVerified: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('welcome Google button signs in through the fake gateway',
      (tester) async {
    await useTabletViewport(tester);
    final gateway = FakeAuthGateway();
    await tester.pumpWidget(buildApp(gateway: gateway));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.byType(WelcomeScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('welcome-google-button')));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(gateway.currentUser, isNotNull);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
