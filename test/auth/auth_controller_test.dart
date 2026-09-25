import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qari/app/app_providers.dart';
import 'package:qari/core/services/storage/settings_service.dart';
import 'package:qari/features/auth/data/auth_gateway_providers.dart';
import 'package:qari/features/auth/data/gateways/fake_auth_gateway.dart';
import 'package:qari/features/auth/data/session_providers.dart';
import 'package:qari/features/auth/data/session_store.dart';
import 'package:qari/features/auth/domain/entities/app_user.dart';
import 'package:qari/features/auth/domain/entities/auth_result.dart';
import 'package:qari/features/auth/domain/entities/auth_user.dart';
import 'package:qari/features/auth/domain/failures/auth_failure.dart';
import 'package:qari/features/auth/presentation/auth_providers.dart';

ProviderContainer buildContainer({
  FakeAuthGateway? gateway,
  SessionStore? sessionStore,
  bool authEnabled = true,
}) {
  final fake = gateway ?? FakeAuthGateway();
  final container = ProviderContainer(
    overrides: [
      authEnabledProvider.overrideWithValue(authEnabled),
      authGatewayProvider.overrideWithValue(fake),
      sessionStoreProvider
          .overrideWithValue(sessionStore ?? MemorySessionStore()),
      settingsServiceProvider.overrideWithValue(MemorySettingsService()),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(fake.dispose);
  return container;
}

void main() {
  group('AuthState', () {
    test('unknown / unauthenticated factories', () {
      expect(AuthState.unknown().isUnknown, isTrue);
      expect(AuthState.unauthenticated().isUnauthenticated, isTrue);
      expect(AuthState.unauthenticated().isAuthenticated, isFalse);
    });

    test('authenticated factory carries the user', () {
      const user = AppUser(
        id: '1',
        email: 'a@b.com',
        provider: AuthProviderKind.google,
      );
      final auth = AuthState.authenticated(user);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.hasUser, isTrue);
      expect(auth.user?.provider, AuthProviderKind.google);
      expect(auth.isError, isFalse);
    });

    test('error factory carries failure', () {
      const failure = AuthFailure(code: AuthFailureCode.networkRequestFailed);
      final state = AuthState.error(failure);
      expect(state.isError, isTrue);
      expect(state.failure?.code, AuthFailureCode.networkRequestFailed);
    });
  });

  group('AppUser provider persistence', () {
    test('json round-trip keeps google provider', () {
      const user = AppUser(
        id: 'u1',
        email: 'a@b.com',
        provider: AuthProviderKind.google,
      );
      final restored = AppUser.fromJson(user.toJson());
      expect(restored.provider, AuthProviderKind.google);
      expect(restored.id, user.id);
      expect(restored.email, user.email);
    });

    test('missing provider key defaults to unknown', () {
      final restored = AppUser.fromJson(const {'id': 'u1', 'email': 'a@b.com'});
      expect(restored.provider, AuthProviderKind.unknown);
    });
  });

  group('AuthController with FakeAuthGateway', () {
    test('restoreSession with no user → unauthenticated', () async {
      final container = buildContainer();
      await container.read(authStateProvider.notifier).restoreSession();
      expect(
        container.read(authStateProvider).isUnauthenticated,
        isTrue,
      );
    });

    test('restoreSession with google user → authenticated + provider kept',
        () async {
      const user = AuthUser(
        uid: 'u1',
        email: 'a@b.com',
        emailVerified: true,
        provider: AuthProviderKind.google,
      );
      final container = buildContainer(
        gateway: FakeAuthGateway(initialUser: user),
      );
      await container.read(authStateProvider.notifier).restoreSession();
      final state = container.read(authStateProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.email, 'a@b.com');
      expect(state.user?.provider, AuthProviderKind.google);
    });

    test('signInWithGoogle success → authenticated with google provider',
        () async {
      final container = buildContainer();
      final result =
          await container.read(authStateProvider.notifier).signInWithGoogle();
      expect(result, isA<AuthSuccess<AuthUser>>());
      final state = container.read(authStateProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.provider, AuthProviderKind.google);
    });

    test('signInWithGoogle cancelled keeps unauthenticated', () async {
      final container = buildContainer(
        gateway: FakeAuthGateway()
          ..failNextGoogle = AuthFailureCode.googleSignInCancelled,
      );
      await container.read(authStateProvider.notifier).restoreSession();
      final result =
          await container.read(authStateProvider.notifier).signInWithGoogle();
      expect((result as AuthFailureResult).failure.isCancelled, isTrue);
      expect(container.read(authStateProvider).isUnauthenticated, isTrue);
    });

    test('signOut clears session', () async {
      final container = buildContainer();
      final notifier = container.read(authStateProvider.notifier);
      await notifier.signInWithGoogle();
      expect(container.read(authStateProvider).isAuthenticated, isTrue);

      await notifier.signOut();
      expect(container.read(authStateProvider).isUnauthenticated, isTrue);
    });

    test('auth disabled → google sign-in returns operationNotAllowed',
        () async {
      final container = buildContainer(authEnabled: false);
      final result =
          await container.read(authStateProvider.notifier).signInWithGoogle();
      expect(
        (result as AuthFailureResult).failure.code,
        AuthFailureCode.operationNotAllowed,
      );
      expect(container.read(authStateProvider).isAuthenticated, isFalse);
    });
  });
}
