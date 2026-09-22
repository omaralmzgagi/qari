import '../../../core/database/app_database.dart';
import '../domain/entities/app_user.dart';

/// Persistent storage for the locally cached session.
abstract class SessionStore {
  Future<AppUser?> read();

  Future<void> write(AppUser? user);
}

/// Hive-backed session store (offline-first; survives restarts).
class HiveSessionStore implements SessionStore {
  HiveSessionStore({String boxName = HiveBoxes.session}) : _boxName = boxName;

  final String _boxName;

  static const String _key = 'current_user';

  @override
  Future<AppUser?> read() async {
    if (!AppDatabase.isInitialized) return null;
    final box = AppDatabase.box(_boxName);
    final raw = box.get(_key);
    if (raw == null) return null;
    return AppUser.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> write(AppUser? user) async {
    if (!AppDatabase.isInitialized) return;
    final box = AppDatabase.box(_boxName);
    if (user == null) {
      await box.delete(_key);
    } else {
      await box.put(_key, user.toJson());
    }
  }
}

/// In-memory session store for tests and previews.
class MemorySessionStore implements SessionStore {
  MemorySessionStore([AppUser? initialUser]) : _user = initialUser;

  AppUser? _user;

  @override
  Future<AppUser?> read() async => _user;

  @override
  Future<void> write(AppUser? user) async {
    _user = user;
  }
}