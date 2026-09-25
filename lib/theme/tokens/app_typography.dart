import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralized typography tokens.
///
/// Font families are intentionally `null` (system fonts) so Arabic and Latin
/// text always render correctly. To bundle custom brand fonts later, drop them
/// into `assets/fonts/`, register them in `pubspec.yaml` and set the family
/// names here.
abstract final class AppFonts {
  static const String? latin = null; // e.g. 'Inter'
  static const String? arabic = null; // e.g. 'NotoNaskhArabic'
}

/// Font sizes scale.
abstract final class AppFontSizes {
  static const double xs = 12;
  static const double sm = 14;
  static const double md = 16;
  static const double lg = 18;
  static const double xl = 22;
  static const double xxl = 28;
  static const double xxxl = 34;
  static const double display = 40;
}

/// Font weights scale.
abstract final class AppFontWeights {
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
}

/// Line height scale (multiplier).
abstract final class AppLineHeights {
  static const double tight = 1.15;
  static const double normal = 1.4;
  static const double relaxed = 1.6;

  /// Comfortable spacing for long reading sessions.
  static const double reader = 1.8;
}

/// Letter spacing scale (pixels).
abstract final class AppLetterSpacing {
  static const double tight = -0.5;
  static const double normal = 0.0;
  static const double wide = 0.5;
}

/// Pre-built text styles used across the app.
abstract final class AppTypography {
  static TextStyle _base(Brightness brightness) {
    final color = brightness == Brightness.dark
        ? const Color(0xFFF1F5F9)
        : AppColors.primaryText;
    return TextStyle(
      fontFamily: AppFonts.latin,
      color: color,
      height: AppLineHeights.normal,
      letterSpacing: AppLetterSpacing.normal,
    );
  }

  static TextStyle display(Brightness brightness) => _base(brightness).copyWith(
        fontSize: AppFontSizes.display,
        fontWeight: AppFontWeights.extraBold,
        height: AppLineHeights.tight,
        letterSpacing: AppLetterSpacing.tight,
      );

  static TextStyle headline(Brightness brightness) =>
      _base(brightness).copyWith(
        fontSize: AppFontSizes.xxxl,
        fontWeight: AppFontWeights.bold,
        height: AppLineHeights.tight,
      );

  static TextStyle title(Brightness brightness) => _base(brightness).copyWith(
        fontSize: AppFontSizes.xxl,
        fontWeight: AppFontWeights.semiBold,
        height: AppLineHeights.tight,
      );

  static TextStyle subtitle(Brightness brightness) =>
      _base(brightness).copyWith(
        fontSize: AppFontSizes.lg,
        fontWeight: AppFontWeights.medium,
        color: AppColors.secondaryTextOn(brightness),
      );

  static TextStyle body(Brightness brightness) => _base(brightness).copyWith(
        fontSize: AppFontSizes.md,
        fontWeight: AppFontWeights.regular,
      );

  static TextStyle bodySmall(Brightness brightness) =>
      _base(brightness).copyWith(
        fontSize: AppFontSizes.sm,
        color: AppColors.secondaryTextOn(brightness),
      );

  static TextStyle caption(Brightness brightness) => _base(brightness).copyWith(
        fontSize: AppFontSizes.xs,
        fontWeight: AppFontWeights.medium,
        color: AppColors.secondaryTextOn(brightness),
      );

  static TextStyle label(Brightness brightness) => _base(brightness).copyWith(
        fontSize: AppFontSizes.md,
        fontWeight: AppFontWeights.semiBold,
      );

  static TextStyle button(Brightness brightness) => _base(brightness).copyWith(
        fontSize: AppFontSizes.md,
        fontWeight: AppFontWeights.semiBold,
        letterSpacing: AppLetterSpacing.wide,
      );
}

/// Reader-specific typography tokens (used by the Reader in later phases).
abstract final class AppReaderTypography {
  static const double minBody = 16;
  static const double defaultBody = 18;
  static const double largeBody = 20;
  static const double maxBody = 24;
  static const double title = 26;
  static const double lineHeightMult = 1.8;

  static TextStyle body(double size, Brightness brightness) =>
      AppTypography.body(brightness).copyWith(
        fontSize: size,
        height: AppLineHeights.reader,
        fontFamily: AppFonts.arabic,
      );
}
