/// Roles within QARI | قارئ.
enum UserRole {
  /// Regular user authenticated via Google Sign-In.
  user,

  /// Root / owner account. Protected by backend rules.
  root;

  static UserRole fromName(String? name) {
    return UserRole.values.firstWhere(
      (r) => r.name == name,
      orElse: () => UserRole.user,
    );
  }
}
