import 'package:flutter/material.dart';

/// Centralized shadow definitions for the elevation scale.
abstract final class AppShadows {
  static const List<BoxShadow> level1 = [
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> level2 = [
    BoxShadow(
      color: Color(0x1A0F172A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> level3 = [
    BoxShadow(
      color: Color(0x240F172A),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> level4 = [
    BoxShadow(
      color: Color(0x330F172A),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}
