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
