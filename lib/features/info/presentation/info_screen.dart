import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/branding/brand_info.dart';
import '../../../core/routing/app_routes.dart';
import '../../../localization/app_localization_ext.dart';
import '../../../theme/tokens/app_component_sizes.dart';
import '../../../theme/tokens/app_radius.dart';
import '../../../theme/tokens/app_spacing.dart';
import '../../../theme/tokens/app_typography.dart';
import '../../../widgets/branding/brand_mark.dart';
import '../../../widgets/common/qari_constrained.dart';

/// Static informational pages (About / Privacy / Terms / Help / About Us).
enum InfoPage { about, privacy, terms, help, aboutUs }

extension InfoPageContent on InfoPage {
  String titleOf(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      InfoPage.about => l10n.aboutTitle,
      InfoPage.privacy => l10n.infoPrivacyTitle,
      InfoPage.terms => l10n.infoTermsTitle,
      InfoPage.help => l10n.infoHelpTitle,
      InfoPage.aboutUs => l10n.infoAboutUsTitle,
    };
  }

  IconData iconOf() => switch (this) {
        InfoPage.about => Icons.info_outline,
        InfoPage.privacy => Icons.privacy_tip_outlined,
        InfoPage.terms => Icons.description_outlined,
        InfoPage.help => Icons.help_outline,
        InfoPage.aboutUs => Icons.people_outline,
      };

  List<String> paragraphsOf(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      InfoPage.about => [l10n.aboutDescription],
      InfoPage.privacy => [l10n.infoPrivacyBody1, l10n.infoPrivacyBody2],
      InfoPage.terms => [l10n.infoTermsBody1, l10n.infoTermsBody2],
      InfoPage.help => [l10n.infoHelpBody],
      InfoPage.aboutUs => [l10n.infoAboutUsBody],
    };
  }
}

/// Branded, scrollable info page. Pushed inside the settings branch so the
/// bottom navigation stays visible.
class InfoScreen extends ConsumerWidget {
  const InfoScreen.info({super.key, required this.info});

  final InfoPage info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final pages = info.paragraphsOf(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        title: Text(info.titleOf(context)),
        actions: [
          if (info == InfoPage.about) ...[
            IconButton(
              tooltip: l10n.settingsTitle,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.go(RoutePaths.settings),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
      body: QariConstrained(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    info.iconOf(),
                    size: AppComponentSizes.iconLg,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        BrandInfo.nameLatin,
                        style: AppTypography.subtitle(theme.brightness),
                      ),
                      Text(
                        info.titleOf(context),
                        style: AppTypography.bodySmall(theme.brightness),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            ...pages.map(
              (paragraph) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Text(
                  paragraph,
                  style: AppTypography.body(theme.brightness),
                ),
              ),
            ),
            if (info == InfoPage.about) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    BrandMark(
                      size: AppComponentSizes.iconMd,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.aboutVersionLabel,
                        style: AppTypography.bodySmall(theme.brightness),
                      ),
                    ),
                    Text(
                      AppConfig.appVersion,
                      style: AppTypography.label(theme.brightness),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
