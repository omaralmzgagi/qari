import 'package:flutter/material.dart';

/// Centralized color tokens for QARI | قارئ.
///
/// To change the brand palette later, edit the values here — the whole app
/// (theme, widgets, logo) picks them up automatically. Keep `primary` and
/// `secondary` in sync with `BrandInfo.gradient` if used together.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Brand palette (initial scheme — configurable)
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);

  static const Color primaryText = Color(0xFF111827);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color darkBackground = Color(0xFF0F172A);

  // ---------------------------------------------------------------------------
  // Brand gradient
  // ---------------------------------------------------------------------------
  static const List<Color> brandGradient = [primary, secondary];

  // ---------------------------------------------------------------------------
  // Light palette
  // ---------------------------------------------------------------------------
  static const Color lightPrimaryContainer = Color(0xFFDBEAFE);
  static const Color lightOnPrimaryContainer = Color(0xFF1E3A8A);
  static const Color lightSecondaryContainer = Color(0xFFEDE9FE);
  static const Color lightOnSecondaryContainer = Color(0xFF4C1D95);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightOnSurfaceVariant = Color(0xFF64748B);
  static const Color lightSuccessContainer = Color(0xFFDCFCE7);
  static const Color lightWarningContainer = Color(0xFFFEF3C7);
  static const Color lightErrorContainer = Color(0xFFFEE2E2);

  // ---------------------------------------------------------------------------
  // Splash gradient
  // ---------------------------------------------------------------------------
  static const Color splashDarkStart = Color(0xFF0B1220);
  static const Color splashDarkEnd = Color(0xFF1E1B4B);

  // ---------------------------------------------------------------------------
  // Dark palette
  // ---------------------------------------------------------------------------
  static const Color darkPrimary = Color(0xFF60A5FA);
  static const Color darkSecondary = Color(0xFFA78BFA);
  static const Color darkSuccess = Color(0xFF22C55E);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkError = Color(0xFFF87171);
  static const Color darkPrimaryContainer = Color(0xFF1E3A8A);
  static const Color darkOnPrimaryContainer = Color(0xFFDBEAFE);
  static const Color darkSecondaryContainer = Color(0xFF5B21B6);
  static const Color darkOnSecondaryContainer = Color(0xFFEDE9FE);
  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkSurfaceVariant = Color(0xFF1E293B);
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8);
  static const Color darkSuccessContainer = Color(0xFF14532D);
  static const Color darkWarningContainer = Color(0xFF78350F);
  static const Color darkErrorContainer = Color(0xFF7F1D1D);

  // ---------------------------------------------------------------------------
  // Semantic token resolvers
  // ---------------------------------------------------------------------------
  static Color primaryTextOn(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFFF1F5F9) : primaryText;

  static Color secondaryTextOn(Brightness brightness) =>
      brightness == Brightness.dark ? darkOnSurfaceVariant : secondaryText;

  static Color borderOn(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFF334155) : border;
}