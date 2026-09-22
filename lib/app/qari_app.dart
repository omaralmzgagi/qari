import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/branding/brand_info.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../localization/generated/app_localizations.dart';
import '../theme/qari_theme.dart';
import 'app_providers.dart';

/// Root widget of QARI | قارئ.
class QariApp extends ConsumerWidget {
  const QariApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    // Re-evaluate router redirects whenever the auth session changes.
    ref.listen<AuthState>(authStateProvider, (_, next) {
      ref.read(routerProvider).refresh();
    });

    return MaterialApp.router(
      title: BrandInfo.nameJoined,
      debugShowCheckedModeBanner: false,
      theme: QariTheme.light(),
      darkTheme: QariTheme.dark(),
      themeMode: themeMode.toMaterial(),
      locale: locale.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}