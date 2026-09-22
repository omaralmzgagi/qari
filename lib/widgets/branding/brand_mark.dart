import 'package:flutter/material.dart';

import '../../theme/tokens/app_colors.dart';

/// Vector-drawn QARI brand mark: an open book with a bookmark ribbon.
///
/// This is the canonical in-app logo. It renders with the brand colors from
/// [AppColors] (no asset file required) and can be restyled by editing the
/// colors passed in — or replaced entirely by the asset at [BrandAssets.logo].
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 72,
    this.color,
    this.gradientEnabled = false,
  });

  final double size;
  final Color? color;

  /// When true the mark is filled with the brand gradient instead of a color.
  final bool gradientEnabled;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BookMarkPainter(
          color: resolvedColor,
          gradientEnabled: gradientEnabled,
        ),
      ),
    );
  }
}

class _BookMarkPainter extends CustomPainter {
  _BookMarkPainter({this.color, required this.gradientEnabled});

  final Color? color;
  final bool gradientEnabled;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    if (gradientEnabled) {
      paint.shader = LinearGradient(
        colors: AppColors.brandGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    } else {
      paint.color = color ?? const Color(0xFFFFFFFF);
    }

    final cx = w / 2;
    final cy = h / 2 - h * 0.02;
    final s = w * 0.55;

    Offset p(double dx, double dy) => Offset(cx + dx * s, cy + dy * s);

    // Left page.
    final left = Path()
      ..moveTo(p(-0.24, -0.23).dx, p(-0.24, -0.23).dy)
      ..lineTo(p(-0.008, -0.105).dx, p(-0.008, -0.105).dy)
      ..lineTo(p(-0.03, 0.055).dx, p(-0.03, 0.055).dy)
      ..lineTo(p(-0.31, -0.07).dx, p(-0.31, -0.07).dy)
      ..close();

    // Right page.
    final right = Path()
      ..moveTo(p(0.008, -0.105).dx, p(0.008, -0.105).dy)
      ..lineTo(p(0.24, -0.23).dx, p(0.24, -0.23).dy)
      ..lineTo(p(0.31, -0.07).dx, p(0.31, -0.07).dy)
      ..lineTo(p(0.03, 0.055).dx, p(0.03, 0.055).dy)
      ..close();

    // Bookmark ribbon.
    final ribbon = Path()
      ..moveTo(p(-0.02, 0.085).dx, p(-0.02, 0.085).dy)
      ..lineTo(p(-0.055, 0.085).dx, p(-0.055, 0.085).dy)
      ..lineTo(p(-0.055, 0.20).dx, p(-0.055, 0.20).dy)
      ..close();

    canvas.drawPath(left, paint);
    canvas.drawPath(right, paint);
    canvas.drawPath(ribbon, paint);
  }

  @override
  bool shouldRepaint(covariant _BookMarkPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.gradientEnabled != gradientEnabled;
  }
}