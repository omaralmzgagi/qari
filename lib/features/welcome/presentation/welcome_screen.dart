import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/branding/brand_assets.dart';
import '../../../core/config/branding/brand_info.dart';
import '../../../core/routing/app_routes.dart';
import '../../../localization/app_localization_ext.dart';
import '../../../theme/tokens/app_colors.dart';
import '../../../theme/tokens/app_component_sizes.dart';
import '../../../theme/tokens/app_radius.dart';
import '../../../theme/tokens/app_spacing.dart';
import '../../../theme/tokens/app_typography.dart';
import '../../auth/domain/entities/auth_result.dart';
import '../../auth/domain/entities/auth_user.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../auth/presentation/widgets/auth_messages.dart';
import '../../../widgets/branding/brand_mark.dart';
import '../../../widgets/common/qari_constrained.dart';

/// Pre-login screen: the only sign-in entry point (Google only).
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Configurable login background (see BrandAssets.loginBackground).
          Image.asset(
            BrandAssets.loginBackground,
            fit: BoxFit.cover,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x990F172A)],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide =
                    constraints.maxWidth >= QariBreakpoints.twoColumns;
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  child:
                      isWide ? _WideWelcomeLayout() : _StackedWelcomeLayout(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WideWelcomeLayout extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandMark(size: AppComponentSizes.brandMarkSize + 12),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  BrandInfo.nameLatin,
                  textAlign: TextAlign.center,
                  style: AppTypography.headline(theme.brightness)
                      .copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  BrandInfo.nameArabic,
                  textAlign: TextAlign.center,
                  style: AppTypography.title(theme.brightness)
                      .copyWith(color: Colors.white, fontSize: 26),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  BrandInfo.taglineArabic,
                  textAlign: TextAlign.center,
                  style: AppTypography.body(theme.brightness)
                      .copyWith(color: Colors.white.withValues(alpha: 0.92)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xxl),
        SizedBox(
          width: 400,
          child: Center(child: _WelcomeCard()),
        ),
      ],
    );
  }
}

class _StackedWelcomeLayout extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Center(
          child: Column(
            children: [
              BrandMark(size: AppComponentSizes.brandMarkSize),
              const SizedBox(height: AppSpacing.lg),
              Text(
                BrandInfo.nameLatin,
                style: AppTypography.title(theme.brightness)
                    .copyWith(color: Colors.white, fontSize: 30),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                BrandInfo.nameArabic,
                style: AppTypography.subtitle(theme.brightness).copyWith(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        _WelcomeCard(),
      ],
    );
  }
}

class _WelcomeCard extends ConsumerStatefulWidget {
  const _WelcomeCard();

  @override
  ConsumerState<_WelcomeCard> createState() => _WelcomeCardState();
}

class _WelcomeCardState extends ConsumerState<_WelcomeCard> {
  bool _busy = false;

  Future<void> _continueWithGoogle() async {
    setState(() => _busy = true);
    final result =
        await ref.read(authStateProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is AuthFailureResult<AuthUser>) {
      if (result.failure.isCancelled) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(authFailureMessage(context, result.failure))),
        );
      return;
    }
    if (ref.read(authStateProvider).isAuthenticated) {
      context.go(RoutePaths.authLoading);
    }
  }

  void _showDisabled() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.authErrorOperationNotAllowed)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final authEnabled = ref.watch(authEnabledProvider);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.welcomeTitle,
            textAlign: TextAlign.center,
            style: AppTypography.title(Brightness.light),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.welcomeSubtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(Brightness.light),
          ),
          const SizedBox(height: AppSpacing.xl),
          _FeatureGrid(),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            key: const Key('welcome-google-button'),
            onPressed: _busy
                ? null
                : authEnabled
                    ? _continueWithGoogle
                    : _showDisabled,
            style: FilledButton.styleFrom(
              minimumSize:
                  const Size.fromHeight(AppComponentSizes.buttonHeight),
            ),
            icon: const Icon(Icons.g_mobiledata_rounded),
            label: Text(l10n.signInWithGoogle),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.welcomeLegalHint,
            textAlign: TextAlign.center,
            style: AppTypography.caption(Brightness.light),
          ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends ConsumerWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final features = <(IconData, String)>[
      (Icons.auto_stories_outlined, l10n.featureRead),
      (Icons.translate, l10n.featureTranslate),
      (Icons.auto_awesome, l10n.featureSummarize),
      (Icons.headphones, l10n.featureListen),
      (Icons.offline_bolt_outlined, l10n.featureOffline),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: features
          .map(
            (feature) => _FeatureChip(
              icon: feature.$1,
              label: feature.$2,
            ),
          )
          .toList(),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.lightPrimaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppComponentSizes.iconMd, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.caption(Brightness.light).copyWith(
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}
