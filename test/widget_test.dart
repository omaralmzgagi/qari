import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qari/app/app_providers.dart';
import 'package:qari/app/qari_app.dart';
import 'package:qari/core/config/branding/brand_info.dart';
import 'package:qari/core/services/storage/settings_service.dart';
import 'package:qari/features/auth/data/session_providers.dart';
import 'package:qari/features/auth/data/session_store.dart';
import 'package:qari/features/auth/domain/entities/app_user.dart';
import 'package:qari/features/home/presentation/home_screen.dart';
import 'package:qari/features/splash/presentation/splash_screen.dart';
import 'package:qari/features/welcome/presentation/welcome_screen.dart';

class _FakeUser extends AppUser {
  const _FakeUser()
      : super(
          id: 'test-user',
          email: 'test@example.com',
          name: 'Test User',
        );
}

void main() {
  ProviderScope buildApp({SessionStore? sessionStore}) {
    return ProviderScope(
      overrides: [
        settingsServiceProvider.overrideWithValue(MemorySettingsService()),
        sessionStoreProvider
            .overrideWithValue(sessionStore ?? MemorySessionStore()),
      ],
      child: const QariApp(),
    );
  }

  testWidgets('splash shows brand identity then routes to welcome',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text(BrandInfo.nameLatin), findsWidgets);

    // Advance past the splash delay (1.8s) and settle navigation.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.bySubtype<ButtonStyleButton>(), findsOneWidget);
  });

  testWidgets('splash routes authenticated users to home', (tester) async {
    await tester.pumpWidget(buildApp(sessionStore: MemorySessionStore(
      const _FakeUser(),
    )));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('welcome Google button shows phase placeholder', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    await tester.tap(find.bySubtype<ButtonStyleButton>());
    await tester.pump();

    expect(find.byType(SnackBar), findsWidgets);
  });
}