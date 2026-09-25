import '../../domain/entities/auth_result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/gateways/auth_gateway.dart';

/// Gateway used while authentication is disabled (`authEnabled == false`).
///
/// Keeps PHASE 02 behavior: no Firebase touch, always unauthenticated, and
/// every operation fails with [AuthFailureCode.operationNotAllowed].
class DisabledAuthGateway implements AuthGateway {
  const DisabledAuthGateway();

  static AuthResult<T> _disabled<T>() => AuthFailureResult<T>(
        const AuthFailure(code: AuthFailureCode.operationNotAllowed),
      );

  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();

  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthResult<void>> signOut() async => const AuthSuccess<void>(null);

  @override
  Future<AuthResult<AuthUser>> signInWithGoogle() async =>
      _disabled<AuthUser>();
}
