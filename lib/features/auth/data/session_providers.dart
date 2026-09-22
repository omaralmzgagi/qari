import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_store.dart';

/// Provider for the session store used by [AuthController].
///
/// Defaults to the Hive-backed implementation; tests override this with
/// [MemorySessionStore].
final sessionStoreProvider = Provider<SessionStore>((ref) {
  return HiveSessionStore();
});