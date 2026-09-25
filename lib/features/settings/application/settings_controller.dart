import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../core/services/storage/settings_service.dart';
import '../../../localization/app_locale.dart';
import '../../../theme/app_theme_mode.dart';
import '../domain/entities/app_settings.dart';

/// Holds and persists the application settings.
///
/// State is loaded from [SettingsService] on startup and saved on every change
/// (offline-first: settings remain available without a connection).
class SettingsController extends AsyncNotifier<AppSettings> {
  SettingsService get _service => ref.read(settingsServiceProvider);

  @override
  Future<AppSettings> build() => _service.load();

  AppSettings get _current => state.valueOrNull ?? AppSettings.defaults;

  Future<void> setThemeMode(AppThemeMode mode) =>
      _update(_current.copyWith(themeMode: mode));

  Future<void> setLocale(AppLocale locale) =>
      _update(_current.copyWith(locale: locale));

  Future<void> _update(AppSettings settings) async {
    state = AsyncData(settings);
    await _service.save(settings);
  }
}
