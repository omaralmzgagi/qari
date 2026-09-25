import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/branding/brand_info.dart';
import '../../../core/routing/app_routes.dart';
import '../../../features/auth/presentation/auth_providers.dart';
import '../../../localization/app_localization_ext.dart';
import '../../../theme/tokens/app_colors.dart';
import '../../../theme/tokens/app_component_sizes.dart';
import '../../../theme/tokens/app_radius.dart';
import '../../../theme/tokens/app_spacing.dart';
import '../../../theme/tokens/app_typography.dart';
import '../../../widgets/branding/brand_mark.dart';
import '../../../widgets/common/qari_constrained.dart';
import '../../../widgets/common/qari_state_view.dart';

/// Branded home screen, ready to host reading features in later phases.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final user = ref.watch(authStateProvider).user;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(
              size: AppComponentSizes.iconXl,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  BrandInfo.nameLatin,
                  style: AppTypography.subtitle(theme.brightness).copyWith(
                    fontWeight: AppFontWeights.semiBold,
                    fontSize: AppFontSizes.md,
                  ),
                ),
                Text(
                  BrandInfo.nameArabic,
                  style: AppTypography.caption(theme.brightness),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go(RoutePaths.settings),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: QariConstrained(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            Text(
              '${l10n.homeGreeting} 👋',
              style: AppTypography.title(theme.brightness),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.homeGreetingSubtitle,
              style: AppTypography.bodySmall(theme.brightness),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.homeQuickActions,
              style: AppTypography.subtitle(theme.brightness),
            ),
            const SizedBox(height: AppSpacing.md),
            const _QuickActionsGrid(),
            const SizedBox(height: AppSpacing.xl),
            QariConstrained(
              child: _SectionHeader(
                title: l10n.homeRecentFiles,
                actionLabel: l10n.homeViewAll,
                onAction: () => context.go(RoutePaths.library),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            QariEmptyState(
              compact: true,
              icon: Icons.history,
              title: l10n.homeNoRecentFiles,
              message: l10n.homeLibraryEmpty,
              actionLabel: l10n.homeAddFirstFile,
              onAction: () => context.push(RoutePaths.fileImport),
            ),
            if (user != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Text(
                  user.email,
                  style: AppTypography.caption(theme.brightness),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Responsive quick actions: 2 per row on phones, 3 per row on wider screens.
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= QariBreakpoints.twoColumns;
        final items = <Widget>[
          _ActionCard(
            icon: Icons.add_circle_outline,
            gradientColors: AppColors.brandGradient,
            title: l10n.homeAddFile,
            subtitle: l10n.homeAddFileSubtitle,
            onTap: () => context.push(RoutePaths.fileImport),
          ),
          _ActionCard(
            icon: Icons.menu_book_outlined,
            title: l10n.homeContinueReading,
            subtitle: l10n.homeContinueReadingSubtitle,
            onTap: () => _comingSoon(context, l10n.featureUnderConstruction),
          ),
          _ActionCard(
            icon: Icons.collections_bookmark_outlined,
            title: l10n.homeLibrary,
            subtitle: l10n.homeLibrarySubtitle,
            onTap: () => context.go(RoutePaths.library),
          ),
        ];

        final perRow = isWide ? 3 : 2;
        final gap = AppSpacing.md;
        final itemWidth = (constraints.maxWidth - gap * (perRow - 1)) / perRow;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children:
              items.map((w) => SizedBox(width: itemWidth, child: w)).toList(),
        );
      },
    );
  }

  void _comingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(title, style: AppTypography.subtitle(theme.brightness)),
        ),
        if (onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.gradientColors,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: (gradientColors != null)
                      ? LinearGradient(colors: gradientColors!)
                      : null,
                  color: gradientColors != null
                      ? null
                      : theme.colorScheme.primaryContainer,
                ),
                child: Icon(
                  icon,
                  size: AppComponentSizes.iconMd,
                  color: gradientColors != null
                      ? Colors.white
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: AppTypography.label(theme.brightness),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: AppTypography.bodySmall(theme.brightness),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
