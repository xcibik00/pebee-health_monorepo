import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../widgets/password_field.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  /// Shared obscure state — the eye icon on the first password field
  /// toggles both fields at once.
  bool _obscurePasswords = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailController.text,
          password: _passwordController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          locale: context.locale.languageCode,
        );
    if (mounted && !ref.read(authNotifierProvider).hasError) {
      context.go(
        AppRoutes.emailVerification,
        extra: _emailController.text.trim(),
      );
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
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'auth.signup.title'.tr(),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'auth.signup.subtitle'.tr(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 32),

                // ── First name ────────────────────────────────────────────
                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'auth.signup.firstNameLabel'.tr(),
                    hintText: 'auth.signup.firstNameHint'.tr(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'validation.firstNameRequired'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Last name ─────────────────────────────────────────────
                TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'auth.signup.lastNameLabel'.tr(),
                    hintText: 'auth.signup.lastNameHint'.tr(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'validation.lastNameRequired'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Email ─────────────────────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'auth.signup.emailLabel'.tr(),
                    hintText: 'auth.signup.emailHint'.tr(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'validation.emailRequired'.tr();
                    }
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'validation.emailInvalid'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Password — eye icon controls both fields ──────────────
                PasswordField(
                  controller: _passwordController,
                  labelText: 'auth.signup.passwordLabel'.tr(),
                  hintText: 'auth.signup.passwordHint'.tr(),
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

                // ── Confirm password — follows the same obscure state ─────
                PasswordField(
                  controller: _confirmPasswordController,
                  labelText: 'auth.signup.confirmPasswordLabel'.tr(),
                  hintText: 'auth.signup.confirmPasswordHint'.tr(),
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

                // ── Generic error banner ──────────────────────────────────
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
                      'auth.signup.error'.tr(),
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Create account button ─────────────────────────────────
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
                      : Text('auth.signup.createButton'.tr()),
                ),
                const SizedBox(height: 24),

                // ── Already have account ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'auth.signup.alreadyHaveAccount'.tr(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: Text('auth.signup.signIn'.tr()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
