import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';

// ── Repository provider ────────────────────────────────────────────────────

/// Provides the [AuthRepository] singleton backed by the Supabase client.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

// ── Auth state ─────────────────────────────────────────────────────────────

/// Watches Supabase auth state changes.
/// Emits the current [User] or null. Used by the router guard and UI.
final authStateProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges.map((state) => state.session?.user);
});

// ── Auth notifier ──────────────────────────────────────────────────────────

/// State for async auth operations (sign in / sign up).
/// Holds the error message string if an operation failed, null otherwise.
class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Signs in the user. On failure, sets [AsyncError] with the message.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          );
    });
  }

  /// Signs up a new user. On failure, sets [AsyncError] with the message.
  /// [locale] is the user's current app language code (e.g. 'sk', 'en') and
  /// is stored in metadata so emails can be localised via an Edge Function.
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String locale,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signUp(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            locale: locale,
          );
    });
  }

  /// Verifies the 8-digit OTP code the user received by email.
  /// On success, Supabase fires a signed-in event; the router redirects
  /// to home automatically.
  Future<void> verifyOtp({
    required String email,
    required String token,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).verifyOtp(
            email: email,
            token: token,
          );
    });
  }

  /// Resends the sign-up OTP to [email].
  Future<void> resendOtp({required String email}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).resendOtp(email: email);
    });
  }

  /// Requests a password reset email for [email].
  /// Supabase sends a magic link that opens the app via deep link.
  Future<void> requestPasswordReset({required String email}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .resetPasswordForEmail(email: email);
    });
  }

  /// Updates the password for the currently authenticated user.
  /// Called after the user opens the reset link and enters a new password.
  Future<void> updatePassword({required String newPassword}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .updatePassword(newPassword: newPassword);
    });
  }

  /// Clears any current error or loading state back to idle.
  /// Called by screens on mount to avoid showing stale errors from a
  /// previous operation (e.g. the EmailNotConfirmedException from login
  /// being visible immediately on the verification screen).
  void reset() {
    state = const AsyncData(null);
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
    });
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);

// ── Password recovery event ────────────────────────────────────────────────

/// Emits `true` when a [AuthChangeEvent.passwordRecovery] event fires.
/// The router listens to this to redirect the user to the reset-password
/// screen after they tap the magic link in their email.
final passwordRecoveryProvider = StreamProvider<bool>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges
      .map((state) => state.event == AuthChangeEvent.passwordRecovery);
});

// ── Deep link error ───────────────────────────────────────────────────────

/// Holds the last [AuthException] from a failed deep link (e.g. expired or
/// invalid reset link). The login screen watches this to show a snackbar.
/// Set by [deepLinkHandlerProvider], cleared when consumed.
final deepLinkErrorProvider = StateProvider<AuthException?>((ref) => null);

// ── Deep link handler ─────────────────────────────────────────────────────

/// Listens for incoming deep links and processes auth callbacks manually.
///
/// This provider exists because [Supabase.initialize] runs before Riverpod
/// providers are created. If the SDK processes a deep link during init, the
/// [AuthChangeEvent.passwordRecovery] event fires on a broadcast stream with
/// no listeners yet — so it is lost. By disabling `detectSessionInUri` and
/// handling links here (after providers are active), the event is captured.
///
/// Must be watched eagerly in the root widget (after [appRouterProvider] so
/// that [authStateProvider] and [passwordRecoveryProvider] are already
/// subscribed to [onAuthStateChange]).
final deepLinkHandlerProvider = Provider<void>((ref) {
  final repository = ref.read(authRepositoryProvider);
  final appLinks = AppLinks();

  /// Routes an incoming URI through [AuthRepository.handleDeepLink].
  /// On failure (e.g. expired link), stores the error in
  /// [deepLinkErrorProvider] so the UI can show feedback.
  Future<void> processUri(Uri uri) async {
    try {
      await repository.handleDeepLink(uri);
    } on AuthException catch (error) {
      debugPrint('[DeepLink] Auth error processing $uri: ${error.message}');
      ref.read(deepLinkErrorProvider.notifier).state = error;
    }
  }

  // Listen for links arriving while the app is running (warm start).
  final subscription = appLinks.uriLinkStream.listen(
    (Uri uri) => processUri(uri),
    onError: (Object error) {
      debugPrint('[DeepLink] Stream error: $error');
    },
  );

  // Handle the link that launched the app (cold start).
  appLinks.getInitialLink().then((Uri? uri) {
    if (uri != null) {
      processUri(uri);
    }
  });

  // Clean up when provider is disposed (won't happen for root providers,
  // but good practice).
  ref.onDispose(subscription.cancel);
});
