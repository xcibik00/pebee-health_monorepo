import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/auth_repository.dart';
import '../../providers/auth_provider.dart';

/// Expected OTP code length as sent by Supabase.
const int _otpLength = 8;

/// Maximum number of consecutive failed OTP attempts before the form locks.
const int _maxAttempts = 5;

/// Seconds the user must wait before requesting a new code.
const int _resendCooldownSeconds = 60;

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  /// How many consecutive wrong codes the user has entered.
  int _failedAttempts = 0;

  /// Seconds remaining before the resend button re-enables.
  int _resendCooldown = 0;

  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Clear any stale auth error (e.g. EmailNotConfirmedException left over
    // from the login attempt) so the error banner does not appear before the
    // user has done anything on this screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authNotifierProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // ── Attempt limiting ───────────────────────────────────────────────────────

  bool get _isLocked => _failedAttempts >= _maxAttempts;

  Future<void> _verify() async {
    if (_isLocked) return;
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authNotifierProvider.notifier).verifyOtp(
          email: widget.email,
          token: _codeController.text.trim(),
        );

    // Count failures. On success the auth stream fires signedIn and the
    // router redirects to /home — no explicit navigation needed here.
    if (mounted && ref.read(authNotifierProvider).hasError) {
      setState(() => _failedAttempts++);
    }
  }

  // ── Resend with cooldown ───────────────────────────────────────────────────

  void _startResendCooldown() {
    setState(() {
      _resendCooldown = _resendCooldownSeconds;
      _failedAttempts = 0; // new code → reset attempt counter
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0) return;

    await ref
        .read(authNotifierProvider.notifier)
        .resendOtp(email: widget.email);

    if (!mounted) return;

    if (ref.read(authNotifierProvider).hasError) {
      final isRateLimited =
          ref.read(authNotifierProvider).error is ResendRateLimitedException;
      // Reset so the verify error banner does not show a misleading message.
      ref.read(authNotifierProvider.notifier).reset();
      if (isRateLimited) {
        // Start cooldown so the user can't keep hammering the button.
        _startResendCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.verification.resendRateLimited'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.verification.resendFailed'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    _startResendCooldown();
    _codeController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('auth.verification.resendSuccess'.tr()),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // ── Scrollable centred content ──────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 48),

                      // Email icon
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_outlined,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        'auth.verification.title'.tr(),
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'auth.verification.messagePre'.tr(),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.email,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // ── OTP code input ───────────────────────────────────────
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: _otpLength,
                          enabled: !_isLocked && !authAsync.isLoading,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 12,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'auth.verification.codeLabel'.tr(),
                            hintText: '00000000',
                            counterText: '',
                            hintStyle: const TextStyle(
                              letterSpacing: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'validation.otpRequired'.tr();
                            }
                            if (value.trim().length < _otpLength) {
                              return 'validation.otpInvalid'.tr();
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _verify(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Error / locked banner ────────────────────────────────
                      if (_isLocked) ...[
                        _ErrorBanner(
                            text: 'auth.verification.tooManyAttempts'.tr()),
                        const SizedBox(height: 16),
                      ] else if (authAsync.hasError) ...[
                        _ErrorBanner(
                            text: 'auth.verification.error'.tr()),
                        // Show remaining attempts when there's ≥1 failure
                        if (_failedAttempts > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'auth.verification.attemptsLeft'.tr(
                                namedArgs: {
                                  'remaining':
                                      '${_maxAttempts - _failedAttempts}',
                                },
                              ),
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],

                      // ── Verify button ────────────────────────────────────────
                      ElevatedButton(
                        onPressed:
                            (authAsync.isLoading || _isLocked) ? null : _verify,
                        child: authAsync.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('auth.verification.verifyButton'.tr()),
                      ),
                      const SizedBox(height: 20),

                      // ── Resend row ───────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'auth.verification.noCode'.tr(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          TextButton(
                            onPressed:
                                (_resendCooldown > 0 || authAsync.isLoading)
                                    ? null
                                    : _resend,
                            child: Text(
                              _resendCooldown > 0
                                  ? 'auth.verification.resendIn'.tr(
                                      namedArgs: {
                                        'seconds': '$_resendCooldown',
                                      },
                                    )
                                  : 'auth.verification.resend'.tr(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // ── Back to login — pinned to bottom ─────────────────────────────
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text('auth.verification.backToLogin'.tr()),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable error banner ──────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.error, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }
}
