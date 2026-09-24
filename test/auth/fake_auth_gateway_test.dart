import 'package:flutter_test/flutter_test.dart';
import 'package:qari/features/auth/data/gateways/fake_auth_gateway.dart';
import 'package:qari/features/auth/domain/entities/auth_result.dart';
import 'package:qari/features/auth/domain/entities/auth_user.dart';
import 'package:qari/features/auth/domain/failures/auth_failure.dart';
import 'package:qari/features/auth/domain/validators/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    test('accepts valid emails', () {
      expect(AuthValidators.isValidEmail('user@example.com'), isTrue);
      expect(AuthValidators.isValidEmail('  user+tag@sub.domain.co '), isTrue);
      expect(AuthValidators.emailError('user@example.com'), isNull);
    });

    test('rejects invalid emails', () {
      expect(AuthValidators.isValidEmail(''), isFalse);
      expect(AuthValidators.isValidEmail('not-an-email'), isFalse);
      expect(AuthValidators.emailError('bad'), 'invalidEmail');
    });

    test('enforces password rules', () {
      expect(AuthValidators.passwordError(''), 'passwordRequired');
      expect(AuthValidators.passwordError('12345'), 'passwordTooShort');
      expect(AuthValidators.passwordError('123456'), isNull);
      expect(AuthValidators.isStrongEnoughPassword('secret1'), isTrue);
    });
  });

  group('FakeAuthGateway', () {
    test('register then sign-in yields unverified user by default', () async {
      final gateway = FakeAuthGateway();
      final reg = await gateway.registerWithEmail(
        email: 'a@b.com',
        password: 'secret1',
        displayName: 'A',
      );
      expect(reg, isA<AuthSuccess<AuthUser>>());
      expect(gateway.currentUser?.emailVerified, isFalse);

      gateway.clearUser();
      final sign = await gateway.signInWithEmail(
        email: 'a@b.com',
        password: 'secret1',
      );
      expect(sign, isA<AuthSuccess<AuthUser>>());
      expect(gateway.currentUser, isNotNull);
      await gateway.dispose();
    });

    test('sign-in unknown email → userNotFound', () async {
      final gateway = FakeAuthGateway();
      final result = await gateway.signInWithEmail(
        email: 'missing@b.com',
        password: 'secret1',
      );
      expect(result, isA<AuthFailureResult<AuthUser>>());
      final failure = (result as AuthFailureResult<AuthUser>).failure;
      expect(failure.code, AuthFailureCode.userNotFound);
      await gateway.dispose();
    });

    test('wrong password → wrongPassword', () async {
      final gateway = FakeAuthGateway();
      await gateway.registerWithEmail(email: 'a@b.com', password: 'secret1');
      gateway.clearUser();
      final result = await gateway.signInWithEmail(
        email: 'a@b.com',
        password: 'wrong99',
      );
      expect((result as AuthFailureResult).failure.code,
          AuthFailureCode.wrongPassword);
      await gateway.dispose();
    });

    test('duplicate register → emailAlreadyInUse', () async {
      final gateway = FakeAuthGateway();
      await gateway.registerWithEmail(email: 'a@b.com', password: 'secret1');
      final again = await gateway.registerWithEmail(
        email: 'a@b.com',
        password: 'secret1',
      );
      expect((again as AuthFailureResult).failure.code,
          AuthFailureCode.emailAlreadyInUse);
      await gateway.dispose();
    });

    test('password reset for registered email succeeds', () async {
      final gateway = FakeAuthGateway();
      await gateway.registerWithEmail(email: 'a@b.com', password: 'secret1');
      final reset =
          await gateway.sendPasswordResetEmail(email: 'a@b.com');
      expect(reset, isA<AuthSuccess<void>>());
      await gateway.dispose();
    });

    test('password reset unknown email fails', () async {
      final gateway = FakeAuthGateway();
      final reset =
          await gateway.sendPasswordResetEmail(email: 'nope@b.com');
      expect((reset as AuthFailureResult).failure.code,
          AuthFailureCode.userNotFound);
      await gateway.dispose();
    });

    test('google sign-in produces verified google user', () async {
      final gateway = FakeAuthGateway();
      final result = await gateway.signInWithGoogle();
      expect(result, isA<AuthSuccess<AuthUser>>());
      final user = (result as AuthSuccess<AuthUser>).value;
      expect(user.emailVerified, isTrue);
      expect(user.provider, AuthProviderKind.google);
      await gateway.dispose();
    });

    test('google cancelled error is mapped', () async {
      final gateway = FakeAuthGateway()
        ..failNextGoogle = AuthFailureCode.googleSignInCancelled;
      final result = await gateway.signInWithGoogle();
      expect((result as AuthFailureResult).failure.isCancelled, isTrue);
      await gateway.dispose();
    });

    test('verification flow: send + reload after markEmailVerified', () async {
      final gateway = FakeAuthGateway();
      await gateway.registerWithEmail(email: 'a@b.com', password: 'secret1');
      final sent = await gateway.sendEmailVerification();
      expect(sent, isA<AuthSuccess<void>>());
      expect(gateway.sendVerificationCalled, isTrue);

      gateway.markEmailVerified();
      final reloaded = await gateway.reloadUser();
      expect((reloaded as AuthSuccess<AuthUser>).value.emailVerified, isTrue);
      await gateway.dispose();
    });

    test('signOut clears currentUser and emits null', () async {
      final gateway = FakeAuthGateway();
      await gateway.registerWithEmail(email: 'a@b.com', password: 'secret1');
      await gateway.signOut();
      expect(gateway.currentUser, isNull);
      expect(gateway.signOutCallCount, 1);
      await gateway.dispose();
    });

    test('forced sign-in failure is returned', () async {
      final gateway = FakeAuthGateway()
        ..failNextSignIn = AuthFailureCode.tooManyRequests;
      final result = await gateway.signInWithEmail(
        email: 'a@b.com',
        password: 'secret1',
      );
      expect((result as AuthFailureResult).failure.code,
          AuthFailureCode.tooManyRequests);
      await gateway.dispose();
    });

    test('autoVerifyEmails produces verified password users', () async {
      final gateway = FakeAuthGateway(autoVerifyEmails: true);
      await gateway.registerWithEmail(email: 'a@b.com', password: 'secret1');
      expect(gateway.currentUser?.emailVerified, isTrue);
      await gateway.dispose();
    });
  });
}
