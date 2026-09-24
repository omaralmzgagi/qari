import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/auth_result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/gateways/auth_gateway.dart';
import '../mappers/firebase_auth_error_mapper.dart';

/// Production [AuthGateway] backed by Firebase Auth + Google Sign-In.
///
/// Throws nothing: every failure is returned as [AuthFailureResult].
class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuthGateway({
    fb.FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<AuthUser?> get authStateChanges =>
      _auth.authStateChanges().map(_mapUser);

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Future<AuthResult<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthSuccess(_requireUser(credential.user));
    } on fb.FirebaseAuthException catch (e) {
      return AuthFailureResult(FirebaseAuthErrorMapper.fromFirebaseException(e));
    } catch (e) {
      return AuthFailureResult(
        AuthFailure(code: AuthFailureCode.unknown, cause: e),
      );
    }
  }

  @override
  Future<AuthResult<AuthUser>> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return const AuthFailureResult(
          AuthFailure(code: AuthFailureCode.unknown),
        );
      }
      if (displayName != null && displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
        await user.reload();
      }
      return AuthSuccess(_requireUser(_auth.currentUser ?? user));
    } on fb.FirebaseAuthException catch (e) {
      return AuthFailureResult(FirebaseAuthErrorMapper.fromFirebaseException(e));
    } catch (e) {
      return AuthFailureResult(
        AuthFailure(code: AuthFailureCode.unknown, cause: e),
      );
    }
  }

  @override
  Future<AuthResult<void>> signOut() async {
    try {
      // Best-effort Google session clear; ignore failures (may not be signed in).
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      await _auth.signOut();
      return const AuthSuccess<void>(null);
    } catch (e) {
      return AuthFailureResult(
        AuthFailure(code: AuthFailureCode.unknown, cause: e),
      );
    }
  }

  @override
  Future<AuthResult<void>> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const AuthSuccess<void>(null);
    } on fb.FirebaseAuthException catch (e) {
      return AuthFailureResult(FirebaseAuthErrorMapper.fromFirebaseException(e));
    } catch (e) {
      return AuthFailureResult(
        AuthFailure(code: AuthFailureCode.unknown, cause: e),
      );
    }
  }

  @override
  Future<AuthResult<void>> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const AuthFailureResult(
        AuthFailure(code: AuthFailureCode.userNotFound),
      );
    }
    try {
      await user.sendEmailVerification();
      return const AuthSuccess<void>(null);
    } on fb.FirebaseAuthException catch (e) {
      return AuthFailureResult(FirebaseAuthErrorMapper.fromFirebaseException(e));
    } catch (e) {
      return AuthFailureResult(
        AuthFailure(code: AuthFailureCode.unknown, cause: e),
      );
    }
  }

  @override
  Future<AuthResult<AuthUser>> reloadUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const AuthFailureResult(
        AuthFailure(code: AuthFailureCode.userNotFound),
      );
    }
    try {
      await user.reload();
      return AuthSuccess(_requireUser(_auth.currentUser));
    } on fb.FirebaseAuthException catch (e) {
      return AuthFailureResult(FirebaseAuthErrorMapper.fromFirebaseException(e));
    } catch (e) {
      return AuthFailureResult(
        AuthFailure(code: AuthFailureCode.unknown, cause: e),
      );
    }
  }

  @override
  Future<AuthResult<AuthUser>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const AuthFailureResult(
          AuthFailure(code: AuthFailureCode.googleSignInCancelled),
        );
      }
      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      return AuthSuccess(_requireUser(userCredential.user));
    } on fb.FirebaseAuthException catch (e) {
      return AuthFailureResult(FirebaseAuthErrorMapper.fromFirebaseException(e));
    } catch (e) {
      return AuthFailureResult(
        FirebaseAuthErrorMapper.fromGoogleSignInError(e),
      );
    }
  }

  AuthUser? _mapUser(fb.User? user) {
    if (user == null) return null;
    final providers = user.providerData.map((p) => p.providerId).toSet();
    final kind = providers.contains('password')
        ? AuthProviderKind.password
        : providers.contains('google.com')
            ? AuthProviderKind.google
            : AuthProviderKind.unknown;
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
      provider: kind,
    );
  }

  AuthUser _requireUser(fb.User? user) {
    final mapped = _mapUser(user);
    if (mapped == null) {
      throw fb.FirebaseAuthException(code: 'user-not-found');
    }
    return mapped;
  }
}
