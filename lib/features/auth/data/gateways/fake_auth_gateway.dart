import 'dart:async';

import '../../domain/entities/auth_result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/gateways/auth_gateway.dart';

/// In-memory [AuthGateway] for tests and previews.
///
/// Simulates authenticated / unauthenticated users and configurable
/// operation errors without touching Firebase.
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({AuthUser? initialUser}) : _user = initialUser;

  AuthUser? _user;
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  /// Forced failures for the next matching operation (cleared after use).
  AuthFailureCode? failNextGoogle;
  bool failSignOut = false;

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
