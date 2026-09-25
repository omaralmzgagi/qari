import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../domain/entities/app_user.dart';
import '../domain/entities/auth_result.dart';
import '../domain/entities/auth_user.dart';
import '../domain/failures/auth_failure.dart';
import '../domain/gateways/auth_gateway.dart';
import '../data/auth_gateway_providers.dart';
import '../data/session_providers.dart';
import '../data/session_store.dart';

/// Whether real Firebase authentication flows are active.
///
/// Defaults to `AppConfig.authEnabled`; tests override with `true` + a
/// `FakeAuthGateway` on `authGatewayProvider`.
final authEnabledProvider = Provider<bool>(
  (ref) => AppConfig.authEnabled,
);

/// Coarse session status for routing and UI.
enum AuthStatus {
  /// Restoring session / awaiting first auth snapshot.
  unknown,

  /// No signed-in user.
  unauthenticated,

  /// Signed in — full app access.
  authenticated,

  /// A recoverable session/auth error (retry available).
  error,
}

/// Immutable authentication state.
@immutable
class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.failure,
  });

  final AuthStatus status;
  final AppUser? user;
  final AuthFailure? failure;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isUnknown => status == AuthStatus.unknown;

  bool get isUnauthenticated => status == AuthStatus.unauthenticated;

  bool get isError => status == AuthStatus.error;

  bool get hasUser => user != null;

  factory AuthState.unknown() => const AuthState(status: AuthStatus.unknown);

  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);

  factory AuthState.authenticated(AppUser user) =>
      AuthState(status: AuthStatus.authenticated, user: user);

  factory AuthState.error(AuthFailure failure, {AppUser? user}) =>
      AuthState(status: AuthStatus.error, failure: failure, user: user);

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    AuthFailure? failure,
    bool clearUser = false,
    bool clearFailure = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

/// Manages the authentication session (persisted snapshot + Google gateway).
///
/// Single listener on `authStateChanges` — screens call the action methods
/// and read [authStateProvider]; they do not open their own stream listeners.
class AuthController extends AutoDisposeNotifier<AuthState> {
  SessionStore get _store => ref.read(sessionStoreProvider);

  AuthGateway get _gateway => ref.read(authGatewayProvider);

  bool get _enabled => ref.read(authEnabledProvider);

  StreamSubscription<AuthUser?>? _subscription;

  @override
  AuthState build() {
    ref.onDispose(_subscription?.cancel ?? () {});
    if (_enabled) {
      _subscribe();
    }
    return AuthState.unknown();
  }

  void _subscribe() {
    _subscription ??= _gateway.authStateChanges.listen(
      _onAuthEvent,
      onError: (Object _) {
        state = AuthState.error(
          const AuthFailure(code: AuthFailureCode.networkRequestFailed),
          user: state.user,
        );
      },
    );
  }

  void _onAuthEvent(AuthUser? user) {
    if (user == null) {
      state = AuthState.unauthenticated();
      return;
    }
    _applyAuthUser(user, persist: true);
  }

  /// Restores the persisted session and, when auth is enabled, the Firebase
  /// user snapshot.
  Future<void> restoreSession() async {
    if (_enabled) {
      _subscribe();
      final user = _gateway.currentUser;
      if (user != null) {
        _applyAuthUser(user, persist: true);
        return;
      }
      final cached = await _store.read();
      if (cached != null) {
        await _store.write(null);
      }
      state = AuthState.unauthenticated();
      return;
    }

    final user = await _store.read();
    state = user == null
        ? AuthState.unauthenticated()
        : AuthState.authenticated(user);
  }

  Future<AuthResult<AuthUser>> signInWithGoogle() async {
    if (!_enabled) return _disabled<AuthUser>();
    final result = await _gateway.signInWithGoogle();
    return _handleUserResult(result);
  }

  Future<AuthResult<void>> signOut() async {
    AuthResult<void> result;
    if (_enabled) {
      result = await _gateway.signOut();
    } else {
      result = const AuthSuccess<void>(null);
    }
    await _store.write(null);
    state = AuthState.unauthenticated();
    return result;
  }

  /// Clears a terminal error and re-reads the session.
  Future<void> retry() => restoreSession();

  AuthResult<T> _disabled<T>() => AuthFailureResult<T>(
        const AuthFailure(code: AuthFailureCode.operationNotAllowed),
      );

  AuthResult<AuthUser> _handleUserResult(AuthResult<AuthUser> result) {
    if (result is AuthFailureResult<AuthUser>) {
      return result;
    }
    final success = result as AuthSuccess<AuthUser>;
    _applyAuthUser(success.value, persist: true);
    return result;
  }

  void _applyAuthUser(AuthUser user, {required bool persist}) {
    final appUser = _toAppUser(user);
    if (persist) {
      unawaited(_store.write(appUser));
    }
    state = AuthState.authenticated(appUser);
  }

  AppUser _toAppUser(AuthUser user) => AppUser(
        id: user.uid,
        email: user.email,
        name: user.displayName,
        photoUrl: user.photoUrl,
        role: user.role,
        provider: user.provider,
      );
}
