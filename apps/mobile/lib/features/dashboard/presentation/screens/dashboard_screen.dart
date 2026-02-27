import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../consent/providers/consent_provider.dart';
import '../../../consent/services/tracking_consent_service.dart';
import '../widgets/greeting_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/todays_exercise_card.dart';
import '../widgets/training_plan_section.dart';
import '../widgets/weekly_goal_card.dart';

/// The main dashboard tab content. Shows user greeting, stats, weekly goal,
/// today's exercise, and training plan — all with mocked data for now.
///
/// Also handles first-login consent checks (terms, privacy, ATT) via
/// [ref.listen] on [consentsProvider]. This logic was migrated from the
/// original HomeScreen and must remain functional.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _consentCheckDone = false;

  // ── Consent logic (migrated from HomeScreen) ────────────────────────────

  Future<void> _checkConsents() async {
    if (_consentCheckDone) return;
    _consentCheckDone = true;

    await _saveTermsAndPrivacyConsent();
    await _checkTrackingConsent();
  }

  /// Saves terms/privacy consent records if they don't exist yet.
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

  /// Shows the ATT tracking consent popup on iOS if not yet recorded.
  Future<void> _checkTrackingConsent() async {
    final hasConsent = ref.read(hasAttConsentProvider);
    if (hasConsent) return;
    if (!mounted) return;

    final repository = ref.read(consentRepositoryProvider);
    final service = TrackingConsentService(repository);
    await service.requestTrackingConsent(context);

    ref.invalidate(consentsProvider);
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Listen for consents data to load, then check if ATT popup is needed.
    // ref.listen must be called inside build (Riverpod requirement).
    ref.listen(consentsProvider, (previous, next) {
      next.whenData((_) => _checkConsents());
    });

    final user = ref.watch(authStateProvider).valueOrNull;
    final firstName =
        user?.userMetadata?['first_name'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting ────────────────────────────────────────────────
          GreetingHeader(firstName: firstName),
          const SizedBox(height: 24),

          // ── Stat cards ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'dashboard.overallProgress'.tr(),
                  value: '85%',
                  valueColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'dashboard.completedExercises'.tr(),
                  value: '23',
                  valueColor: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Weekly goal ─────────────────────────────────────────────
          const WeeklyGoalCard(completed: 3, total: 5),
          const SizedBox(height: 24),

          // ── Today's exercise ────────────────────────────────────────
          Text(
            'dashboard.todaysExercise'.tr(),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const TodaysExerciseCard(),
          const SizedBox(height: 24),

          // ── Training plan ───────────────────────────────────────────
          const TrainingPlanSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
