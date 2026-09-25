import 'dart:async';

import '../entities/auth_result.dart';
import '../entities/auth_user.dart';

/// Boundary between the application and the authentication provider.
///
/// The domain layer depends only on this interface — never on Firebase.
/// Production uses `FirebaseAuthGateway`; tests use `FakeAuthGateway`.
///
/// Google Sign-In is the only supported way to establish a session.
abstract interface class AuthGateway {
  /// Stream of authentication-state changes (`null` = signed out).
  ///
  /// Emits only on changes; initial state is read via [currentUser].
  Stream<AuthUser?> get authStateChanges;

  /// The currently signed-in user, or `null`.
  AuthUser? get currentUser;

  /// Signs the current user out (Google session + Firebase session).
  Future<AuthResult<void>> signOut();

  /// Real Google Sign-In (OAuth → Firebase credential).
  Future<AuthResult<AuthUser>> signInWithGoogle();
}
