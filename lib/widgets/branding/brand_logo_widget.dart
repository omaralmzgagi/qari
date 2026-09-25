import 'package:flutter/material.dart';

import '../../core/config/branding/brand_assets.dart';
import '../../core/config/branding/brand_info.dart';
import '../../theme/tokens/app_colors.dart';
import '../../theme/tokens/app_spacing.dart';
import '../../theme/tokens/app_typography.dart';
import 'brand_mark.dart';

/// Renders the QARI | قارئ logo.
///
/// By default it draws the vector [BrandMark] (crisp at any size). Set
/// [useAsset] to render one of the configurable brand PNG assets instead —
/// see [BrandAssets] for the replaceable files.
class BrandLogoWidget extends StatelessWidget {
  const BrandLogoWidget({
    super.key,
    this.size = 96,
    this.useAsset = false,
    this.showWordmark = false,
    this.showTagline = false,
    this.brightness,
    this.tagline,
  });

  final double size;
  final bool useAsset;
  final bool showWordmark;
  final bool showTagline;
  final Brightness? brightness;
  final String? tagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = brightness ?? theme.brightness;

    final mark = useAsset
        ? Image.asset(_assetFor(b), width: size, height: size)
        : BrandMark(
            size: size,
            color: _markColor(theme),
            gradientEnabled: false,
          );

    final titleColor =
        b == Brightness.dark ? const Color(0xFFF1F5F9) : AppColors.primaryText;

    final Widget title = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          BrandInfo.nameLatin,
          style: AppTypography.title(b).copyWith(color: titleColor),
        ),
        Text(
          BrandInfo.nameArabic,
          style: AppTypography.subtitle(b).copyWith(
            fontSize: 20,
            fontWeight: AppFontWeights.semiBold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );

    final Widget widget = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        mark,
        if (showWordmark) ...[
          const SizedBox(height: AppSpacing.md),
          title,
        ],
        if (showTagline) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            tagline ??
                (b == Brightness.light
                    ? BrandInfo.taglineEnglish
                    : BrandInfo.taglineArabic),
            textAlign: TextAlign.center,
            style: AppTypography.caption(b),
          ),
        ],
      ],
    );

    return widget;
  }

  String _assetFor(Brightness brightness) {
    return switch (brightness) {
      Brightness.light => BrandAssets.logoLight,
      Brightness.dark => BrandAssets.logoDark,
    };
  }

  Color _markColor(ThemeData theme) => theme.colorScheme.onSurface;
}
