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

/// Email + password sign-in (PHASE 03).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _error;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

    setState(() => _loading = true);
    final result = await ref.read(authStateProvider.notifier).signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (result is AuthFailureResult<AuthUser>) {
      setState(() => _error = authFailureMessage(context, result.failure));
      return;
    }
    _navigateAfterAuth();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    final result =
        await ref.read(authStateProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (result is AuthFailureResult<AuthUser>) {
      if (result.failure.isCancelled) return;
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
    final authEnabled = ref.watch(authEnabledProvider);

    return AuthScaffold(
      title: l10n.loginTitle,
      subtitle: l10n.loginSubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('login-email-field'),
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
              key: const Key('login-password-field'),
              controller: _passwordController,
              enabled: !_loading,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: l10n.authPasswordLabel,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: AuthLink(
                label: l10n.forgotPasswordLink,
                onPressed: authEnabled
                    ? () => context.push(RoutePaths.forgotPassword)
                    : () => ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(content: Text(l10n.authPhasePlaceholder)),
                        ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AuthErrorText(_error!),
            ],
            const SizedBox(height: AppSpacing.lg),
            AuthSubmitButton(
              label: l10n.loginSubmit,
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.md),
            if (authEnabled)
              OutlinedButton.icon(
                key: const Key('login-google-button'),
                onPressed: _loading ? null : _signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata_rounded),
                label: Text(l10n.continueWithGoogle),
                style: OutlinedButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(48),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            AuthLink(
              label: l10n.noAccountCreateOne,
              onPressed: () => context.push(RoutePaths.register),
            ),
          ],
        ),
      ),
    );
  }
}
