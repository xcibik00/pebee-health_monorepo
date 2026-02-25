import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../consent/providers/consent_provider.dart';
import '../../../consent/services/tracking_consent_service.dart';

/// Placeholder home screen — will be replaced when the dashboard is built.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _consentCheckDone = false;

  Future<void> _checkConsents() async {
    if (_consentCheckDone) return;
    _consentCheckDone = true;

    await _saveTermsAndPrivacyConsent();
    await _checkTrackingConsent();
  }

  /// Saves terms/privacy consent records if they don't exist yet.
  /// For new signups these were accepted via checkboxes; for existing
  /// users they are auto-accepted (or backfilled via SQL migration).
  Future<void> _saveTermsAndPrivacyConsent() async {
    final hasTerms = ref.read(hasTermsConsentProvider);
    final hasPrivacy = ref.read(hasPrivacyConsentProvider);

    if (hasTerms && hasPrivacy) return;
    if (!mounted) return;

    final repository = ref.read(consentRepositoryProvider);
    final platform = Platform.isIOS ? 'ios' : 'android';

    if (!hasTerms) {
      await repository.saveConsent(
        consentType: 'terms',
        granted: true,
        platform: platform,
      );
    }

    if (!hasPrivacy) {
      await repository.saveConsent(
        consentType: 'privacy',
        granted: true,
        platform: platform,
      );
    }

    ref.invalidate(consentsProvider);
  }

  Future<void> _checkTrackingConsent() async {
    final hasConsent = ref.read(hasAttConsentProvider);
    if (hasConsent) return;
    if (!mounted) return;

    final repository = ref.read(consentRepositoryProvider);
    final service = TrackingConsentService(repository);
    await service.requestTrackingConsent(context);

    // Refresh consents so the popup won't appear again
    ref.invalidate(consentsProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Listen for consents data to load, then check if ATT popup is needed.
    // ref.listen must be called inside build (Riverpod requirement).
    ref.listen(consentsProvider, (previous, next) {
      next.whenData((_) => _checkConsents());
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Pebee Health',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textPrimary),
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Text('Dashboard — coming soon'),
      ),
    );
  }
}
