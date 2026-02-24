import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/consent_repository.dart';
import '../models/user_consent.dart';

/// Provides the [ConsentRepository] instance.
final consentRepositoryProvider = Provider<ConsentRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ConsentRepository(apiClient);
});

/// Fetches all consent records for the authenticated user.
/// Depends on [authStateProvider] so it only fires when a session exists
/// and automatically refetches after login.
/// Invalidate this provider to re-fetch after saving a new consent.
final consentsProvider = FutureProvider<List<UserConsent>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;

  // No authenticated user yet — return empty list (no consents to show).
  if (user == null) return <UserConsent>[];

  final repository = ref.watch(consentRepositoryProvider);
  return repository.getConsents();
});

/// Derived provider: true if the user has already recorded an ATT consent.
final hasAttConsentProvider = Provider<bool>((ref) {
  final consents = ref.watch(consentsProvider);
  return consents.maybeWhen(
    data: (list) => list.any((c) => c.consentType == 'att'),
    orElse: () => true, // Default to true (don't show popup) while loading or on error
  );
});

/// Derived provider: true if the user has already recorded a Terms consent.
final hasTermsConsentProvider = Provider<bool>((ref) {
  final consents = ref.watch(consentsProvider);
  return consents.maybeWhen(
    data: (list) => list.any((c) => c.consentType == 'terms'),
    orElse: () => true,
  );
});

/// Derived provider: true if the user has already recorded a Privacy consent.
final hasPrivacyConsentProvider = Provider<bool>((ref) {
  final consents = ref.watch(consentsProvider);
  return consents.maybeWhen(
    data: (list) => list.any((c) => c.consentType == 'privacy'),
    orElse: () => true,
  );
});
