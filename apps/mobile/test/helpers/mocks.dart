import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pebee_mobile/features/auth/data/auth_repository.dart';
import 'package:pebee_mobile/features/auth/providers/auth_provider.dart';

/// A controllable [AuthNotifier] for widget tests.
///
/// Override methods are no-ops by default (state stays idle).
/// Set [signInError], [signUpError], etc. before triggering the operation
/// to simulate a failure.
class FakeAuthNotifier extends AuthNotifier {
  // ── Configuration ─────────────────────────────────────────────────────────

  /// When non-null, [signIn] sets the state to [AsyncError] with this value.
  Object? signInError;

  /// When non-null, [signUp] sets the state to [AsyncError] with this value.
  Object? signUpError;

  /// When non-null, [verifyOtp] sets the state to [AsyncError] with this value.
  Object? verifyOtpError;

  /// When non-null, [resendOtp] sets the state to [AsyncError] with this value.
  Object? resendOtpError;

  // ── Call tracking ─────────────────────────────────────────────────────────

  bool signInCalled = false;
  String? lastSignInEmail;
  String? lastSignInPassword;

  bool signUpCalled = false;
  String? lastSignUpEmail;
  String? lastSignUpFirstName;
  String? lastSignUpLastName;
  String? lastSignUpLocale;

  bool verifyOtpCalled = false;
  String? lastVerifyEmail;
  String? lastVerifyToken;

  bool resendOtpCalled = false;
  String? lastResendEmail;

  bool resetCalled = false;

  // ── Overrides ─────────────────────────────────────────────────────────────

  @override
  Future<void> build() async {}

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    signInCalled = true;
    lastSignInEmail = email;
    lastSignInPassword = password;
    state = const AsyncLoading();
    await Future<void>.delayed(Duration.zero);
    if (signInError != null) {
      state = AsyncError(signInError!, StackTrace.current);
    } else {
      state = const AsyncData(null);
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String locale,
  }) async {
    signUpCalled = true;
    lastSignUpEmail = email;
    lastSignUpFirstName = firstName;
    lastSignUpLastName = lastName;
    lastSignUpLocale = locale;
    state = const AsyncLoading();
    await Future<void>.delayed(Duration.zero);
    if (signUpError != null) {
      state = AsyncError(signUpError!, StackTrace.current);
    } else {
      state = const AsyncData(null);
    }
  }

  @override
  Future<void> verifyOtp({
    required String email,
    required String token,
  }) async {
    verifyOtpCalled = true;
    lastVerifyEmail = email;
    lastVerifyToken = token;
    state = const AsyncLoading();
    await Future<void>.delayed(Duration.zero);
    if (verifyOtpError != null) {
      state = AsyncError(verifyOtpError!, StackTrace.current);
    } else {
      state = const AsyncData(null);
    }
  }

  @override
  Future<void> resendOtp({required String email}) async {
    resendOtpCalled = true;
    lastResendEmail = email;
    state = const AsyncLoading();
    await Future<void>.delayed(Duration.zero);
    if (resendOtpError != null) {
      state = AsyncError(resendOtpError!, StackTrace.current);
    } else {
      state = const AsyncData(null);
    }
  }

  @override
  void reset() {
    resetCalled = true;
    state = const AsyncData(null);
  }
}
