import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/placeholder/presentation/screens/coming_soon_screen.dart';
import '../../features/shell/presentation/screens/main_shell.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

// ── Route names ────────────────────────────────────────────────────────────

abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String emailVerification = '/email-verification';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Shell tabs
  static const String dashboard = '/home/dashboard';
  static const String therapist = '/home/therapist';
  static const String mriReader = '/home/mri-reader';
  static const String wellbeing = '/home/wellbeing';
}

// ── Router provider ────────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isPasswordRecovery =
      ref.watch(passwordRecoveryProvider).valueOrNull ?? false;

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthStateListenable(ref),
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.valueOrNull != null;
      final isOnSplash = state.matchedLocation == AppRoutes.splash;
      final isOnResetPassword =
          state.matchedLocation == AppRoutes.resetPassword;
      final isOnAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.emailVerification ||
          state.matchedLocation == AppRoutes.forgotPassword;
      final isOnProtectedRoute =
          state.matchedLocation.startsWith('/home');

      // While auth is loading, stay on (or redirect to) splash
      if (isLoading) {
        return isOnSplash ? null : AppRoutes.splash;
      }

      // Password recovery deep link: redirect to reset-password screen
      if (isPasswordRecovery && !isOnResetPassword) {
        return AppRoutes.resetPassword;
      }

      // Auth resolved — redirect away from splash
      if (isOnSplash) {
        return isLoggedIn ? AppRoutes.dashboard : AppRoutes.login;
      }

      // Logged-in user trying to access auth pages → send to dashboard
      // (but allow reset-password — user has a recovery session)
      if (isLoggedIn && isOnAuthRoute) {
        return AppRoutes.dashboard;
      }

      // Not logged in trying to access protected pages → send to login
      // (allow auth routes + reset-password)
      if (!isLoggedIn && !isOnAuthRoute && !isOnResetPassword &&
          isOnProtectedRoute) {
        return AppRoutes.login;
      }

      return null; // no redirect needed
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.emailVerification,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),

      // ── Shell with bottom navigation ──────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.therapist,
                builder: (context, state) => ComingSoonScreen(
                  title: 'dashboard.tabs.therapist'.tr(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.mriReader,
                builder: (context, state) => ComingSoonScreen(
                  title: 'dashboard.tabs.mriReader'.tr(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.wellbeing,
                builder: (context, state) => ComingSoonScreen(
                  title: 'dashboard.tabs.wellbeing'.tr(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// ── Auth state listenable ──────────────────────────────────────────────────

/// Bridges Riverpod auth state to GoRouter's [refreshListenable] so the
/// router re-evaluates the redirect whenever auth state changes.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(passwordRecoveryProvider, (_, __) => notifyListeners());
  }
}
