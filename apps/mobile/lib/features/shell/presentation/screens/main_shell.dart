import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';

/// The main application shell that provides the bottom navigation bar
/// and wraps all tab content. Persists across tab switches.
///
/// Uses GoRouter's [StatefulNavigationShell] to manage tab state while
/// preserving each tab's widget tree via IndexedStack internally.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  /// Provided by GoRouter's [StatefulShellRoute.indexedStack].
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home, color: AppColors.primary),
            label: 'dashboard.tabs.home'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outlined),
            selectedIcon: const Icon(Icons.people, color: AppColors.primary),
            label: 'dashboard.tabs.therapist'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.document_scanner_outlined),
            selectedIcon: const Icon(Icons.document_scanner,
                color: AppColors.primary),
            label: 'dashboard.tabs.mriReader'.tr(),
          ),
          NavigationDestination(
            icon: Badge(
              backgroundColor: AppColors.error,
              label: Text(
                'dashboard.comingSoonBadge'.tr(),
                style: const TextStyle(fontSize: 9),
              ),
              child: const Icon(Icons.spa_outlined),
            ),
            selectedIcon: Badge(
              backgroundColor: AppColors.error,
              label: Text(
                'dashboard.comingSoonBadge'.tr(),
                style: const TextStyle(fontSize: 9),
              ),
              child: const Icon(Icons.spa, color: AppColors.primary),
            ),
            label: 'dashboard.tabs.wellbeing'.tr(),
          ),
        ],
      ),
    );
  }
}
