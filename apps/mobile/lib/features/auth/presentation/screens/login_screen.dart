import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/language_switcher.dart';
import '../../data/auth_repository.dart';
import '../../providers/auth_provider.dart';
import '../widgets/password_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authNotifierProvider);

    // Handle auth errors: redirect unverified users to the verification
    // screen; clear the password field for all other failures.
    ref.listen(authNotifierProvider, (_, next) {
      if (next.hasError) {
        if (next.error is EmailNotConfirmedException) {
          final email =
              (next.error! as EmailNotConfirmedException).email;
          context.go(AppRoutes.emailVerification, extra: email);
          return;
        }
        _passwordController.clear();
      }
    });

    // Show snackbar if the user arrived here via an expired/invalid deep link
    // (e.g. tapped a stale password-reset email).
    ref.listen(deepLinkErrorProvider, (_, error) {
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.login.resetLinkExpired'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
        // Clear so the snackbar doesn't fire again on rebuild.
        ref.read(deepLinkErrorProvider.notifier).state = null;
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Language switcher ─────────────────────────────────────
                const Align(
                  alignment: Alignment.centerRight,
                  child: LanguageSwitcher(),
                ),
                const SizedBox(height: 24),
                Text(
                  'auth.login.title'.tr(),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'auth.login.subtitle'.tr(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 40),

                // ── Email field ──────────────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'auth.login.emailLabel'.tr(),
                    hintText: 'auth.login.emailHint'.tr(),
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

                // ── Password field ────────────────────────────────────────
                PasswordField(
                  controller: _passwordController,
                  labelText: 'auth.login.passwordLabel'.tr(),
                  hintText: 'auth.login.passwordHint'.tr(),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'validation.passwordRequired'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // ── Forgot password ───────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.forgotPassword),
                    child: Text('auth.login.forgotPassword'.tr()),
                  ),
                ),
                const SizedBox(height: 8),

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
                      'auth.login.error'.tr(),
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Sign in button ────────────────────────────────────────
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
                      : Text('auth.login.signInButton'.tr()),
                ),
                const SizedBox(height: 32),

                // ── Create account link ───────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'auth.login.noAccount'.tr(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.signup),
                      child: Text('auth.login.createAccount'.tr()),
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
