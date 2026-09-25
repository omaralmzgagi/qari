import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/branding/brand_assets.dart';
import '../../../core/config/branding/brand_info.dart';
import '../../../core/routing/app_routes.dart';
import '../../../features/auth/presentation/auth_providers.dart';
import '../../../theme/tokens/app_colors.dart';
import '../../../theme/tokens/app_component_sizes.dart';
import '../../../theme/tokens/app_spacing.dart';
import '../../../theme/tokens/app_typography.dart';

/// Startup screen that applies the brand identity and boots the session.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, this.delay = AppConfig.splashDelay});

  final Duration delay;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 0.86,
    end: 1,
  ).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    // Session restore failures must never block startup: on error the app
    // falls back to the unauthenticated welcome flow.
    try {
      await ref.read(authStateProvider.notifier).restoreSession();
    } catch (_) {
      // Stay unauthenticated -> welcome.
    }
    await Future<void>.delayed(widget.delay);
    if (!mounted) return;

    final router = ref.read(routerProvider);
    final auth = ref.read(authStateProvider);
    if (auth.isError) {
      // Stay on splash; caller may retry via AuthController.retry().
      return;
    }
    // Authenticated sessions always pass through the transition screen so
    // the loading bar is shown before the shell opens.
    router.go(
      auth.isAuthenticated ? RoutePaths.authLoading : RoutePaths.welcome,
    );
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
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      BrandAssets.splashLogo,
                      width: AppComponentSizes.splashLogoSize,
                      height: AppComponentSizes.splashLogoSize,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      BrandInfo.nameLatin,
                      style: AppTypography.headline(theme.brightness)
                          .copyWith(color: Colors.white),
                    ),
                    Text(
                      BrandInfo.nameArabic,
                      style: AppTypography.title(theme.brightness).copyWith(
                        color: Colors.white,
                        fontSize: AppFontSizes.xxl,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      BrandInfo.taglineArabic,
                      style: AppTypography.bodySmall(theme.brightness).copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      BrandInfo.taglineEnglish,
                      style: AppTypography.caption(theme.brightness).copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}