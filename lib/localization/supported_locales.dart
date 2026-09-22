import 'package:flutter/material.dart';

/// Supported locales configured in `lib/localization/l10n/`.
class SupportedLocales {
  static const Locale english = Locale('en');
  static const Locale arabic = Locale('ar');

  static const List<Locale> all = [arabic, english];

  static const Locale defaultLocale = arabic;
}