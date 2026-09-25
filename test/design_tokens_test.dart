import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qari/features/settings/domain/entities/app_settings.dart';
import 'package:qari/localization/app_locale.dart';
import 'package:qari/theme/app_theme_mode.dart';
import 'package:qari/theme/tokens/app_colors.dart';

void main() {
  group('AppThemeMode', () {
    test('parses names and produces Material modes', () {
      expect(AppThemeMode.fromName('dark'), AppThemeMode.dark);
      expect(AppThemeMode.fromName('light'), AppThemeMode.light);
      expect(AppThemeMode.fromName('system'), AppThemeMode.system);
      expect(AppThemeMode.fromName('unknown'), AppThemeMode.system);
    });
  });

  group('AppLocale', () {
    test('parses language codes with a safe fallback', () {
      expect(AppLocale.fromLanguageCode('ar'), AppLocale.arabic);
      expect(AppLocale.fromLanguageCode('en'), AppLocale.english);
      expect(AppLocale.fromLanguageCode('de'), AppLocale.arabic);
    });
  });

  group('AppSettings', () {
    test('serializes and deserializes without loss', () {
      const original = AppSettings(
        themeMode: AppThemeMode.dark,
        locale: AppLocale.english,
      );

      final decoded = AppSettings.decode(original.encode());

      expect(decoded.themeMode, AppThemeMode.dark);
      expect(decoded.locale, AppLocale.english);
    });

    test('defaults are stable and safe', () {
      expect(AppSettings.defaults.themeMode, AppThemeMode.system);
      expect(AppSettings.defaults.locale, AppLocale.arabic);
    });
  });

  group('Brand colors', () {
    test('exposes the initial palette values', () {
      expect(AppColors.primary, const Color(0xFF2563EB));
      expect(AppColors.secondary, const Color(0xFF7C3AED));
      expect(AppColors.lightBackground, const Color(0xFFF8FAFC));
      expect(AppColors.darkBackground, const Color(0xFF0F172A));
    });
  });
}
