import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown by [AuthRepository.signIn] when the user's email has not been
/// confirmed yet. The login screen catches this and redirects the user to
/// the verification screen so they can enter (or re-request) their OTP.
class EmailNotConfirmedException implements Exception {
  const EmailNotConfirmedException(this.email);

  /// The email address the user attempted to sign in with.
  final String email;
}

/// Thrown by [AuthRepository.resendOtp] when Supabase rejects the request
/// because too many emails have been sent recently (HTTP 429).
/// The UI should start its cooldown timer to block further attempts.
class ResendRateLimitedException implements Exception {
  const ResendRateLimitedException();
}

/// Wraps all Supabase auth calls.
/// The rest of the app must never import supabase_flutter directly —
/// all auth operations go through this repository.
class AuthRepository {
  const AuthRepository(this._supabase);

  final SupabaseClient _supabase;

  /// The current authenticated user, or null if not logged in.
  User? get currentUser => _supabase.auth.currentUser;

  /// Stream of auth state changes. Used by the router to redirect on
  /// login / logout.
  Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  /// Signs in an existing user with email and password.
  ///
  /// Throws [EmailNotConfirmedException] when the account exists but the
  /// email has not been verified yet — the caller should redirect to the
  /// verification screen with [email] so the user can complete sign-up.
  ///
  /// Throws [AuthException] on invalid credentials or network failure.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('email not confirmed')) {
        throw EmailNotConfirmedException(email.trim());
      }
      rethrow;
    }
  }

  /// Creates a new user account and sends a verification email.
  /// First name, last name, and preferred locale are stored in user metadata
  /// and synced to the public.profiles table via a Postgres trigger.
  /// The locale is used by the email Edge Function to send a localised email.
  ///
  /// Throws [AuthException] if the email is already registered.
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String locale,
  }) async {
    await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'locale': locale,
      },
    );
  }

  /// Verifies the 8-digit OTP code sent to [email] during sign-up.
  ///
  /// On success, Supabase automatically signs the user in and fires an
  /// [AuthChangeEvent.signedIn], which the router guard picks up to
  /// redirect to the home screen.
  ///
  /// Throws [AuthException] if the code is invalid or expired.
  Future<void> verifyOtp({
    required String email,
    required String token,
  }) async {
    await _supabase.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.signup,
    );
  }

  /// Resends the sign-up OTP email to [email].
  ///
  /// Throws [ResendRateLimitedException] when Supabase rate-limits the
  /// request (HTTP 429). Throws [AuthException] on other failures.
  Future<void> resendOtp({required String email}) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
      );
    } on AuthException catch (e) {
      if (e.statusCode == '429') {
        throw const ResendRateLimitedException();
      }
      rethrow;
    }
  }

  /// Sends a password reset email to [email].
  ///
  /// The email contains a magic link that opens the app via custom URL scheme,
  /// triggering an [AuthChangeEvent.passwordRecovery] event. The user is then
  /// shown the new-password screen.
  ///
  /// Throws [AuthException] on failure (e.g. email not found).
  Future<void> resetPasswordForEmail({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'com.pebeehealth.mobile://reset-password',
    );
  }

  /// Updates the current user's password.
  ///
  /// Called after the user taps the reset link and enters a new password.
  /// Requires an active recovery session (set by Supabase when the reset
  /// link is opened).
  ///
  /// Throws [AuthException] on failure.
  Future<void> updatePassword({required String newPassword}) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Signs out the current user and clears the local session.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
