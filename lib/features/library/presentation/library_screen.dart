import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../localization/app_localization_ext.dart';
import '../../../theme/tokens/app_spacing.dart';
import '../../../theme/tokens/app_typography.dart';
import '../../../widgets/common/qari_constrained.dart';
import '../../../widgets/common/qari_state_view.dart';

/// Library tab: hosts imported files (files import lands in PHASE 04/05).
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        title: Text(l10n.libraryTitle),
        actions: [
          IconButton(
            tooltip: l10n.librarySearch,
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(l10n.featureUnderConstruction),
                  ),
                );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: QariConstrained(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            Text(
              l10n.homeLibrarySubtitle,
              style: AppTypography.bodySmall(theme.brightness),
            ),
            const SizedBox(height: AppSpacing.xl),
            QariEmptyState(
              icon: Icons.collections_bookmark_outlined,
              title: l10n.libraryEmptyTitle,
              message: l10n.libraryEmptySubtitle,
              actionLabel: l10n.libraryImportFile,
              onAction: () => context.push(RoutePaths.fileImport),
            ),
          ],
        ),
      ),
    );
  }
}
