import '../failures/auth_failure.dart';

/// Typed outcome of an authentication operation.
///
/// [AuthSuccess] carries the operation's payload; [AuthFailureResult] carries
/// a user-presentable [AuthFailure]. Nothing in the domain layer throws.
sealed class AuthResult<T> {
  const AuthResult();
}

/// A successful authentication operation.
class AuthSuccess<T> extends AuthResult<T> {
  const AuthSuccess(this.value);

  final T value;
}

/// A failed authentication operation.
class AuthFailureResult<T> extends AuthResult<T> {
  const AuthFailureResult(this.failure);

  final AuthFailure failure;
}
