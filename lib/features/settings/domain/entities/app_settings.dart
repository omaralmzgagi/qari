import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../localization/app_locale.dart';
import '../../../../theme/app_theme_mode.dart';

/// Persisted application settings (theme, app language, ...).
///
/// Serialized to JSON so it can be stored in SharedPreferences / Hive and
/// later synced to Firestore.
@immutable
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.locale,
  });

  final AppThemeMode themeMode;
  final AppLocale locale;

  static const AppSettings defaults = AppSettings(
    themeMode: AppThemeMode.system,
    locale: AppLocale.arabic,
  );

  AppSettings copyWith({
    AppThemeMode? themeMode,
    AppLocale? locale,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'locale': locale.languageCode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: AppThemeMode.fromName(json['themeMode'] as String?),
      locale: AppLocale.fromLanguageCode(json['locale'] as String?),
    );
  }

  String encode() => jsonEncode(toJson());

  static AppSettings decode(String raw) {
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings.defaults;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is AppSettings &&
        other.themeMode == themeMode &&
        other.locale == locale;
  }

  @override
  int get hashCode => Object.hash(themeMode, locale);
}
