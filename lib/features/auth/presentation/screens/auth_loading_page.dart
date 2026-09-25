import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/config/branding/brand_assets.dart';
import '../../../../core/config/branding/brand_info.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../localization/app_localization_ext.dart';
import '../../../../theme/tokens/app_colors.dart';
import '../../../../theme/tokens/app_component_sizes.dart';
import '../../../../theme/tokens/app_radius.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../../../theme/tokens/app_typography.dart';

/// One-shot transition shown right after a Google session becomes available.
///
/// Runs a horizontal progress bar for [duration] (3 s by default) so the
/// session + brand are visible before the shell opens, then navigates to the
/// home route with `go()` — which replaces the stack, so the Android back
/// button cannot return here.
class AuthLoadingPage extends ConsumerStatefulWidget {
  const AuthLoadingPage({super.key, this.duration = AppConfig.authLoadingDuration});

  final Duration duration;

  @override
  ConsumerState<AuthLoadingPage> createState() => _AuthLoadingPageState();
}

class _AuthLoadingPageState extends ConsumerState<AuthLoadingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(_finish);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (!mounted) return;
    ref.read(routerProvider).go(RoutePaths.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    AppColors.splashDarkStart,
                    AppColors.splashDarkEnd,
                  ]
                : [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.page),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    BrandAssets.splashLogo,
                    key: const Key('auth-loading-logo'),
                    width: AppComponentSizes.splashLogoSize,
                    height: AppComponentSizes.splashLogoSize,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    BrandInfo.nameLatin,
                    textAlign: TextAlign.center,
                    style: AppTypography.headline(theme.brightness)
                        .copyWith(color: Colors.white),
                  ),
                  Text(
                    BrandInfo.nameArabic,
                    textAlign: TextAlign.center,
                    style: AppTypography.title(theme.brightness).copyWith(
                      color: Colors.white,
                      fontSize: AppFontSizes.xxl,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    context.l10n.signingIn,
                    key: const Key('auth-loading-label'),
                    textAlign: TextAlign.center,
                    style: AppTypography.body(theme.brightness).copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: 260,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) => ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: LinearProgressIndicator(
                          key: const Key('auth-loading-progress'),
                          value: _controller.value,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.28),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
