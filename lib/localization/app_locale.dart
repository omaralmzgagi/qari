import 'package:flutter/material.dart';

/// Supported application locales.
enum AppLocale {
  arabic('ar', 'العربية'),
  english('en', 'English');

  const AppLocale(this.languageCode, this.nativeName);

  final String languageCode;
  final String nativeName;

  Locale get locale => Locale(languageCode);

  bool get isRtl => this == AppLocale.arabic;

  static AppLocale fromLanguageCode(String? code) {
    return AppLocale.values.firstWhere(
      (l) => l.languageCode == code,
      orElse: () => AppLocale.arabic,
    );
  }
}