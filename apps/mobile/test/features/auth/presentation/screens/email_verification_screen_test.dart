import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pebee_mobile/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:pebee_mobile/features/auth/providers/auth_provider.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/test_app.dart';

void main() {
  const testEmail = 'test@example.com';
  late FakeAuthNotifier fakeNotifier;

  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() {
    fakeNotifier = FakeAuthNotifier();
  });

  Future<void> pumpVerificationScreen(WidgetTester tester) async {
    await pumpApp(
      tester,
      child: const EmailVerificationScreen(email: testEmail),
      overrides: [
        authNotifierProvider.overrideWith(() => fakeNotifier),
      ],
    );
  }

  group('EmailVerificationScreen', () {
    testWidgets('renders email and expected elements', (tester) async {
      await pumpVerificationScreen(tester);

      expect(find.text('auth.verification.title'), findsOneWidget);
      expect(find.text(testEmail), findsOneWidget);
      expect(find.text('auth.verification.codeLabel'), findsOneWidget);
      expect(find.text('auth.verification.verifyButton'), findsOneWidget);
      expect(find.text('auth.verification.noCode'), findsOneWidget);
      expect(find.text('auth.verification.backToLogin'), findsOneWidget);
    });

    testWidgets('calls reset on mount to clear stale errors', (tester) async {
      await pumpVerificationScreen(tester);

      expect(fakeNotifier.resetCalled, isTrue);
    });

    testWidgets('no error banner on initial render', (tester) async {
      await pumpVerificationScreen(tester);

      expect(find.text('auth.verification.error'), findsNothing);
      expect(find.text('auth.verification.tooManyAttempts'), findsNothing);
    });

    testWidgets('empty code shows validation error', (tester) async {
      await pumpVerificationScreen(tester);

      await tester.tap(find.text('auth.verification.verifyButton'));
      await tester.pumpAndSettle();

      expect(find.text('validation.otpRequired'), findsOneWidget);
    });

    testWidgets('code shorter than 8 digits shows validation error',
        (tester) async {
      await pumpVerificationScreen(tester);

      await tester.enterText(find.byType(TextFormField), '1234');

      await tester.tap(find.text('auth.verification.verifyButton'));
      await tester.pumpAndSettle();

      expect(find.text('validation.otpInvalid'), findsOneWidget);
    });

    testWidgets('valid code calls verifyOtp with correct args',
        (tester) async {
      await pumpVerificationScreen(tester);

      await tester.enterText(find.byType(TextFormField), '12345678');

      await tester.tap(find.text('auth.verification.verifyButton'));
      await tester.pumpAndSettle();

      expect(fakeNotifier.verifyOtpCalled, isTrue);
      expect(fakeNotifier.lastVerifyEmail, testEmail);
      expect(fakeNotifier.lastVerifyToken, '12345678');
    });

    testWidgets('failed verify shows error banner', (tester) async {
      fakeNotifier.verifyOtpError = Exception('Invalid code');

      await pumpVerificationScreen(tester);

      await tester.enterText(find.byType(TextFormField), '12345678');
      await tester.tap(find.text('auth.verification.verifyButton'));
      await tester.pumpAndSettle();

      expect(find.text('auth.verification.error'), findsOneWidget);
    });

    testWidgets('resend calls resendOtp with email', (tester) async {
      await pumpVerificationScreen(tester);

      await tester.tap(find.text('auth.verification.resend'));
      await tester.pumpAndSettle();

      expect(fakeNotifier.resendOtpCalled, isTrue);
      expect(fakeNotifier.lastResendEmail, testEmail);
    });

    testWidgets('back to login navigates away', (tester) async {
      await pumpVerificationScreen(tester);

      await tester.tap(find.text('auth.verification.backToLogin'));
      await tester.pumpAndSettle();

      expect(find.text('LOGIN_ROUTE'), findsOneWidget);
    });
  });
}
