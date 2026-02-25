import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

// ── Route names ────────────────────────────────────────────────────────────

abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String emailVerification = '/email-verification';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
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
        return isLoggedIn ? AppRoutes.home : AppRoutes.login;
      }

      // Logged-in user trying to access auth pages → send to home
      // (but allow reset-password — user has a recovery session)
      if (isLoggedIn && isOnAuthRoute) {
        return AppRoutes.home;
      }

      // Not logged in trying to access protected pages → send to login
      // (allow auth routes + reset-password)
      if (!isLoggedIn && !isOnAuthRoute && !isOnResetPassword) {
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
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
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
