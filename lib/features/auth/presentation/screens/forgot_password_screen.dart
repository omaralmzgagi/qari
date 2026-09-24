import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../localization/app_localization_ext.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/validators/auth_validators.dart';
import '../auth_providers.dart';
import '../widgets/auth_messages.dart';
import '../widgets/auth_scaffold.dart';

/// Password-reset email request (PHASE 03).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  String? _error;
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final emailError = AuthValidators.emailError(_emailController.text);
    if (emailError != null) {
      setState(() => _error = authValidationMessage(context, emailError));
      return;
    }

    setState(() => _loading = true);
    final result =
        await ref.read(authStateProvider.notifier).sendPasswordResetEmail(
              email: _emailController.text,
            );
    if (!mounted) return;
    setState(() => _loading = false);

    if (result is AuthFailureResult<void>) {
      setState(() => _error = authFailureMessage(context, result.failure));
      return;
    }
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AuthScaffold(
      title: l10n.forgotPasswordTitle,
      subtitle: l10n.forgotPasswordSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_sent) ...[
            AuthSuccessBanner(l10n.resetEmailSent),
            const SizedBox(height: AppSpacing.lg),
            AuthSubmitButton(
              label: l10n.backToLogin,
              onPressed: () => context.go(RoutePaths.login),
            ),
          ] else ...[
            TextFormField(
              key: const Key('forgot-email-field'),
              controller: _emailController,
              enabled: !_loading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: l10n.authEmailLabel,
                prefixIcon: const Icon(Icons.mail_outline),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AuthErrorText(_error!),
            ],
            const SizedBox(height: AppSpacing.lg),
            AuthSubmitButton(
              label: l10n.sendResetLink,
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.md),
            AuthLink(
              label: l10n.backToLogin,
              onPressed: () => context.go(RoutePaths.login),
            ),
          ],
        ],
      ),
    );
  }
}
