import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/file_engine_config.dart';
import '../../../localization/app_localization_ext.dart';
import '../../../theme/tokens/app_component_sizes.dart';
import '../../../theme/tokens/app_radius.dart';
import '../../../theme/tokens/app_spacing.dart';
import '../../../theme/tokens/app_typography.dart';
import '../../../widgets/common/qari_constrained.dart';
import '../../../widgets/common/qari_state_view.dart';
import '../application/file_import_controller.dart';
import '../data/providers/file_engine_providers.dart';
import '../domain/entities/imported_file.dart';
import '../domain/entities/processing_status.dart';
import 'file_import_error_messages.dart';

/// File Engine entry point: pick a file, watch the pipeline, see the result.
///
/// The screen never contains format logic — it only renders
/// [FileImportState] produced by [FileImportController].
class FileImportScreen extends ConsumerWidget {
  const FileImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final state = ref.watch(fileImportControllerProvider);
    final controller = ref.read(fileImportControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        title: Text(l10n.importTitle),
      ),
      body: QariConstrained(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            Text(
              l10n.importSubtitle,
              style: AppTypography.bodySmall(theme.brightness),
            ),
            const SizedBox(height: AppSpacing.xl),
            ..._buildStateContent(
              context,
              ref,
              state: state,
              onPick: controller.pickAndImport,
              onReset: controller.reset,
            ),
            const SizedBox(height: AppSpacing.xl),
            _FormatsCard(
              config: ref.watch(fileEngineConfigProvider),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStateContent(
    BuildContext context,
    WidgetRef ref, {
    required FileImportState state,
    required VoidCallback onPick,
    required VoidCallback onReset,
  }) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    if (state.isBusy) {
      return [
        _ProgressPanel(
          status: state.status,
          fileName: state.fileName,
        ),
      ];
    }

    if (state.hasError && !state.wasCancelled) {
      return [
        QariErrorState(
          message: fileImportErrorMessage(l10n, state.errorKind!),
          onRetry: onPick,
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton(
            onPressed: onReset,
            child: Text(l10n.back),
          ),
        ),
      ];
    }

    if (state.isCompleted && state.result != null) {
      return [
        _ResultCard(result: state.result!),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.file_open_outlined),
          label: Text(l10n.importAgainButton),
        ),
      ];
    }

    return [
      QariEmptyState(
        icon: Icons.upload_file_outlined,
        title: l10n.importIdleTitle,
        message: l10n.importIdleBody,
        actionLabel: l10n.importPickButton,
        onAction: onPick,
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        l10n.importFormatsHint,
        textAlign: TextAlign.center,
        style: AppTypography.caption(theme.brightness),
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Progress
// ---------------------------------------------------------------------------

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.status, this.fileName});

  final ProcessingStatus status;
  final String? fileName;

  static double? _value(ProcessingStatus status) {
    switch (status) {
      case ProcessingStatus.idle:
        return 0;
      case ProcessingStatus.selecting:
        return 0.15;
      case ProcessingStatus.validating:
        return 0.35;
      case ProcessingStatus.processing:
        return 0.55;
      case ProcessingStatus.extracting:
      case ProcessingStatus.ocr:
        return 0.85;
      case ProcessingStatus.completed:
        return 1;
      case ProcessingStatus.failed:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (fileName != null) ...[
            Row(
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  size: AppComponentSizes.iconMd,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    fileName!,
                    style: AppTypography.label(theme.brightness),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: _value(status),
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerLowest,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  fileImportStatusMessage(l10n, status),
                  style: AppTypography.bodySmall(theme.brightness),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result
// ---------------------------------------------------------------------------

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final ImportedFile result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final rows = <Widget>[
      _ResultRow(
        label: l10n.importDoneLanguage,
        value: detectedLanguageLabel(l10n, result.detectedLanguage),
      ),
      _ResultRow(
        label: l10n.importDoneCharacters,
        value: result.characterCount.toString(),
      ),
      if (result.pageCount != null)
        _ResultRow(
          label: l10n.importDonePages,
          value: result.pageCount.toString(),
        ),
      _ResultRow(
        label: l10n.importDoneSize,
        value: formatByteSize(result.fileSizeBytes),
      ),
      _ResultRow(
        label: l10n.importDoneSource,
        value: result.usedOcr ? l10n.importSourceOcr : l10n.importSourceText,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.primaryContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: theme.colorScheme.primary,
                size: AppComponentSizes.iconXl,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.importDoneTitle,
                  style: AppTypography.subtitle(theme.brightness),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            result.fileName,
            style: AppTypography.label(theme.brightness),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...rows,
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.importDoneHint,
            style: AppTypography.caption(theme.brightness),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption(theme.brightness),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.label(theme.brightness),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Formats
// ---------------------------------------------------------------------------

class _FormatsCard extends StatelessWidget {
  const _FormatsCard({required this.config});

  final FileEngineConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.importSupportedFormatsTitle,
            style: AppTypography.label(theme.brightness),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.importSupportedFormatsBody,
            style: AppTypography.bodySmall(theme.brightness),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                l10n.importMaxSizeLabel,
                style: AppTypography.caption(theme.brightness),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                formatByteSize(config.maxFileSizeBytes),
                style: AppTypography.label(theme.brightness),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.importLegacyFormatsTitle,
            style: AppTypography.label(theme.brightness),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.importLegacyFormatsBody,
            style: AppTypography.caption(theme.brightness),
          ),
        ],
      ),
    );
  }
}
