import 'dart:async';

import '../entities/auth_result.dart';
import '../entities/auth_user.dart';

/// Boundary between the application and the authentication provider.
///
/// The domain layer depends only on this interface — never on Firebase.
/// Production uses `FirebaseAuthGateway`; tests use `FakeAuthGateway`.
abstract interface class AuthGateway {
  /// Stream of authentication-state changes (`null` = signed out).
  ///
  /// Emits only on changes; initial state is read via [currentUser].
  Stream<AuthUser?> get authStateChanges;

  /// The currently signed-in user, or `null`.
  AuthUser? get currentUser;

  /// Signs in an existing user with email + password.
  Future<AuthResult<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Creates a new account and signs the user in.
  Future<AuthResult<AuthUser>> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  /// Signs the current user out (email session + Google session).
  Future<AuthResult<void>> signOut();

  /// Sends a password-reset email to [email].
  Future<AuthResult<void>> sendPasswordResetEmail({required String email});

  /// Sends an email-verification link to the current user.
  Future<AuthResult<void>> sendEmailVerification();

  /// Reloads the current user (refreshes `emailVerified`).
  Future<AuthResult<AuthUser>> reloadUser();

  /// Real Google Sign-In (OAuth → Firebase credential).
  Future<AuthResult<AuthUser>> signInWithGoogle();
}
