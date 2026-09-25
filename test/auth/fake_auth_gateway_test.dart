import 'package:flutter_test/flutter_test.dart';
import 'package:qari/features/auth/data/gateways/fake_auth_gateway.dart';
import 'package:qari/features/auth/domain/entities/auth_result.dart';
import 'package:qari/features/auth/domain/entities/auth_user.dart';
import 'package:qari/features/auth/domain/failures/auth_failure.dart';

void main() {
  group('FakeAuthGateway', () {
    test('google sign-in produces a verified google user', () async {
      final gateway = FakeAuthGateway();
      final result = await gateway.signInWithGoogle();
      expect(result, isA<AuthSuccess<AuthUser>>());
      final user = (result as AuthSuccess<AuthUser>).value;
      expect(user.emailVerified, isTrue);
      expect(user.provider, AuthProviderKind.google);
      expect(gateway.currentUser, isNotNull);
      await gateway.dispose();
    });

    test('google cancelled error is mapped', () async {
      final gateway = FakeAuthGateway()
        ..failNextGoogle = AuthFailureCode.googleSignInCancelled;
      final result = await gateway.signInWithGoogle();
      expect((result as AuthFailureResult).failure.isCancelled, isTrue);
      expect(gateway.currentUser, isNull);
      await gateway.dispose();
    });

    test('forced google failure is returned and not signed in', () async {
      final gateway = FakeAuthGateway()
        ..failNextGoogle = AuthFailureCode.tooManyRequests;
      final result = await gateway.signInWithGoogle();
      expect(
        (result as AuthFailureResult).failure.code,
        AuthFailureCode.tooManyRequests,
      );
      expect(gateway.currentUser, isNull);
      await gateway.dispose();
    });

    test('signOut clears currentUser and emits null', () async {
      final gateway = FakeAuthGateway();
      await gateway.signInWithGoogle();
      expect(gateway.currentUser, isNotNull);

      await gateway.signOut();
      expect(gateway.currentUser, isNull);
      expect(gateway.signOutCallCount, 1);
      await gateway.dispose();
    });

    test('forced signOut failure keeps the user', () async {
      final gateway = FakeAuthGateway()..failSignOut = true;
      await gateway.signInWithGoogle();
      final result = await gateway.signOut();
      expect(result, isA<AuthFailureResult<void>>());
      expect(gateway.currentUser, isNotNull);
      await gateway.dispose();
    });

    test('authStateChanges emits seed and clear', () async {
      final gateway = FakeAuthGateway();
      final events = <AuthUser?>[];
      final sub = gateway.authStateChanges.listen(events.add);

      gateway.seedUser(const AuthUser(uid: 'u1', email: 'a@b.com'));
      gateway.clearUser();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(events.length, 2);
      expect(events.first?.uid, 'u1');
      expect(events.last, isNull);
      await gateway.dispose();
    });
  });
}
