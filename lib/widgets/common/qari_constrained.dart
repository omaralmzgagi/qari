import 'package:flutter/material.dart';

import '../../theme/tokens/app_radius.dart';
import '../../theme/tokens/app_spacing.dart';

/// Maximum content width for phone/tablet/desktop responsive layouts.
abstract final class QariBreakpoints {
  static const double maxContentWidth = 840;
  static const double twoColumns = 720;
}

/// Centers content on wide screens so layouts do not stretch on tablets.
class QariConstrained extends StatelessWidget {
  const QariConstrained({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? QariBreakpoints.maxContentWidth,
        ),
        child: child,
      ),
    );
  }
}

/// A rounded card container used across screens for visual consistency.
class QariSurfaceCard extends StatelessWidget {
  const QariSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = AppRadius.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );
    return Material(
      color: theme.colorScheme.surface,
      elevation: 1,
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(onTap: onTap, child: content)
          : content,
    );
  }
}