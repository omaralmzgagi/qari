import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/session_providers.dart';
import '../data/session_store.dart';
import '../domain/entities/app_user.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

/// Immutable authentication state.
@immutable
class AuthState {
  const AuthState({
    required this.status,
    this.user,
  });

  final AuthStatus status;
  final AppUser? user;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isUnknown => status == AuthStatus.unknown;

  factory AuthState.unknown() =>
      const AuthState(status: AuthStatus.unknown);

  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);

  factory AuthState.authenticated(AppUser user) =>
      AuthState(status: AuthStatus.authenticated, user: user);

  AuthState copyWith({AuthStatus? status, AppUser? user}) {
    return AuthState(status: status ?? this.status, user: user ?? this.user);
  }
}

/// Manages the local authentication session.
///
/// Real authentication (Google Sign-In, email verification, Root login,
/// password reset) is implemented in PHASE 03. This controller already owns
/// the session lifecycle that those flows will drive.
class AuthController extends AutoDisposeNotifier<AuthState> {
  SessionStore get _store => ref.read(sessionStoreProvider);

  @override
  AuthState build() => AuthState.unknown();

  /// Restores the persisted session from local storage.
  Future<void> restoreSession() async {
    final user = await _store.read();
    state = user == null
        ? AuthState.unauthenticated()
        : AuthState.authenticated(user);
  }

  /// Registers a successful sign-in (used by PHASE 03 flows).
  Future<void> signIn(AppUser user) async {
    await _store.write(user);
    state = AuthState.authenticated(user);
  }

  Future<void> signOut() async {
    await _store.write(null);
    state = AuthState.unauthenticated();
  }
}