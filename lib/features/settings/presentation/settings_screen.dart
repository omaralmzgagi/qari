import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/branding/brand_info.dart';
import '../../../features/settings/domain/entities/app_settings.dart';
import '../../../localization/app_locale.dart';
import '../../../localization/app_localization_ext.dart';
import '../../../theme/app_theme_mode.dart';
import '../../../theme/tokens/app_colors.dart';
import '../../../theme/tokens/app_radius.dart';
import '../../../theme/tokens/app_spacing.dart';
import '../../../theme/tokens/app_typography.dart';

/// Application settings screen (identity preview).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final settingsAsync = ref.watch(settingsControllerProvider);
    final settings = settingsAsync.valueOrNull ?? AppSettings.defaults;
    final controller = ref.read(
      settingsControllerProvider.notifier,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          _SectionLabel(l10n.settingsAppearance),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsTheme,
                    style: AppTypography.body(theme.brightness),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<AppThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: AppThemeMode.system,
                          icon: const Icon(Icons.brightness_auto_outlined),
                          label: Text(l10n.settingsThemeSystem),
                        ),
                        ButtonSegment(
                          value: AppThemeMode.light,
                          icon: const Icon(Icons.light_mode_outlined),
                          label: Text(l10n.settingsThemeLight),
                        ),
                        ButtonSegment(
                          value: AppThemeMode.dark,
                          icon: const Icon(Icons.dark_mode_outlined),
                          label: Text(l10n.settingsThemeDark),
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (selection) =>
                          controller.setThemeMode(selection.first),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel(l10n.settingsLanguage),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                _LanguageTile(
                  title: l10n.settingsLanguageArabic,
                  subtitle: 'العربية',
                  selected: settings.locale == AppLocale.arabic,
                  onTap: () => controller.setLocale(AppLocale.arabic),
                ),
                _LanguageTile(
                  title: l10n.settingsLanguageEnglish,
                  subtitle: 'English',
                  selected: settings.locale == AppLocale.english,
                  onTap: () => controller.setLocale(AppLocale.english),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel(l10n.settingsAbout),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.aboutTitle),
              subtitle: Text(
                '${l10n.settingsVersion} ${AppConfig.appVersion}',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Column(
              children: [
                Text(
                  BrandInfo.taglineEnglish,
                  style: AppTypography.caption(theme.brightness),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  BrandInfo.taglineArabic,
                  style: AppTypography.caption(theme.brightness),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.caption(Theme.of(context).brightness)
          .copyWith(letterSpacing: 1.1),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      title: Row(
        children: [
          Text(title, style: AppTypography.body(theme.brightness)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            subtitle,
            style: AppTypography.caption(theme.brightness),
          ),
        ],
      ),
      trailing: selected
          ? Icon(Icons.check_circle, color: AppColors.success)
          : const Icon(Icons.circle_outlined),
      onTap: onTap,
    );
  }
}
