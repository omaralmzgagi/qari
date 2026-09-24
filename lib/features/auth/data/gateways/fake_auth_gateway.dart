import 'dart:async';

import '../../domain/entities/auth_result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/gateways/auth_gateway.dart';

/// In-memory [AuthGateway] for tests and previews.
///
/// Simulates authenticated / unauthenticated / unverified / verified users
/// and configurable operation errors without touching Firebase.
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({
    AuthUser? initialUser,
    this.autoVerifyEmails = false,
  }) : _user = initialUser;

  AuthUser? _user;
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  /// When `true`, register/sign-in produce already-verified users.
  bool autoVerifyEmails;

  /// Last password seen for a given email (simple map for tests).
  final Map<String, String> passwordsByEmail = {};

  /// Emails that already exist in this fake backend.
  final Set<String> registeredEmails = {};

  /// Forced failures for the next matching operation (cleared after use).
  AuthFailureCode? failNextSignIn;
  AuthFailureCode? failNextRegister;
  AuthFailureCode? failNextPasswordReset;
  AuthFailureCode? failNextGoogle;
  bool failSignOut = false;
  bool failSendVerification = false;
  bool failReload = false;

  /// Whether [sendEmailVerification] has been invoked for the current user.
  bool sendVerificationCalled = false;

  /// Number of [signOut] calls.
  int signOutCallCount = 0;

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => _user;

  /// Test helper: sets the user and emits an auth-state change.
  void seedUser(AuthUser user) {
    _user = user;
    _controller.add(user);
  }

  /// Test helper: signs out and emits an auth-state change.
  void clearUser() {
    _user = null;
    _controller.add(null);
  }

  @override
  Future<AuthResult<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final code = failNextSignIn;
    failNextSignIn = null;
    if (code != null) return AuthFailureResult(AuthFailure(code: code));

    final normalized = email.trim().toLowerCase();
    if (!registeredEmails.contains(normalized)) {
      return const AuthFailureResult(
        AuthFailure(code: AuthFailureCode.userNotFound),
      );
    }
    final stored = passwordsByEmail[normalized];
    if (stored != null && stored != password) {
      return const AuthFailureResult(
        AuthFailure(code: AuthFailureCode.wrongPassword),
      );
    }

    final user = AuthUser(
      uid: 'fake-${normalized.hashCode}',
      email: normalized,
      displayName: 'Fake User',
      emailVerified: autoVerifyEmails,
      provider: AuthProviderKind.password,
    );
    passwordsByEmail[normalized] = password;
    _emit(user);
    return AuthSuccess(user);
  }

  @override
  Future<AuthResult<AuthUser>> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final code = failNextRegister;
    failNextRegister = null;
    if (code != null) return AuthFailureResult(AuthFailure(code: code));

    final normalized = email.trim().toLowerCase();
    if (registeredEmails.contains(normalized)) {
      return const AuthFailureResult(
        AuthFailure(code: AuthFailureCode.emailAlreadyInUse),
      );
    }

    registeredEmails.add(normalized);
    passwordsByEmail[normalized] = password;
    final user = AuthUser(
      uid: 'fake-${normalized.hashCode}',
      email: normalized,
      displayName: displayName,
      emailVerified: autoVerifyEmails,
      provider: AuthProviderKind.password,
    );
    _emit(user);
    return AuthSuccess(user);
  }

  @override
  Future<AuthResult<void>> signOut() async {
    signOutCallCount++;
    if (failSignOut) {
      return const AuthFailureResult(
        AuthFailure(code: AuthFailureCode.unknown),
      );
    }
    _emit(null);
    return const AuthSuccess<void>(null);
  }

  @override
  Future<AuthResult<void>> sendPasswordResetEmail({required String email}) async {
    final code = failNextPasswordReset;
    failNextPasswordReset = null;
    if (code != null) return AuthFailureResult(AuthFailure(code: code));

    final normalized = email.trim().toLowerCase();
    if (!registeredEmails.contains(normalized)) {
      return const AuthFailureResult(
        AuthFailure(code: AuthFailureCode.userNotFound),
      );
    }
    return const AuthSuccess<void>(null);
  }

  @override
  Future<AuthResult<void>> sendEmailVerification() async {
    if (_user == null) {
      return const AuthFailureResult(
        AuthFailure(code: AuthFailureCode.userNotFound),
      );
    }
    if (failSendVerification) {
      return const AuthFailureResult(
        AuthFailure(code: AuthFailureCode.unknown),
      );
    }
    sendVerificationCalled = true;
    return const AuthSuccess<void>(null);
  }

  @override
  Future<AuthResult<AuthUser>> reloadUser() async {
    if (failReload) {
      return const AuthFailureResult(
        AuthFailure(code: AuthFailureCode.unknown),
      );
    }
    final user = _user;
    if (user == null) {
      return const AuthFailureResult(
        AuthFailure(code: AuthFailureCode.userNotFound),
      );
    }
    return AuthSuccess(user);
  }

  /// Marks the current user's email as verified (simulates link click).
  void markEmailVerified() {
    final user = _user;
    if (user == null) return;
    _emit(user.copyWith(emailVerified: true));
  }

  @override
  Future<AuthResult<AuthUser>> signInWithGoogle() async {
    final code = failNextGoogle;
    failNextGoogle = null;
    if (code != null) return AuthFailureResult(AuthFailure(code: code));

    const user = AuthUser(
      uid: 'fake-google-user',
      email: 'google.user@example.com',
      displayName: 'Google User',
      emailVerified: true,
      provider: AuthProviderKind.google,
    );
    registeredEmails.add(user.email);
    _emit(user);
    return const AuthSuccess(user);
  }

  void _emit(AuthUser? user) {
    _user = user;
    _controller.add(user);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
