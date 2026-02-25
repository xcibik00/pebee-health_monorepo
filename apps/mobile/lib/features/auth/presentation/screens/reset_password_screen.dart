import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/language_switcher.dart';
import '../../providers/auth_provider.dart';
import '../widgets/password_field.dart';

/// Screen where the user sets a new password after tapping the reset link.
/// Shown when a [AuthChangeEvent.passwordRecovery] event is detected.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePasswords = true;
  bool _passwordUpdated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).updatePassword(
          newPassword: _passwordController.text,
        );
    if (mounted && !ref.read(authNotifierProvider).hasError) {
      setState(() => _passwordUpdated = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () {
            ref.read(authNotifierProvider.notifier).signOut();
            context.go(AppRoutes.login);
          },
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: LanguageSwitcher(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: _passwordUpdated
              ? _buildSuccessView(context)
              : _buildFormView(context, authAsync),
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context, AsyncValue<void> authAsync) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'auth.resetPassword.title'.tr(),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'auth.resetPassword.subtitle'.tr(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 32),

          // ── New password ───────────────────────────────────────────
          PasswordField(
            controller: _passwordController,
            labelText: 'auth.resetPassword.passwordLabel'.tr(),
            hintText: 'auth.resetPassword.passwordHint'.tr(),
            textInputAction: TextInputAction.next,
            obscureText: _obscurePasswords,
            onToggleObscure: () =>
                setState(() => _obscurePasswords = !_obscurePasswords),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'validation.passwordRequired'.tr();
              }
              if (value.length < 8) {
                return 'validation.passwordTooShort'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ── Confirm new password ───────────────────────────────────
          PasswordField(
            controller: _confirmPasswordController,
            labelText: 'auth.resetPassword.confirmPasswordLabel'.tr(),
            hintText: 'auth.resetPassword.confirmPasswordHint'.tr(),
            textInputAction: TextInputAction.done,
            showVisibilityToggle: false,
            obscureText: _obscurePasswords,
            onFieldSubmitted: (_) => _submit(),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'validation.passwordMismatch'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // ── Error banner ───────────────────────────────────────────
          if (authAsync.hasError) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.errorBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'auth.resetPassword.error'.tr(),
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Reset button ───────────────────────────────────────────
          ElevatedButton(
            onPressed: authAsync.isLoading ? null : _submit,
            child: authAsync.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('auth.resetPassword.resetButton'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Icon(Icons.check_circle_outline,
            size: 64, color: AppColors.primary),
        const SizedBox(height: 24),
        Text(
          'auth.resetPassword.successTitle'.tr(),
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'auth.resetPassword.successMessage'.tr(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            ref.read(authNotifierProvider.notifier).signOut();
            context.go(AppRoutes.login);
          },
          child: Text('auth.resetPassword.goToLogin'.tr()),
        ),
      ],
    );
  }
}
