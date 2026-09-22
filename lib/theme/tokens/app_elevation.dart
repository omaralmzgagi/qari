import 'package:flutter/material.dart';

/// Centralized elevation levels (Material elevation numbers).
abstract final class AppElevation {
  static const double none = 0;
  static const double subtle = 1;
  static const double raised = 2;
  static const double overlay = 4;
  static const double modal = 8;
}

/// Resolves an elevation level to its intended overlay color for a brightness.
abstract final class AppScrim {
  static Color overlay(ColorScheme scheme) => scheme.scrim.withValues(alpha: 0.5);
}