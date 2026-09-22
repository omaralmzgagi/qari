import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/settings/domain/entities/app_settings.dart';

/// Storage abstraction for [AppSettings].
///
/// The production implementation persists to SharedPreferences; tests use a
/// pure in-memory implementation (see `MemorySettingsService`).
abstract class SettingsService {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}

class SharedPrefsSettingsService implements SettingsService {
  static const String _key = 'app_settings_v1';

  @override
  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return AppSettings.defaults;
    return AppSettings.decode(raw);
  }

  @override
  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, settings.encode());
  }
}

/// In-memory implementation for tests and previews.
class MemorySettingsService implements SettingsService {
  AppSettings current = AppSettings.defaults;

  @override
  Future<AppSettings> load() async => current;

  @override
  Future<void> save(AppSettings settings) async {
    current = settings;
  }
}