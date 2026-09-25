import 'package:flutter/foundation.dart';

import '../gateways/../entities/user_role.dart';

/// Authentication provider that signed a user in.
///
/// Google is the only supported sign-in method; [unknown] covers sessions
/// restored from a session snapshot without provider metadata.
enum AuthProviderKind { google, unknown }

/// Normalized, Firebase-free user model.
///
/// The domain and UI layers depend only on this type — never on
/// `FirebaseAuth.User`. Convert at the gateway boundary.
@immutable
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
    this.provider = AuthProviderKind.unknown,
    this.role = UserRole.user,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;

  /// Whether the email has been verified (Firebase `emailVerified`).
  final bool emailVerified;

  final AuthProviderKind provider;

  /// Always defaults to [UserRole.user]; root is never self-assigned.
  final UserRole role;

  bool get isRoot => role == UserRole.root;

  AuthUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? emailVerified,
    AuthProviderKind? provider,
    UserRole? role,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      provider: provider ?? this.provider,
      role: role ?? this.role,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AuthUser && other.uid == uid && other.email == email;

  @override
  int get hashCode => Object.hash(uid, email);

  @override
  String toString() =>
      'AuthUser(uid: $uid, email: $email, verified: $emailVerified, '
      'provider: ${provider.name}, role: ${role.name})';
}
