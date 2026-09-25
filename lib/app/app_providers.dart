import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/routing/app_router.dart';
import '../core/services/storage/settings_service.dart';
import '../features/settings/application/settings_controller.dart';
import '../features/settings/domain/entities/app_settings.dart';
import '../localization/app_locale.dart';
import '../theme/app_theme_mode.dart';

/// Persisted application settings.
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SharedPrefsSettingsService();
});

/// Loaded application settings state.
final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

/// Resolved theme mode (falls back to the configured default while loading).
final themeModeProvider = Provider<AppThemeMode>((ref) {
  final settings = ref.watch(settingsControllerProvider);
  return settings.valueOrNull?.themeMode ?? AppConfig.defaultThemeMode;
});

/// Resolved app locale (falls back to the configured default while loading).
final localeProvider = Provider<AppLocale>((ref) {
  final settings = ref.watch(settingsControllerProvider);
  return settings.valueOrNull?.locale ?? AppConfig.defaultLocale;
});

/// Application router. Refresh it from app-level listeners when auth changes.
final routerProvider = Provider<GoRouter>((ref) {
  return buildAppRouter(ref);
});
