import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../localization/app_localization_ext.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/auth_user.dart';
import '../auth_providers.dart';
import '../widgets/auth_messages.dart';
import '../widgets/auth_scaffold.dart';

/// Post-registration email verification gate (PHASE 03).
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  String? _error;
  String? _success;
  bool _busy = false;

  Future<void> _resend() async {
    setState(() {
      _error = null;
      _success = null;
      _busy = true;
    });
    final result =
        await ref.read(authStateProvider.notifier).sendEmailVerification();
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is AuthFailureResult<void>) {
      setState(() => _error = authFailureMessage(context, result.failure));
      return;
    }
    setState(() => _success = context.l10n.verifyEmailSent);
  }

  Future<void> _checkVerified() async {
    setState(() {
      _error = null;
      _success = null;
      _busy = true;
    });
    final result = await ref.read(authStateProvider.notifier).reloadUser();
    if (!mounted) return;
    setState(() => _busy = false);

    if (result is AuthFailureResult<AuthUser>) {
      setState(() => _error = authFailureMessage(context, result.failure));
      return;
    }
    final auth = ref.read(authStateProvider);
    if (auth.isAuthenticated) {
      context.go(RoutePaths.home);
      return;
    }
    setState(() {
      _success = null;
      _error = context.l10n.verifyStillUnverified;
    });
  }

  Future<void> _signOut() async {
    await ref.read(authStateProvider.notifier).signOut();
    if (!mounted) return;
    context.go(RoutePaths.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = ref.watch(authStateProvider);
    final email = auth.user?.email ?? '';

    return AuthScaffold(
      title: l10n.verifyTitle,
      subtitle: email.isEmpty
          ? l10n.verifySubtitle
          : '${l10n.verifySubtitle}\n$email',
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.mark_email_read_outlined, size: 64),
          const SizedBox(height: AppSpacing.lg),
          if (_success != null) ...[
            AuthSuccessBanner(_success!),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (_error != null) ...[
            AuthErrorText(_error!),
            const SizedBox(height: AppSpacing.lg),
          ],
          AuthSubmitButton(
            key: const Key('verify-check-button'),
            label: l10n.verifyIHaveVerified,
            loading: _busy,
            onPressed: _checkVerified,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            key: const Key('verify-resend-button'),
            onPressed: _busy ? null : _resend,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(l10n.verifyResend),
          ),
          const SizedBox(height: AppSpacing.md),
          AuthLink(
            label: l10n.verifySignOut,
            onPressed: _busy ? null : _signOut,
          ),
        ],
      ),
    );
  }
}
