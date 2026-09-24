import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../localization/app_localization_ext.dart';
import '../../../../theme/tokens/app_spacing.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/validators/auth_validators.dart';
import '../auth_providers.dart';
import '../widgets/auth_messages.dart';
import '../widgets/auth_scaffold.dart';

/// Email + password registration (PHASE 03).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _error;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final emailError = AuthValidators.emailError(_emailController.text);
    final passwordError = AuthValidators.passwordError(_passwordController.text);
    if (emailError != null || passwordError != null) {
      setState(() {
        _error = authValidationMessage(
          context,
          emailError ?? passwordError!,
        );
      });
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() {
        _error = authValidationMessage(context, 'passwordMismatch');
      });
      return;
    }

    setState(() => _loading = true);
    final result = await ref.read(authStateProvider.notifier).registerWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text.trim().isEmpty
              ? null
              : _nameController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (result is AuthFailureResult<AuthUser>) {
      setState(() => _error = authFailureMessage(context, result.failure));
      return;
    }
    _navigateAfterAuth();
  }

  void _navigateAfterAuth() {
    final auth = ref.read(authStateProvider);
    if (auth.requiresEmailVerification) {
      context.go(RoutePaths.emailVerification);
    } else if (auth.isAuthenticated) {
      context.go(RoutePaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AuthScaffold(
      title: l10n.registerTitle,
      subtitle: l10n.registerSubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('register-name-field'),
              controller: _nameController,
              enabled: !_loading,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.authNameLabel,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              key: const Key('register-email-field'),
              controller: _emailController,
              enabled: !_loading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: l10n.authEmailLabel,
                prefixIcon: const Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              key: const Key('register-password-field'),
              controller: _passwordController,
              enabled: !_loading,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: l10n.authPasswordLabel,
                helperText: l10n.authPasswordHint,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              key: const Key('register-confirm-field'),
              controller: _confirmController,
              enabled: !_loading,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: l10n.authConfirmPasswordLabel,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AuthErrorText(_error!),
            ],
            const SizedBox(height: AppSpacing.lg),
            AuthSubmitButton(
              label: l10n.registerSubmit,
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.md),
            AuthLink(
              label: l10n.haveAccountSignIn,
              onPressed: () => context.go(RoutePaths.login),
            ),
          ],
        ),
      ),
    );
  }
}
