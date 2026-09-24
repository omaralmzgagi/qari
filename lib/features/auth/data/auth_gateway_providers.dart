import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../domain/gateways/auth_gateway.dart';
import 'gateways/auth_gateway_selector.dart';
import 'gateways/firebase_auth_gateway.dart';

/// Active [AuthGateway] for the app.
///
/// - `authEnabled == false` → [DisabledAuthGateway] (PHASE 02 placeholder).
/// - `authEnabled == true` → [FirebaseAuthGateway] (real Firebase Auth).
///
/// Tests override this with `FakeAuthGateway`.
final authGatewayProvider = Provider<AuthGateway>((ref) {
  if (!AppConfig.authEnabled) return const DisabledAuthGateway();
  return FirebaseAuthGateway();
});
