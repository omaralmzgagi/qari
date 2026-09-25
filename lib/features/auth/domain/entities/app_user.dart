import 'package:flutter/foundation.dart';

import 'auth_user.dart';
import 'user_role.dart';

/// An authenticated user of QARI | قارئ.
@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    this.role = UserRole.user,
    this.provider = AuthProviderKind.unknown,
  });

  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final UserRole role;

  /// Authentication provider that created this session (persists across
  /// restarts so the UI can tell a Google session from an unknown one).
  final AuthProviderKind provider;

  bool get isRoot => role == UserRole.root;

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    UserRole? role,
    AuthProviderKind? provider,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      provider: provider ?? this.provider,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'photoUrl': photoUrl,
        'role': role.name,
        'provider': provider.name,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      photoUrl: json['photoUrl'] as String?,
      role: UserRole.fromName(json['role'] as String?),
      provider: AuthProviderKind.values.asNameMap()[json['provider'] as String?] ??
          AuthProviderKind.unknown,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppUser && other.id == id && other.email == email;
  }

  @override
  int get hashCode => Object.hash(id, email);
}