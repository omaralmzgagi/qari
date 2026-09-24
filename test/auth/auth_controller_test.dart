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

    test('authenticated and emailVerificationRequired factories', () {
      const user = AppUser(id: '1', email: 'a@b.com');
      final auth = AuthState.authenticated(user);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.requiresEmailVerification, isFalse);

      final verify = AuthState.emailVerificationRequired(user);
      expect(verify.requiresEmailVerification, isTrue);
      expect(verify.isAuthenticated, isFalse);
      expect(verify.hasUser, isTrue);
    });

    test('error factory carries failure', () {
      const failure = AuthFailure(code: AuthFailureCode.networkRequestFailed);
      final state = AuthState.error(failure);
      expect(state.isError, isTrue);
      expect(state.failure?.code, AuthFailureCode.networkRequestFailed);
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

    test('restoreSession with seeded verified user → authenticated', () async {
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
    });

    test('restoreSession with unverified user → emailVerificationRequired',
        () async {
      const user = AuthUser(
        uid: 'u1',
        email: 'a@b.com',
        emailVerified: false,
      );
      final container = buildContainer(
        gateway: FakeAuthGateway(initialUser: user),
      );
      await container.read(authStateProvider.notifier).restoreSession();
      expect(
        container.read(authStateProvider).requiresEmailVerification,
        isTrue,
      );
    });

    test('registerWithEmail unverified → emailVerificationRequired', () async {
      final container = buildContainer();
      final result = await container.read(authStateProvider.notifier)
          .registerWithEmail(email: 'a@b.com', password: 'secret1');
      expect(result, isA<AuthSuccess<AuthUser>>());
      expect(
        container.read(authStateProvider).requiresEmailVerification,
        isTrue,
      );
    });

    test('registerWithEmail with autoVerify → authenticated', () async {
      final container = buildContainer(
        gateway: FakeAuthGateway(autoVerifyEmails: true),
      );
      await container.read(authStateProvider.notifier).registerWithEmail(
            email: 'a@b.com',
            password: 'secret1',
          );
      expect(container.read(authStateProvider).isAuthenticated, isTrue);
    });

    test('signInWithEmail wrong password returns failure', () async {
      final container = buildContainer();
      final notifier = container.read(authStateProvider.notifier);
      await notifier.registerWithEmail(email: 'a@b.com', password: 'secret1');
      await notifier.signOut();

      final result = await notifier.signInWithEmail(
        email: 'a@b.com',
        password: 'wrong99',
      );
      expect(result, isA<AuthFailureResult<AuthUser>>());
      expect(
        (result as AuthFailureResult<AuthUser>).failure.code,
        AuthFailureCode.wrongPassword,
      );
      expect(container.read(authStateProvider).isUnauthenticated, isTrue);
    });

    test('signInWithGoogle success → authenticated', () async {
      final container = buildContainer();
      final result =
          await container.read(authStateProvider.notifier).signInWithGoogle();
      expect(result, isA<AuthSuccess<AuthUser>>());
      expect(container.read(authStateProvider).isAuthenticated, isTrue);
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
      final container = buildContainer(
        gateway: FakeAuthGateway(autoVerifyEmails: true),
      );
      final notifier = container.read(authStateProvider.notifier);
      await notifier.registerWithEmail(email: 'a@b.com', password: 'secret1');
      expect(container.read(authStateProvider).isAuthenticated, isTrue);

      await notifier.signOut();
      expect(container.read(authStateProvider).isUnauthenticated, isTrue);
    });

    test('sendPasswordResetEmail success for registered user', () async {
      final container = buildContainer();
      final notifier = container.read(authStateProvider.notifier);
      await notifier.registerWithEmail(email: 'a@b.com', password: 'secret1');
      await notifier.signOut();

      final result =
          await notifier.sendPasswordResetEmail(email: 'a@b.com');
      expect(result, isA<AuthSuccess<void>>());
    });

    test('sendPasswordResetEmail failure for unknown user', () async {
      final container = buildContainer();
      final result = await container
          .read(authStateProvider.notifier)
          .sendPasswordResetEmail(email: 'x@y.com');
      expect((result as AuthFailureResult).failure.code,
          AuthFailureCode.userNotFound);
    });

    test('sendEmailVerification then reload after verify → authenticated',
        () async {
      final gateway = FakeAuthGateway();
      final container = buildContainer(gateway: gateway);
      final notifier = container.read(authStateProvider.notifier);

      await notifier.registerWithEmail(email: 'a@b.com', password: 'secret1');
      expect(notifier, isNotNull);

      final sent = await notifier.sendEmailVerification();
      expect(sent, isA<AuthSuccess<void>>());
      expect(gateway.sendVerificationCalled, isTrue);

      gateway.markEmailVerified();
      final reloaded = await notifier.reloadUser();
      expect(reloaded, isA<AuthSuccess<AuthUser>>());
      expect(container.read(authStateProvider).isAuthenticated, isTrue);
    });

    test('auth disabled → operations return operationNotAllowed', () async {
      final container = buildContainer(authEnabled: false);
      final notifier = container.read(authStateProvider.notifier);
      final result =
          await notifier.signInWithEmail(email: 'a@b.com', password: 'secret1');
      expect((result as AuthFailureResult).failure.code,
          AuthFailureCode.operationNotAllowed);
    });
  });
}
