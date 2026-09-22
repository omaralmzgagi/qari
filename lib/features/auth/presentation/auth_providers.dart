import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_controller.dart';

/// Current authentication state for the whole app.
final authStateProvider = AutoDisposeNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);