import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/language_switcher.dart';
import '../../providers/auth_provider.dart';

/// Screen where the user enters their email to request a password reset link.
/// After a successful request the UI switches to a confirmation view with
/// a "Back to login" button.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).requestPasswordReset(
          email: _emailController.text,
        );
    if (mounted && !ref.read(authNotifierProvider).hasError) {
      setState(() => _emailSent = true);
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
          child: _emailSent ? _buildSuccessView(context) : _buildFormView(context, authAsync),
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
            'auth.forgotPassword.title'.tr(),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'auth.forgotPassword.subtitle'.tr(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 32),

          // ── Email field ────────────────────────────────────────────
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'auth.forgotPassword.emailLabel'.tr(),
              hintText: 'auth.forgotPassword.emailHint'.tr(),
            ),
            onFieldSubmitted: (_) => _submit(),
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
                'auth.forgotPassword.error'.tr(),
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Send button ────────────────────────────────────────────
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
                : Text('auth.forgotPassword.sendButton'.tr()),
          ),
          const SizedBox(height: 24),

          // ── Back to login ──────────────────────────────────────────
          Center(
            child: TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: Text('auth.forgotPassword.backToLogin'.tr()),
            ),
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
        const Icon(Icons.mark_email_read_outlined,
            size: 64, color: AppColors.primary),
        const SizedBox(height: 24),
        Text(
          'auth.forgotPassword.successTitle'.tr(),
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'auth.forgotPassword.successMessage'.tr(
            namedArgs: {'email': _emailController.text.trim()},
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => context.go(AppRoutes.login),
          child: Text('auth.forgotPassword.backToLogin'.tr()),
        ),
      ],
    );
  }
}
